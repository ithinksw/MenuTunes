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
    savedPSN = [self iTunesPSN];
    return YES;
}

- (BOOL)halt
{
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

- (BOOL)showPrimaryInterface
{
    // Still have to convert these to AEs:
    //	set minimized of browser window 1 to false
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(0), '----':obj { form:'prop', want:type('prop'), seld:type('pMin'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    //	set visible of browser window 1 to true
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pvis'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    // Make this into AppleEvents... shouldn't be too hard, I'm just too tired to do it right now.
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pisf'), from:'null'() }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];

    return YES;
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
    long result = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlS'), from:'null'() }" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    
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
    const signed long numPlaylists = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cPly'), '----':()" eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
    NSMutableArray *playlists = [[NSMutableArray alloc] initWithCapacity:numPlaylists];
    
    for (i = 1; i <= numPlaylists; i++) {
        const long j = i;
        NSString *sendStr = [NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() } }",(unsigned long)j];
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:sendStr eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
        [playlists addObject:theObj];
    }
    return [playlists autorelease];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:[NSString stringWithFormat:@"kocl:type('cTrk'), '----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() }",index] eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
}

- (ITMTRemotePlayerSource)currentSource
{
    unsigned long fourcc = (unsigned long)[[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pKnd" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    switch (fourcc) {
	case 'kUnk':
	case 'kLib':
	case 'kShd':
	default:
	    return ITMTRemoteLibrarySource;
	    break;
	case 'kTun':
	    return ITMTRemoteRadioSource;
	    break;
	case 'kDev':
	    return ITMTRemoteGenericDeviceSource;
	case 'kPod':
	    return ITMTRemoteiPodSource; //this is stupid
	    break;
	case 'kMCD':
	case 'kACD':
	    return ITMTRemoteCDSource;
	    break;
    }
}

- (ITMTRemotePlayerPlaylistClass)currentPlaylistClass
{
    int realResult = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pcls" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    

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
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)songTitleAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index] eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (int)currentAlbumTrackCount
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pTrC" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (int)currentSongTrack
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pTrN" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)playerStateUniqueIdentifier
{
    return [NSString stringWithFormat:@"%i-%i", [self currentPlaylistIndex], [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pDID" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN]];
}

- (int)currentSongIndex
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongTitle
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pnam" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongArtist
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pArt" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongAlbum
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pAlb" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongGenre
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pGen" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongLength
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pTim" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
}

- (NSString *)currentSongRemaining
{
    long duration = [[ITAppleEventCenter sharedCenter]
                        sendTwoTierAEWithRequestedKeyForNumber:@"pDur" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    long current = [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pPos" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];

    return [[NSNumber numberWithLong:duration - current] stringValue];
}

- (float)currentSongRating
{
    return (float)[[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRte" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN] / 100.0;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pRte'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",(long)(rating*100),[self currentSongIndex]] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
}

/* - (BOOL)equalizerEnabled
{
    int thingy = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:type('prop'), want:type('prop'), seld:type('pEQ '), from:() }" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    NSLog(@"Debug equalizerEnabled: %i", thingy);
    return thingy;
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:'null'() }",enabled] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
} */

- (NSArray *)eqPresets
{
    int i;
    long numPresets = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cEQP'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];
    
    for (i = 1; i <= numPresets; i++) {
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() } }",i] eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
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
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pEQP" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    return result;
}

- (float)volume
{
    return (float)[[ITAppleEventCenter sharedCenter] sendAEWithRequestedKeyForNumber:@"pVol" eventClass:@"core" eventID:@"getd" appPSN:savedPSN] / 100;
}

- (BOOL)setVolume:(float)volume
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pVol'), from:'null'() }",(long)(volume*100)] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
}

- (BOOL)shuffleEnabled
{
    int result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pShf" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    return result;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pShf'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",(unsigned long)enabled] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
}

- (ITMTRemotePlayerRepeatMode)repeatMode
{
    FourCharCode m00f = 0;
    int result = 0;
    m00f = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRpt" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];

    switch (m00f)
	   {
	   //case 'kRp0':
           case 1800564815:
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
    char *m00f;
    switch (repeatMode)
	   {
	default:
	   case ITMTRemotePlayerRepeatOff:
		  m00f = "kRp0";
		  break;
	   case ITMTRemotePlayerRepeatOne:
		  m00f = "kRp1";
		  break;
	   case ITMTRemotePlayerRepeatAll:
		  m00f = "kRpA";
		  break;
	   }

    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:'%s', '----':obj { form:'prop', want:type('prop'), seld:type('pRpt'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }",m00f] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
}

- (BOOL)play
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    return YES;
}

- (BOOL)pause
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Paus" appPSN:savedPSN];
    return YES;
}

- (BOOL)goToNextSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Next" appPSN:savedPSN];
    return YES;
}

- (BOOL)goToPreviousSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Prev" appPSN:savedPSN];
    return YES;
}

- (BOOL)forward
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Fast" appPSN:savedPSN];
    return YES;
}

- (BOOL)rewind
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Rwnd" appPSN:savedPSN];
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:() }",index] eventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    return YES;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }",index] eventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    return YES;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    // index should count from 0, but itunes counts from 1, so let's add 1.
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }, data:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() }",(index+1)] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    return YES;
}

- (ProcessSerialNumber)iTunesPSN
{
    /*NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
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
    return number;*/
    ProcessSerialNumber number;
    number.highLongOfPSN = kNoProcess;
    number.lowLongOfPSN = 0;
    
    while ( (GetNextProcess(&number) == noErr) ) 
    {
        CFStringRef name;
        if ( (CopyProcessName(&number, &name) == noErr) )
        {
            if ([(NSString *)name isEqualToString:@"iTunes"])
            {
                return number;
            }
            [(NSString *)name release];
        }
    }
    return number;
}

@end
