#import "iTunesRemote.h"

@implementation iTunesRemote

+ (id)remote
{
    return [[[iTunesRemote alloc] init] autorelease];
}

- (NSString *)remoteTitle
{
    return @"iTunes Remote";
}

- (NSString *)remoteInformation
{
    return @"Default MenuTunes plugin to control iTunes, by iThink Software.";
}

- (NSImage *)remoteIcon
{
    return nil;
}

- (BOOL)begin
{
    iTunesPSN = [self iTunesPSN];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    
    return YES;
}

- (BOOL)halt
{
    iTunesPSN.highLongOfPSN = kNoProcess;

    //Unregister for application termination in NSWorkspace
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    return YES;
}

- (NSString *)playerFullName
{
    return @"iTunes";
}

- (NSString *)playerSimpleName
{
    return @"iTunes";
}

- (NSDictionary *)capabilities
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool: YES], @"Remote",
                [NSNumber numberWithBool: YES], @"Basic Track Control",
                [NSNumber numberWithBool: YES], @"Track Information",
                [NSNumber numberWithBool: YES], @"Track Navigation",
                [NSNumber numberWithBool: YES], @"Upcoming Songs",
                [NSNumber numberWithBool: YES], @"Playlists",
                [NSNumber numberWithBool: YES], @"Volume",
                [NSNumber numberWithBool: YES], @"Shuffle",
                [NSNumber numberWithBool: YES], @"Repeat Modes",
                [NSNumber numberWithBool: YES], @"Equalizer",
                [NSNumber numberWithBool: YES], @"Track Rating",
                nil];
}

- (ITMTRemotePlayerRunningState)playerRunningState
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    int i;
    int count = [apps count];
    
    for (i = 0; i < count; i++) {
        if ([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
            return ITMTRemotePlayerRunning;
        }
    }
    return ITMTRemotePlayerNotRunning;
}

- (ITMTRemotePlayerPlayingState)playerPlayingState
{
    long result = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlS'), from:'null'() }" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    
    switch (result)
    {
        default:
        case 'kPSS':
            return ITMTRemotePlayerStopped;
        case 'kPSP':
            return ITMTRemotePlayerPlaying;
        case 'kPSp':
            return ITMTRemotePlayerPaused;
        case 'kPSR':
            return ITMTRemotePlayerRewinding;
        case 'kPSF':
            return ITMTRemotePlayerForwarding;
    }
    
    return ITMTRemotePlayerStopped;
}

- (NSArray *)playlists
{
    long i = 0;
    const signed long numPlaylists = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cPly'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:iTunesPSN];
    NSMutableArray *playlists = [[NSMutableArray alloc] initWithCapacity:numPlaylists];
    
    for (i = 1; i <= numPlaylists; i++) {
        const long j = i;
        NSString *sendStr = [NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() } }",(unsigned long)j];
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:sendStr eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
        [playlists addObject:theObj];
    }
    return [playlists autorelease];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:[NSString stringWithFormat:@"kocl:type('cTrk'), '----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() }",index] eventClass:@"core" eventID:@"cnte" appPSN:iTunesPSN];
}

- (ITMTRemotePlayerPlaylistClass)classOfPlaylistAtIndex:(int)index
{
    int realResult = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pcls" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    

    switch (realResult)
	   {
	   case 'cLiP':
		  return ITMTRemotePlayerLibraryPlaylist;
		  break;
	   case 'cRTP':
		  return ITMTRemotePlayerRadioPlaylist;
		  break;
	   default:
		  return ITMTRemotePlayerPlaylist;
	   }
}

- (int)currentPlaylistIndex
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)songTitleAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index] eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (int)currentSongIndex
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongTitle
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pnam" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongArtist
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pArt" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongAlbum
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pAlb" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongGenre
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pGen" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongLength
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pTim" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (NSString *)currentSongRemaining
{
    long duration = [[ITAppleEventCenter sharedCenter]
                        sendTwoTierAEWithRequestedKeyForNumber:@"pDur" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    long current = [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pPos" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];

    return [[NSNumber numberWithLong:duration - current] stringValue];
}

- (float)currentSongRating
{
    return [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRte" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN] / 100;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu) ----:obj { form:'prop', want:type('prop'), seld:type('pRte'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }",(long)rating*100] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)equalizerEnabled
{
    return [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pEQ " eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
[[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu) ----:obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",enabled] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
}

- (NSArray *)eqPresets
{
    int i;
    long numPresets = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cEQP'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:iTunesPSN];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];
    
    for (i = 1; i <= numPresets; i++) {
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() } }",i] eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
        if (theObj) {
            [presets addObject:theObj];
        }
    }
    return [presets autorelease];
}

- (int)currentEQPresetIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pEQP" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    return result;
}

- (float)volume
{
    long vol = [[ITAppleEventCenter sharedCenter] sendAEWithRequestedKeyForNumber:@"pVol" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    return vol / 100;
}

- (BOOL)setVolume:(float)volume
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), ----:obj { form:'prop', want:type('prop'), seld:type('pVol'), from:'null'() }",(long)volume*100] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
    return NO;
}

- (BOOL)shuffleEnabled
{
    int result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pShf" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    return result;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu) ----:obj { form:'prop', want:type('prop'), seld:type('pShf'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",enabled] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
}

- (ITMTRemotePlayerRepeatMode)repeatMode
{
    FourCharCode m00f;
    int result;
    m00f = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRpt" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];

    switch (m00f)
	   {
	   case 'kRp0':
		  result = ITMTRemotePlayerRepeatOff;
		  break;
	   case 'kRp1':
		  result = ITMTRemotePlayerRepeatOne;
		  break;
	   case 'kRpA':
		  result = ITMTRemotePlayerRepeatAll;
		  break;
	   }
    
    return result;
}

- (BOOL)setRepeatMode:(ITMTRemotePlayerRepeatMode)repeatMode
{
    FourCharCode m00f;
    switch (repeatMode)
	   {
	   case ITMTRemotePlayerRepeatOff:
		  m00f = 'kRp0';
		  break;
	   case ITMTRemotePlayerRepeatOne:
		  m00f = 'kRp1';
		  break;
	   case ITMTRemotePlayerRepeatAll:
		  m00f = 'kRpA';
		  break;
	   }

    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu) ----:obj { form:'prop', want:type('pRpt'), seld:type('pShf'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",m00f] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];

}

- (BOOL)play
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Play" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)pause
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Paus" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)goToNextSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Next" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)goToPreviousSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Prev" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)forward
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Fast" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)rewind
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Rwnd" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:() }",index] eventClass:@"hook" eventID:@"Play" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }",index] eventClass:@"hook" eventID:@"Play" appPSN:iTunesPSN];
    return YES;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:obj { form:'ID  ', want:type('cEQP'), seld:long(%lu), from:'null'() }, ----:obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }",index] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
    return YES;
}

- (ProcessSerialNumber)iTunesPSN
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    ProcessSerialNumber number;
    int i;
    int count = [apps count];
    
    number.highLongOfPSN = kNoProcess;
    
    for (i = 0; i < count; i++)
    {
        NSDictionary *curApp = [apps objectAtIndex:i];
        
        if ([[curApp objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"])
        {
            number.highLongOfPSN = [[curApp objectForKey:
                @"NSApplicationProcessSerialNumberHigh"] intValue];
            number.lowLongOfPSN = [[curApp objectForKey:
                @"NSApplicationProcessSerialNumberLow"] intValue];
        }
    }
    return number;
}

- (void)applicationLaunched:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];

    if ([[info objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
        iTunesPSN.highLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
        iTunesPSN.lowLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTRemoteAppDidLaunchNotification" object:nil];
    }
}

- (void)applicationTerminated:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];

    if ([[info objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
        iTunesPSN.highLongOfPSN = kNoProcess;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTRemoteAppDidTerminateNotification" object:nil];
    }
}

@end
