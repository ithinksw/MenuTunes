#import "MainController.h"
#import "MenuController.h"
#import "PreferencesController.h"
#import <ITKit/ITHotKeyCenter.h>
#import "StatusWindowController.h"
#import "StatusItemHack.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
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
        if ([df boolForKey:@"LaunchPlayerWithMT"])
        {
            [self showPlayer];
        }
        else
        {
            [self applicationTerminated:nil];
        }
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
            NSLog(@"MenuTunes: Error Launching Player");
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
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"PlayPause"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"NextTrack"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"PrevTrack"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"TrackInfo"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"ShowPlayer"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"UpcomingSongs"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"ToggleLoop"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"ToggleShuffle"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"IncrementVolume"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"DecrementVolume"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"IncrementRating"];
    [[ITHotKeyCenter sharedCenter] removeHotKey:@"DecrementRating"];
}

- (void)setupHotKeys
{
    if ([df objectForKey:@"PlayPause"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"PlayPause"
                combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PlayPause"]]
                target:self action:@selector(playPause)];
    }
    
    if ([df objectForKey:@"NextTrack"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"NextTrack"
                combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"NextTrack"]]
                target:self action:@selector(nextSong)];
    }
    
    if ([df objectForKey:@"PrevTrack"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"PrevTrack"
                combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PrevTrack"]]
                target:self action:@selector(prevSong)];
    }
    
    if ([df objectForKey:@"ShowPlayer"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"ShowPlayer"
                combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ShowPlayer"]]
                target:self action:@selector(showPlayer)];
    }
    
    if ([df objectForKey:@"TrackInfo"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"TrackInfo"
                combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"TrackInfo"]]
                target:self action:@selector(showCurrentTrackInfo)];
    }
    
    if ([df objectForKey:@"UpcomingSongs"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"UpcomingSongs"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"UpcomingSongs"]]
               target:self action:@selector(showUpcomingSongs)];
    }
    
    if ([df objectForKey:@"ToggleLoop"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"ToggleLoop"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleLoop"]]
               target:self action:@selector(toggleLoop)];
    }
    
    if ([df objectForKey:@"ToggleShuffle"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"ToggleShuffle"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleShuffle"]]
               target:self action:@selector(toggleShuffle)];
    }
    
    if ([df objectForKey:@"IncrementVolume"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"IncrementVolume"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementVolume"]]
               target:self action:@selector(incrementVolume)];
    }
    
    if ([df objectForKey:@"DecrementVolume"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"DecrementVolume"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementVolume"]]
               target:self action:@selector(decrementVolume)];
    }
    
    if ([df objectForKey:@"IncrementRating"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"IncrementRating"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementRating"]]
               target:self action:@selector(incrementRating)];
    }
    
    if ([df objectForKey:@"DecrementRating"] != nil) {
        [[ITHotKeyCenter sharedCenter] addHotKey:@"DecrementRating"
               combo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementRating"]]
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
        title = NSLocalizedString(@"noSongPlaying", @"No song is playing.");
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
        [statusWindowController showUpcomingSongsWithTitles:[NSArray arrayWithObject:NSLocalizedString(@"noUpcomingSongs", @"No upcoming songs.")]];
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