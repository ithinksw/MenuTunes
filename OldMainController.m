#import "MainController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindow.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)rebuildUpcomingSongsMenu;
- (void)rebuildPlaylistMenu;
- (void)rebuildEQPresetsMenu;
- (void)setupHotKeys;
- (void)timerUpdate;
- (void)updateMenu;
- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(NSMenuItem *)item;

@end

@implementation MainController

/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION/DEALLOCATION METHODS
/*************************************************************************/

- (id)init
{
    if ( ( self = [super init] ) ) {
        remoteArray = [[NSMutableArray alloc] initWithCapacity:1];
        statusWindow = [StatusWindow sharedWindow];
    }
    return self;
}

- (void)dealloc
{
    if (refreshTimer) {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
    [currentRemote halt];
    [statusItem release];
    [menu release];
    [super dealloc];
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
    
    [self registerDefaults];
    
    statusItem = [[ITStatusItem alloc]
            initWithStatusBar:[NSStatusBar systemStatusBar]
            withLength:NSSquareStatusItemLength];
    
    menu = [[NSMenu alloc] initWithTitle:@""];
    if ( ( [currentRemote playerRunningState] == ITMTRemotePlayerRunning ) ) {
        [self applicationLaunched:nil];
    } else {
        [self applicationTerminated:nil];
    }
    
    [statusItem setImage:[NSImage imageNamed:@"menu"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"selected_image"]];
    // Below line of code is for creating builds for Beta Testers
    // [statusItem setToolTip:@[NSString stringWithFormat:@"This Nontransferable Beta (Built on %s) of iThink Software's MenuTunes is Registered to: Beta Tester (betatester@somedomain.com).",__DATE__]];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self clearHotKeys];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
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

//
//

- (void)applicationLaunched:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        [NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
        
        [self rebuildMenu];
        [statusItem setMenu:menu];
        [self setupHotKeys];
        isAppRunning = ITMTRemotePlayerRunning;
        return;
    }
    
    isAppRunning = ITMTRemotePlayerRunning;
}

- (void)applicationTerminated:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {        
        NSMenu *notRunningMenu = [[NSMenu alloc] initWithTitle:@""];
        [[notRunningMenu addItemWithTitle:[NSString stringWithFormat:@"Open %@", [currentRemote playerSimpleName]] action:@selector(showPlayer:) keyEquivalent:@""] setTarget:self];
        [notRunningMenu addItem:[NSMenuItem separatorItem]];
        [[notRunningMenu addItemWithTitle:@"Preferences" action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        [[notRunningMenu addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""] setTarget:self];
        [statusItem setMenu:[notRunningMenu autorelease]];
        
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
        [self clearHotKeys];
        isAppRunning = NO;
        return;
    }
}

/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (void)registerDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"menu"]) {
        BOOL found = NO;
        NSMutableDictionary *loginwindow;
        NSMutableArray *loginarray;
        int i;
        
        [defaults setObject:
            [NSArray arrayWithObjects:
                @"Play/Pause",
                @"Next Track",
                @"Previous Track",
                @"Fast Forward",
                @"Rewind",
                @"<separator>",
                @"Upcoming Songs",
                @"Playlists",
                @"Song Rating",
                @"<separator>",
                @"Preferences…",
                @"Quit",
                @"<separator>",
                @"Current Track Info",
                nil] forKey:@"menu"];
        
        [defaults synchronize];
        loginwindow = [[defaults persistentDomainForName:@"loginwindow"] mutableCopy];
        loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];
        
        for (i = 0; i < [loginarray count]; i++) {
            NSDictionary *tempDict = [loginarray objectAtIndex:i];
            if ([[[tempDict objectForKey:@"Path"] lastPathComponent] isEqualToString:
                [[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
                found = YES;
            }
        }
        
        //
        //This is teh sux
        //We must fix it so it is no longer suxy
        if (!found) {
            if (NSRunInformationalAlertPanel(@"Auto-launch MenuTunes", @"Would you like MenuTunes to automatically launch at login?", @"Yes", @"No", nil) == NSOKButton) {
                AEDesc scriptDesc, resultDesc;
                NSString *script = [NSString stringWithFormat:@"tell application \"System Events\"\nmake new login item at end of login items with properties {path:\"%@\", kind:\"APPLICATION\"}\nend tell", [[NSBundle mainBundle] bundlePath]];
                ComponentInstance asComponent = OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype);
                
                AECreateDesc(typeChar, [script cString], [script cStringLength], 
            &scriptDesc);
                
                OSADoScript(asComponent, &scriptDesc, kOSANullScript, typeChar, kOSAModeCanInteract, &resultDesc);
                
                AEDisposeDesc(&scriptDesc);
                AEDisposeDesc(&resultDesc);
                
                CloseComponent(asComponent);
            }
        }
    }
    
    if (![defaults integerForKey:@"SongsInAdvance"])
    {
        [defaults setInteger:5 forKey:@"SongsInAdvance"];
    }
    
    if (![defaults objectForKey:@"showName"]) {
        [defaults setBool:YES forKey:@"showName"];
    }
    
    if (![defaults objectForKey:@"showArtist"]) {
        [defaults setBool:YES forKey:@"showArtist"];
    }
    
    if (![defaults objectForKey:@"showAlbum"]) {
        [defaults setBool:NO forKey:@"showAlbum"];
    }
    
    if (![defaults objectForKey:@"showTime"]) {
        [defaults setBool:NO forKey:@"showTime"];
    }
}

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

//Recreate the status item menu
- (void)rebuildMenu
{
    NSArray *myMenu = [[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"];
    int i;
    
    trackInfoIndex = -1;
    lastPlaylistIndex = -1;
    didHaveAlbumName = ([[currentRemote currentSongAlbum] length] > 0);
    didHaveArtistName = ([[currentRemote currentSongArtist] length] > 0);
    
    [menu autorelease];
    menu = [[NSMenu alloc] initWithTitle:@""];
    
    /*while ([menu numberOfItems] > 0) {
        [menu removeItemAtIndex:0];
    }*/
    
    playPauseItem = nil;
    lastSongIdentifier = @"0-0";
    
    upcomingSongsItem = nil;
    [upcomingSongsMenu release];
    upcomingSongsMenu = nil;
    
    ratingItem = nil;
    [ratingMenu release];
    ratingMenu = nil;
    
    playlistItem = nil;
    [playlistMenu release];
    playlistMenu = nil;
    
    eqItem = nil;
    [eqMenu release];
    eqMenu = nil;
    
    for (i = 0; i < [myMenu count]; i++) {
        NSString *item = [myMenu objectAtIndex:i];
        if ([item isEqualToString:@"Play/Pause"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"PlayPause"];
            playPauseItem = [menu addItemWithTitle:@"Play"
                                    action:@selector(playPause:)
                                    keyEquivalent:@""];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:playPauseItem];
                [tempCombo release];
            }
        } else if ([item isEqualToString:@"Next Track"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"NextTrack"];
            NSMenuItem *nextTrack = [menu addItemWithTitle:@"Next Track"
                                        action:@selector(nextSong:)
                                        keyEquivalent:@""];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:nextTrack];
                [tempCombo release];
            }
        } else if ([item isEqualToString:@"Previous Track"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"PrevTrack"];
            NSMenuItem *prevTrack = [menu addItemWithTitle:@"Previous Track"
                                        action:@selector(prevSong:)
                                        keyEquivalent:@""];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:prevTrack];
                [tempCombo release];
            }
        } else if ([item isEqualToString:@"Fast Forward"]) {
            [menu addItemWithTitle:@"Fast Forward"
                    action:@selector(fastForward:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Rewind"]) {
            [menu addItemWithTitle:@"Rewind"
                    action:@selector(rewind:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Upcoming Songs"]) {
            upcomingSongsItem = [menu addItemWithTitle:@"Upcoming Songs"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Playlists"]) {
            playlistItem = [menu addItemWithTitle:@"Playlists"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"EQ Presets"]) {
            eqItem = [menu addItemWithTitle:@"EQ Presets"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Preferences…"]) {
            [menu addItemWithTitle:@"Preferences…"
                    action:@selector(showPreferences:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Quit"]) {
            [menu addItemWithTitle:@"Quit"
                    action:@selector(quitMenuTunes:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Current Track Info"]) {
            trackInfoIndex = [menu numberOfItems];
            [menu addItemWithTitle:@"No Song"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Song Rating"]) {
            unichar fullstar = 0x2605;
            unichar emptystar = 0x2606;
            NSString *fullStarChar = [NSString stringWithCharacters:&fullstar length:1];
            NSString *emptyStarChar = [NSString stringWithCharacters:&emptystar length:1];
            NSMenuItem *item;
            
            ratingItem = [menu addItemWithTitle:@"Song Rating"
                    action:nil
                    keyEquivalent:@""];
            
            ratingMenu = [[NSMenu alloc] initWithTitle:@""];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:0];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:20];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:40];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:60];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:80];
            
            item = [ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, fullStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
            [item setTag:100];
        } else if ([item isEqualToString:@"<separator>"]) {
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    [statusItem setMenu:menu];
    
    [self updateMenu];
    
    [self clearHotKeys];
    [self setupHotKeys];
}

//Rebuild the upcoming songs submenu. Can be improved a lot.
- (void)rebuildUpcomingSongsMenu
{
    int curIndex = [currentRemote currentPlaylistIndex];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curIndex];
    int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
    
    if (!isPlayingRadio) {
        if (numSongs > 0) {
            int curTrack = [currentRemote currentSongIndex];
            int i;
            
            [upcomingSongsMenu release];
            upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
            [upcomingSongsItem setSubmenu:upcomingSongsMenu];
            [upcomingSongsItem setEnabled:YES];
            
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    NSString *curSong = [currentRemote songTitleAtIndex:i];
                    NSMenuItem *songItem;
                    songItem = [[NSMenuItem alloc] initWithTitle:curSong action:@selector(selectSong:) keyEquivalent:@""];
                    [songItem setRepresentedObject:[NSNumber numberWithInt:i]];
                    [upcomingSongsMenu addItem:songItem];
                    [songItem release];
                } else {
                    break;
                }
            }
        }
    } else {
        [upcomingSongsItem setSubmenu:nil];
        [upcomingSongsItem setEnabled:NO];
    }
}

- (void)rebuildPlaylistMenu
{
    NSArray *playlists = [currentRemote playlists];
    int i, curPlaylist = [currentRemote currentPlaylistIndex];
    
    if (playlistMenu && ([playlists count] == [playlistMenu numberOfItems]))
        return;
    
    [playlistMenu release];
    playlistMenu = [[NSMenu alloc] initWithTitle:@""];
    
    for (i = 0; i < [playlists count]; i++) {
        NSString *playlistName = [playlists objectAtIndex:i];
        NSMenuItem *tempItem;
        tempItem = [[NSMenuItem alloc] initWithTitle:playlistName action:@selector(selectPlaylist:) keyEquivalent:@""];
        [tempItem setRepresentedObject:[NSNumber numberWithInt:i + 1]];
        [playlistMenu addItem:tempItem];
        [tempItem release];
    }
    [playlistItem setSubmenu:playlistMenu];
    [playlistItem setEnabled:YES];
    
    if (!isPlayingRadio) {
        [[playlistMenu itemAtIndex:curPlaylist - 1] setState:NSOnState];
    }
}

//Build a menu with the list of all available EQ presets
- (void)rebuildEQPresetsMenu
{
    NSArray *eqPresets = [currentRemote eqPresets];
    NSMenuItem *enabledItem;
    int i;
    
    if (eqMenu && ([[currentRemote eqPresets] count] == [eqMenu numberOfItems]))
        return;
    
    [eqMenu release];
    eqMenu = [[NSMenu alloc] initWithTitle:@""];
    
    enabledItem = [eqMenu addItemWithTitle:@"Enabled"
                          action:@selector(selectEQPreset:)
                          keyEquivalent:@""];
    [enabledItem setTag:-1];
    
    if ([currentRemote equalizerEnabled]) {
        [enabledItem setState:NSOnState];
    }
    
    [eqMenu addItem:[NSMenuItem separatorItem]];
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *setName = [eqPresets objectAtIndex:i];
        NSMenuItem *tempItem;
	if (setName) {
        tempItem = [[NSMenuItem alloc] initWithTitle:setName action:@selector(selectEQPreset:) keyEquivalent:@""];
        [tempItem setTag:i];
        [eqMenu addItem:tempItem];
        [tempItem release];
	}
    }
    [eqItem setSubmenu:eqMenu];
    
    [[eqMenu itemAtIndex:[currentRemote currentEQPresetIndex] + 1] setState:NSOnState];
}

- (void)timerUpdate
{
    NSString *currentIdentifier = [currentRemote currentSongUniqueIdentifier];
    if (![lastSongIdentifier isEqualToString:currentIdentifier]) {
        [self updateMenu];
    } else if (!isPlayingRadio && ([currentRemote classOfPlaylistAtIndex:[currentRemote currentPlaylistIndex]] == ITMTRemotePlayerRadioPlaylist)) {
        [self rebuildMenu];
    }
    
    //Update Play/Pause menu item
    if (playPauseItem){
        if ([currentRemote playerPlayingState] == ITMTRemotePlayerPlaying) {
            [playPauseItem setTitle:@"Pause"];
        } else {
            [playPauseItem setTitle:@"Play"];
        }
    }
}

- (void)updateMenu
{
    NSUserDefaults *defaults;
    int playlist = [currentRemote currentPlaylistIndex];
    BOOL wasPlayingRadio = isPlayingRadio;
    
    if ( (isAppRunning == ITMTRemotePlayerNotRunning) ) {
        return;
    }
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    isPlayingRadio = ([currentRemote classOfPlaylistAtIndex:playlist] == ITMTRemotePlayerRadioPlaylist);
    
    //
    //
    //rebuild submenus, make them properly enabled for once...
    //
    //
    
    if ( (trackInfoIndex > -1) && (playlist) ) {
        NSString *title, *album, *artist;
        int temp;
        
        lastSongIdentifier = [[currentRemote currentSongUniqueIdentifier] retain];
        
        if ( (temp = [menu indexOfItemWithTitle:@"No Song"]) && (temp > -1) ) {
            [menu removeItemAtIndex:temp];
            [menu insertItemWithTitle:@"Now Playing" action:NULL keyEquivalent:@"" atIndex:temp];
        } else {
            if ([defaults boolForKey:@"showName"]) {
                [menu removeItemAtIndex:trackInfoIndex + 1];
            }
        }
        
        title = [currentRemote currentSongTitle];
        
        if (!wasPlayingRadio && (temp == -1)) {
            if (didHaveAlbumName && [defaults boolForKey:@"showAlbum"]) {
                [menu removeItemAtIndex:trackInfoIndex + 1];
            }
            if (didHaveArtistName && [defaults boolForKey:@"showArtist"]) {
                [menu removeItemAtIndex:trackInfoIndex + 1];
            }
            if ([defaults boolForKey:@"showTime"]) {
                [menu removeItemAtIndex:trackInfoIndex + 1];
            }
        }
        
        if (!isPlayingRadio) {
            ([defaults boolForKey:@"showAlbum"]) ? (album = [currentRemote currentSongAlbum]) :
                                                   (album = @"");
            ([defaults boolForKey:@"showArtist"]) ? (artist = [currentRemote currentSongArtist]) :
                                                    (artist = @"");
            if ([defaults boolForKey:@"showTime"]) {
                [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", [currentRemote currentSongLength]] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
            }
            
            if ([artist length] > 0) {
                [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", artist] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
            }
            
            if ([album length] > 0) {
                [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", album] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
            }
            
            if ([defaults boolForKey:@"showArtist"]) {
                didHaveArtistName = (([artist length] > 0) ? YES : NO);
            }
            
            if ([defaults boolForKey:@"showAlbum"]) {
                didHaveAlbumName = (([album length] > 0) ? YES : NO);
            }
        }
        
        if ([title length] > 0) {
            [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", title] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
        }
    }
}


//
//
// Menu Selectors
//
//

- (void)selectSong:(id)sender
{
    [currentRemote switchToSongAtIndex:[[sender representedObject] intValue]];
}

- (void)selectPlaylist:(id)sender
{
    int playlist = [[sender representedObject] intValue];
    if (!isPlayingRadio) {
        int curPlaylist = [currentRemote currentPlaylistIndex];
        if (curPlaylist > 0) {
            [[playlistMenu itemAtIndex:curPlaylist - 1] setState:NSOffState];
        }
    }
    [currentRemote switchToPlaylistAtIndex:playlist];
    [[playlistMenu itemAtIndex:playlist - 1] setState:NSOnState];
    [self updateMenu];
}

- (void)selectEQPreset:(id)sender
{
    int curSet = [currentRemote currentEQPresetIndex];
    int item = [sender tag];
    
    if (item == -1) {
        [currentRemote setEqualizerEnabled:![currentRemote equalizerEnabled]];
    } else {
        [currentRemote setEqualizerEnabled:YES];
        [currentRemote switchToEQAtIndex:item];
        [[eqMenu itemAtIndex:curSet + 1] setState:NSOffState];
        [[eqMenu itemAtIndex:item + 2] setState:NSOnState];
    }
}

- (void)selectSongRating:(id)sender
{
    [[ratingMenu itemAtIndex:([currentRemote currentSongRating] / 20)] setState:NSOffState];
    [currentRemote setCurrentSongRating:(float)[sender tag] / 100.0];
    [sender setState:NSOnState];
}

- (void)playPause:(id)sender
{
    ITMTRemotePlayerPlayingState state = [currentRemote playerPlayingState];
    
    if (state == ITMTRemotePlayerPlaying) {
        [currentRemote pause];
        [playPauseItem setTitle:@"Play"];
    } else if ((state == ITMTRemotePlayerForwarding) || (state == ITMTRemotePlayerRewinding)) {
        [currentRemote pause];
        [currentRemote play];
    } else {
        [currentRemote play];
        [playPauseItem setTitle:@"Pause"];
    }
}

- (void)nextSong:(id)sender
{
    [currentRemote goToNextSong];
}

- (void)prevSong:(id)sender
{
    [currentRemote goToPreviousSong];
}

- (void)fastForward:(id)sender
{
    [currentRemote forward];
    [playPauseItem setTitle:@"Play"];
}

- (void)rewind:(id)sender
{
    [currentRemote rewind];
    [playPauseItem setTitle:@"Play"];
}

//
//
- (void)quitMenuTunes:(id)sender
{
    [NSApp terminate:self];
}

- (void)showPlayer:(id)sender
{
    if ( ( isAppRunning == ITMTRemotePlayerRunning) ) {
        [currentRemote showPrimaryInterface];
    } else {
        if (![[NSWorkspace sharedWorkspace] launchApplication:[currentRemote playerFullName]]) {
            NSLog(@"Error Launching Player");
        }
    }
}

- (void)showPreferences:(id)sender
{
    if (!prefsController) {
        prefsController = [[PreferencesController alloc] initWithMenuTunes:self];
        [self clearHotKeys];
    }
}

- (void)closePreferences
{
    if ( ( isAppRunning == ITMTRemotePlayerRunning) ) {
        [self setupHotKeys];
    }
    [prefsController release];
    prefsController = nil;
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
}

- (void)setupHotKeys
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"PlayPause"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"PlayPause"
                combo:[defaults keyComboForKey:@"PlayPause"]
                target:self action:@selector(playPause:)];
    }
    
    if ([defaults objectForKey:@"NextTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"NextTrack"
                combo:[defaults keyComboForKey:@"NextTrack"]
                target:self action:@selector(nextSong:)];
    }
    
    if ([defaults objectForKey:@"PrevTrack"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"PrevTrack"
                combo:[defaults keyComboForKey:@"PrevTrack"]
                target:self action:@selector(prevSong:)];
    }
    
    if ([defaults objectForKey:@"TrackInfo"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"TrackInfo"
                combo:[defaults keyComboForKey:@"TrackInfo"]
                target:self action:@selector(showCurrentTrackInfo)];
    }
    
    if ([defaults objectForKey:@"UpcomingSongs"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"UpcomingSongs"
               combo:[defaults keyComboForKey:@"UpcomingSongs"]
               target:self action:@selector(showUpcomingSongs)];
    }
}

//
//
// Show Current Track Info And Show Upcoming Songs Floaters
//
//

- (void)showCurrentTrackInfo
{
    NSString *trackName = [currentRemote currentSongTitle];
    if (!statusWindow && [trackName length]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *stringToShow = @"";
        
        if ([defaults boolForKey:@"showName"]) {
            if ([defaults boolForKey:@"showArtist"]) {
                NSString *trackArtist = [currentRemote currentSongArtist];
                trackName = [NSString stringWithFormat:@"%@ - %@", trackArtist, trackName];
            }
            stringToShow = [stringToShow stringByAppendingString:trackName];
            stringToShow = [stringToShow stringByAppendingString:@"\n"];
        }
        
        if ([defaults boolForKey:@"showAlbum"]) {
            NSString *trackAlbum = [currentRemote currentSongAlbum];
            if ([trackAlbum length]) {
                stringToShow = [stringToShow stringByAppendingString:trackAlbum];
                stringToShow = [stringToShow stringByAppendingString:@"\n"];
            }
        }
        
        if ([defaults boolForKey:@"showTime"]) {
            NSString *trackTime = [currentRemote currentSongLength];
            if ([trackTime length]) {
                stringToShow = [NSString stringWithFormat:@"%@Total Time: %@\n", stringToShow, trackTime];
            }
        }
        
        {
            int trackTimeLeft = [[currentRemote currentSongRemaining] intValue];
            int minutes = trackTimeLeft / 60, seconds = trackTimeLeft % 60;
            if (seconds < 10) {
                stringToShow = [stringToShow stringByAppendingString:
                            [NSString stringWithFormat:@"Time Remaining: %i:0%i", minutes, seconds]];
            } else {
                stringToShow = [stringToShow stringByAppendingString:
                            [NSString stringWithFormat:@"Time Remaining: %i:%i", minutes, seconds]];
            }
        }
        
        [statusWindow setText:stringToShow];
        [NSTimer scheduledTimerWithTimeInterval:3.0
                    target:self
                    selector:@selector(fadeAndCloseStatusWindow)
                    userInfo:nil
                    repeats:NO];
    }
}

- (void)showUpcomingSongs
{
    int curPlaylist = [currentRemote currentPlaylistIndex];
    if (!statusWindow) {
        int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curPlaylist];
        
        if (numSongs > 0) {
            int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
            int curTrack = [currentRemote currentSongIndex];
            int i;
            NSString *songs = @"";
            
            statusWindow = [ITTransientStatusWindow sharedWindow];
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    NSString *curSong = [currentRemote songTitleAtIndex:i];
                    songs = [songs stringByAppendingString:curSong];
                    songs = [songs stringByAppendingString:@"\n"];
                }
            }
            [statusWindow setText:songs];
            [NSTimer scheduledTimerWithTimeInterval:3.0
                        target:self
                        selector:@selector(fadeAndCloseStatusWindow)
                        userInfo:nil
                        repeats:NO];
        }
    }
}

- (void)fadeAndCloseStatusWindow
{
    [statusWindow orderOut:self];
}

- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(NSMenuItem *)item
{
    unichar charcode = 'a';
    int i;
    long cocoaModifiers = 0;
    static long carbonToCocoa[6][2] = 
    {
        { cmdKey, NSCommandKeyMask },
        { optionKey, NSAlternateKeyMask },
        { controlKey, NSControlKeyMask },
        { shiftKey, NSShiftKeyMask },
    };
    
    for (i = 0; i < 6; i++) {
        if (modifiers & carbonToCocoa[i][0]) {
            cocoaModifiers += carbonToCocoa[i][1];
        }
    }
    [item setKeyEquivalentModifierMask:cocoaModifiers];
    
    //Missing key combos for some keys. Must find them later.
    switch (code)
    {
        case 36:
            charcode = '\r';
        break;
        
        case 48:
            charcode = '\t';
        break;
        
        //Space -- ARGH!
        case 49:
        {
            /*MenuRef menuRef = _NSGetCarbonMenu([item menu]);
            NSLog(@"%@", menuRef);
            SetMenuItemCommandKey(menuRef, 0, NO, 49);
            SetMenuItemModifiers(menuRef, 0, kMenuNoCommandModifier);
            SetMenuItemKeyGlyph(menuRef, 0, kMenuBlankGlyph);
            charcode = 'b';*/
        }
        break;
        
        case 51:
            charcode = NSDeleteFunctionKey;
        break;
        
        case 53:
            charcode = '\e';
        break;
        
        case 71:
            charcode = '\e';
        break;
        
        case 76:
            charcode = '\r';
        break;
        
        case 96:
            charcode = NSF5FunctionKey;
        break;
        
        case 97:
            charcode = NSF6FunctionKey;
        break;
        
        case 98:
            charcode = NSF7FunctionKey;
        break;
        
        case 99:
            charcode = NSF3FunctionKey;
        break;
        
        case 100:
            charcode = NSF8FunctionKey;
        break;
        
        case 101:
            charcode = NSF9FunctionKey;
        break;
        
        case 103:
            charcode = NSF11FunctionKey;
        break;
        
        case 105:
            charcode = NSF3FunctionKey;
        break;
        
        case 107:
            charcode = NSF14FunctionKey;
        break;
        
        case 109:
            charcode = NSF10FunctionKey;
        break;
        
        case 111:
            charcode = NSF12FunctionKey;
        break;
        
        case 113:
            charcode = NSF13FunctionKey;
        break;
        
        case 114:
            charcode = NSInsertFunctionKey;
        break;
        
        case 115:
            charcode = NSHomeFunctionKey;
        break;
        
        case 116:
            charcode = NSPageUpFunctionKey;
        break;
        
        case 117:
            charcode = NSDeleteFunctionKey;
        break;
        
        case 118:
            charcode = NSF4FunctionKey;
        break;
        
        case 119:
            charcode = NSEndFunctionKey;
        break;
        
        case 120:
            charcode = NSF2FunctionKey;
        break;
        
        case 121:
            charcode = NSPageDownFunctionKey;
        break;
        
        case 122:
            charcode = NSF1FunctionKey;
        break;
        
        case 123:
            charcode = NSLeftArrowFunctionKey;
        break;
        
        case 124:
            charcode = NSRightArrowFunctionKey;
        break;
        
        case 125:
            charcode = NSDownArrowFunctionKey;
        break;
        
        case 126:
            charcode = NSUpArrowFunctionKey;
        break;
    }
    
    if (charcode == 'a') {
        unsigned long state;
        long keyTrans;
        char charCode;
        Ptr kchr;
        state = 0;
        kchr = (Ptr) GetScriptVariable(smCurrentScript, smKCHRCache);
        keyTrans = KeyTranslate(kchr, code, &state);
        charCode = keyTrans;
        [item setKeyEquivalent:[NSString stringWithCString:&charCode length:1]];
    } else if (charcode != 'b') {
        [item setKeyEquivalent:[NSString stringWithCharacters:&charcode length:1]];
    }
}

@end
