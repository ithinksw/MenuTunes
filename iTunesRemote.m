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
    ITDebugLog(@"iTunesRemote begun");
    savedPSN = [self iTunesPSN];
    return YES;
}

- (BOOL)halt
{
    ITDebugLog(@"iTunesRemote halted");
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
    ITDebugLog(@"Showing player primary interface.");
    // Still have to convert these to AEs:
    //	set minimized of browser window 1 to false
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(0), '----':obj { form:'prop', want:type('prop'), seld:type('pMin'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    //	set visible of browser window 1 to true
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pvis'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    // Make this into AppleEvents... shouldn't be too hard, I'm just too tired to do it right now.
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pisf'), from:'null'() }" eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Done showing player primary interface.");
    return YES;
}

- (ITMTRemotePlayerRunningState)playerRunningState
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    int i;
    int count = [apps count];
    
    for (i = 0; i < count; i++) {
        if ([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
            ITDebugLog(@"Player running state: 1");
            return ITMTRemotePlayerRunning;
        }
    }
    ITDebugLog(@"Player running state: 0");
    return ITMTRemotePlayerNotRunning;
}

- (ITMTRemotePlayerPlayingState)playerPlayingState
{
    long result;
    
    ITDebugLog(@"Getting player playing state");
    
    result = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlS'), from:'null'() }" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    
    switch (result)
    {
        default:
        case 'kPSS':
            ITDebugLog(@"Getting player playing state done. Player state: Stopped");
            return ITMTRemotePlayerStopped;
        case 'kPSP':
            ITDebugLog(@"Getting player playing state done. Player state: Playing");
            return ITMTRemotePlayerPlaying;
        case 'kPSp':
            ITDebugLog(@"Getting player playing state done. Player state: Paused");
            return ITMTRemotePlayerPaused;
        case 'kPSR':
            ITDebugLog(@"Getting player playing state done. Player state: Rewinding");
            return ITMTRemotePlayerRewinding;
        case 'kPSF':
            ITDebugLog(@"Getting player playing state done. Player state: Forwarding");
            return ITMTRemotePlayerForwarding;
    }
    ITDebugLog(@"Getting player playing state done. Player state: Stopped");
    return ITMTRemotePlayerStopped;
}

- (NSArray *)playlists
{
    long i = 0;
    const signed long numPlaylists = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cPly'), '----':()" eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
    NSMutableArray *playlists = [[NSMutableArray alloc] initWithCapacity:numPlaylists];
    
    ITDebugLog(@"Getting playlists.");
    
    for (i = 1; i <= numPlaylists; i++) {
        const long j = i;
        NSString *sendStr = [NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() } }",(unsigned long)j];
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:sendStr eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
        ITDebugLog(@"Adding playlist: %@", theObj);
        [playlists addObject:theObj];
    }
    ITDebugLog(@"Finished getting playlists.");
    return [playlists autorelease];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    int temp1;
    ITDebugLog(@"Getting number of songs in playlist at index %i", index);
    temp1 = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:[NSString stringWithFormat:@"kocl:type('cTrk'), '----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:'null'() }",index] eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
    ITDebugLog(@"Getting number of songs in playlist at index %i done", index);
    return temp1;
}

- (ITMTRemotePlayerSource)currentSource
{
    unsigned long fourcc;

    ITDebugLog(@"Getting current source.");   
    
    fourcc = (unsigned long)[[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pKnd" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    switch (fourcc) {
        case 'kUnk':
        case 'kLib':
        case 'kShd':
        default:
            ITDebugLog(@"Getting current source done. Source: Library.");
            return ITMTRemoteLibrarySource;
            break;
        case 'kTun':
            ITDebugLog(@"Getting current source done. Source: Radio.");
            return ITMTRemoteRadioSource;
            break;
        case 'kDev':
            ITDebugLog(@"Getting current source done. Source: Generic Device.");
            return ITMTRemoteGenericDeviceSource;
        case 'kPod':
            ITDebugLog(@"Getting current source done. Source: iPod.");
            return ITMTRemoteiPodSource; //this is stupid
            break;
        case 'kMCD':
        case 'kACD':
            ITDebugLog(@"Getting current source done. Source: CD.");
            return ITMTRemoteCDSource;
            break;
    }
}

- (ITMTRemotePlayerPlaylistClass)currentPlaylistClass
{
    int realResult = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pcls" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    
    ITDebugLog(@"Getting current playlist class");
    switch (realResult)
	   {
	   case 'cLiP':
	       ITDebugLog(@"Getting current playlist class done. Class: Library.");
	       return ITMTRemotePlayerLibraryPlaylist;
	       break;
	   case 'cRTP':
	       ITDebugLog(@"Getting current playlist class done. Class: Radio.");
	       return ITMTRemotePlayerRadioPlaylist;
	       break;
	   default:
	       ITDebugLog(@"Getting current playlist class done. Class: Standard playlist.");
	       return ITMTRemotePlayerPlaylist;
	   }
}

- (int)currentPlaylistIndex
{  
    int temp1;
    ITDebugLog(@"Getting current playlist index.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current playlist index done.");
    return temp1;
}

- (NSString *)songTitleAtIndex:(int)index
{
    NSString *temp1;
    ITDebugLog(@"Getting song title at index %i.", index);
    temp1 = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index] eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting song title at index %i done.", index);
    return temp1;
}

- (int)currentAlbumTrackCount
{
    int temp1;
    ITDebugLog(@"Getting current album track count.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pTrC" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current album track count done.");
    return temp1;
}

- (int)currentSongTrack
{
    int temp1;
    ITDebugLog(@"Getting current song track.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pTrN" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song track done.");
    return temp1;
}

- (NSString *)playerStateUniqueIdentifier
{
    NSString *temp1;
    ITDebugLog(@"Getting current unique identifier.");
    temp1 = [NSString stringWithFormat:@"%i-%i", [self currentPlaylistIndex], [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pDID" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN]];
    ITDebugLog(@"Getting current unique identifier done.");
    return temp1;
}

- (int)currentSongIndex
{
    int temp1;
    ITDebugLog(@"Getting current song index.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song index done.");
    return temp1;
}

- (NSString *)currentSongTitle
{
    NSString *temp1;
    ITDebugLog(@"Getting current song title.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pnam" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song title done.");
    return temp1;
}

- (NSString *)currentSongArtist
{
    NSString *temp1;
    ITDebugLog(@"Getting current song artist.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pArt" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song artist done.");
    return temp1;
}

- (NSString *)currentSongAlbum
{
    NSString *temp1;
    ITDebugLog(@"Getting current song album.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pAlb" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song album done.");
    return temp1;
}

- (NSString *)currentSongGenre
{
    NSString *temp1;
    ITDebugLog(@"Getting current song genre.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pGen" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song genre done.");
    return temp1;
}

- (NSString *)currentSongLength
{
    NSString *temp1;
    ITDebugLog(@"Getting current song length.");
    temp1 = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pTim" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song length done.");
    return temp1;
}

- (NSString *)currentSongRemaining
{
    long duration;
    long current;
    
    ITDebugLog(@"Getting current song remaining time.");
    
    duration = [[ITAppleEventCenter sharedCenter]
                        sendTwoTierAEWithRequestedKeyForNumber:@"pDur" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    current = [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pPos" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current song remaining time done.");
    return [[NSNumber numberWithLong:duration - current] stringValue];
}

- (float)currentSongRating
{
    float temp1;
    ITDebugLog(@"Getting current song rating.");
    temp1 = ((float)[[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRte" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:savedPSN] / 100.0);
    ITDebugLog(@"Getting current song rating done.");
    return temp1;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    ITDebugLog(@"Setting current song rating to %f.", rating);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pRte'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",(long)(rating*100),[self currentSongIndex]] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Setting current song rating to %f done.", rating);
    return YES;
}

- (BOOL)equalizerEnabled
{
    ITDebugLog(@"Getting equalizer enabled status.");
    int thingy = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:type('prop'), want:type('prop'), seld:type('pEQ '), from:() }" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Done getting equalizer enabled status.");
    return thingy;
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
    ITDebugLog(@"Setting equalizer enabled to %i.", enabled);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:'null'() }",enabled] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Done setting equalizer enabled to %i.", enabled);
    return YES;
}

- (NSArray *)eqPresets
{
    int i;
    long numPresets = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cEQP'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:savedPSN];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];
    ITDebugLog(@"Getting EQ presets");
    for (i = 1; i <= numPresets; i++) {
        NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() } }",i] eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
        if (theObj) {
            ITDebugLog(@"Adding preset %@", theObj);
            [presets addObject:theObj];
        }
    }
    ITDebugLog(@"Done getting EQ presets");
    return [presets autorelease];
}

- (int)currentEQPresetIndex
{
    int result;
    ITDebugLog(@"Getting current EQ preset index.");
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pEQP" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting current EQ preset index done.");
    return result;
}

- (float)volume
{
    ITDebugLog(@"Getting volume.");
    ITDebugLog(@"Getting volume done.");
    return (float)[[ITAppleEventCenter sharedCenter] sendAEWithRequestedKeyForNumber:@"pVol" eventClass:@"core" eventID:@"getd" appPSN:savedPSN] / 100;
}

- (BOOL)setVolume:(float)volume
{
    ITDebugLog(@"Setting volume to %f.", volume);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pVol'), from:'null'() }",(long)(volume*100)] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Setting volume to %f done.", volume);
    return YES;
}

- (BOOL)shuffleEnabled
{
    ITDebugLog(@"Getting shuffle enabled status.");
    int result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pShf" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting shuffle enabled status done.");
    return result;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    ITDebugLog(@"Set shuffle enabled to %i", enabled);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pShf'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",(unsigned long)enabled] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Set shuffle enabled to %i done", enabled);
    return YES;
}

- (ITMTRemotePlayerRepeatMode)repeatMode
{
    FourCharCode m00f = 0;
    int result = 0;
    m00f = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pRpt" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:savedPSN];
    ITDebugLog(@"Getting repeat mode.");
    switch (m00f)
    {
        //case 'kRp0':
        case 1800564815:
            ITDebugLog(@"Repeat off");
            result = ITMTRemotePlayerRepeatOff;
            break;
        case 'kRp1':
            ITDebugLog(@"Repeat one");
            result = ITMTRemotePlayerRepeatOne;
            break;
        case 'kRpA':
            ITDebugLog(@"Repeat all");
            result = ITMTRemotePlayerRepeatAll;
            break;
    }
    ITDebugLog(@"Getting repeat mode done.");
    return result;
}

- (BOOL)setRepeatMode:(ITMTRemotePlayerRepeatMode)repeatMode
{
    char *m00f;
    ITDebugLog(@"Setting repeat mode to %i", repeatMode);
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
    ITDebugLog(@"Setting repeat mode to %c done", m00f);
    return YES;
}

- (BOOL)play
{
    ITDebugLog(@"Play");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    ITDebugLog(@"Play done");
    return YES;
}

- (BOOL)pause
{
    ITDebugLog(@"Pause");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Paus" appPSN:savedPSN];
    ITDebugLog(@"Pause done");
    return YES;
}

- (BOOL)goToNextSong
{
    ITDebugLog(@"Go to next track");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Next" appPSN:savedPSN];
    ITDebugLog(@"Go to next track done");
    return YES;
}

- (BOOL)goToPreviousSong
{
    ITDebugLog(@"Go to previous track");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Prev" appPSN:savedPSN];
    ITDebugLog(@"Go to previous track done");
    return YES;
}

- (BOOL)forward
{
    ITDebugLog(@"Fast forward action");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Fast" appPSN:savedPSN];
    ITDebugLog(@"Fast forward action done");
    return YES;
}

- (BOOL)rewind
{
    ITDebugLog(@"Rewind action");
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Rwnd" appPSN:savedPSN];
    ITDebugLog(@"Rewind action done");
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    ITDebugLog(@"Switching to playlist at index %i", index);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:() }",index] eventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    ITDebugLog(@"Done switching to playlist at index %i", index);
    return YES;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    ITDebugLog(@"Switching to track at index %i", index);
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }",index] eventClass:@"hook" eventID:@"Play" appPSN:savedPSN];
    ITDebugLog(@"Done switching to track at index %i", index);
    return YES;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    ITDebugLog(@"Switching to EQ preset at index %i", index);
    // index should count from 0, but itunes counts from 1, so let's add 1.
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }, data:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() }",(index+1)] eventClass:@"core" eventID:@"setd" appPSN:savedPSN];
    ITDebugLog(@"Done switching to EQ preset at index %i", index);
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
    ITDebugLog(@"Getting iTunes' PSN.");
    while ( (GetNextProcess(&number) == noErr) ) 
    {
        CFStringRef name;
        if ( (CopyProcessName(&number, &name) == noErr) )
        {
            if ([(NSString *)name isEqualToString:@"iTunes"])
            {
                ITDebugLog(@"iTunes' highLongOfPSN: %lu.", number.highLongOfPSN);
                ITDebugLog(@"iTunes' lowLongOfPSN: %lu.", number.lowLongOfPSN);
                ITDebugLog(@"Done getting iTunes' PSN.");
                return number;
            }
            [(NSString *)name release];
        }
    }
    ITDebugLog(@"Failed getting iTunes' PSN.");
    return number;
}

@end
