#import "iTunesRemote.h"

@implementation iTunesRemote

+ (id)remote
{
    return [[[iTunesRemote alloc] init] autorelease];
}

- (NSString *)title
{
    return @"iTunes";
}

- (NSString *)information;
{
    return @"Default MenuTunes plugin to control iTunes. Written by iThink Software.";
}

- (NSImage *)icon
{
    return nil;
}

- (BOOL)begin
{
    iTunesPSN = [self iTunesPSN];

    //Register for application termination in NSWorkspace
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

- (ITMTRemotePlayerRunningStatus)playerRunningStatus
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    int i;
    int count = [apps count];

    for (i = 0; i < count; i++) {
        if ([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"]
                isEqualToString:@"iTunes"]) {
            return ITMTRemotePlayerRunning;
        }
    }
    return ITMTRemotePlayerNotRunning;
}

- (ITMTRemotePlayerState)playerState
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
    
    return stopped;
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
		  NSLog(@"sent event cur %d max %d",i,numPlaylists);
		  [playlists addObject:theObj];
	   }
	   return [playlists autorelease];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:[NSString stringWithFormat:@"kocl:type('cTrk'), '----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() }",index] eventClass:@"core" eventID:@"cnte" appPSN:iTunesPSN];
}

- (NSString *)classOfPlaylistAtIndex:(int)index
{
    int realResult = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pcls" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];

    if (realResult == 'cRTP') return @"radio tuner playlist";
    else return @"playlist";
}

- (int)currentPlaylistIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    return result;
}

- (NSString *)songTitleAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index] eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
}

- (int)currentSongIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
    return result;
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
    return 0.00;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    return NO;
}

- (float)volume
{
    return 1.00;
}

- (BOOL)setVolume:(float)volume
{
    return NO;
}

- (NSArray *)eqPresets;
{
    int i;
    long numPresets = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cEQP'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:iTunesPSN];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];

	   for (i = 1; i <= numPresets; i++) {
		  NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() } }",i] eventClass:@"core" eventID:@"getd" appPSN:iTunesPSN];
		  if (theObj) [presets addObject:theObj];
	   }
	   return [presets autorelease];
}

- (int)currentEQPresetIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx"fromObjectByKey:@"pEQP" eventClass:@"core" eventID:@"getd"appPSN:iTunesPSN];
    return result;
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

- (BOOL)fastForward
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
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() }, '----':obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }",index] eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:1, '----':obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:'null'() }" eventClass:@"core" eventID:@"setd" appPSN:iTunesPSN];
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
