#import "MainController.h"
#import "MenuController.h"
#import "PreferencesController.h"
#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITHotKey.h>
#import <ITKit/ITKeyCombo.h>
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
        statusWindowController = [StatusWindowController sharedController];
        menuController = [[MenuController alloc] init];
        df = [[NSUserDefaults standardUserDefaults] retain];
        timerUpdating = NO;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    //Turn on debug mode if needed
    if ([df boolForKey:@"ITDebugMode"]) {
        SetITDebugMode(YES);
    }
    
    bling = [[MTBlingController alloc] init];
    blingDate = nil;
    
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
            [self showPlayer];
        else
            [self applicationTerminated:nil];
    }
    
    [statusItem setImage:[NSImage imageNamed:@"MenuNormal"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"MenuInverted"]];

    [NSApp deactivate];
}

- (ITMTRemote *)loadRemote
{
    NSString *folderPath = [[NSBundle mainBundle] builtInPlugInsPath];
    ITDebugLog(@"Gathering remotes.");
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
                    ITDebugLog(@"Adding remote at path %@", bundlePath);
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

/*- (void)startTimerInNewThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                             target:self
                             selector:@selector(timerUpdate)
                             userInfo:nil
                             repeats:YES] retain];
    [runLoop run];
    ITDebugLog(@"Timer started.");
    [pool release];
}*/

- (void)blingTime
{
    NSDate *now = [NSDate date];
    if ( (! blingDate) || ([now timeIntervalSinceDate:blingDate] >= 86400) ) {
        [bling showPanelIfNeeded];
        [blingDate autorelease];
        blingDate = [now retain];
    }
}

- (void)blingNow
{
    [bling showPanel];
    [blingDate autorelease];
    blingDate = [[NSDate date] retain];
}

- (BOOL)blingBling
{
    if ( ! ([bling checkDone] == 2475) ) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)songIsPlaying
{
    return ( ! ([[currentRemote playerStateUniqueIdentifier] isEqualToString:@"0-0"]) );
}

- (BOOL)radioIsPlaying
{
    return ( [currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist );
}

- (BOOL)songChanged
{
    return ( ! [[currentRemote playerStateUniqueIdentifier] isEqualToString:_latestSongIdentifier] );
}

- (NSString *)latestSongIdentifier
{
    return _latestSongIdentifier;
}

- (void)setLatestSongIdentifier:(NSString *)newIdentifier
{
    ITDebugLog(@"Setting latest song identifier to %@", newIdentifier);
    [_latestSongIdentifier autorelease];
    _latestSongIdentifier = [newIdentifier copy];
}

- (void)timerUpdate
{
    if ( [self songChanged] && (timerUpdating != YES) ) {
        ITDebugLog(@"The song changed.");
        timerUpdating = YES;
        latestPlaylistClass = [currentRemote currentPlaylistClass];
        [menuController rebuildSubmenus];

        if ( [df boolForKey:@"showSongInfoOnChange"] ) {
            [self performSelector:@selector(showCurrentTrackInfo) withObject:nil afterDelay:0.0];
        }
        
        [self setLatestSongIdentifier:[currentRemote playerStateUniqueIdentifier]];
        
        timerUpdating = NO;
    }
}

- (void)menuClicked
{
    ITDebugLog(@"Menu clicked.");
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
    ITDebugLog(@"Play/Pause toggled");
    if (state == ITMTRemotePlayerPlaying) {
        [currentRemote pause];
    } else if ((state == ITMTRemotePlayerForwarding) || (state == ITMTRemotePlayerRewinding)) {
        [currentRemote pause];
        [currentRemote play];
    } else {
        [currentRemote play];
    }
    [self timerUpdate];
}

- (void)nextSong
{
    ITDebugLog(@"Going to next song.");
    [currentRemote goToNextSong];
    [self timerUpdate];
}

- (void)prevSong
{
    ITDebugLog(@"Going to previous song.");
    [currentRemote goToPreviousSong];
    [self timerUpdate];
}

- (void)fastForward
{
    ITDebugLog(@"Fast forwarding.");
    [currentRemote forward];
    [self timerUpdate];
}

- (void)rewind
{
    ITDebugLog(@"Rewinding.");
    [currentRemote rewind];
    [self timerUpdate];
}

- (void)selectPlaylistAtIndex:(int)index
{
    ITDebugLog(@"Selecting playlist %i", index);
    [currentRemote switchToPlaylistAtIndex:index];
    [self timerUpdate];
}

- (void)selectSongAtIndex:(int)index
{
    ITDebugLog(@"Selecting song %i", index);
    [currentRemote switchToSongAtIndex:index];
    [self timerUpdate];
}

- (void)selectSongRating:(int)rating
{
    ITDebugLog(@"Selecting song rating %i", rating);
    [currentRemote setCurrentSongRating:(float)rating / 100.0];
    [self timerUpdate];
}

- (void)selectEQPresetAtIndex:(int)index
{
    ITDebugLog(@"Selecting EQ preset %i", index);
    [currentRemote switchToEQAtIndex:index];
    [self timerUpdate];
}

- (void)showPlayer
{
    ITDebugLog(@"Beginning show player.");
    if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        ITDebugLog(@"Showing player interface.");
        [currentRemote showPrimaryInterface];
    } else {
        ITDebugLog(@"Launching player.");
        if (![[NSWorkspace sharedWorkspace] launchApplication:[currentRemote playerFullName]]) {
            ITDebugLog(@"Error Launching Player");
        }
    }
    ITDebugLog(@"Finished show player.");
}

- (void)showPreferences
{
    ITDebugLog(@"Show preferences.");
    [[PreferencesController sharedPrefs] setController:self];
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
}

- (void)quitMenuTunes
{
    ITDebugLog(@"Quitting MenuTunes.");
    [NSApp terminate:self];
}

//
//

- (void)closePreferences
{
    ITDebugLog(@"Preferences closed.");
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
    NSEnumerator *hotKeyEnumerator = [[[ITHotKeyCenter sharedCenter] allHotKeys] objectEnumerator];
    ITHotKey *nextHotKey;
    ITDebugLog(@"Clearing hot keys.");
    while ( (nextHotKey = [hotKeyEnumerator nextObject]) ) {
        [[ITHotKeyCenter sharedCenter] unregisterHotKey:nextHotKey];
    }
    ITDebugLog(@"Done clearing hot keys.");
}

- (void)setupHotKeys
{
    ITHotKey *hotKey;
    ITDebugLog(@"Setting up hot keys.");
    if ([df objectForKey:@"PlayPause"] != nil) {
        ITDebugLog(@"Setting up play pause hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"PlayPause"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PlayPause"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(playPause)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"NextTrack"] != nil) {
        ITDebugLog(@"Setting up next track hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"NextTrack"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"NextTrack"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(nextSong)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"PrevTrack"] != nil) {
        ITDebugLog(@"Setting up previous track hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"PrevTrack"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PrevTrack"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(prevSong)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"ShowPlayer"] != nil) {
        ITDebugLog(@"Setting up show player hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"ShowPlayer"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ShowPlayer"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(showPlayer)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"TrackInfo"] != nil) {
        ITDebugLog(@"Setting up track info hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"TrackInfo"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"TrackInfo"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(showCurrentTrackInfo)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"UpcomingSongs"] != nil) {
        ITDebugLog(@"Setting up upcoming songs hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"UpcomingSongs"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"UpcomingSongs"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(showUpcomingSongs)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"ToggleLoop"] != nil) {
        ITDebugLog(@"Setting up toggle loop hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"ToggleLoop"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleLoop"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(toggleLoop)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"ToggleShuffle"] != nil) {
        ITDebugLog(@"Setting up toggle shuffle hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"ToggleShuffle"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleShuffle"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(toggleShuffle)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"IncrementVolume"] != nil) {
        ITDebugLog(@"Setting up increment volume hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"IncrementVolume"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementVolume"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(incrementVolume)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"DecrementVolume"] != nil) {
        ITDebugLog(@"Setting up decrement volume hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"DecrementVolume"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementVolume"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(decrementVolume)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"IncrementRating"] != nil) {
        ITDebugLog(@"Setting up increment rating hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"IncrementRating"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementRating"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(incrementRating)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"DecrementRating"] != nil) {
        ITDebugLog(@"Setting up decrement rating hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"DecrementRating"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementRating"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(decrementRating)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    ITDebugLog(@"Finished setting up hot keys.");
}

- (void)showCurrentTrackInfo
{
    ITMTRemotePlayerSource  source      = [currentRemote currentSource];
    NSString               *title       = [currentRemote currentSongTitle];
    NSString               *album       = nil;
    NSString               *artist      = nil;
    NSString               *time        = nil;
    NSString               *track       = nil;
    int                     rating      = -1;
    
    ITDebugLog(@"Showing track info status window.");
    
    if ( title ) {

        if ( [df boolForKey:@"showAlbum"] ) {
            album = [currentRemote currentSongAlbum];
        }

        if ( [df boolForKey:@"showArtist"] ) {
            artist = [currentRemote currentSongArtist];
        }

        if ( [df boolForKey:@"showTime"] ) {
            time = [NSString stringWithFormat:@"%@: %@ / %@",
                @"Time",
                [currentRemote currentSongElapsed],
                [currentRemote currentSongLength]];
        }

        if ( [df boolForKey:@"showTrackNumber"] ) {
            int trackNo    = [currentRemote currentSongTrack];
            int trackCount = [currentRemote currentAlbumTrackCount];
            
            if ( (trackNo > 0) || (trackCount > 0) ) {
                track = [NSString stringWithFormat:@"%@: %i %@ %i",
                    @"Track", trackNo, @"of", trackCount];
            }
        }

        if ( [df boolForKey:@"showTrackRating"] ) {
            rating = ( [currentRemote currentSongRating] * 5 );
        }
        
    } else {
        title = NSLocalizedString(@"noSongPlaying", @"No song is playing.");
    }

    [statusWindowController showSongInfoWindowWithSource:source
                                                   title:title
                                                   album:album
                                                  artist:artist
                                                    time:time
                                                   track:track
                                                  rating:rating];
}

- (void)showUpcomingSongs
{
    int curPlaylist = [currentRemote currentPlaylistIndex];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curPlaylist];
    ITDebugLog(@"Showing upcoming songs status window.");
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
        
        [statusWindowController showUpcomingSongsWindowWithTitles:songList];
        
    } else {
        [statusWindowController showUpcomingSongsWindowWithTitles:[NSArray arrayWithObject:NSLocalizedString(@"noUpcomingSongs", @"No upcoming songs.")]];
    }
}

- (void)incrementVolume
{
    float volume  = [currentRemote volume];
    float dispVol = volume;
    ITDebugLog(@"Incrementing volume.");
    volume  += 0.110;
    dispVol += 0.100;
    
    if (volume > 1.0) {
        volume  = 1.0;
        dispVol = 1.0;
    }

    ITDebugLog(@"Setting volume to %f", volume);
    [currentRemote setVolume:volume];

    // Show volume status window
    [statusWindowController showVolumeWindowWithLevel:dispVol];
}

- (void)decrementVolume
{
    float volume  = [currentRemote volume];
    float dispVol = volume;
    ITDebugLog(@"Decrementing volume.");
    volume  -= 0.090;
    dispVol -= 0.100;

    if (volume < 0.0) {
        volume  = 0.0;
        dispVol = 0.0;
    }
    
    ITDebugLog(@"Setting volume to %f", volume);
    [currentRemote setVolume:volume];
    
    //Show volume status window
    [statusWindowController showVolumeWindowWithLevel:dispVol];
}

- (void)incrementRating
{
    float rating = [currentRemote currentSongRating];
    ITDebugLog(@"Incrementing rating.");
    rating += 0.2;
    if (rating > 1.0) {
        rating = 1.0;
    }
    ITDebugLog(@"Setting rating to %f", rating);
    [currentRemote setCurrentSongRating:rating];
    
    //Show rating status window
    [statusWindowController showRatingWindowWithRating:rating];
}

- (void)decrementRating
{
    float rating = [currentRemote currentSongRating];
    ITDebugLog(@"Decrementing rating.");
    rating -= 0.2;
    if (rating < 0.0) {
        rating = 0.0;
    }
    ITDebugLog(@"Setting rating to %f", rating);
    [currentRemote setCurrentSongRating:rating];
    
    //Show rating status window
    [statusWindowController showRatingWindowWithRating:rating];
}

- (void)toggleLoop
{
    ITMTRemotePlayerRepeatMode repeatMode = [currentRemote repeatMode];
    ITDebugLog(@"Toggling repeat mode.");
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
    ITDebugLog(@"Setting repeat mode to %i", repeatMode);
    [currentRemote setRepeatMode:repeatMode];
    
    //Show loop status window
    [statusWindowController showRepeatWindowWithMode:repeatMode];
}

- (void)toggleShuffle
{
    BOOL newShuffleEnabled = ( ! [currentRemote shuffleEnabled] );
    ITDebugLog(@"Toggling shuffle mode.");
    [currentRemote setShuffleEnabled:newShuffleEnabled];
    //Show shuffle status window
    ITDebugLog(@"Setting shuffle mode to %i", newShuffleEnabled);
    [statusWindowController showShuffleWindow:newShuffleEnabled];
}

/*************************************************************************/
#pragma mark -
#pragma mark WORKSPACE NOTIFICATION HANDLERS
/*************************************************************************/

- (void)applicationLaunched:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        ITDebugLog(@"Remote application launched.");
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
        ITDebugLog(@"Remote application terminated.");
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
    [bling release];
    [statusItem release];
    [statusWindowController release];
    [menuController release];
    [super dealloc];
}


@end