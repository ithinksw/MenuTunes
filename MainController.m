#import "NewMainController.h"
#import "MenuController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindowController.h"
#import "StatusItemHack.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)setupHotKeys;
- (void)timerUpdate;
- (void)setLatestSongIdentifier:(NSString *)newIdentifier;
- (void)showCurrentTrackInfo;
- (void)applicationLaunched:(NSNotification *)note;
- (void)applicationTerminated:(NSNotification *)note;
@end

static MainController *sharedController;

@implementation MainController

+ (MainController *)sharedController
{
    return sharedController;
}

/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION/DEALLOCATION METHODS
/*************************************************************************/

- (id)init
{
    if ( ( self = [super init] ) ) {
        sharedController = self;
        
        remoteArray = [[NSMutableArray alloc] initWithCapacity:1];
        statusWindowController = [[StatusWindowController alloc] init];
        menuController = [[MenuController alloc] init];
        df = [[NSUserDefaults standardUserDefaults] retain];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    currentRemote = [self loadRemote];
    [currentRemote begin];
    
    //Setup for notification of the remote player launching or quitting
    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
            selector:@selector(applicationTerminated:)
            name:NSWorkspaceDidTerminateApplicationNotification
            object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
            selector:@selector(applicationLaunched:)
            name:NSWorkspaceDidLaunchApplicationNotification
            object:nil];
    
    if ( ! [df objectForKey:@"menu"] ) {  // If this is nil, defaults have never been registered.
        [[PreferencesController sharedPrefs] registerDefaults];
    }
    
    [StatusItemHack install];
    statusItem = [[ITStatusItem alloc]
            initWithStatusBar:[NSStatusBar systemStatusBar]
            withLength:NSSquareStatusItemLength];
    
    if ([currentRemote playerRunningState] == ITMTRemotePlayerRunning) {
        [self applicationLaunched:nil];
    } else {
        [self applicationTerminated:nil];
    }
    
    [statusItem setImage:[NSImage imageNamed:@"menu"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"selected_image"]];
}

- (ITMTRemote *)loadRemote
{
    NSString *folderPath = [[NSBundle mainBundle] builtInPlugInsPath];
    
    if (folderPath) {
        NSArray      *bundlePathList = [NSBundle pathsForResourcesOfType:@"remote" inDirectory:folderPath];
        NSEnumerator *enumerator     = [bundlePathList objectEnumerator];
        NSString     *bundlePath;

        while ( (bundlePath = [enumerator nextObject]) ) {
            NSBundle* remoteBundle = [NSBundle bundleWithPath:bundlePath];

            if (remoteBundle) {
                Class remoteClass = [remoteBundle principalClass];

                if ([remoteClass conformsToProtocol:@protocol(ITMTRemote)] &&
                    [remoteClass isKindOfClass:[NSObject class]]) {

                    id remote = [remoteClass remote];
                    [remoteArray addObject:remote];
                }
            }
        }

//      if ( [remoteArray count] > 0 ) {  // UNCOMMENT WHEN WE HAVE > 1 PLUGIN
//          if ( [remoteArray count] > 1 ) {
//              [remoteArray sortUsingSelector:@selector(sortAlpha:)];
//          }
//          [self loadModuleAccessUI]; //Comment out this line to disable remote visibility
//      }
    }
//  NSLog(@"%@", [remoteArray objectAtIndex:0]);  //DEBUG
    return [remoteArray objectAtIndex:0];
}

/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (void)startTimerInNewThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                             target:self
                             selector:@selector(timerUpdate)
                             userInfo:nil
                             repeats:YES] retain];
    [runLoop run];
    [pool release];
}

- (BOOL)songIsPlaying
{
    return ( ! ([[currentRemote currentSongUniqueIdentifier] isEqualToString:@"0-0"]) );
}

- (BOOL)radioIsPlaying
{
    return ( [currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist );
}

- (BOOL)songChanged
{
    return ( ! [[currentRemote currentSongUniqueIdentifier] isEqualToString:_latestSongIdentifier] );
}

- (NSString *)latestSongIdentifier
{
    return _latestSongIdentifier;
}

- (void)setLatestSongIdentifier:(NSString *)newIdentifier
{
    [_latestSongIdentifier autorelease];
    _latestSongIdentifier = [newIdentifier copy];
}

- (void)timerUpdate
{
    //This huge if statement is being nasty
    /*if ( ( [self songChanged] ) ||
         ( ([self radioIsPlaying]) && (latestPlaylistClass != ITMTRemotePlayerRadioPlaylist) ) ||
         ( (! [self radioIsPlaying]) && (latestPlaylistClass == ITMTRemotePlayerRadioPlaylist) ) )*/
    
    if ([self songChanged]) {
        [self setLatestSongIdentifier:[currentRemote currentSongUniqueIdentifier]];
        latestPlaylistClass = [currentRemote currentPlaylistClass];
        [menuController rebuildSubmenus];
        
        if ( [df boolForKey:@"showSongInfoOnChange"] ) {
            [self showCurrentTrackInfo];
        }
    }
}

- (void)menuClicked
{
    if ([currentRemote playerRunningState] == ITMTRemotePlayerRunning) {
        [statusItem setMenu:[menuController menu]];
    } else {
        [statusItem setMenu:[menuController menuForNoPlayer]];
    }
}

//
//
// Menu Selectors
//
//

- (void)playPause
{
    ITMTRemotePlayerPlayingState state = [currentRemote playerPlayingState];
    
    if (state == ITMTRemotePlayerPlaying) {
        [currentRemote pause];
    } else if ((state == ITMTRemotePlayerForwarding) || (state == ITMTRemotePlayerRewinding)) {
        [currentRemote pause];
        [currentRemote play];
    } else {
        [currentRemote play];
    }
}

- (void)nextSong
{
    [currentRemote goToNextSong];
}

- (void)prevSong
{
    [currentRemote goToPreviousSong];
}

- (void)fastForward
{
    [currentRemote forward];
}

- (void)rewind
{
    [currentRemote rewind];
}

- (void)selectPlaylistAtIndex:(int)index
{
    [currentRemote switchToPlaylistAtIndex:index];
}

- (void)selectSongAtIndex:(int)index
{
    [currentRemote switchToSongAtIndex:index];
}

- (void)selectSongRating:(int)rating
{
    [currentRemote setCurrentSongRating:(float)rating / 100.0];
}

- (void)selectEQPresetAtIndex:(int)index
{
    [currentRemote switchToEQAtIndex:index];
}

- (void)showPlayer
{
    if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        [currentRemote showPrimaryInterface];
    } else {
        if (![[NSWorkspace sharedWorkspace] launchApplication:[currentRemote playerFullName]]) {
            NSLog(@"Error Launching Player");
        }
    }
}

- (void)showPreferences
{
    [[PreferencesController sharedPrefs] setController:self];
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
}

- (void)quitMenuTunes
{
    [NSApp terminate:self];
}

//
//

- (void)closePreferences
{
    if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        [self setupHotKeys];
    }
}

- (ITMTRemote *)currentRemote
{
    return currentRemote;
}

//
//
// Hot key setup
//
//

- (void)clearHotKeys
{
    [[HotKeyCenter sharedCenter] removeHotKey:@"PlayPause"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"NextTrack"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"PrevTrack"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"TrackInfo"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"ShowPlayer"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"UpcomingSongs"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"ToggleLoop"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"ToggleShuffle"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"IncrementVolume"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"DecrementVolume"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"IncrementRating"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"DecrementRating"];
}

- (void)setupHotKeys
{
    if ([df objectForKey:@"PlayPause"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"PlayPause"
                combo:[df keyComboForKey:@"PlayPause"]
                target:self action:@selector(playPause)];
    }
    
    if ([df objectForKey:@"NextTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"NextTrack"
                combo:[df keyComboForKey:@"NextTrack"]
                target:self action:@selector(nextSong)];
    }
    
    if ([df objectForKey:@"PrevTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"PrevTrack"
                combo:[df keyComboForKey:@"PrevTrack"]
                target:self action:@selector(prevSong)];
    }
    
    if ([df objectForKey:@"ShowPlayer"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ShowPlayer"
                combo:[df keyComboForKey:@"ShowPlayer"]
                target:self action:@selector(showPlayer)];
    }
    
    if ([df objectForKey:@"TrackInfo"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"TrackInfo"
                combo:[df keyComboForKey:@"TrackInfo"]
                target:self action:@selector(showCurrentTrackInfo)];
    }
    
    if ([df objectForKey:@"UpcomingSongs"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"UpcomingSongs"
               combo:[df keyComboForKey:@"UpcomingSongs"]
               target:self action:@selector(showUpcomingSongs)];
    }
    
    if ([df objectForKey:@"ToggleLoop"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleLoop"
               combo:[df keyComboForKey:@"ToggleLoop"]
               target:self action:@selector(toggleLoop)];
    }
    
    if ([df objectForKey:@"ToggleShuffle"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleShuffle"
               combo:[df keyComboForKey:@"ToggleShuffle"]
               target:self action:@selector(toggleShuffle)];
    }
    
    if ([df objectForKey:@"IncrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementVolume"
               combo:[df keyComboForKey:@"IncrementVolume"]
               target:self action:@selector(incrementVolume)];
    }
    
    if ([df objectForKey:@"DecrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementVolume"
               combo:[df keyComboForKey:@"DecrementVolume"]
               target:self action:@selector(decrementVolume)];
    }
    
    if ([df objectForKey:@"IncrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementRating"
               combo:[df keyComboForKey:@"IncrementRating"]
               target:self action:@selector(incrementRating)];
    }
    
    if ([df objectForKey:@"DecrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementRating"
               combo:[df keyComboForKey:@"DecrementRating"]
               target:self action:@selector(decrementRating)];
    }
}

- (void)showCurrentTrackInfo
{
    NSString *title = [currentRemote currentSongTitle];

    if ( title ) {
        NSString *album       = nil;
        NSString *artist      = nil;
        NSString *time        = nil;
        int       trackNumber = 0;
        int       trackTotal  = 0;
        int       rating      = 0;

        if ( [df boolForKey:@"showAlbum"] ) {
            album = [currentRemote currentSongAlbum];
        }

        if ( [df boolForKey:@"showArtist"] ) {
            artist = [currentRemote currentSongArtist];
        }

        if ( [df boolForKey:@"showTime"] ) {
            time = [currentRemote currentSongLength];
        }

        if ( [df boolForKey:@"showNumber"] ) {
            trackNumber = [currentRemote currentSongTrack];
            trackTotal  = [currentRemote currentAlbumTrackCount];
        }

        if ( [df boolForKey:@"showRating"] ) {
            rating = ( [currentRemote currentSongRating] * 5 );
        }

        [statusWindowController showSongWindowWithTitle:title
                                                  album:album
                                                 artist:artist
                                                   time:time
                                            trackNumber:trackNumber
                                             trackTotal:trackTotal
                                                 rating:rating];
    } else {
        title = @"No song is playing.";
        [statusWindowController showSongWindowWithTitle:title
                                                  album:nil
                                                 artist:nil
                                                   time:nil
                                            trackNumber:0
                                             trackTotal:0
                                                 rating:0];
    }
}

- (void)showUpcomingSongs
{
    int curPlaylist = [currentRemote currentPlaylistIndex];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curPlaylist];

    if (numSongs > 0) {
        NSMutableArray *songList = [NSMutableArray arrayWithCapacity:5];
        int numSongsInAdvance = [df integerForKey:@"SongsInAdvance"];
        int curTrack = [currentRemote currentSongIndex];
        int i;

        for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++) {
            if (i <= numSongs) {
                [songList addObject:[currentRemote songTitleAtIndex:i]];
            }
        }
        
        [statusWindowController showUpcomingSongsWithTitles:songList];
        
    } else {
        [statusWindowController showUpcomingSongsWithTitles:[NSArray arrayWithObject:@"No upcoming songs."]];
    }
}

- (void)incrementVolume
{
    float volume = [currentRemote volume];
    volume += 0.2;
    if (volume > 1.0) {
        volume = 1.0;
    }
    [currentRemote setVolume:volume];
    
    //Show volume status window
    [statusWindowController showVolumeWindowWithLevel:volume];
}

- (void)decrementVolume
{
    float volume = [currentRemote volume];
    volume -= 0.2;
    if (volume < 0.0) {
        volume = 0.0;
    }
    [currentRemote setVolume:volume];
    
    //Show volume status window
    [statusWindowController showVolumeWindowWithLevel:volume];
}

- (void)incrementRating
{
    float rating = [currentRemote currentSongRating];
    rating += 0.2;
    if (rating > 1.0) {
        rating = 1.0;
    }
    [currentRemote setCurrentSongRating:rating];
    
    //Show rating status window
    [statusWindowController showRatingWindowWithLevel:rating];
}

- (void)decrementRating
{
    float rating = [currentRemote currentSongRating];
    rating -= 0.2;
    if (rating < 0.0) {
        rating = 0.0;
    }
    [currentRemote setCurrentSongRating:rating];
    
    //Show rating status window
    [statusWindowController showRatingWindowWithLevel:rating];
}

- (void)toggleLoop
{
    ITMTRemotePlayerRepeatMode repeatMode = [currentRemote repeatMode];
    
    switch (repeatMode) {
        case ITMTRemotePlayerRepeatOff:
            repeatMode = ITMTRemotePlayerRepeatAll;
        break;
        case ITMTRemotePlayerRepeatAll:
            repeatMode = ITMTRemotePlayerRepeatOne;
        break;
        case ITMTRemotePlayerRepeatOne:
            repeatMode = ITMTRemotePlayerRepeatOff;
        break;
    }
    [currentRemote setRepeatMode:repeatMode];
    
    //Show loop status window
    [statusWindowController showLoopWindowWithMode:repeatMode];
}

- (void)toggleShuffle
{
    bool newShuffleEnabled = ![currentRemote shuffleEnabled];
    [currentRemote setShuffleEnabled:newShuffleEnabled];
    //Show shuffle status window
    [statusWindowController showLoopWindowWithMode:newShuffleEnabled];
}

/*************************************************************************/
#pragma mark -
#pragma mark WORKSPACE NOTIFICATION HANDLERS
/*************************************************************************/

- (void)applicationLaunched:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        [currentRemote begin];
        [self setLatestSongIdentifier:@""];
        [self timerUpdate];
        refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                             target:self
                             selector:@selector(timerUpdate)
                             userInfo:nil
                             repeats:YES] retain];
        //[NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
        [self setupHotKeys];
        playerRunningState = ITMTRemotePlayerRunning;
    }
}

 - (void)applicationTerminated:(NSNotification *)note
 {
     if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        [currentRemote halt];
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
        [self clearHotKeys];
        playerRunningState = ITMTRemotePlayerNotRunning;
     }
 }


/*************************************************************************/
#pragma mark -
#pragma mark NSApplication DELEGATE METHODS
/*************************************************************************/

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self clearHotKeys];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}


/*************************************************************************/
#pragma mark -
#pragma mark DEALLOCATION METHOD
/*************************************************************************/

- (void)dealloc
{
    [self applicationTerminated:nil];
    [statusItem release];
    [statusWindowController release];
    [menuController release];
    [super dealloc];
}


@end