#import "NewMainController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindowController.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)setupHotKeys;
- (void)timerUpdate;
- (void)setLatestSongIdentifier:(NSString *)newIdentifier;
- (void)showCurrentTrackInfo;
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
        df = [[NSUserDefaults standardUserDefaults] retain];
        [self setLatestSongIdentifier:@"0-0"];
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
    
    statusItem = [[ITStatusItem alloc]
            initWithStatusBar:[NSStatusBar systemStatusBar]
            withLength:NSSquareStatusItemLength];
    
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
    if ( ( [self songChanged] ) ||
         ( ([self radioIsPlaying]) && (latestPlaylistClass != ITMTRemotePlayerRadioPlaylist) ) ||
         ( (! [self radioIsPlaying]) && (latestPlaylistClass == ITMTRemotePlayerRadioPlaylist) ) ) {
        //[statusItem setMenu:[self menu]];
        [self setLatestSongIdentifier:[currentRemote currentSongUniqueIdentifier]];
        latestPlaylistClass = [currentRemote currentPlaylistClass];
        
        if ( [df boolForKey:@"showSongInfoOnChange"] ) {
            [self showCurrentTrackInfo];
        }
    }
/*    
    //Update Play/Pause menu item
    if (playPauseItem){
        if ([currentRemote playerPlayingState] == ITMTRemotePlayerPlaying) {
            [playPauseItem setTitle:@"Pause"];
        } else {
            [playPauseItem setTitle:@"Play"];
        }
    }
*/
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

- (void)showPlayer:(id)sender
{
    if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        [currentRemote showPrimaryInterface];
    } else {
        if (![[NSWorkspace sharedWorkspace] launchApplication:[currentRemote playerFullName]]) {
            NSLog(@"Error Launching Player");
        }
    }
}

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
                target:self action:@selector(playPause:)];
    }
    
    if ([df objectForKey:@"NextTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"NextTrack"
                combo:[df keyComboForKey:@"NextTrack"]
                target:self action:@selector(nextSong:)];
    }
    
    if ([df objectForKey:@"PrevTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"PrevTrack"
                combo:[df keyComboForKey:@"PrevTrack"]
                target:self action:@selector(prevSong:)];
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
               target:self action:NULL/*Set this to something*/];
    }
    
    if ([df objectForKey:@"ToggleShuffle"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleShuffle"
               combo:[df keyComboForKey:@"ToggleShuffle"]
               target:self action:NULL/*Set this to something*/];
    }
    
    if ([df objectForKey:@"IncrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementVolume"
               combo:[df keyComboForKey:@"IncrementVolume"]
               target:self action:NULL/*Set this to something*/];
    }
    
    if ([df objectForKey:@"DecrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementVolume"
               combo:[df keyComboForKey:@"DecrementVolume"]
               target:self action:NULL/*Set this to something*/];
    }
    
    if ([df objectForKey:@"IncrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementRating"
               combo:[df keyComboForKey:@"IncrementRating"]
               target:self action:NULL/*Set this to something*/];
    }
    
    if ([df objectForKey:@"DecrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementRating"
               combo:[df keyComboForKey:@"DecrementRating"]
               target:self action:NULL/*Set this to something*/];
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

/*************************************************************************/
#pragma mark -
#pragma mark WORKSPACE NOTIFICATION HANDLERS
/*************************************************************************/

- (void)applicationLaunched:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        [NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
        [self setupHotKeys];
        playerRunningState = ITMTRemotePlayerRunning;
    }
}

 - (void)applicationTerminated:(NSNotification *)note
 {
     if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
/*
         NSMenu *notRunningMenu = [[NSMenu alloc] initWithTitle:@""];
         [notRunningMenu addItemWithTitle:[NSString stringWithFormat:@"Open %@", [currentRemote playerSimpleName]] action:@selector(showPlayer:) keyEquivalent:@""];
         [notRunningMenu addItem:[NSMenuItem separatorItem]];
         [notRunningMenu addItemWithTitle:@"Preferences" action:@selector(showPreferences:) keyEquivalent:@""];
         [notRunningMenu addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""];
*/
         [refreshTimer invalidate];
         [refreshTimer release];
         refreshTimer = nil;
         [self clearHotKeys];
         playerRunningState = ITMTRemotePlayerNotRunning;

         [statusItem setMenu:[self menuForNoPlayer]];
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
    if (refreshTimer) {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
    
    [currentRemote halt];
    [statusItem release];
    [statusWindowController release];
    [super dealloc];
}


@end
