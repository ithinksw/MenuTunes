#import "MainController.h"
#import "MenuController.h"
#import "PreferencesController.h"
#import "NetworkController.h"
#import "NetworkObject.h"
#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITHotKey.h>
#import <ITKit/ITKeyCombo.h>
#import <ITKit/ITCategory-NSMenu.h>
#import "StatusWindow.h"
#import "StatusWindowController.h"
#import "AudioscrobblerController.h"
#import "StatusItemHack.h"

@interface NSMenu (MenuImpl)
- (id)_menuImpl;
@end

@interface NSCarbonMenuImpl:NSObject
{
    NSMenu *_menu;
}

+ (void)initialize;
+ (void)setupForNoMenuBar;
- (void)dealloc;
- (void)setMenu:fp8;
- menu;
- (void)itemChanged:fp8;
- (void)itemAdded:fp8;
- (void)itemRemoved:fp8;
- (void)performActionWithHighlightingForItemAtIndex:(int)fp8;
- (void)performMenuAction:(SEL)fp8 withTarget:fp12;
- (void)setupCarbonMenuBar;
- (void)setAsMainCarbonMenuBar;
- (void)clearAsMainCarbonMenuBar;
- (void)popUpMenu:fp8 atLocation:(NSPoint)fp12 width:(float)fp20 forView:fp24 withSelectedItem:(int)fp28 withFont:fp32;
- (void)_popUpContextMenu:fp8 withEvent:fp12 forView:fp16 withFont:fp20;
- (void)_popUpContextMenu:fp8 withEvent:fp12 forView:fp16;
- window;
@end

@implementation NSImage (SmoothAdditions)

- (NSImage *)imageScaledSmoothlyToSize:(NSSize)scaledSize
{
    NSImage *newImage;
    NSImageRep *rep = [self bestRepresentationForDevice:nil];
    
    newImage = [[NSImage alloc] initWithSize:scaledSize];
    [newImage lockFocus];
    {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [[NSGraphicsContext currentContext] setShouldAntialias:YES];
        [rep drawInRect:NSMakeRect(3, 3, scaledSize.width - 6, scaledSize.height - 6)];
    }
    [newImage unlockFocus];
    return [newImage autorelease];
}

@end

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)setLatestSongIdentifier:(NSString *)newIdentifier;
- (void)applicationLaunched:(NSNotification *)note;
- (void)applicationTerminated:(NSNotification *)note;

- (void)invalidateStatusWindowUpdateTimer;
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
        
		_statusWindowUpdateTimer = nil;
		_audioscrobblerTimer = nil;
		
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
	NSString *iTunesPath = [df stringForKey:@"CustomPlayerPath"];
	NSDictionary *iTunesInfoPlist;
	float iTunesVersion;
	
    //Turn on debug mode if needed
	/*if ((GetCurrentKeyModifiers() & (controlKey | rightControlKey)) != 0)
    if ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0)
    if ((GetCurrentKeyModifiers() & (shiftKey | rightShiftKey)) != 0)*/
    if ([df boolForKey:@"ITDebugMode"] || ((GetCurrentKeyModifiers() & (controlKey | rightControlKey)) != 0)) {
        SetITDebugMode(YES);
		[[StatusWindowController sharedController] showDebugModeEnabledWindow];
    }

	//Check if iTunes 4.7 or later is installed	
	if (!iTunesPath) {
		iTunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes.app"];
	}
	iTunesInfoPlist = [[NSBundle bundleWithPath:iTunesPath] infoDictionary];
	iTunesVersion = [[iTunesInfoPlist objectForKey:@"CFBundleVersion"] floatValue];
	ITDebugLog(@"iTunes version found: %f.", iTunesVersion);
	if (iTunesVersion >= 4.7) {
		_needsPolling = NO;
	} else {
		_needsPolling = YES;
	}
	
    if (([df integerForKey:@"appVersion"] < 1200) && ([df integerForKey:@"SongsInAdvance"] > 0)) {
        [df removePersistentDomainForName:@"com.ithinksw.menutunes"];
        [df synchronize];
        [[PreferencesController sharedPrefs] registerDefaults];
        [[StatusWindowController sharedController] showPreferencesUpdateWindow];
    }
    
    currentRemote = [self loadRemote];
    [[self currentRemote] begin];
    
	[[self currentRemote] currentSongElapsed];
	
    //Turn on network stuff if needed
    networkController = [[NetworkController alloc] init];
    if ([df boolForKey:@"enableSharing"]) {
        [self setServerStatus:YES];
    } else if ([df boolForKey:@"useSharedPlayer"]) {
        [self checkForRemoteServerAndConnectImmediately:YES];
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
    
    if (![df objectForKey:@"menu"]) {  // If this is nil, defaults have never been registered.
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
    
    /*bling = [[MTBlingController alloc] init];
    [self blingTime];
    registerTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0
                             target:self
                             selector:@selector(blingTime)
                             userInfo:nil
                             repeats:YES] retain];*/
    
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

	if ([df boolForKey:@"audioscrobblerEnabled"]) {
		if ([PreferencesController getKeychainItemPasswordForUser:[df stringForKey:@"audioscrobblerUser"]] != nil) {
			[[AudioscrobblerController sharedController] attemptHandshake:NO];
		}
	}

    [networkController startRemoteServerSearch];
    [NSApp deactivate];
	[self performSelector:@selector(rawr) withObject:nil afterDelay:1.0];
	
	bling = [[MTBlingController alloc] init];
    [self blingTime];
    registerTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0
                             target:self
                             selector:@selector(blingTime)
                             userInfo:nil
                             repeats:YES] retain];
}

- (void)rawr
{
	_open = YES;
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
                    [(NSObject *)remoteClass isKindOfClass:[NSObject class]]) {
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
        [globalPrefs setObject:[NSNumber numberWithInt:MT_CURRENT_VERSION] forKey:@"ITMTTrialVers"];
    } else {
        [globalPrefs removeObjectForKey:@"ITMTTrialStart"];
        [globalPrefs removeObjectForKey:@"ITMTTrialVers"];
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
        } else if ([[[df persistentDomainForName:@".GlobalPreferences"] objectForKey:@"ITMTTrialVers"] intValue] < MT_CURRENT_VERSION) {
            if ([now timeIntervalSinceDate:[self getBlingTime]] >= 345600) {
                [self setBlingTime:[now addTimeInterval:-259200]];
            } else {
                NSMutableDictionary *globalPrefs;
                [df synchronize];
                globalPrefs = [[df persistentDomainForName:@".GlobalPreferences"] mutableCopy];
                [globalPrefs setObject:[NSNumber numberWithInt:MT_CURRENT_VERSION] forKey:@"ITMTTrialVers"];
                [df setPersistentDomain:globalPrefs forName:@".GlobalPreferences"];
                [df synchronize];
                [globalPrefs release];
            }
        }
        
        if ( ([now timeIntervalSinceDate:[self getBlingTime]] >= 604800) && (blinged != YES) ) {
            blinged = YES;
            [statusItem setEnabled:NO];
			[[ITHotKeyCenter sharedCenter] setEnabled:NO];
            if ([refreshTimer isValid]) {
                [refreshTimer invalidate];
				[refreshTimer release];
				refreshTimer = nil;
            }
            [statusWindowController showRegistrationQueryWindow];
        }
    } else {
        if (blinged) {
            [statusItem setEnabled:YES];
            [[ITHotKeyCenter sharedCenter] setEnabled:YES];
            if (_needsPolling && ![refreshTimer isValid]) {
                [refreshTimer release];
                refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:([networkController isConnectedToServer] ? 10.0 : 0.5)
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
    ITDebugLog(@"Setting latest song identifier:");
    ITDebugLog(@"   - Identifier: %@", newIdentifier);
    [_latestSongIdentifier autorelease];
    _latestSongIdentifier = [newIdentifier retain];
}

- (void)timerUpdate
{
	NSString *identifier = nil;
	NS_DURING
		identifier = [[self currentRemote] playerStateUniqueIdentifier];
	NS_HANDLER
		[self networkError:localException];
	NS_ENDHANDLER
	if (refreshTimer && identifier == nil) {
		if ([statusItem isEnabled]) {
			[statusItem setToolTip:@"iTunes not responding."];
		}
		[statusItem setEnabled:NO];
		return;
	} else if (![statusItem isEnabled]) {
		[statusItem setEnabled:YES];
		[statusItem setToolTip:_toolTip];
		return;
	}
	
	if ( [self songChanged] && (timerUpdating != YES) && (playerRunningState == ITMTRemotePlayerRunning) ) {
        ITDebugLog(@"The song changed. '%@'", _latestSongIdentifier);
        if ([df boolForKey:@"runScripts"]) {
            NSArray *scripts = [[NSFileManager defaultManager] directoryContentsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/MenuTunes/Scripts"]];
            NSEnumerator *scriptsEnum = [scripts objectEnumerator];
            NSString *nextScript;
            ITDebugLog(@"Running AppleScripts for song change.");
            while ( (nextScript = [scriptsEnum nextObject]) ) {
                NSDictionary *error;
                NSAppleScript *currentScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/MenuTunes/Scripts"] stringByAppendingPathComponent:nextScript]] error:&error];
                ITDebugLog(@"Running script: %@", nextScript);
                if (!currentScript || ![currentScript executeAndReturnError:nil]) {
                    ITDebugLog(@"Error running script %@.", nextScript);
                }
                [currentScript release];
            }
        }
        
        timerUpdating = YES;
        [statusItem setEnabled:NO];
		
        NS_DURING
            latestPlaylistClass = [[self currentRemote] currentPlaylistClass];
			
			if ([menuController rebuildSubmenus]) {
				if ( [df boolForKey:@"showSongInfoOnChange"] ) {
					[self performSelector:@selector(showCurrentTrackInfo) withObject:nil afterDelay:0.0];
				}
				[self setLatestSongIdentifier:identifier];
				//Create the tooltip for the status item
				if ( [df boolForKey:@"showToolTip"] ) {
					NSString *artist = [[self currentRemote] currentSongArtist];
					NSString *title = [[self currentRemote] currentSongTitle];
					ITDebugLog(@"Creating status item tooltip.");
					if (artist) {
						_toolTip = [NSString stringWithFormat:@"%@ - %@", artist, title];
					} else if (title) {
						_toolTip = title;
					} else {
						_toolTip = NSLocalizedString(@"noSongPlaying", @"No song is playing.");
					}
					[statusItem setToolTip:_toolTip];
				} else {
					[statusItem setToolTip:nil];
				}
			}
			
			if ([df boolForKey:@"audioscrobblerEnabled"]) {
				int length = [[self currentRemote] currentSongDuration];
				if (_audioscrobblerTimer) {
					[_audioscrobblerTimer invalidate];
				}
				if (length > 30) {
					_audioscrobblerTimer = [NSTimer scheduledTimerWithTimeInterval:((length / 2 < 240) ? length / 2 : 240) target:self selector:@selector(submitAudioscrobblerTrack:) userInfo:nil repeats:YES];
				}
			} else {
				_audioscrobblerTimer = nil;
			}
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
        timerUpdating = NO;
        [statusItem setEnabled:YES];
    }
	
    if ([networkController isConnectedToServer]) {
        [statusItem setMenu:([[self currentRemote] playerRunningState] == ITMTRemotePlayerRunning) ? [menuController menu] : [menuController menuForNoPlayer]];
    }
}

- (void)menuClicked
{
    ITDebugLog(@"Menu clicked.");
	
	if (([[self currentRemote] playerStateUniqueIdentifier] == nil) && playerRunningState == ITMTRemotePlayerRunning) {
		if (refreshTimer) {
			if ([statusItem isEnabled]) {
				[statusItem setToolTip:NSLocalizedString(@"iTunesNotResponding", @"iTunes is not responding.")];
			}
			[statusItem setEnabled:NO];
		} else {
			NSMenu *menu = [[NSMenu alloc] init];
			[menu addItemWithTitle:NSLocalizedString(@"iTunesNotResponding", @"iTunes is not responding.") action:nil keyEquivalent:@""];
			[statusItem setMenu:[menu autorelease]];
		}
		return;
	} else if (![statusItem isEnabled]) {
		[statusItem setEnabled:YES];
		[statusItem setToolTip:_toolTip];
		return;
	}
	
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

- (void)trackChanged:(NSNotification *)note
{
	//If we're running the timer, shut it off since we don't need it!
	/*if (refreshTimer && [refreshTimer isValid]) {
		ITDebugLog(@"Invalidating refresh timer.");
		[refreshTimer invalidate];
		[refreshTimer release];
		refreshTimer = nil;
	}*/
	
	if (![self songChanged]) {
		return;
	}
	NSString *identifier = [[self currentRemote] playerStateUniqueIdentifier];
	if ( [df boolForKey:@"showSongInfoOnChange"] ) {
		[self performSelector:@selector(showCurrentTrackInfo) withObject:nil afterDelay:0.0];
	}
	[_lastTrackInfo release];
	_lastTrackInfo = [[note userInfo] retain];
	
	[self setLatestSongIdentifier:identifier];
	ITDebugLog(@"The song changed. '%@'", _latestSongIdentifier);
	if ([df boolForKey:@"runScripts"]) {
		NSArray *scripts = [[NSFileManager defaultManager] directoryContentsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/MenuTunes/Scripts"]];
		NSEnumerator *scriptsEnum = [scripts objectEnumerator];
		NSString *nextScript;
		ITDebugLog(@"Running AppleScripts for song change.");
		while ( (nextScript = [scriptsEnum nextObject]) ) {
			NSDictionary *error;
			NSAppleScript *currentScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/MenuTunes/Scripts"] stringByAppendingPathComponent:nextScript]] error:&error];
			ITDebugLog(@"Running script: %@", nextScript);
			if (!currentScript || ![currentScript executeAndReturnError:nil]) {
				ITDebugLog(@"Error running script %@.", nextScript);
			}
			[currentScript release];
		}
	}
	
	[statusItem setEnabled:NO];
	
	NS_DURING
		latestPlaylistClass = [[self currentRemote] currentPlaylistClass];
		
		if ([menuController rebuildSubmenus]) {
			/*if ( [df boolForKey:@"showSongInfoOnChange"] ) {
				[self performSelector:@selector(showCurrentTrackInfo) withObject:nil afterDelay:0.0];
			}*/
			[self setLatestSongIdentifier:identifier];
			//Create the tooltip for the status item
			if ( [df boolForKey:@"showToolTip"] ) {
				ITDebugLog(@"Creating status item tooltip.");
				NSString *artist = [_lastTrackInfo objectForKey:@"Artist"], *title = [_lastTrackInfo objectForKey:@"Name"];
				if (artist) {
					_toolTip = [NSString stringWithFormat:@"%@ - %@", artist, title];
				} else if (title) {
					_toolTip = title;
				} else {
					_toolTip = NSLocalizedString(@"noSongPlaying", @"No song is playing.");;
				}
				[statusItem setToolTip:_toolTip];
			} else {
				[statusItem setToolTip:nil];
			}
		}
		
		if ([df boolForKey:@"audioscrobblerEnabled"]) {
			int length = [[self currentRemote] currentSongDuration];
			if (_audioscrobblerTimer) {
				[_audioscrobblerTimer invalidate];
			}
			if (length > 30) {
				_audioscrobblerTimer = [NSTimer scheduledTimerWithTimeInterval:((length / 2 < 240) ? length / 2 : 240) target:self selector:@selector(submitAudioscrobblerTrack:) userInfo:nil repeats:YES];
			}
		} else {
			_audioscrobblerTimer = nil;
		}
	NS_HANDLER
		[self networkError:localException];
	NS_ENDHANDLER
	timerUpdating = NO;
	[statusItem setEnabled:YES];
	
	if ([networkController isConnectedToServer]) {
        [statusItem setMenu:([[self currentRemote] playerRunningState] == ITMTRemotePlayerRunning) ? [menuController menu] : [menuController menuForNoPlayer]];
    }
}

- (void)submitAudioscrobblerTrack:(NSTimer *)timer
{
	int interval = [timer timeInterval];
	[timer invalidate];
	_audioscrobblerTimer = nil;
	ITDebugLog(@"Audioscrobbler: Attempting to submit current track");
	if ([df boolForKey:@"audioscrobblerEnabled"]) {
		NS_DURING
			int elapsed = [[self currentRemote] currentSongPlayed];
			if ((abs(elapsed - interval) < 5) && ([[self currentRemote] playerPlayingState] == ITMTRemotePlayerPlaying)) {
				NSString *title = [[self currentRemote] currentSongTitle], *artist = [[self currentRemote] currentSongArtist];
				if (title && artist) {
					ITDebugLog(@"Audioscrobbler: Submitting current track");
					[[AudioscrobblerController sharedController] submitTrack:title
																	artist:artist
																	album:[[self currentRemote] currentSongAlbum]
																	length:[[self currentRemote] currentSongDuration]];
				}
			} else if (interval - elapsed > 0) {
				ITDebugLog(@"Audioscrobbler: Creating a new timer that will run in %i seconds", interval - elapsed);
				_audioscrobblerTimer = [NSTimer scheduledTimerWithTimeInterval:(interval - elapsed) target:self selector:@selector(submitAudioscrobblerTrack:) userInfo:nil repeats:YES];
			}
		NS_HANDLER
			[self networkError:localException];
		NS_ENDHANDLER
	}
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
    
	if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)nextSong
{
    ITDebugLog(@"Going to next song.");
    NS_DURING
        [[self currentRemote] goToNextSong];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)prevSong
{
    ITDebugLog(@"Going to previous song.");
    NS_DURING
        [[self currentRemote] goToPreviousSong];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)fastForward
{
    ITDebugLog(@"Fast forwarding.");
    NS_DURING
        [[self currentRemote] forward];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)rewind
{
    ITDebugLog(@"Rewinding.");
    NS_DURING
        [[self currentRemote] rewind];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)selectPlaylistAtIndex:(int)index
{
    ITDebugLog(@"Selecting playlist %i", index);
    NS_DURING
        [[self currentRemote] switchToPlaylistAtIndex:(index % 1000) ofSourceAtIndex:(index / 1000)];
        //[[self currentRemote] switchToPlaylistAtIndex:index];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)selectSongAtIndex:(int)index
{
    ITDebugLog(@"Selecting song %i", index);
    NS_DURING
        [[self currentRemote] switchToSongAtIndex:index];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)selectSongRating:(int)rating
{
    ITDebugLog(@"Selecting song rating %i", rating);
    NS_DURING
        [[self currentRemote] setCurrentSongRating:(float)rating / 100.0];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)selectEQPresetAtIndex:(int)index
{
    ITDebugLog(@"Selecting EQ preset %i", index);
    NS_DURING
        if (index == -1) {
            [[self currentRemote] setEqualizerEnabled:![[self currentRemote] equalizerEnabled]];
        } else {
            [[self currentRemote] switchToEQAtIndex:index];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    if (refreshTimer) {
		[self timerUpdate];
	}
}

- (void)makePlaylistWithTerm:(NSString *)term ofType:(int)type
{
    ITDebugLog(@"Making playlist with term %@, type %i", term, type);
    NS_DURING
        [[self currentRemote] makePlaylistWithTerm:term ofType:type];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    ITDebugLog(@"Done making playlist");
}

- (void)showPlayer
{
    ITDebugLog(@"Beginning show player.");
    //if ( ( playerRunningState == ITMTRemotePlayerRunning) ) {
        ITDebugLog(@"Showing player interface.");
        NS_DURING
            [[self currentRemote] showPrimaryInterface];
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
    /*} else {
        ITDebugLog(@"Launching player.");
        NS_DURING
            NSString *path;
            if ( (path = [df stringForKey:@"CustomPlayerPath"]) ) {
            } else {
                pathITDebugLog(@"Showing player interface."); = [[self currentRemote] playerFullName];
            }
            if (![[NSWorkspace sharedWorkspace] launchApplication:path]) {
                ITDebugLog(@"Error Launching Player");
            }
        NS_HANDLER
            [self networkError:localException];
        NS_ENDHANDLER
    }*/
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
    [(StatusWindow *)[StatusWindow sharedWindow] setLocked:NO];
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

- (MenuController *)menuController
{
    return menuController;
}

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
    
    if (playerRunningState == ITMTRemotePlayerNotRunning && ![[NetworkController sharedController] isConnectedToServer]) {
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
    
    if ([df objectForKey:@"FastForward"] != nil) {
        ITDebugLog(@"Setting up fast forward hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"FastForward"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"FastForward"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(fastForward)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    if ([df objectForKey:@"Rewind"] != nil) {
        ITDebugLog(@"Setting up rewind hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"Rewind"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"Rewind"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(rewind)];
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
        [hotKey setAction:@selector(showCurrentTrackInfoHotKey)];
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
    
	if ([df objectForKey:@"ToggleShufflability"] != nil) {
        ITDebugLog(@"Setting up toggle song shufflability hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"ToggleShufflability"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleShufflability"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(toggleSongShufflable)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
	
    if ([df objectForKey:@"PopupMenu"] != nil) {
        ITDebugLog(@"Setting up popup menu hot key.");
        hotKey = [[ITHotKey alloc] init];
        [hotKey setName:@"PopupMenu"];
        [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PopupMenu"]]];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(popupMenu)];
        [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
    }
    
    int i;
    for (i = 0; i <= 5; i++) {
        NSString *curName = [NSString stringWithFormat:@"SetRating%i", i];
        if ([df objectForKey:curName] != nil) {
            ITDebugLog(@"Setting up set rating %i hot key.", i);
            hotKey = [[ITHotKey alloc] init];
            [hotKey setName:curName];
            [hotKey setKeyCombo:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:curName]]];
            [hotKey setTarget:self];
            [hotKey setAction:@selector(setRating:)];
            [[ITHotKeyCenter sharedCenter] registerHotKey:[hotKey autorelease]];
        }
    }
    ITDebugLog(@"Finished setting up hot keys.");
}

- (void)showCurrentTrackInfoHotKey
{
	//If we're already visible and the setting says so, vanish instead of displaying again.
	if ([df boolForKey:@"ToggleTrackInfoWithHotKey"] && [statusWindowController currentStatusWindowType] == StatusWindowTrackInfoType && [[StatusWindow sharedWindow] visibilityState] == ITWindowVisibleState) {
		ITDebugLog(@"Track window is already visible, hiding track window.");
		[self invalidateStatusWindowUpdateTimer];
		[[StatusWindow sharedWindow] vanish:nil];
		return;
	}
	[self showCurrentTrackInfo];
}

- (void)showCurrentTrackInfo
{
    ITMTRemotePlayerSource  source      = 0;
    NSString               *title       = nil;
    NSString               *album       = nil;
    NSString               *artist      = nil;
    NSString               *composer    = nil;
    NSString               *time        = nil;
    NSString               *track       = nil;
    NSImage                *art         = nil;
    int                     rating      = -1;
    int                     playCount   = -1;
	
    ITDebugLog(@"Showing track info status window.");
    
    NS_DURING
        source      = [[self currentRemote] currentSource];
        title       = [[self currentRemote] currentSongTitle];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
    if ( title ) {
        if ( [df boolForKey:@"showAlbumArtwork"] ) {
			NSSize oldSize, newSize;
			NS_DURING
				art = [[self currentRemote] currentSongAlbumArt];
				oldSize = [art size];
				if (oldSize.width > oldSize.height) {
					newSize = NSMakeSize(110,oldSize.height * (110.0f / oldSize.width));
				}
				else newSize = NSMakeSize(oldSize.width * (110.0f / oldSize.height),110);
				art = [[[[NSImage alloc] initWithData:[art TIFFRepresentation]] autorelease] imageScaledSmoothlyToSize:newSize];
			NS_HANDLER
				[self networkError:localException];
			NS_ENDHANDLER
        }
        
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

        if ( [df boolForKey:@"showComposer"] ) {
            NS_DURING
                composer = [[self currentRemote] currentSongComposer];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
        }

        if ( [df boolForKey:@"showTime"] ) {
            NS_DURING
                time = [NSString stringWithFormat:@"%@: %@ / %@",
                NSLocalizedString(@"time", @"Time"),
                [[self currentRemote] currentSongElapsed],
                [[self currentRemote] currentSongLength]];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
			_timeUpdateCount = 0;
			[self invalidateStatusWindowUpdateTimer];
			_statusWindowUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
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
        
        if ( [df boolForKey:@"showPlayCount"] && ![self radioIsPlaying] && [[self currentRemote] currentSource] == ITMTRemoteLibrarySource ) {
            NS_DURING
                playCount = [[self currentRemote] currentSongPlayCount];
            NS_HANDLER
                [self networkError:localException];
            NS_ENDHANDLER
        }
    } else {
        title = NSLocalizedString(@"noSongPlaying", @"No song is playing.");
    }
    ITDebugLog(@"Showing current track info status window.");
    [statusWindowController showSongInfoWindowWithSource:source
                                                   title:title
                                                   album:album
                                                  artist:artist
                                                composer:composer
                                                    time:time
                                                   track:track
                                                  rating:rating
                                               playCount:playCount
                                                   image:art];
}

- (void)updateTime:(NSTimer *)timer
{
	StatusWindow *sw = (StatusWindow *)[StatusWindow sharedWindow];
	_timeUpdateCount++;
	if ([sw visibilityState] != ITWindowHiddenState) {
		NSString *time = nil, *length;
		NS_DURING
			length = [[self currentRemote] currentSongLength];
			if (length) {
				time = [NSString stringWithFormat:@"%@: %@ / %@",
							NSLocalizedString(@"time", @"Time"),
							[[self currentRemote] currentSongElapsed],
							length];
				[[StatusWindowController sharedController] updateTime:time];
			}
		NS_HANDLER
			[self networkError:localException];
		NS_ENDHANDLER
	} else {
		[self invalidateStatusWindowUpdateTimer];
	}
}

- (void)invalidateStatusWindowUpdateTimer
{
	if (_statusWindowUpdateTimer) {
		[_statusWindowUpdateTimer invalidate];
		_statusWindowUpdateTimer = nil;
	}
}

- (void)showUpcomingSongs
{
    int numSongs = 0;
    NS_DURING
        numSongs = [[self currentRemote] numberOfSongsInPlaylistAtIndex:[[self currentRemote] currentPlaylistIndex]];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
    
	[self invalidateStatusWindowUpdateTimer];
	
    ITDebugLog(@"Showing upcoming songs status window.");
    NS_DURING
        if (numSongs > 0) {
            int numSongsInAdvance = [df integerForKey:@"SongsInAdvance"];
            NSMutableArray *songList = [NSMutableArray arrayWithCapacity:numSongsInAdvance];
            int curTrack = [[self currentRemote] currentSongIndex];
            int i;
    
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance && i <= numSongs; i++) {
                if ([[self currentRemote] songEnabledAtIndex:i]) {
                    [songList addObject:[[self currentRemote] songTitleAtIndex:i]];
                } else {
					numSongsInAdvance++;
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

- (void)popupMenu
{
    if (!_popped) {
        _popped = YES;
        [self menuClicked];
        NSMenu *menu = [statusItem menu];
        [(NSCarbonMenuImpl *)[menu _menuImpl] popUpMenu:menu atLocation:[NSEvent mouseLocation] width:1 forView:nil withSelectedItem:-30 withFont:[NSFont menuFontOfSize:32]];
        _popped = NO;
    }
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
		[self invalidateStatusWindowUpdateTimer];
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
		[self invalidateStatusWindowUpdateTimer];
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
		[self invalidateStatusWindowUpdateTimer];
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
		[self invalidateStatusWindowUpdateTimer];
        [statusWindowController showRatingWindowWithRating:rating];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)setRating:(ITHotKey *)sender
{
	if ([self songIsPlaying]) {
		int stars = [[sender name] characterAtIndex:9] - 48;
		[self selectSongRating:stars * 20];
		[statusWindowController showRatingWindowWithRating:(float)stars / 5.0];
	}
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
		[self invalidateStatusWindowUpdateTimer];
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
		[self invalidateStatusWindowUpdateTimer];
        [statusWindowController showShuffleWindow:newShuffleEnabled];
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

- (void)toggleSongShufflable
{
	if ([self songIsPlaying]) {
		NS_DURING
			BOOL flag = ![[self currentRemote] currentSongShufflable];
			ITDebugLog(@"Toggling shufflability.");
			[[self currentRemote] setCurrentSongShufflable:flag];
			//Show song shufflability status window
			[self invalidateStatusWindowUpdateTimer];
			[statusWindowController showSongShufflabilityWindow:flag];
		NS_HANDLER
			[self networkError:localException];
		NS_ENDHANDLER
	}
}

- (void)registerNowOK
{
    [(StatusWindow *)[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];

    [self blingNow];
}

- (void)registerNowCancel
{
    [(StatusWindow *)[StatusWindow sharedWindow] setLocked:NO];
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
        
        [self setupHotKeys];
        //playerRunningState = ITMTRemotePlayerRunning;
        playerRunningState = [[self currentRemote] playerRunningState];
		if (_needsPolling) {
			if (refreshTimer) {
				[refreshTimer invalidate];
			}
		}
		
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
    
    if ([[self currentRemote] playerRunningState] == ITMTRemotePlayerRunning) {
		refreshTimer = nil;
        [self applicationLaunched:nil];
    } else {
        [self applicationTerminated:nil];
    }
	
    if (refreshTimer) {
		[self timerUpdate];
	};
    return YES;
}

- (void)checkForRemoteServer
{
    [self checkForRemoteServerAndConnectImmediately:NO];
}

- (void)checkForRemoteServerAndConnectImmediately:(BOOL)connectImmediately
{
    ITDebugLog(@"Checking for remote server.");
    if (!_checkingForServer) {
        if (!_serverCheckLock) {
            _serverCheckLock = [[NSLock alloc] init];
        }
        [_serverCheckLock lock];
        _checkingForServer = YES;
        [_serverCheckLock unlock];
        [NSThread detachNewThreadSelector:@selector(runRemoteServerCheck:) toTarget:self withObject:[NSNumber numberWithBool:connectImmediately]];
    }
}

- (void)runRemoteServerCheck:(id)sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ITDebugLog(@"Remote server check running.");
    if ([networkController checkForServerAtHost:[df stringForKey:@"sharedPlayerHost"]]) {
        ITDebugLog(@"Remote server found.");
        if ([sender boolValue]) {
            [self performSelectorOnMainThread:@selector(connectToServer) withObject:nil waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(remoteServerFound:) withObject:nil waitUntilDone:NO];
        }
    } else {
        ITDebugLog(@"Remote server not found.");
        [self performSelectorOnMainThread:@selector(remoteServerNotFound:) withObject:nil waitUntilDone:NO];
    }
    [_serverCheckLock lock];
    _checkingForServer = NO;
    [_serverCheckLock unlock];
    [pool release];
}

- (void)remoteServerFound:(id)sender
{
    if (![networkController isServerOn] && ![networkController isConnectedToServer]) {
		[self invalidateStatusWindowUpdateTimer];
        [[StatusWindowController sharedController] showReconnectQueryWindow];
    }
}

- (void)remoteServerNotFound:(id)sender
{
    if (![[NetworkController sharedController] isConnectedToServer]) {
        [NSTimer scheduledTimerWithTimeInterval:90.0 target:self selector:@selector(checkForRemoteServer) userInfo:nil repeats:NO];
    }
}

- (void)networkError:(NSException *)exception
{
    ITDebugLog(@"Remote exception thrown: %@: %@", [exception name], [exception reason]);
    if ( ((exception == nil) || [[exception name] isEqualToString:NSPortTimeoutException]) && [networkController isConnectedToServer]) {
        //NSRunCriticalAlertPanel(@"Remote MenuTunes Disconnected", @"The MenuTunes server you were connected to stopped responding or quit. MenuTunes will revert back to the local player.", @"OK", nil, nil);
		[self invalidateStatusWindowUpdateTimer];
        [[StatusWindowController sharedController] showNetworkErrorQueryWindow];
        if ([self disconnectFromServer]) {
            [[PreferencesController sharedPrefs] resetRemotePlayerTextFields];
            [NSTimer scheduledTimerWithTimeInterval:90.0 target:self selector:@selector(checkForRemoteServer) userInfo:nil repeats:NO];
        } else {
            ITDebugLog(@"CRITICAL ERROR, DISCONNECTING!");
        }
    }
}

- (void)reconnect
{
    /*if ([self connectToServer] == 0) {
        [NSTimer scheduledTimerWithTimeInterval:90.0 target:self selector:@selector(checkForRemoteServer) userInfo:nil repeats:NO];
    }*/
    [self checkForRemoteServerAndConnectImmediately:YES];
    [(StatusWindow *)[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
}

- (void)cancelReconnect
{
    [(StatusWindow *)[StatusWindow sharedWindow] setLocked:NO];
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
        if (!note || ([[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[[self currentRemote] playerFullName]] && ![[NetworkController sharedController] isConnectedToServer])) {
            ITDebugLog(@"Remote application launched.");
            playerRunningState = ITMTRemotePlayerRunning;
            [[self currentRemote] begin];
            [self setLatestSongIdentifier:@""];
            [self timerUpdate];
			if (_needsPolling) {
				refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:([networkController isConnectedToServer] ? 10.0 : 0.5)
									target:self
									selector:@selector(timerUpdate)
									userInfo:nil
									repeats:YES] retain];
			}
            //[NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
			if (![df boolForKey:@"UsePollingOnly"]) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackChanged:) name:@"ITMTTrackChanged" object:nil];
			}
            [self setupHotKeys];
        }
    NS_HANDLER
        [self networkError:localException];
    NS_ENDHANDLER
}

 - (void)applicationTerminated:(NSNotification *)note
 {
    NS_DURING
        if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[[self currentRemote] playerFullName]] && ![[NetworkController sharedController] isConnectedToServer]) {
            ITDebugLog(@"Remote application terminated.");
            playerRunningState = ITMTRemotePlayerNotRunning;
            [[self currentRemote] halt];
            [refreshTimer invalidate];
            [refreshTimer release];
            refreshTimer = nil;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ITMTTrackChanged" object:nil];
			[statusItem setEnabled:YES];
			[statusItem setToolTip:@"iTunes not running."];
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
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [networkController stopRemoteServerSearch];
    [self clearHotKeys];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	//This appears to not work in 10.4
	if (_open && !blinged && ![[ITAboutWindowController sharedController] isVisible] && ![NSApp mainWindow] && ([[StatusWindow sharedWindow] exitMode] == ITTransientStatusWindowExitAfterDelay)) {
		[[MainController sharedController] showPreferences];
	}
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
    [_serverCheckLock release];
    [super dealloc];
}

@end
