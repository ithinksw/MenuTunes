#import "MainController.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindowController.h"

@interface MainController(Private)
- (ITMTRemote *)loadRemote;
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


/*************************************************************************/
#pragma mark -
#pragma mark MENU BUILDING METHODS
/*************************************************************************/

- (NSMenu *)menu
{
    NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    [theMenu addItem:[self playlistMenuItem]];
    [theMenu addItem:[self upcomingSongsMenuItem]];
    [theMenu addItem:[self ratingMenuItem]];

    return theMenu;
}

- (NSMenu *)menuForNoPlayer
{
    return nil;
}

- (NSMenuItem *)playlistMenuItem
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Playlists"
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    int           currentPlaylist = [currentRemote currentPlaylistIndex];
    NSArray      *playlists       = [currentRemote playlists];
    NSEnumerator *playlistEnum    = [playlists objectEnumerator];
    int           playlistTag     = 1;
    id            aPlaylist;

    [item setSubmenu:submenu];
    [submenu setAutoenablesItems:NO];
    
    while ( (aPlaylist = [playlistEnum nextObject]) ) {
        NSMenuItem *playlistItem = [[[NSMenuItem alloc] initWithTitle:aPlaylist
                                                               action:@selector(selectPlaylist:)
                                                        keyEquivalent:@""] autorelease];
        [playlistItem setTag:playlistTag];
        [playlistItem setTarget:self];
        playlistTag++;
        [submenu addItem:playlistItem];
    }

    if ( (! [self radioIsPlaying]) && currentPlaylist) {
        [[submenu itemAtIndex:(currentPlaylist - 1)] setState:NSOnState];
    }

    return item;
}

- (NSMenuItem *)upcomingSongsMenuItem
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Upcoming Songs"
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    int curIndex = [currentRemote currentPlaylistIndex];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:curIndex];
    int numSongsInAdvance = [df integerForKey:@"SongsInAdvance"];

    [item setSubmenu:submenu];

    if ( [self radioIsPlaying] ) {
        [submenu addItemWithTitle:@"No Upcoming Songs..." action:nil keyEquivalent:@""];
        [submenu addItemWithTitle:@"Playing Radio Stream" action:nil keyEquivalent:@""];
    } else {
        if ( ! (numSongs > 0) ) {
            [submenu addItemWithTitle:@"No Songs in Playlist" action:nil keyEquivalent:@""];
        } else {
            int curTrack = [currentRemote currentSongIndex];
            int i;

            for (i = curTrack + 1; ( (i <= curTrack + numSongsInAdvance) && (i <= numSongs) ); i++) {

                NSString *curSong = [currentRemote songTitleAtIndex:i];
                NSMenuItem *songItem = [[[NSMenuItem alloc] initWithTitle:curSong
                                                                   action:@selector(selectSong:)
                                                            keyEquivalent:@""] autorelease];
                [songItem setRepresentedObject:[NSNumber numberWithInt:i]];
                [submenu addItem:songItem];
            }
        }
    }
    
    return item;
}

- (NSMenuItem *)ratingMenuItem
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Rating"
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    [item setSubmenu:submenu];

    [submenu addItemWithTitle:[NSString stringWithUTF8String:"☆☆☆☆☆"] action:nil keyEquivalent:@""];
    [submenu addItemWithTitle:[NSString stringWithUTF8String:"★☆☆☆☆"] action:nil keyEquivalent:@""];
    [submenu addItemWithTitle:[NSString stringWithUTF8String:"★★☆☆☆"] action:nil keyEquivalent:@""];
    [submenu addItemWithTitle:[NSString stringWithUTF8String:"★★★☆☆"] action:nil keyEquivalent:@""];
    [submenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★☆"] action:nil keyEquivalent:@""];
    [submenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★★"] action:nil keyEquivalent:@""];

    if ( ! ( [self radioIsPlaying] || [self songIsPlaying] ) ) {

        NSEnumerator *itemEnum;
        id            anItem;
        int           itemTag      = 0;
        SEL           itemSelector = @selector(selectSongRating:);

        itemEnum = [[submenu itemArray] objectEnumerator];
        while ( (anItem = [itemEnum nextObject]) ) {
            [anItem setAction:itemSelector];
            [anItem setTag:itemTag];
            itemTag += 20;
        }
    }

    return item;
}

- (NSMenuItem *)eqMenuItem
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Equalizer"
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    NSArray      *eqPresets = [currentRemote eqPresets];
    NSEnumerator *eqEnum    = [eqPresets objectEnumerator];
    int           eqTag     = 0;
    id            anEq;
    
    [item setSubmenu:submenu];

    while ( ( anEq = [eqEnum nextObject]) ) {
        NSMenuItem *eqItem = [[[NSMenuItem alloc] initWithTitle:anEq
                                                         action:@selector(selectEQPreset:)
                                                  keyEquivalent:@""] autorelease];
        [eqItem setTag:eqTag];
        eqTag++;
        [submenu addItem:eqItem];
    }

    [[submenu itemAtIndex:([currentRemote currentEQPresetIndex] - 1)] setState:NSOnState];
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

/*
//Recreate the status item menu
- (void)rebuildMenu
{
    NSArray *myMenu = [df arrayForKey:@"menu"];
    int playlist = [currentRemote currentPlaylistIndex];
    int i;
    
    if ([currentRemote playerRunningState] == ITMTRemotePlayerNotRunning) {
        return;
    }
    
    trackInfoIndex = -1;
    lastPlaylistIndex = -1;
    
    [menu release];
    menu = [[NSMenu alloc] initWithTitle:@""];
    
    playPauseItem = nil;
    
    upcomingSongsItem = nil;
    [upcomingSongsMenu release];
    upcomingSongsMenu = nil;
    
    if (ratingItem) {
        [ratingItem setSubmenu:nil];
    }
    
    playlistItem = nil;
    [playlistMenu release];
    playlistMenu = nil;
    
    eqItem = nil;
    [eqMenu release];
    eqMenu = nil;
    
    //Build the custom menu
    for (i = 0; i < [myMenu count]; i++) {
        NSString *item = [myMenu objectAtIndex:i];
        if ([item isEqualToString:@"Play/Pause"]) {
            KeyCombo *tempCombo = [df keyComboForKey:@"PlayPause"];
            playPauseItem = [menu addItemWithTitle:@"Play"
                                    action:@selector(playPause:)
                                    keyEquivalent:@""];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:playPauseItem];
                [tempCombo release];
            }
        } else if ([item isEqualToString:@"Next Track"]) {
            KeyCombo *tempCombo = [df keyComboForKey:@"NextTrack"];
            NSMenuItem *nextTrack = [menu addItemWithTitle:@"Next Track"
                                        action:@selector(nextSong:)
                                        keyEquivalent:@""];
            
            if (tempCombo) {
                [self setKeyEquivalentForCode:[tempCombo keyCode]
                    andModifiers:[tempCombo modifiers] onItem:nextTrack];
                [tempCombo release];
            }
        } else if ([item isEqualToString:@"Previous Track"]) {
            KeyCombo *tempCombo = [df keyComboForKey:@"PrevTrack"];
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
            ratingItem = [menu addItemWithTitle:@"Song Rating"
                    action:nil
                    keyEquivalent:@""];
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
    
    isPlayingRadio = ([currentRemote classOfPlaylistAtIndex:playlist] == ITMTRemotePlayerRadioPlaylist);
    
    if (upcomingSongsItem) {
        [self rebuildUpcomingSongsMenu];
    }
    
    if (ratingItem) {
        if (isPlayingRadio || !playlist) {
            [ratingItem setEnabled:NO];
        } else {
            int currentSongRating = ([currentRemote currentSongRating] * 5);
            [[ratingMenu itemAtIndex:lastSongRating] setState:NSOffState];
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
            if ([df boolForKey:@"showTime"]) {
                NSString *length = [currentRemote currentSongLength];
                char character = [length characterAtIndex:0];
                if ( (character > '0') && (character < '9') ) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", [currentRemote currentSongLength]] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([df boolForKey:@"showRating"]) {
                if (title) { //Check to see if there's a song playing
                [menu insertItemWithTitle:[NSString stringWithFormat:@"	 %@", [[ratingMenu itemAtIndex:[currentRemote currentSongRating] * 5] title]] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([df boolForKey:@"showArtist"]) {
                NSString *artist = [currentRemote currentSongArtist];
                if ([artist length] > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", artist] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([df boolForKey:@"showNumber"]) {
                int track = [currentRemote currentSongTrack];
                int total = [currentRemote currentAlbumTrackCount];
                if (total > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  Track %i of %i", track, total] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
            
            if ([df boolForKey:@"showAlbum"]) {
                NSString *album = [currentRemote currentSongAlbum];
                if ([album length] > 0) {
                    [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", album] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
                }
            }
        }
        
        if ([title length] > 0) {
            [menu insertItemWithTitle:[NSString stringWithFormat:@"  %@", title] action:nil keyEquivalent:@"" atIndex:trackInfoIndex + 1];
        }
    }
    
    [statusItem setMenu:menu];
    
    [self clearHotKeys];
    [self setupHotKeys];
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

*/

- (void)timerUpdate
{
    if ( ( [self songChanged] ) ||
         ( ([self radioIsPlaying]) && (latestPlaylistClass != ITMTRemotePlayerRadioPlaylist) ) ||
         ( (! [self radioIsPlaying]) && (latestPlaylistClass == ITMTRemotePlayerRadioPlaylist) ) ) {
        [statusItem setMenu:[self menu]];
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

/*
//
//
// Menu Selectors
//
//

- (void)selectSong:(id)sender
{
    [currentRemote switchToSongAtIndex:[[sender representedObject] intValue]];
}
*/
- (void)selectPlaylist:(id)sender
{
    int playlist = [sender tag];
    [currentRemote switchToPlaylistAtIndex:playlist];
}
/*
- (void)selectEQPreset:(id)sender
{
    int curSet = [currentRemote currentEQPresetIndex];
    int item = [sender tag];
    
    [currentRemote switchToEQAtIndex:item];
    [[eqMenu itemAtIndex:curSet - 1] setState:NSOffState];
    [[eqMenu itemAtIndex:item] setState:NSOnState];
}
*/
/*
- (void)selectSongRating:(id)sender
{
    int newRating = [sender tag];
//  [[ratingMenu itemAtIndex:lastSongRating] setState:NSOffState];
    [sender setState:NSOnState];
    [currentRemote setCurrentSongRating:(float)newRating / 100.0];
    lastSongRating = newRating / 20;
}
*/
/*
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
*/

//
//
- (void)quitMenuTunes:(id)sender
{
    [NSApp terminate:self];
}

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

- (void)showPreferences:(id)sender
{
    [[PreferencesController sharedPrefs] setController:self];
    [[PreferencesController sharedPrefs] showPrefsWindow:self];
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
            // Haven't tested this, though it should work.
            unichar buffer;
            [[NSString stringWithString:@"Space"] getCharacters:&buffer];
            charcode = buffer;
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
