#import "MainController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindow.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)setupHotKeys;
- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(NSMenuItem *)item;
- (NSMenu *)mainMenu;
- (NSMenu *)songRatingMenu;
- (NSMenu *)playlistsMenu;
- (NSMenu *)upcomingSongsMenu;
- (NSMenu *)eqPresetsMenu;
@end

@implementation MainController

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
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    currentRemote = [self loadRemote];
    [currentRemote begin];
    
    //Setup for notification of the remote player launching or quitting
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    
    [self registerDefaults];
    
    statusItem = [[ITStatusItem alloc] initWithStatusBar:[NSStatusBar systemStatusBar] withLength:NSSquareStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"menu"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"selected_image"]];
    // Below line of code is for creating builds for Beta Testers
    // [statusItem setToolTip:@[NSString stringWithFormat:@"This Nontransferable Beta (Built on %s) of iThink Software's MenuTunes is Registered to: Beta Tester (betatester@somedomain.com).",__DATE__]];
    
    if ( ( [currentRemote playerRunningState] == ITMTRemotePlayerRunning ) ) {
        [self applicationLaunched:nil];
    } else {
        [self applicationTerminated:nil];
    }
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self clearHotKeys];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

//
//

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
            if ([[[tempDict objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
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

//
//

- (void)applicationLaunched:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        [NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
        [statusItem setMenu:[self mainMenu]];
        [self setupHotKeys];
        isAppRunning = ITMTRemotePlayerRunning;
        return;
    }
    
    isAppRunning = ITMTRemotePlayerRunning;
}

- (void)applicationTerminated:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {        
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [[menu addItemWithTitle:[NSString stringWithFormat:@"Open %@", [currentRemote playerSimpleName]] action:@selector(showPlayer:) keyEquivalent:@""] setTarget:self];
        [menu addItem:[NSMenuItem separatorItem]];
        [[menu addItemWithTitle:@"Preferences" action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        [[menu addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""] setTarget:self];
        [statusItem setMenu:[menu autorelease]];
        
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
        [self clearHotKeys];
        isAppRunning = NO;
        return;
    }
}

- (void)startTimerInNewThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES] retain];
    [runLoop run];
    [pool release];
}

- (void)timerUpdate
{
    ITMTRemotePlayerPlayingState playerPlayingState = [currentRemote playerPlayingState];
    NSMenu *statusMenu = [statusItem menu];
    int index;
    
    //Update play/pause menu item
    if (playerPlayingState == ITMTRemotePlayerPlaying) {
        index = [statusMenu indexOfItemWithTitle:@"Play"];
        if (index > -1) {
            [[statusMenu itemAtIndex:index] setTitle:@"Pause"];
        }
    } else {
        index = [statusMenu indexOfItemWithTitle:@"Pause"];
        if (index > -1) {
            [[statusMenu itemAtIndex:index] setTitle:@"Play"];
        }
    }
    
    if (0 == 1/*Maybe set this to something better sometime*/) {
        [statusItem setMenu:[self mainMenu]];
    }
}

//
//

- (NSMenu *)mainMenu
{
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *myMenu = [[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"];
    int i;
    
    for (i = 0; i < [myMenu count]; i++) {
        NSString *currentItem = [myMenu objectAtIndex:i];
        
        if ([currentItem isEqualToString:@"Play/Pause"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"PlayPause"];
            NSMenuItem *playPauseMenuItem = [mainMenu addItemWithTitle:@"Play" action:@selector(playPause:) keyEquivalent:@""];
            [playPauseMenuItem setTarget:self];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:playPauseMenuItem];
                [tempCombo release];
            }
        } else if ([currentItem isEqualToString:@"Next Track"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"NextTrack"];
            NSMenuItem *nextTrack = [mainMenu addItemWithTitle:@"Next Track" action:@selector(nextSong:) keyEquivalent:@""];
            [nextTrack setTarget:self];
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:nextTrack];
                [tempCombo release];
            }
        } else if ([currentItem isEqualToString:@"Previous Track"]) {
            KeyCombo *tempCombo = [[NSUserDefaults standardUserDefaults] keyComboForKey:@"PrevTrack"];
            NSMenuItem *prevTrack = [mainMenu addItemWithTitle:@"Previous Track" action:@selector(prevSong:) keyEquivalent:@""];
            [prevTrack setTarget:self];
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:prevTrack];
                [tempCombo release];
            }
        } else if ([currentItem isEqualToString:@"Fast Forward"]) {
            [[mainMenu addItemWithTitle:@"Fast Forward"action:@selector(fastForward:) keyEquivalent:@""] setTarget:self];
        } else if ([currentItem isEqualToString:@"Rewind"]) {
            [[mainMenu addItemWithTitle:@"Rewind" action:@selector(rewind:) keyEquivalent:@""] setTarget:self];
        } else if ([currentItem isEqualToString:@"EQ Presets"]) {
            [[mainMenu addItemWithTitle:@"EQ Presets" action:NULL keyEquivalent:@""] setSubmenu:[self eqPresetsMenu]];
        } else if ([currentItem isEqualToString:@"Playlists"]) {
            [[mainMenu addItemWithTitle:@"Playlists" action:NULL keyEquivalent:@""] setSubmenu:[self playlistsMenu]];
        } else if ([currentItem isEqualToString:@"Song Rating"]) {
            [[mainMenu addItemWithTitle:@"Song Rating"action:NULL keyEquivalent:@""] setSubmenu:[self songRatingMenu]];
        } else if ([currentItem isEqualToString:@"Upcoming Songs"]) {
            [[mainMenu addItemWithTitle:@"Upcoming Songs"action:NULL keyEquivalent:@""] setSubmenu:[self upcomingSongsMenu]];
        } else if ([currentItem isEqualToString:@"Preferences…"]) {
            [[mainMenu addItemWithTitle:@"Preferences..." action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        } else if ([currentItem isEqualToString:@"Quit"]) {
            [[mainMenu addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""] setTarget:self];
        } else if ([currentItem isEqualToString:@"Current Song Info"]) {
            //Current Song Info
            {
                int currentSongIndex = [currentRemote currentSongIndex];
                
                if (currentSongIndex == 0) {
                    [mainMenu addItemWithTitle:@"No Song" action:NULL keyEquivalent:@""];
                } else {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [mainMenu addItemWithTitle:@"Now Playing" action:NULL keyEquivalent:@""];
                    
                    if ([defaults objectForKey:@"showName"]) {
                        [mainMenu addItemWithTitle:[NSString stringWithFormat:@"	%@", [currentRemote currentSongTitle]] action:NULL keyEquivalent:@""];
                    }
                    
                    if ([defaults objectForKey:@"showAlbum"]) {
                        [mainMenu addItemWithTitle:[NSString stringWithFormat:@"	%@", [currentRemote currentSongAlbum]] action:NULL keyEquivalent:@""];
                    }
                    
                    if ([defaults objectForKey:@"showArtist"]) {
                        [mainMenu addItemWithTitle:[NSString stringWithFormat:@"	%@", [currentRemote currentSongArtist]] action:NULL keyEquivalent:@""];
                    }
                    
                    if ([defaults objectForKey:@"showTime"]) {
                        [mainMenu addItemWithTitle:[NSString stringWithFormat:@"	%@", [currentRemote currentSongLength]] action:NULL keyEquivalent:@""];
                    }
                }
            }
        } else if ([currentItem isEqualToString:@"<separator>"]) {
            [mainMenu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    NSLog(@"%@", mainMenu);
    return [mainMenu autorelease];
}

- (NSMenu *)songRatingMenu
{
    NSMenu *songRatingMenu = [[NSMenu alloc] initWithTitle:@""];
    unichar fullstar = 0x2605;
    unichar emptystar = 0x2606;
    NSString *fullStarChar = [NSString stringWithCharacters:&fullstar length:1];
    NSString *emptyStarChar = [NSString stringWithCharacters:&emptystar length:1];
    NSMenuItem *item;
    int currentSongRating = ([currentRemote currentSongRating] * 5);
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:0];
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:20];
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:40];
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:60];
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:80];
    
    item = [songRatingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, fullStarChar] action:@selector(selectSongRating:) keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:100];
    
    [[songRatingMenu itemAtIndex:(currentSongRating / 20)] setState:NSOnState];
    
    return [songRatingMenu autorelease];
}

- (void)selectSongRating:(id)sender
{
    [currentRemote setCurrentSongRating:(float)[sender tag] / 100.0];
}

- (NSMenu *)playlistsMenu
{
    NSMenu *playlistsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *playlists = [currentRemote playlists];
    int i, currentPlaylistIndex = [currentRemote currentPlaylistIndex];
    
    if ([currentRemote classOfPlaylistAtIndex:currentPlaylistIndex] == ITMTRemotePlayerRadioPlaylist) {
        currentPlaylistIndex = 0;
    }
    
    for (i = 0; i < [playlists count]; i++) {
        NSString *name = [playlists objectAtIndex:i];
        NSMenuItem *item;
        item = [playlistsMenu addItemWithTitle:name action:@selector(selectPlaylist:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:i + 1];
        
        if (i + 1 == currentPlaylistIndex) {
            [item setState:NSOnState];
        }
    }
    return [playlistsMenu autorelease];
}

- (void)selectPlaylist:(id)sender
{
    int newPlaylistIndex = [sender tag];
    if ([currentRemote currentPlaylistIndex] + 1 != newPlaylistIndex) {
        [currentRemote switchToPlaylistAtIndex:newPlaylistIndex];
    }
}

- (NSMenu *)upcomingSongsMenu
{
    NSMenu *upcomingSongsMenu;
    int i, currentPlaylistIndex, currentPlaylistLength, currentSongIndex, songsInAdvance;
    
    if ([currentRemote classOfPlaylistAtIndex:currentPlaylistIndex] == ITMTRemotePlayerRadioPlaylist)
    {
        return nil;
    }
    
    upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
    currentPlaylistIndex = [currentRemote currentPlaylistIndex];
    currentPlaylistLength = [currentRemote numberOfSongsInPlaylistAtIndex:currentPlaylistIndex];
    currentSongIndex = [currentRemote currentSongIndex];
    songsInAdvance = 8; //Change according to the preferences
    
    for (i = currentSongIndex + 1; i <= currentSongIndex + songsInAdvance; i++) {
        if (i <= currentPlaylistLength) {
            NSString *name = [currentRemote songTitleAtIndex:i];
            NSMenuItem *item;
            
            item = [upcomingSongsMenu addItemWithTitle:name action:@selector(selectUpcomingSong:) keyEquivalent:@""];
            [item setTarget:self];
            [item setTag:i];
        }
    }
    return [upcomingSongsMenu autorelease];    
}

- (void)selectUpcomingSong:(id)sender
{
    [currentRemote switchToSongAtIndex:[sender tag]];
}

- (NSMenu *)eqPresetsMenu
{
    NSMenu *eqPresetsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *eqPresets = [currentRemote eqPresets];
    int i, currentPresetIndex = [currentRemote currentEQPresetIndex];
    
    NSMenuItem *eqEnabledMenuItem;
    
    eqEnabledMenuItem = [eqPresetsMenu addItemWithTitle:@"Enabled" action:@selector(selectEQPreset:) keyEquivalent:@""];
    [eqEnabledMenuItem setTarget:self];
    [eqEnabledMenuItem setTag:-1];
    if ([currentRemote equalizerEnabled] == YES) {
        [eqEnabledMenuItem setState:NSOnState];
    }
    
    [eqPresetsMenu addItem:[NSMenuItem separatorItem]];
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *name = [eqPresets objectAtIndex:i];
        NSMenuItem *item;
        
        item = [eqPresetsMenu addItemWithTitle:name action:@selector(selectEQPreset:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:i];
        
        if (currentPresetIndex == i) {
            [item setState:NSOnState];
        }
    }
    return [eqPresetsMenu autorelease];
}

- (void)selectEQPreset:(id)sender
{
    int newEQPresetIndex = [sender tag];
    
    if (newEQPresetIndex == -1) {
        [currentRemote setEqualizerEnabled:![currentRemote equalizerEnabled]];
    }
    
    if ([currentRemote currentEQPresetIndex] + 1 != newEQPresetIndex) {
        [currentRemote switchToEQAtIndex:newEQPresetIndex];
    }
}

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

- (void)playPause:(id)sender
{
    ITMTRemotePlayerPlayingState state = [currentRemote playerPlayingState];
    NSMenu *statusMenu = [statusItem menu];
    
    if (state == ITMTRemotePlayerPlaying) {
        [currentRemote pause];
        [[statusMenu itemAtIndex:[statusMenu indexOfItemWithTitle:@"Pause"]] setTitle:@"Play"];
    } else if ((state == ITMTRemotePlayerForwarding) || (state == ITMTRemotePlayerRewinding)) {
        [currentRemote pause];
        [currentRemote play];
    } else {
        [currentRemote play];
        [[statusMenu itemAtIndex:[statusMenu indexOfItemWithTitle:@"Play"]] setTitle:@"Pause"];
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
}

- (void)rewind:(id)sender
{
    [currentRemote rewind];
}

- (void)toggleEqualizer
{
    [currentRemote setEqualizerEnabled:![currentRemote equalizerEnabled]];
}

- (void)quitMenuTunes:(id)sender
{
    [NSApp terminate:self];
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

//
//

//The status window methods go here!

//
//

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