#import "MainController.h"
#import "MenuController.h"
#import "PreferencesController.h"
#import "NetworkController.h"
#import "NetworkObject.h"
#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITHotKey.h>
#import <ITKit/ITKeyCombo.h>
#import "StatusWindow.h"
#import "StatusWindowController.h"
#import "StatusItemHack.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)timerUpdate;
- (void)setLatestSongIdentifier:(NSString *)newIdentifier;
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
        [[PreferencesController sharedPrefs] setController:self];
        statusWindowController = [StatusWindowController sharedController];
        menuController = [[MenuController alloc] init];
        df = [[NSUserDefaults standardUserDefaults] retain];
        timerUpdating = NO;
        blinged = NO;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    //Turn on debug mode if needed
    if ([df boolForKey:@"ITDebugMode"]) {
        SetITDebugMode(YES);
    }
    
    if (([df integerForKey:@"appVersion"] < 1200) && ([df integerForKey:@"SongsInAdvance"] > 0)) {
        [df removePersistentDomainForName:@"com.ithinksw.menutunes"];
        [df synchronize];
        [[PreferencesController sharedPrefs] registerDefaults];
        [[StatusWindowController sharedController] showPreferencesUpdateWindow];
    }
    
    currentRemote = [self loadRemote];
    [[self currentRemote] begin];
    
    //Turn on network stuff if needed
    networkController = [[NetworkController alloc] init];
    if ([df boolForKey:@"enableSharing"]) {
        [self setServerStatus:YES];
    } else if ([df boolForKey:@"useSharedPlayer"]) {
        if ([self connectToServer] == 0) {
            [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(checkForRemoteServer:) userInfo:nil repeats:YES];
        }
    }
    
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
    
    if ([df boolForKey:@"ITMTNoStatusItem"]) {
        statusItem = nil;
    } else {
        [StatusItemHack install];
        statusItem = [[ITStatusItem alloc]
                initWithStatusBar:[NSStatusBar systemStatusBar]
                withLength:NSSquareStatusItemLength];
    }
    
    bling = [[MTBlingController alloc] init];
    [self blingTime];
    registerTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0
                             target:self
                             selector:@selector(blingTime)
                             userInfo:nil
                             repeats:YES] retain];
    
    NS_DURING
        if ([[self currentRemote] playerRunningState] == ITMTRemotePlayerRunning) {
            [self applicationLaunched:nil];
        } else {
            if ([df boolForKey:@"LaunchPlayerWithMT"])
                [self showPlayer];
            else
                [self applicationTerminated:nil];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
    [statusItem setImage:[NSImage imageNamed:@"MenuNormal"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"MenuInverted"]];

    [networkController startRemoteServerSearch];
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

- (void)setBlingTime:(NSDate*)date
{
    NSMutableDictionary *globalPrefs;
    [df synchronize];
    globalPrefs = [[df persistentDomainForName:@".GlobalPreferences"] mutableCopy];
    if (date) {
        [globalPrefs setObject:date forKey:@"ITMTTrialStart"];
    } else {
        [globalPrefs removeObjectForKey:@"ITMTTrialStart"];
    }
    [df setPersistentDomain:globalPrefs forName:@".GlobalPreferences"];
    [df synchronize];
    [globalPrefs release];
}

- (NSDate*)getBlingTime
{
    [df synchronize];
    return [[df persistentDomainForName:@".GlobalPreferences"] objectForKey:@"ITMTTrialStart"];
}

- (void)blingTime
{
    NSDate *now = [NSDate date];
    if (![self blingBling]) {
        if ( (! [self getBlingTime] ) || ([now timeIntervalSinceDate:[self getBlingTime]] < 0) ) {
            [self setBlingTime:now];
        }
        if ( ([now timeIntervalSinceDate:[self getBlingTime]] >= 604800) && (blinged != YES) ) {
            blinged = YES;
            [statusItem setEnabled:NO];
            [self clearHotKeys];
            if ([refreshTimer isValid]) {
                [refreshTimer invalidate];
            }
            [statusWindowController showRegistrationQueryWindow];
        }
    } else {
        if (blinged) {
            [statusItem setEnabled:YES];
            [self setupHotKeys];
            if (![refreshTimer isValid]) {
                [refreshTimer release];
                refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                             target:self
                             selector:@selector(timerUpdate)
                             userInfo:nil
                             repeats:YES] retain];
            }
            blinged = NO;
        }
        [self setBlingTime:nil];
    }
}

- (void)blingNow
{
    [bling showPanel];
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
    NSString *identifier = nil;
    NS_DURING
        identifier = [[self currentRemote] playerStateUniqueIdentifier];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    return ( ! ([identifier isEqualToString:@"0-0"]) );
}

- (BOOL)radioIsPlaying
{
    ITMTRemotePlayerPlaylistClass class = nil;
    NS_DURING
        class = [[self currentRemote] currentPlaylistClass];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    return (class  == ITMTRemotePlayerRadioPlaylist );
}

- (BOOL)songChanged
{
    NSString *identifier = nil;
    NS_DURING
        identifier = [[self currentRemote] playerStateUniqueIdentifier];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    return ( ! [identifier isEqualToString:_latestSongIdentifier] );
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
    if ([networkController isConnectedToServer]) {
        [statusItem setMenu:[menuController menu]];
    }
    
    if ( [self songChanged] && (timerUpdating != YES) && (playerRunningState == ITMTRemotePlayerRunning) ) {
        ITDebugLog(@"The song changed.");
        timerUpdating = YES;
        
        NS_DURING
            latestPlaylistClass = [[self currentRemote] currentPlaylistClass];
            [menuController rebuildSubmenus];
    
            if ( [df boolForKey:@"showSongInfoOnChange"] ) {
                [self performSelector:@selector(showCurrentTrackInfo) withObject:nil afterDelay:0.0];
            }
            
            [self setLatestSongIdentifier:[[self currentRemote] playerStateUniqueIdentifier]];
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
        
        timerUpdating = NO;
    }
}

- (void)menuClicked
{
    ITDebugLog(@"Menu clicked.");
    if ([networkController isConnectedToServer]) {
        //Used the cached version
        return;
    }
    
    NS_DURING
        if ([[self currentRemote] playerRunningState] == ITMTRemotePlayerRunning) {
            [statusItem setMenu:[menuController menu]];
        } else {
            [statusItem setMenu:[menuController menuForNoPlayer]];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

//
//
// Menu Selectors
//
//

- (void)playPause
{
    NS_DURING
        ITMTRemotePlayerPlayingState state = [[self currentRemote] playerPlayingState];
        ITDebugLog(@"Play/Pause toggled");
        if (state == ITMTRemotePlayerPlaying) {
            [[self currentRemote] pause];
        } else if ((state == ITMTRemotePlayerForwarding) || (state == ITMTRemotePlayerRewinding)) {
            [[self currentRemote] pause];
            [[self currentRemote] play];
        } else {
            [[self currentRemote] play];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
    [self timerUpdate];
}

- (void)nextSong
{
    ITDebugLog(@"Going to next song.");
    NS_DURING
        [[self currentRemote] goToNextSong];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)prevSong
{
    ITDebugLog(@"Going to previous song.");
    NS_DURING
        [[self currentRemote] goToPreviousSong];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)fastForward
{
    ITDebugLog(@"Fast forwarding.");
    NS_DURING
        [[self currentRemote] forward];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)rewind
{
    ITDebugLog(@"Rewinding.");
    NS_DURING
        [[self currentRemote] rewind];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)selectPlaylistAtIndex:(int)index
{
    ITDebugLog(@"Selecting playlist %i", index);
    NS_DURING
        //[[self currentRemote] switchToPlaylistAtIndex:(index % 1000) ofSourceAtIndex:(index / 1000)];
        [[self currentRemote] switchToPlaylistAtIndex:index];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)selectSongAtIndex:(int)index
{
    ITDebugLog(@"Selecting song %i", index);
    NS_DURING
        [[self currentRemote] switchToSongAtIndex:index];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)selectSongRating:(int)rating
{
    ITDebugLog(@"Selecting song rating %i", rating);
    NS_DURING
        [[self currentRemote] setCurrentSongRating:(float)rating / 100.0];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)selectEQPresetAtIndex:(int)index
{
    ITDebugLog(@"Selecting EQ preset %i", index);
    NS_DURING
        [[self currentRemote] switchToEQAtIndex:index];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    [self timerUpdate];
}

- (void)showPlayer
{
    ITDebugLog(@"Beginning show player.");
    if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        ITDebugLog(@"Showing player interface.");
        NS_DURING
            [[self currentRemote] showPrimaryInterface];
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
    } else {
        ITDebugLog(@"Launching player.");
        NS_DURING
            if (![[NSWorkspace sharedWorkspace] launchApplication:[[self currentRemote] playerFullName]]) {
                ITDebugLog(@"Error Launching Player");
            }
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
    }
    ITDebugLog(@"Finished show player.");
}

- (void)showPreferences
{
    ITDebugLog(@"Show preferences.");
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
}

- (void)showPreferencesAndClose
{
    ITDebugLog(@"Show preferences.");
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
}

- (void)showTestWindow
{
    [self showCurrentTrackInfo];
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
    if ([networkController isConnectedToServer] && ![[networkController networkObject] isValid]) {
        [self networkError:nil];
        return nil;
    }
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
    
    if (playerRunningState == ITMTRemotePlayerNotRunning) {
        return;
    }
    
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
    ITMTRemotePlayerSource  source      = 0;
    NSString               *title       = nil;
    NSString               *album       = nil;
    NSString               *artist      = nil;
    NSString               *time        = nil;
    NSString               *track       = nil;
    NSImage                *art         = nil;
    int                     rating      = -1;
    
    NS_DURING
        source      = [[self currentRemote] currentSource];
        title       = [[self currentRemote] currentSongTitle];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
    ITDebugLog(@"Showing track info status window.");
    
    if ( title ) {

        if ( [df boolForKey:@"showAlbum"] ) {
            NS_DURING
                album = [[self currentRemote] currentSongAlbum];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
        }

        if ( [df boolForKey:@"showArtist"] ) {
            NS_DURING
                artist = [[self currentRemote] currentSongArtist];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
        }

        if ( [df boolForKey:@"showTime"] ) {
            NS_DURING
                time = [NSString stringWithFormat:@"%@: %@ / %@",
                @"Time",
                [[self currentRemote] currentSongElapsed],
                [[self currentRemote] currentSongLength]];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
        }

        if ( [df boolForKey:@"showTrackNumber"] ) {
            int trackNo    = 0;
            int trackCount = 0;
            
            NS_DURING
                trackNo    = [[self currentRemote] currentSongTrack];
                trackCount = [[self currentRemote] currentAlbumTrackCount];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
            
            if ( (trackNo > 0) || (trackCount > 0) ) {
                track = [NSString stringWithFormat:@"%@: %i %@ %i",
                    @"Track", trackNo, @"of", trackCount];
            }
        }

        if ( [df boolForKey:@"showTrackRating"] ) {
            float currentRating = 0;
            
            NS_DURING
                currentRating = [[self currentRemote] currentSongRating];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
            
            if (currentRating >= 0.0) {
                rating = ( currentRating * 5 );
            }
        }
        
        if ( [df boolForKey:@"showAlbumArtwork"] ) {
             NS_DURING
                art = [[self currentRemote] currentSongAlbumArt];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
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
                                                  rating:rating
                                                   image:art];
}

- (void)showUpcomingSongs
{
    int numSongs = 0;
    NS_DURING
        numSongs = [[self currentRemote] numberOfSongsInPlaylistAtIndex:[[self currentRemote] currentPlaylistIndex]];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
    ITDebugLog(@"Showing upcoming songs status window.");
    NS_DURING
        if (numSongs > 0) {
            int numSongsInAdvance = [df integerForKey:@"SongsInAdvance"];
            NSMutableArray *songList = [NSMutableArray arrayWithCapacity:numSongsInAdvance];
            int curTrack = [[self currentRemote] currentSongIndex];
            int i;
    
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    [songList addObject:[[self currentRemote] songTitleAtIndex:i]];
                }
            }
            
            if ([songList count] == 0) {
                [songList addObject:NSLocalizedString(@"noUpcomingSongs", @"No upcoming songs.")];
            }
            
            [statusWindowController showUpcomingSongsWindowWithTitles:songList];
        } else {
            [statusWindowController showUpcomingSongsWindowWithTitles:[NSArray arrayWithObject:NSLocalizedString(@"noUpcomingSongs", @"No upcoming songs.")]];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)incrementVolume
{
    NS_DURING
        float volume  = [[self currentRemote] volume];
        float dispVol = volume;
        ITDebugLog(@"Incrementing volume.");
        volume  += 0.110;
        dispVol += 0.100;
        
        if (volume > 1.0) {
            volume  = 1.0;
            dispVol = 1.0;
        }
    
        ITDebugLog(@"Setting volume to %f", volume);
        [[self currentRemote] setVolume:volume];
    
        // Show volume status window
        [statusWindowController showVolumeWindowWithLevel:dispVol];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)decrementVolume
{
    NS_DURING
        float volume  = [[self currentRemote] volume];
        float dispVol = volume;
        ITDebugLog(@"Decrementing volume.");
        volume  -= 0.090;
        dispVol -= 0.100;
    
        if (volume < 0.0) {
            volume  = 0.0;
            dispVol = 0.0;
        }
        
        ITDebugLog(@"Setting volume to %f", volume);
        [[self currentRemote] setVolume:volume];
        
        //Show volume status window
        [statusWindowController showVolumeWindowWithLevel:dispVol];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)incrementRating
{
    NS_DURING
        float rating = [[self currentRemote] currentSongRating];
        ITDebugLog(@"Incrementing rating.");
        
        if ([[self currentRemote] currentPlaylistIndex] == 0) {
            ITDebugLog(@"No song playing, rating change aborted.");
            return;
        }
        
        rating += 0.2;
        if (rating > 1.0) {
            rating = 1.0;
        }
        ITDebugLog(@"Setting rating to %f", rating);
        [[self currentRemote] setCurrentSongRating:rating];
        
        //Show rating status window
        [statusWindowController showRatingWindowWithRating:rating];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)decrementRating
{
    NS_DURING
        float rating = [[self currentRemote] currentSongRating];
        ITDebugLog(@"Decrementing rating.");
        
        if ([[self currentRemote] currentPlaylistIndex] == 0) {
            ITDebugLog(@"No song playing, rating change aborted.");
            return;
        }
        
        rating -= 0.2;
        if (rating < 0.0) {
            rating = 0.0;
        }
        ITDebugLog(@"Setting rating to %f", rating);
        [[self currentRemote] setCurrentSongRating:rating];
        
        //Show rating status window
        [statusWindowController showRatingWindowWithRating:rating];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)toggleLoop
{
    NS_DURING
        ITMTRemotePlayerRepeatMode repeatMode = [[self currentRemote] repeatMode];
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
        [[self currentRemote] setRepeatMode:repeatMode];
        
        //Show loop status window
        [statusWindowController showRepeatWindowWithMode:repeatMode];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)toggleShuffle
{
    NS_DURING
        BOOL newShuffleEnabled = ( ! [[self currentRemote] shuffleEnabled] );
        ITDebugLog(@"Toggling shuffle mode.");
        [[self currentRemote] setShuffleEnabled:newShuffleEnabled];
        //Show shuffle status window
        ITDebugLog(@"Setting shuffle mode to %i", newShuffleEnabled);
        [statusWindowController showShuffleWindow:newShuffleEnabled];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)registerNowOK
{
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];

    [self blingNow];
}

- (void)registerNowCancel
{
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];

    [NSApp terminate:self];
}

/*************************************************************************/
#pragma mark -
#pragma mark NETWORK HANDLERS
/*************************************************************************/

- (void)setServerStatus:(BOOL)newStatus
{
    if (newStatus) {
        //Turn on
        [networkController setServerStatus:YES];
    } else {
        //Tear down
        [networkController setServerStatus:NO];
    }
}

- (int)connectToServer
{
    int result;
    ITDebugLog(@"Attempting to connect to shared remote.");
    result = [networkController connectToHost:[df stringForKey:@"sharedPlayerHost"]];
    //Connect
    if (result == 1) {
        [[PreferencesController sharedPrefs] resetRemotePlayerTextFields];
        currentRemote = [[[networkController networkObject] remote] retain];
        [refreshTimer invalidate];
        refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:([networkController isConnectedToServer] ? 10.0 : 0.5)
                                target:self
                                selector:@selector(timerUpdate)
                                userInfo:nil
                                repeats:YES] retain];
        [self timerUpdate];
        ITDebugLog(@"Connection successful.");
        return 1;
    } else if (result == 0) {
        ITDebugLog(@"Connection failed.");
        currentRemote = [remoteArray objectAtIndex:0];
        return 0;
    } else {
        //Do something about the password being invalid
        ITDebugLog(@"Connection failed.");
        currentRemote = [remoteArray objectAtIndex:0];
        return -1;
    }
}

- (BOOL)disconnectFromServer
{
    ITDebugLog(@"Disconnecting from shared remote.");
    //Disconnect
    [currentRemote release];
    currentRemote = [remoteArray objectAtIndex:0];
    [networkController disconnect];
    [self timerUpdate];
    return YES;
}

- (void)checkForRemoteServer:(NSTimer *)timer
{
    ITDebugLog(@"Checking for remote server.");
    if ([networkController checkForServerAtHost:[df stringForKey:@"sharedPlayerHost"]]) {
        ITDebugLog(@"Remote server found.");
        [timer invalidate];
        if (![networkController isServerOn] && ![networkController isConnectedToServer]) {
            [[StatusWindowController sharedController] showReconnectQueryWindow];
        }
    } else {
        ITDebugLog(@"Remote server not found.");
    }
}

- (void)networkError:(NSException *)exception
{
    ITDebugLog(@"Remote exception thrown: %@: %@", [exception name], [exception reason]);
    if ( ((exception == nil) || [[exception name] isEqualToString:NSPortTimeoutException]) && [networkController isConnectedToServer]) {
        NSRunCriticalAlertPanel(@"Remote MenuTunes Disconnected", @"The MenuTunes server you were connected to stopped responding or quit. MenuTunes will revert back to the local player.", @"OK", nil, nil);
        if ([self disconnectFromServer]) {
            [[PreferencesController sharedPrefs] resetRemotePlayerTextFields];
            [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(checkForRemoteServer:) userInfo:nil repeats:YES];
        } else {
            ITDebugLog(@"CRITICAL ERROR, DISCONNECTING!");
        }
    }
}

- (void)reconnect
{
    if ([self connectToServer] == 0) {
        [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(checkForRemoteServer:) userInfo:nil repeats:YES];
    }
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
}

- (void)cancelReconnect
{
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
}

/*************************************************************************/
#pragma mark -
#pragma mark WORKSPACE NOTIFICATION HANDLERS
/*************************************************************************/

- (void)applicationLaunched:(NSNotification *)note
{
    NS_DURING
        if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[[self currentRemote] playerFullName]]) {
            ITDebugLog(@"Remote application launched.");
            playerRunningState = ITMTRemotePlayerRunning;
            [[self currentRemote] begin];
            [self setLatestSongIdentifier:@""];
            [self timerUpdate];
            refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:([networkController isConnectedToServer] ? 10.0 : 0.5)
                                target:self
                                selector:@selector(timerUpdate)
                                userInfo:nil
                                repeats:YES] retain];
            //[NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
            [self setupHotKeys];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

 - (void)applicationTerminated:(NSNotification *)note
 {
    NS_DURING
        if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[[self currentRemote] playerFullName]]) {
            ITDebugLog(@"Remote application terminated.");
            playerRunningState = ITMTRemotePlayerNotRunning;
            [[self currentRemote] halt];
            [refreshTimer invalidate];
            [refreshTimer release];
            refreshTimer = nil;
            [self clearHotKeys];
            
            if ([df objectForKey:@"ShowPlayer"] != nil) {
                ITHotKey *hotKey;
                ITDebugLog(@"Setting up show player hot key.");
                hotKey = [[ITHotKey alloc] init];
                [hotKey setName:@"ShowPlayer"];
                [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ShowPlayer"]]];
                [hotKey setTarget:self];
                [hotKey setAction:@selector(showPlayer)];
                [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
            }
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
 }


/*************************************************************************/
#pragma mark -
#pragma mark NSApplication DELEGATE METHODS
/*************************************************************************/

- (void)applicationWillTerminate:(NSNotification *)note
{
    [networkController stopRemoteServerSearch];
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
    [networkController release];
    [super dealloc];
}

@end