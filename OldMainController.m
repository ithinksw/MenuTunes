#import "MainController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindow.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
- (void)rebuildUpcomingSongsMenu;
- (void)rebuildPlaylistMenu;
- (void)rebuildEQPresetsMenu;
- (void)updateRatingMenu;
- (void)setupHotKeys;
- (void)timerUpdate;
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    currentRemote = [self loadRemote];
    
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

    if ( ! [defaults objectForKey:@"menu"] ) {  // If this is nil, defaults have never been registered.
        [[PreferencesController sharedPrefs] registerDefaults];
    }
    
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
        [currentRemote begin];
        [self timerUpdate];
        [NSThread detachNewThreadSelector:@selector(startTimerInNewThread) toTarget:self withObject:nil];
        [self setupHotKeys];
        isAppRunning = ITMTRemotePlayerRunning;
    }
}

- (void)applicationTerminated:(NSNotification *)note
{
    if (!note || [[[note userInfo] objectForKey:@"NSApplicationName"] isEqualToString:[currentRemote playerFullName]]) {
        NSMenu *notRunningMenu = [[NSMenu alloc] initWithTitle:@""];
        [notRunningMenu addItemWithTitle:[NSString stringWithFormat:@"Open %@", [currentRemote playerSimpleName]] action:@selector(showPlayer:) keyEquivalent:@""];
        [notRunningMenu addItem:[NSMenuItem separatorItem]];
        [notRunningMenu addItemWithTitle:@"Preferences..." action:@selector(showPreferences:) keyEquivalent:@""];
        [[notRunningMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""] setTarget:NSApp];
        [statusItem setMenu:[notRunningMenu autorelease]];
        
        [currentRemote halt];
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
        [self clearHotKeys];
        isAppRunning = ITMTRemotePlayerNotRunning;
    }
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

//Recreate the status item menu
- (void)rebuildMenu
{
    NSUserDefaults *defaults;
    NSArray *myMenu;
    int playlist;
    int i;
    unichar fullstar = 0x2605;
    unichar emptystar = 0x2606;
    NSString *fullStarChar;
    NSString *emptyStarChar;
    
    if ([currentRemote playerRunningState] == ITMTRemotePlayerNotRunning) {
        return;
    }
    
    defaults = [NSUserDefaults standardUserDefaults];
    myMenu = [defaults arrayForKey:@"menu"];
    playlist = [currentRemote currentPlaylistIndex];
    fullStarChar = [NSString stringWithCharacters:&fullstar length:1];
    emptyStarChar = [NSString stringWithCharacters:&emptystar length:1];
    
    trackInfoIndex = -1;
    lastPlaylistIndex = -1;
    
    [menu release];
    menu = [[NSMenu alloc] initWithTitle:@""];
    
    //Release the old submenus
    playPauseItem = nil;
    upcomingSongsItem = nil;
    [upcomingSongsMenu release];
    upcomingSongsMenu = nil;
    playlistItem = nil;
    [playlistMenu release];
    playlistMenu = nil;
    eqItem = nil;
    [eqMenu release];
    eqMenu = nil;
    if (ratingItem) {
        [ratingItem setSubmenu:nil];
        [ratingItem release];
        ratingItem = nil;
    }
    
    //Build the rating menu
    [ratingMenu release];
    ratingMenu = [[NSMenu alloc] initWithTitle:@""];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:0];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:20];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, emptyStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:40];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, emptyStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:60];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, emptyStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:80];
    [[ratingMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@%@%@%@", fullStarChar, fullStarChar, fullStarChar, fullStarChar, fullStarChar] action:@selector(selectSongRating:) keyEquivalent:@""] setTag:100];
    
    //Build the custom menu
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
        } else if ([item isEqualToString:@"Show Player"]) {
            [menu addItemWithTitle:[NSString stringWithFormat:@"Show %@", [currentRemote playerSimpleName]]
                    action:@selector(showPlayer:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Upcoming Songs"]) {
            upcomingSongsItem = [menu addItemWithTitle:@"Upcoming Songs"
                    action:nil
                    keyEquivalent:@""];
            upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
            [upcomingSongsItem setSubmenu:upcomingSongsMenu];
            [upcomingSongsItem setEnabled:NO];
        } else if ([item isEqualToString:@"Playlists"]) {
            playlistItem = [menu addItemWithTitle:@"Playlists"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"EQ Presets"]) {
            eqItem = [menu addItemWithTitle:@"EQ Presets"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"PreferencesÉ"]) {
            [menu addItemWithTitle:@"PreferencesÉ"
                    action:@selector(showPreferences:)
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Quit"]) {
            [[menu addItemWithTitle:@"Quit"
                    action:@selector(terminate:)
                    keyEquivalent:@""] setTarget:NSApp];
        } else if ([item isEqualToString:@"Current Track Info"]) {
            trackInfoIndex = [menu numberOfItems];
            [menu addItemWithTitle:@"No Song"
                    action:nil
                    keyEquivalent:@""];
        } else if ([item isEqualToString:@"Song Rating"]) {
            ratingItem = [[menu addItemWithTitle:@"Song Rating"
                    action:nil
                    keyEquivalent:@""] retain];
            [ratingItem setSubmenu:ratingMenu];
        } else if ([item isEqualToString:@"<separator>"]) {
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    if (playlistItem) {
        [self rebuildPlaylistMenu];
    }
    
    if (eqItem) {
        [self rebuildEQPresetsMenu];
    }
    
    isPlayingRadio = ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
    
    if (upcomingSongsItem) {
        [self rebuildUpcomingSongsMenu];
    }
    
    if (ratingItem) {
        if (isPlayingRadio || !playlist) {
            [ratingItem setEnabled:NO];
        } else {
            int currentSongRating = ([currentRemote currentSongRating] * 5);
            lastSongRating = currentSongRating;
            [[ratingMenu itemAtIndex:lastSongRating] setState:NSOnState];
            [ratingItem setEnabled:YES];
        }
    }
    
    //Set the new unique song identifier
    lastSongIdentifier = [[currentRemote currentSongUniqueIdentifier] retain];
    
    //If we're in a playlist or radio mode
    if ( ![lastSongIdentifier isEqualToString:@"0-0"] && (trackInfoIndex > -1) ) {
        NSString *title;
        
        if ( (i = [menu indexOfItemWithTitle:@"No Song"]) ) {
            if ( (i > -1) ) {
                [menu removeItemAtIndex:i];
                [menu insertItemWithTitle:@"Now Playing" action:NULL keyEquivalent:@"" atIndex:i];
            }
        }
        
        title = [currentRemote currentSongTitle];
        
        if (!isPlayingRadio) {
            if ([defaults boolForKey:@"showTime"]) {
                NSString *length = [currentRemote currentSongLength];
                char character = [length characterAtIndex:0];
                if ( (character > '0') && (character < '9') ) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", [currentRemote currentSongLength]] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([defaults boolForKey:@"showTrackRating"]) {
                if (title) { //Check to see if there's a song playing
                [menu insertItemWithTitle:[NSString stringWithFormat:@"	 %@", [[ratingMenu itemAtIndex:[currentRemote currentSongRating] * 5] title]] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([defaults boolForKey:@"showArtist"]) {
                NSString *artist = [currentRemote currentSongArtist];
                if ([artist length] > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", artist] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([defaults boolForKey:@"showTrackNumber"]) {
                int track = [currentRemote currentSongTrack];
                int total = [currentRemote currentAlbumTrackCount];
                if (total > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  Track %i of %i", track, total] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([defaults boolForKey:@"showAlbum"]) {
                NSString *album = [currentRemote currentSongAlbum];
                if ([album length] > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", album] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
        }
        
        if ([title length] > 0) {
            [menu insertItemWithTitle:[NSString stringWithFormat:@"	 %@", title] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
        }
    }
    
    [statusItem setMenu:menu];
    
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
    int i, currentPlaylist = [currentRemote currentPlaylistIndex];
    
    [playlistMenu release];
    playlistMenu = [[NSMenu alloc] initWithTitle:@""];
    
    for (i = 0; i < [playlists count]; i++) {
        NSString *playlistName = [playlists objectAtIndex:i];
        NSMenuItem *tempItem;
        tempItem = [[NSMenuItem alloc] initWithTitle:playlistName action:@selector(selectPlaylist:) keyEquivalent:@""];
        [tempItem setTag:i + 1];
        [playlistMenu addItem:tempItem];
        [tempItem release];
    }
    [playlistItem setSubmenu:playlistMenu];
    [playlistItem setEnabled:YES];
    
    if (!isPlayingRadio && currentPlaylist) {
        [[playlistMenu itemAtIndex:currentPlaylist - 1] setState:NSOnState];
    }
}

//Build a menu with the list of all available EQ presets
- (void)rebuildEQPresetsMenu
{
    NSArray *eqPresets = [currentRemote eqPresets];
    int i;
    
    [eqMenu autorelease];
    eqMenu = [[NSMenu alloc] initWithTitle:@""];
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *name;
        NSMenuItem *tempItem;
	if ( ( name = [eqPresets objectAtIndex:i] ) ) {
            tempItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectEQPreset:) keyEquivalent:@""];
            [tempItem setTag:i];
            [eqMenu addItem:tempItem];
            [tempItem autorelease];
	}
    }
    
    [eqItem setSubmenu:eqMenu];
    [eqItem setEnabled:YES];
    [[eqMenu itemAtIndex:([currentRemote currentEQPresetIndex] - 1)] setState:NSOnState];
}

- (void)updateRatingMenu
{
    int currentSongRating = ([currentRemote currentSongRating] * 5);
    if ([currentRemote currentPlaylistIndex] && (currentSongRating != lastSongRating)) {
        if ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist) {
            return;
        }
        [[ratingMenu itemAtIndex:lastSongRating] setState:NSOffState];
        lastSongRating = currentSongRating;
        [[ratingMenu itemAtIndex:lastSongRating] setState:NSOnState];
    }
}

- (void)timerUpdate
{
    NSString *currentIdentifier = [currentRemote currentSongUniqueIdentifier];
    if (![lastSongIdentifier isEqualToString:currentIdentifier] ||
       (!isPlayingRadio && ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist))) {
        //
        //
        // If we want to show the new track floater, do it here!
        //[self showCurrentTrackInfoStatusWindow];
        //
        //
        [self rebuildMenu];
    }
    
    [self updateRatingMenu];
    
    //Update Play/Pause menu item
    if (playPauseItem){
        //
        //
        // If we want to show the song played/paused, show it here!
        //
        //
        if ([currentRemote playerPlayingState] == ITMTRemotePlayerPlaying) {
            [playPauseItem setTitle:@"Pause"];
        } else {
            [playPauseItem setTitle:@"Play"];
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
    int playlist = [sender tag];
    [currentRemote switchToPlaylistAtIndex:playlist];
}

- (void)selectEQPreset:(id)sender
{
    int curSet = [currentRemote currentEQPresetIndex];
    int item = [sender tag];
    
    [currentRemote switchToEQAtIndex:item];
    [[eqMenu itemAtIndex:curSet - 1] setState:NSOffState];
    [[eqMenu itemAtIndex:item] setState:NSOnState];
}

- (void)selectSongRating:(id)sender
{
    int newRating = [sender tag];
    [[ratingMenu itemAtIndex:lastSongRating] setState:NSOffState];
    [sender setState:NSOnState];
    [currentRemote setCurrentSongRating:(float)newRating / 100.0];
    lastSongRating = newRating / 20;
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
    [[PreferencesController sharedPrefs] setController:self];
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
}

- (void)closePreferences
{
    if ( ( isAppRunning == ITMTRemotePlayerRunning) ) {
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
    [[HotKeyCenter sharedCenter] removeHotKey:@"ToggleVisualizer"];
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
    
    if ([defaults objectForKey:@"ToggleVisualizer"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleVisualizer"
                combo:[defaults keyComboForKey:@"ToggleVisualizer"]
                target:self action:@selector(toggleVisualizer)];
    }
    
    if ([defaults objectForKey:@"TrackInfo"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"TrackInfo"
                combo:[defaults keyComboForKey:@"TrackInfo"]
                target:self action:@selector(showCurrentTrackInfoStatusWindow)];
    }
    
    if ([defaults objectForKey:@"UpcomingSongs"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"UpcomingSongs"
               combo:[defaults keyComboForKey:@"UpcomingSongs"]
               target:self action:@selector(showUpcomingSongsStatusWindow)];
    }
    
    if ([defaults objectForKey:@"ToggleLoop"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleLoop"
               combo:[defaults keyComboForKey:@"ToggleLoop"]
               target:self action:@selector(showToggleLoopStatusWindow)];
    }
    
    if ([defaults objectForKey:@"ToggleShuffle"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"ToggleShuffle"
               combo:[defaults keyComboForKey:@"ToggleShuffle"]
               target:self action:@selector(showToggleShuffleStatusWindow)];
    }
    
    if ([defaults objectForKey:@"IncrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementVolume"
               combo:[defaults keyComboForKey:@"IncrementVolume"]
               target:self action:@selector(showVolumeIncrementStatusWindow)];
    }
    
    if ([defaults objectForKey:@"DecrementVolume"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementVolume"
               combo:[defaults keyComboForKey:@"DecrementVolume"]
               target:self action:@selector(showVolumeDecrementStatusWindow)];
    }
    
    if ([defaults objectForKey:@"IncrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"IncrementRating"
               combo:[defaults keyComboForKey:@"IncrementRating"]
               target:self action:@selector(showRatingIncrementStatusWindow)];
    }
    
    if ([defaults objectForKey:@"DecrementRating"] != nil) {
        [[HotKeyCenter sharedCenter] addHotKey:@"DecrementRating"
               combo:[defaults keyComboForKey:@"DecrementRating"]
               target:self action:@selector(showRatingDecrementStatusWindow)];
    }
}

//
//
// Status Window Methods
//
//

- (void)showCurrentTrackInfoStatusWindow
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
        
        //
        //SHOW THE STATUS WINDOW HERE WITH STRING stringToShow
        //
        
        /*[statusWindow setText:stringToShow];
        [NSTimer scheduledTimerWithTimeInterval:3.0
                    target:self
                    selector:@selector(fadeAndCloseStatusWindow)
                    userInfo:nil
                    repeats:NO];*/
    }
}

- (void)showUpcomingSongsStatusWindow
{
    int curPlaylist = [currentRemote currentPlaylistIndex];
    if (!statusWindow) {
        int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curPlaylist];
        
        if (numSongs > 0) {
            int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
            int curTrack = [currentRemote currentSongIndex];
            int i;
            NSString *songs = @"";
            
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    NSString *curSong = [currentRemote songTitleAtIndex:i];
                    songs = [songs stringByAppendingString:curSong];
                    songs = [songs stringByAppendingString:@"\n"];
                }
            }
            
            //
            //SHOW STATUS WINDOW HERE WITH STRING songs
            //
            
            /*[statusWindow setText:songs];
            [NSTimer scheduledTimerWithTimeInterval:3.0
                        target:self
                        selector:@selector(fadeAndCloseStatusWindow)
                        userInfo:nil
                        repeats:NO];*/
        }
    }
}

- (void)showVolumeIncrementStatusWindow
{
}

- (void)showVolumeDecrementStatusWindow
{
}

- (void)showRatingIncrementStatusWindow
{
}

- (void)showRatingDecrementStatusWindow
{
}

- (void)showToggleLoopStatusWindow
{
}

- (void)showToggleShuffleStatusWindow
{
}

- (void)toggleVisualizer
{
    NSLog(@"Visualizer On/Off");
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
            SetMenuItemCommandKey(menuRef, 1, NO, 49);
            SetMenuItemModifiers(menuRef, 1, kMenuNoCommandModifier);
            SetMenuItemKeyGlyph(menuRef, 1, kMenuBlankGlyph);*/
            charcode = 'b';
            
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
