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
    
    if ([self playerRunningState] == ITMTRemotePlayerRunning) {
        ITDebugLog(@"Showing player interface.");
        //If not minimized and visible
        if ( ([ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pMin'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }", 'core', 'getd', &savedPSN) booleanValue] == 0) &&
			 ([ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pvis'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }", 'core', 'getd', &savedPSN) booleanValue] != 0) &&
             [[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"] ) {
            //set minimized of browser window 1 to true
			ITSendAEWithString(@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pMin'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }", 'core', 'setd', &savedPSN);
        } else {
            //set minimized of browser window 1 to false
			ITSendAEWithString(@"data:long(0), '----':obj { form:'prop', want:type('prop'), seld:type('pMin'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }", 'core', 'setd', &savedPSN);
        }
        //set visible of browser window 1 to true
		ITSendAEWithString(@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pvis'), from:obj { form:'indx', want:type('cBrW'), seld:1, from:'null'() } }", 'core', 'setd', &savedPSN);
        //active iTunes
		ITSendAEWithString(@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pisf'), from:'null'() }", 'core', 'setd', &savedPSN);
        ITDebugLog(@"Done showing player primary interface.");
        return YES;
    } else {
        NSString *path;
        ITDebugLog(@"Launching player.");
        if ( (path = [[NSUserDefaults standardUserDefaults] stringForKey:@"CustomPlayerPath"]) ) {
        } else {
            path = [self playerFullName];
        }
        if (![[NSWorkspace sharedWorkspace] launchApplication:path]) {
            ITDebugLog(@"Error Launching Player");
            return NO;
        }
        return YES;
    }
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
    SInt32 result;
    
    ITDebugLog(@"Getting player playing state");
    result = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlS'), from:'null'() }", 'core', 'getd', &savedPSN) int32Value];
    switch (result)
    {
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
        case 'kPSS':
        default:
            ITDebugLog(@"Getting player playing state done. Player state: Stopped");
            return ITMTRemotePlayerStopped;
    }
    ITDebugLog(@"Getting player playing state done. Player state: Stopped");
    return ITMTRemotePlayerStopped;
}

/*- (NSArray *)playlists
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
}*/

//Full source awareness
- (NSArray *)playlists
{
    unsigned long i, k;
    SInt32 numSources = [ITSendAEWithString(@"kocl:type('cSrc'), '----':()", 'core', 'cnte', &savedPSN) int32Value];
    NSMutableArray *allSources = [[NSMutableArray alloc] init];
    
    ITDebugLog(@"Getting playlists.");
    if (numSources == 0) {
        ITDebugLog(@"No sources.");
        return nil;
    }
    
    for (k = 1; k <= numSources ; k++) {
        SInt32 numPlaylists = [ITSendAEWithString([NSString stringWithFormat:@"kocl:type('cPly'), '----':obj { form:'indx', want:type('cSrc'), seld:long(%u), from:() }",k], 'core', 'cnte', &savedPSN) int32Value];
        SInt32 fourcc = [ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pKnd'), from:obj { form:'indx', want:type('cSrc'), seld:long(%u), from:() } }",k], 'core', 'getd', &savedPSN) int32Value];
        NSString *sourceName = [ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cSrc'), seld:long(%u), from:() } }",k], 'core', 'getd', &savedPSN) stringValue];
        SInt32 index = [ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pidx'), from:obj { form:'indx', want:type('cSrc'), seld:long(%u), from:() } }",k], 'core', 'getd', &savedPSN) int32Value];
        unsigned long class;
        if (sourceName) {
            NSMutableArray *aSource = [[NSMutableArray alloc] init];
            [aSource addObject:sourceName];
            switch (fourcc) {
                case 'kTun':
                    class = ITMTRemoteRadioSource;
                    break;
                case 'kDev':
                    class = ITMTRemoteGenericDeviceSource;
                    break;
                case 'kPod':
                    class = ITMTRemoteiPodSource;
                    break;
                case 'kMCD':
                case 'kACD':
                    class = ITMTRemoteCDSource;
                    break;
                case 'kShd':
                    class = ITMTRemoteSharedLibrarySource;
                    break;
                case 'kUnk':
                case 'kLib':
                default:
                    class = ITMTRemoteLibrarySource;
                    break;
            }
            ITDebugLog(@"Adding source %@ of type %i at index %i", sourceName, class, index);
            [aSource addObject:[NSNumber numberWithInt:class]];
            [aSource addObject:[NSNumber numberWithInt:index]];
            for (i = 1; i <= numPlaylists; i++) {
                NSString *sendStr = [NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cPly'), seld:long(%u), from:obj { form:'indx', want:type('cSrc'), seld:long(%u), from:() } } }",i,k];
                NSString *theObj = [ITSendAEWithString(sendStr, 'core', 'getd', &savedPSN) stringValue];
                ITDebugLog(@" - Adding playlist %@", theObj);
                if (theObj) {
                    [aSource addObject:theObj];
                }
            }
            [allSources addObject:[aSource autorelease]];
        } else {
            ITDebugLog(@"Source at index %i disappeared.", k);
        }
    }
    ITDebugLog(@"Finished getting playlists.");
    return [allSources autorelease];
}

- (NSArray *)artists
{
    NSAppleEventDescriptor *rawr = ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pArt'), from:obj { form:'indx', want:type('cTrk'), seld:abso($616C6C20$), from:obj { form:'indx', want:type('cPly'), seld:long(1), from:obj { form:'indx', want:type('cSrc'), seld:long(1), from:() } } } }", 'core', 'getd', &savedPSN);
    int i;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *returnArray;
    for (i = 1; i <= [rawr numberOfItems]; i++) {
        NSString *artist = [[rawr descriptorAtIndex:i] stringValue];
        if (artist && [artist length] && ![array containsObject:artist]) {
            [array addObject:artist];
        }
    }
    [array sortUsingSelector:@selector(caseInsensitiveCompare:)];
    returnArray = [NSArray arrayWithArray:array];
    [array release];
    return returnArray;
}

- (NSArray *)albums
{
    NSAppleEventDescriptor *rawr = ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pAlb'), from:obj { form:'indx', want:type('cTrk'), seld:abso($616C6C20$), from:obj { form:'indx', want:type('cPly'), seld:long(1), from:obj { form:'indx', want:type('cSrc'), seld:long(1), from:() } } } }", 'core', 'getd', &savedPSN);
    int i;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *returnArray;
    for (i = 1; i <= [rawr numberOfItems]; i++) {
        NSString *album = [[rawr descriptorAtIndex:i] stringValue];
        if (album && [album length] && ![array containsObject:album]) {
            [array addObject:album];
        }
    }
    [array sortUsingSelector:@selector(caseInsensitiveCompare:)];
    returnArray = [NSArray arrayWithArray:array];
    [array release];
    return returnArray;
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    int temp1;
    ITDebugLog(@"Getting number of songs in playlist at index %i", index);
    temp1 = [ITSendAEWithString([NSString stringWithFormat:@"kocl:type('cTrk'), '----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('ctnr'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index], 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Getting number of songs in playlist at index %i done", index);
    return temp1;
}

- (ITMTRemotePlayerSource)currentSource
{
    SInt32 fourcc;

    ITDebugLog(@"Getting current source.");   
    
    fourcc = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pKnd'), from:obj { form:'prop', want:type('prop'), seld:type('ctnr'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }", 'core', 'getd', &savedPSN) int32Value];
    
    switch (fourcc) {
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
        case 'kShd':
            ITDebugLog(@"Getting current source done. Source: Shared Library.");
            return ITMTRemoteSharedLibrarySource;
            break;
        case 'kUnk':
        case 'kLib':
        default:
            ITDebugLog(@"Getting current source done. Source: Library.");
            return ITMTRemoteLibrarySource;
            break;
    }
}

- (int)currentSourceIndex
{
    ITDebugLog(@"Getting current source.");
    return [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pidx'), from:obj { form:'prop', want:type('prop'), seld:type('ctnr'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }", 'core', 'getd', &savedPSN) int32Value];
}

- (ITMTRemotePlayerPlaylistClass)currentPlaylistClass
{
    SInt32 realResult;
    ITDebugLog(@"Getting current playlist class");
    realResult = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pcls'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
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
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pidx'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Getting current playlist index done.");
    return temp1;
}

- (NSString *)songTitleAtIndex:(int)index
{
    NSString *temp1;
    ITDebugLog(@"Getting song title at index %i.", index);
    temp1 = [ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index], 'core', 'getd', &savedPSN) stringValue];
    ITDebugLog(@"Getting song title at index %i done.", index);
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (int)currentAlbumTrackCount
{
    int temp1;
    ITDebugLog(@"Getting current album track count.");
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pTrC'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    if ( [self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist ) { temp1 = 0; }
    ITDebugLog(@"Getting current album track count done.");
    return temp1;
}

- (int)currentSongTrack
{
    int temp1;
    ITDebugLog(@"Getting current song track.");
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pTrN'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    if ( [self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist ) { temp1 = 0; }
    ITDebugLog(@"Getting current song track done.");
    return temp1;
}

- (NSString *)playerStateUniqueIdentifier
{
    NSString *temp1;
    ITDebugLog(@"Getting current unique identifier.");
	NSAppleEventDescriptor *descriptor = ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pcls'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN);
	if (descriptor == nil) {
		return nil;
	}
    SInt32 cls = [descriptor int32Value];
    if ( ([self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist) || (cls == 'cURT') ) {
		NSString *bad = [NSString stringWithUTF8String:"浳湧"];
        temp1 = [ITSendAEWithKey('pStT', 'core', 'getd', &savedPSN) stringValue];
        if ([temp1 isEqualToString:bad]) {
            temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
        }
    } else {
        temp1 = [NSString stringWithFormat:@"%i-%i", [self currentPlaylistIndex], [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pDID'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value]];
    }
    ITDebugLog(@"Getting current unique identifier done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (int)currentSongIndex
{
    int temp1;
    ITDebugLog(@"Getting current song index.");
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pidx'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Getting current song index done.");
    return temp1;
}

- (NSString *)currentSongTitle
{
    NSString *temp1;
    ITDebugLog(@"Getting current song title.");
    
    //If we're listening to the radio.
    if ([ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pcls'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value] == 'cURT') {
        NSString *bad = [NSString stringWithUTF8String:"浳湧"];
        temp1 = [ITSendAEWithKey('pStT', 'core', 'getd', &savedPSN) stringValue];
        if ([temp1 isEqualToString:bad]) {
            temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
        }
        temp1 = [temp1 stringByAppendingString:@" (Stream)"];
    } else {
        temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    }
    ITDebugLog(@"Getting current song title done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (NSString *)currentSongArtist
{
    NSString *temp1;
    ITDebugLog(@"Getting current song artist.");
    if ( [self currentPlaylistClass] != ITMTRemotePlayerRadioPlaylist ) {
        temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pArt'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    } else {
        temp1 = @"";
    }
    ITDebugLog(@"Getting current song artist done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (NSString *)currentSongComposer
{
    NSString *temp1;
    ITDebugLog(@"Getting current song artist.");
    if ( [self currentPlaylistClass] != ITMTRemotePlayerRadioPlaylist ) {
        temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pCmp'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    } else {
        temp1 = @"";
    }
    ITDebugLog(@"Getting current song artist done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (NSString *)currentSongAlbum
{
    NSString *temp1;
    ITDebugLog(@"Getting current song album.");
    if ( [self currentPlaylistClass] != ITMTRemotePlayerRadioPlaylist ) {
        temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pAlb'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    } else {
        temp1 = @"";
    }
    ITDebugLog(@"Getting current song album done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (NSString *)currentSongGenre
{
    NSString *temp1;
    ITDebugLog(@"Getting current song genre.");
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pGen'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    ITDebugLog(@"Getting current song genre done.");
    return ( ([temp1 length]) ? temp1 : nil ) ;
}

- (NSString *)currentSongLength
{
    SInt32 temp1;
    NSString *temp2;
    ITDebugLog(@"Getting current song length.");
    temp1 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pcls'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    temp2 = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pTim'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) stringValue];
    if ( ([self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist) || (temp1 == 'cURT') ) { temp2 = @"Continuous"; }
    ITDebugLog(@"Getting current song length done.");
    return temp2;
}

- (NSString *)currentSongRemaining
{
    SInt32 duration, current, final;
    NSString *finalString;
    
    ITDebugLog(@"Getting current song remaining time.");
    
    duration = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pDur'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    current = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pPos'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    final = duration - current;
    finalString = [self formatTimeInSeconds:final];
    
    if ( [self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist ) { finalString = nil; }
    
    ITDebugLog(@"Getting current song remaining time done.");
    
    return finalString;
}

- (NSString *)currentSongElapsed
{
    long final;
    NSString *finalString;
    
    ITDebugLog(@"Getting current song elapsed time.");
	final = (long)[ITSendAEWithKey('pPos', 'core', 'getd', &savedPSN) int32Value];
    finalString = [self formatTimeInSeconds:final];
    ITDebugLog(@"Getting current song elapsed time done.");
    return finalString;
}

- (NSImage *)currentSongAlbumArt
{
    ITDebugLog(@"Getting current song album art.");
    NSData *data = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pPCT'), from:obj { form:'indx', want:type('cArt'), seld:long(1), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } } }", 'core', 'getd', &savedPSN) data];
    ITDebugLog(@"Getting current song album art done.");    
    if (data) {
        return [[[NSImage alloc] initWithData:data] autorelease];
    } else {
        return nil;
    }
}

- (int)currentSongPlayCount
{
    int count;
    ITDebugLog(@"Getting current song play count.");
    count = (int)[ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlC'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Getting current song play count done.");
    return count;
}

- (float)currentSongRating
{
    float temp1;
    ITDebugLog(@"Getting current song rating.");
    temp1 = ((float)[ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pRte'), from:obj { form:'prop', want:type('prop'), seld:type('pTrk'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value] / 100.0);
    if ( [self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist ) { temp1 = -1.0; }
    ITDebugLog(@"Getting current song rating done.");
    return temp1;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    ITDebugLog(@"Setting current song rating to %f.", rating);
    if ( [self currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist ) { return NO; }
	ITSendAEWithString([NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pRte'), from:obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",(long)(rating*100), [self currentSongIndex]], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Setting current song rating to %f done.", rating);
    return YES;
}

- (BOOL)equalizerEnabled
{
    ITDebugLog(@"Getting equalizer enabled status.");
    int thingy = (int)[ITSendAEWithKey('pEQ ', 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Done getting equalizer enabled status.");
    return (thingy != 0) ? YES : NO;
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
    ITDebugLog(@"Setting equalizer enabled to %i.", enabled);
	ITSendAEWithString([NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:'null'() }", enabled], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Done setting equalizer enabled to %i.", enabled);
    return YES;
}

- (NSArray *)eqPresets
{
    int i;
    SInt32 numPresets = [ITSendAEWithString(@"kocl:type('cEQP'), '----':(), &subj:()", 'core', 'cnte', &savedPSN) int32Value];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];
    ITDebugLog(@"Getting EQ presets");
    for (i = 1; i <= numPresets; i++) {
        NSString *theObj = [ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() } }", i], 'core', 'getd', &savedPSN) stringValue];
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
    result = (int)[ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pidx'), from:obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    ITDebugLog(@"Getting current EQ preset index done.");
    return result;
}

- (float)volume
{
    ITDebugLog(@"Getting volume.");
    ITDebugLog(@"Getting volume done.");
    return (float)[ITSendAEWithKey('pVol', 'core', 'getd', &savedPSN) int32Value] / 100;
}

- (BOOL)setVolume:(float)volume
{
    ITDebugLog(@"Setting volume to %f.", volume);
	ITSendAEWithString([NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pVol'), from:'null'() }", (long)(volume * 100)], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Setting volume to %f done.", volume);
    return YES;
}

- (BOOL)shuffleEnabled
{
    ITDebugLog(@"Getting shuffle enabled status.");
    BOOL final;
    int result = (int)[ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pShf'), from:obj { form:'prop', want:type('pPla'), seld:type('pEQP'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
    if (result != 0) {
        final = YES;
    } else {
        final = NO;
    }
    ITDebugLog(@"Getting shuffle enabled status done.");
    return final;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    ITDebugLog(@"Set shuffle enabled to %i", enabled);
	ITSendAEWithString([NSString stringWithFormat:@"data:long(%lu), '----':obj { form:'prop', want:type('prop'), seld:type('pShf'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }", (unsigned long)enabled], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Set shuffle enabled to %i done", enabled);
    return YES;
}

- (ITMTRemotePlayerRepeatMode)repeatMode
{
    FourCharCode m00f = 0;
    int result = 0;
    m00f = (FourCharCode)[ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pRpt'), from:obj { form:'prop', want:type('pPla'), seld:type('pEQP'), from:'null'() } }", 'core', 'getd', &savedPSN) int32Value];
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
        case ITMTRemotePlayerRepeatOne:
            m00f = "kRp1";
            break;
        case ITMTRemotePlayerRepeatAll:
            m00f = "kRpA";
            break;
        case ITMTRemotePlayerRepeatOff:
        default:
            m00f = "kRp0";
            break;
    }
	ITSendAEWithString([NSString stringWithFormat:@"data:'%s', '----':obj { form:'prop', want:type('prop'), seld:type('pRpt'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }", m00f], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Setting repeat mode to %c done", m00f);
    return YES;
}

- (BOOL)play
{
    ITDebugLog(@"Play");
	ITSendAE('hook', 'Play', &savedPSN);
    ITDebugLog(@"Play done");
    return YES;
}

- (BOOL)pause
{
    ITDebugLog(@"Pause");
    ITSendAE('hook', 'Paus', &savedPSN);
    ITDebugLog(@"Pause done");
    return YES;
}

- (BOOL)goToNextSong
{
    ITDebugLog(@"Go to next track");
    ITSendAE('hook', 'Next', &savedPSN);
    ITDebugLog(@"Go to next track done");
    return YES;
}

- (BOOL)goToPreviousSong
{
    ITDebugLog(@"Go to previous track");
    ITSendAE('hook', 'Prev', &savedPSN);
    ITDebugLog(@"Go to previous track done");
    return YES;
}

- (BOOL)forward
{
    ITDebugLog(@"Fast forward action");
    ITSendAE('hook', 'Fast', &savedPSN);
    ITDebugLog(@"Fast forward action done");
    return YES;
}

- (BOOL)rewind
{
    ITDebugLog(@"Rewind action");
    ITSendAE('hook', 'Rwnd', &savedPSN);
    ITDebugLog(@"Rewind action done");
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    ITDebugLog(@"Switching to playlist at index %i", index);
	ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from:() }", index], 'hook', 'Play', &savedPSN);
    ITDebugLog(@"Done switching to playlist at index %i", index);
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index ofSourceAtIndex:(int)index2
{
    ITDebugLog(@"Switching to playlist at index %i of source %i", index, index2);
	ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cPly'), seld:long(%lu), from: obj { form:'indx', want:type('cSrc'), seld:long(%lu), from:'null'() } }", index - 1, index2 + 1], 'hook', 'Play', &savedPSN);
    ITDebugLog(@"Done switching to playlist at index %i of source %i", index, index2);
    return YES;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    ITDebugLog(@"Switching to track at index %i", index);
	ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cTrk'), seld:long(%lu), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:() } }", index], 'hook' ,'Play', &savedPSN);
    ITDebugLog(@"Done switching to track at index %i", index);
    return YES;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    ITDebugLog(@"Switching to EQ preset at index %i", index);
    // index should count from 0, but itunes counts from 1, so let's add 1.
    [self setEqualizerEnabled:YES];
	ITSendAEWithString([NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }, data:obj { form:'indx', want:type('cEQP'), seld:long(%lu), from:'null'() }", (index+1)], 'core', 'setd', &savedPSN);
    ITDebugLog(@"Done switching to EQ preset at index %i", index);
    return YES;
}

- (BOOL)makePlaylistWithTerm:(NSString *)term ofType:(int)type
{
    int i;
    
    //Get fixed indexing status
    BOOL fixed = [ITSendAEWithString(@"'----':obj { form:'prop', want:type('prop'), seld:type('pFix'), from:'null'() }", 'core', 'getd', &savedPSN) booleanValue];
    
    //Enabled fixed indexing
    ITSendAEWithString(@"data:long(1), '----':obj { form:'prop', want:type('prop'), seld:type('pFix'), from:'null'() }", 'core', 'setd', &savedPSN);
    
    //Search for the term
    NSAppleEventDescriptor *searchResults = ITSendAEWithString([NSString stringWithFormat:@"pTrm:\"%@\", pAre:'%@', '----':obj { form:'indx', want:type('cPly'), seld:long(1), from:obj { form:'indx', want:type('cSrc'), seld:long(1), from:'null'() } }", term, ((type == 1) ? @"kSrR" : @"kSrL")], 'hook', 'Srch', &savedPSN);
    
    //If MenuTunes playlist exists
    if ([ITSendAEWithString(@"'----':obj { form:'name', want:type('cPly'), seld:\"MenuTunes\", from:'null'() }", 'core', 'doex', &savedPSN) booleanValue]) {
        //Clear old MenuTunes playlist
        int numSongs = [ITSendAEWithString(@"kocl:type('cTrk'), '----':obj { form:'name', want:type('cPly'), seld:\"MenuTunes\", from:obj { form:'prop', want:type('prop'), seld:type('ctnr'), from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }", 'core', 'cnte', &savedPSN) int32Value];
        for (i = 1; i <= numSongs; i++) {
            ITSendAEWithString(@"'----':obj { form:'indx', want:type('cTrk'), seld:long(1), from:obj { form:'name', want:type('cPly'), seld:\"MenuTunes\", from:'null'() } }", 'core', 'delo', &savedPSN);
        }
    } else {
        //Create MenuTunes playlist
        ITSendAEWithString(@"prdt:{ pnam:\"MenuTunes\" }, kocl:type('cPly'), &subj:()", 'core', 'crel', &savedPSN);
    }
    
    //Duplicate search results to playlist
    for (i = 1; i <= [searchResults numberOfItems]; i++) {
        ITSendAEWithStringAndObject(@"insh:obj { form:'name', want:type('cPly'), seld:\"MenuTunes\", from:'null'() }", [[searchResults descriptorAtIndex:i] aeDesc], 'core', 'clon', &savedPSN);
    }
    //Reset fixed indexing
    ITSendAEWithString([NSString stringWithFormat:@"data:long(%i), '----':obj { form:'prop', want:type('prop'), seld:type('pFix'), from:'null'() }", fixed], 'core', 'setd', &savedPSN);
    
    //Play MenuTunes playlist
    ITSendAEWithString(@"'----':obj { form:'name', want:type('cPly'), seld:\"MenuTunes\", from:'null'() }", 'hook', 'Play', &savedPSN);
    
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
                ITDebugLog(@"iTunes' highLPongOfPSN: %lu.", number.highLongOfPSN);
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

- (NSString*)formatTimeInSeconds:(long)seconds {
    long final = seconds;
    NSString *finalString;
    if (final >= 60) {
        if (final > 3600) {
            finalString = [NSString stringWithFormat:@"%i:%@:%@",(final / 3600),[self zeroSixty:(int)((final % 3600) / 60)],[self zeroSixty:(int)((final % 3600) % 60)]];
        } else {
            finalString = [NSString stringWithFormat:@"%i:%@",(final / 60),[self zeroSixty:(int)(final % 60)]];
        }
    } else {
        finalString = [NSString stringWithFormat:@"0:%@",[self zeroSixty:(int)final]];
    }
    return finalString;
}
- (NSString*)zeroSixty:(int)seconds {
    if ( (seconds < 10) && (seconds > 0) ) {
        return [NSString stringWithFormat:@"0%i",seconds];
    } else if ( (seconds == 0) ) {
        return [NSString stringWithFormat:@"00"];
    } else {
        return [NSString stringWithFormat:@"%i",seconds];
    }
}

@end
