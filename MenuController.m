//
//  MenuController.m
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MenuController.h"
#import "MainController.h"
#import <ITFoundation/ITDebug.h>
#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITHotKey.h>
#import <ITKit/ITKeyCombo.h>
#import <ITKit/ITCategory-NSMenu.h>

@interface MenuController (SubmenuMethods)
- (NSMenu *)ratingMenu;
- (NSMenu *)upcomingSongsMenu;
- (NSMenu *)playlistsMenu;
- (NSMenu *)eqMenu;
- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(NSMenuItem *)item;
@end

@implementation MenuController

- (id)init
{
    if ( (self = [super init]) ) {
        _menuLayout = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSMenu *)menu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *menuArray = [defaults arrayForKey:@"menu"];
    NSEnumerator *enumerator = [menuArray objectEnumerator];
    NSString *nextObject;
    NSMenuItem *tempItem;
    NSEnumerator *itemEnum;
    ITHotKey *hotKey;
    NSArray *hotKeys = [[ITHotKeyCenter sharedCenter] allHotKeys];
    
    //Get the information
    _currentPlaylist = [currentRemote currentPlaylistIndex];
    _playingRadio = ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
    
    ITDebugLog(@"Reset menu if required.");
    
    //Kill the old submenu items
    if ( (tempItem = [_currentMenu itemWithTag:1]) ) {
        ITDebugLog(@"Removing \"Song Rating\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:2]) ) {
        ITDebugLog(@"Removing \"Upcoming Songs\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:3]) ) {
        ITDebugLog(@"Removing \"Playlists\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:4]) ) {
        ITDebugLog(@"Removing \"EQ Presets\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    ITDebugLog(@"Begin building menu.");
    
    //create our menu
    while ( (nextObject = [enumerator nextObject]) ) {
        //Main menu items
        if ([nextObject isEqualToString:@"playPause"]) {
            ITDebugLog(@"Add \"Play\"/\"Pause\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"play", @"Play")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPlayPauseItem];
            [tempItem setTarget:self];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"PlayPause"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            ITDebugLog(@"Set \"Play\"/\"Pause\" menu item's title to correct state.");
            switch ([currentRemote playerPlayingState]) {
                case ITMTRemotePlayerPlaying:
                    [tempItem setTitle:NSLocalizedString(@"pause", @"Pause")];
                break;
                case ITMTRemotePlayerRewinding:
                case ITMTRemotePlayerForwarding:
                    [tempItem setTitle:NSLocalizedString(@"resume", @"Resume")];
                break;
                default:
                break;
            }
        } else if ([nextObject isEqualToString:@"nextTrack"]) {
            ITDebugLog(@"Add \"Next Track\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"nextTrack", @"Next Track")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"NextTrack"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuNextTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"prevTrack"]) {
            ITDebugLog(@"Add \"Previous Track\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"prevTrack", @"Previous Track")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"PrevTrack"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuPreviousTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"fastForward"]) {
            ITDebugLog(@"Add \"Fast Forward\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"fastForward", @"Fast Forward")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuFastForwardItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"rewind"]) {
            ITDebugLog(@"Add \"Rewind\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"rewind", @"Rewind")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuRewindItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"showPlayer"]) {
            ITDebugLog(@"Add \"Show Player\" menu item.");
            tempItem = [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@",
                            NSLocalizedString(@"show", @"Show"),
                            [[[MainController sharedController] currentRemote] playerSimpleName]]
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"ShowPlayer"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            [tempItem setTarget:self];
            [tempItem setTag:MTMenuShowPlayerItem];
        } else if ([nextObject isEqualToString:@"preferences"]) {
            ITDebugLog(@"Add \"Preferences...\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPreferencesItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"quit"]) {
            ITDebugLog(@"Add \"Quit\" menu item.");
            if ([[MainController sharedController] blingBling] == NO) {
                ITDebugLog(@"Add \"Register MenuTunes...\" menu item.");
                tempItem = [menu addItemWithTitle:NSLocalizedString(@"register", @"Register MenuTunes...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
                [tempItem setTag:MTMenuRegisterItem];
                [tempItem setTarget:self];
            }
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuQuitItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"trackInfo"]) {
            ITDebugLog(@"Check to see if a Track is playing...");
            //Handle playing radio too
            if (_currentPlaylist) {
                NSString *title = [currentRemote currentSongTitle];
                ITDebugLog(@"A Track is Playing, Add \"Track Info\" menu items.");
                ITDebugLog(@"Add \"Now Playing\" menu item.");
                [menu addItemWithTitle:NSLocalizedString(@"nowPlaying", @"Now Playing") action:NULL keyEquivalent:@""];
                
                if ([title length] > 0) {
                    ITDebugLog(@"Add Track Title (\"%@\") menu item.", title);
                    [menu indentItem:
                        [menu addItemWithTitle:title action:nil keyEquivalent:@""]];
                }
                
                    if ([defaults boolForKey:@"showAlbum"]) {
                        NSString *curAlbum = [currentRemote currentSongAlbum];
                        ITDebugLog(@"Add Track Album (\"%@\") menu item.", curAlbum);
                        if ( curAlbum ) {
                            [menu indentItem:
                                [menu addItemWithTitle:curAlbum action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showArtist"]) {
                        NSString *curArtist = [currentRemote currentSongArtist];
                        ITDebugLog(@"Add Track Artist (\"%@\") menu item.", curArtist);
                        if ( curArtist ) {
                            [menu indentItem:
                                [menu addItemWithTitle:curArtist action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showTrackNumber"]) {
                        int track = [currentRemote currentSongTrack];
                        ITDebugLog(@"Add Track Number (\"Track %i\") menu item.", track);
                        if ( track > 0 ) {
                            [menu indentItem:
                                [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %i", NSLocalizedString(@"track", @"Track"), track] action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showTime"] && ( ([currentRemote currentSongElapsed] != nil) || ([currentRemote currentSongLength] != nil) )) {
                        ITDebugLog(@"Add Track Elapsed (\"%@/%@\") menu item.", [currentRemote currentSongElapsed], [currentRemote currentSongLength]);
                        [menu indentItem:[menu addItemWithTitle:[NSString stringWithFormat:@"%@/%@", [currentRemote currentSongElapsed], [currentRemote currentSongLength]] action:nil keyEquivalent:@""]];
                    }
                    
                    if ([defaults boolForKey:@"showTrackRating"] && ( [currentRemote currentSongRating] != -1.0 )) {
                        NSString *string = nil;
                        switch ((int)([currentRemote currentSongRating] * 5)) {
                            case 0:
                                string = [NSString stringWithUTF8String:"☆☆☆☆☆"];
                            break;
                            case 1:
                                string = [NSString stringWithUTF8String:"★☆☆☆☆"];
                            break;
                            case 2:
                                string = [NSString stringWithUTF8String:"★★☆☆☆"];
                            break;
                            case 3:
                                string = [NSString stringWithUTF8String:"★★★☆☆"];
                            break;
                            case 4:
                                string = [NSString stringWithUTF8String:"★★★★☆"];
                            break;
                            case 5:
                                string = [NSString stringWithUTF8String:"★★★★★"];
                            break;
                        }
                        ITDebugLog(@"Add Track Rating (\"%@\") menu item.", string);
                        [menu indentItem:[menu addItemWithTitle:string action:nil keyEquivalent:@""]];
                    }
                
            } else {
                ITDebugLog(@"No Track is Playing, Add \"No Song\" menu item.");
                [menu addItemWithTitle:NSLocalizedString(@"noSong", @"No Song") action:NULL keyEquivalent:@""];
            }
        } else if ([nextObject isEqualToString:@"separator"]) {
            ITDebugLog(@"Add a separator menu item.");
            [menu addItem:[NSMenuItem separatorItem]];
        //Submenu items
        } else if ([nextObject isEqualToString:@"playlists"]) {
            ITDebugLog(@"Add \"Playlists\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"playlists", @"Playlists")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_playlistsMenu];
            [tempItem setTag:3];
        } else if ([nextObject isEqualToString:@"eqPresets"]) {
            ITDebugLog(@"Add \"EQ Presets\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"eqPresets", @"EQ Presets")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_eqMenu];
            [tempItem setTag:4];
            
            itemEnum = [[_eqMenu itemArray] objectEnumerator];
            while ( (tempItem = [itemEnum nextObject]) ) {
                [tempItem setState:NSOffState];
            }
            [[_eqMenu itemAtIndex:([currentRemote currentEQPresetIndex] - 1)] setState:NSOnState];
        } else if ([nextObject isEqualToString:@"songRating"] && ( [currentRemote currentSongRating] != -1 )) {
                ITDebugLog(@"Add \"Song Rating\" submenu.");
                tempItem = [menu addItemWithTitle:NSLocalizedString(@"songRating", @"Song Rating")
                        action:nil
                        keyEquivalent:@""];
                [tempItem setSubmenu:_ratingMenu];
                [tempItem setTag:1];
                if (_playingRadio || !_currentPlaylist) {
                    [tempItem setEnabled:NO];
                }
                
                itemEnum = [[_ratingMenu itemArray] objectEnumerator];
                while ( (tempItem = [itemEnum nextObject]) ) {
                    [tempItem setState:NSOffState];
                }
                
                [[_ratingMenu itemAtIndex:([currentRemote currentSongRating] * 5)] setState:NSOnState];
            } else if ([nextObject isEqualToString:@"upcomingSongs"]) {
                ITDebugLog(@"Add \"Upcoming Songs\" submenu.");
                tempItem = [menu addItemWithTitle:NSLocalizedString(@"upcomingSongs", @"Upcoming Songs")
                        action:nil
                        keyEquivalent:@""];
                [tempItem setSubmenu:_upcomingSongsMenu];
                [tempItem setTag:2];
                if (_playingRadio || !_currentPlaylist) {
                    [tempItem setEnabled:NO];
                }
            }
        }
    ITDebugLog(@"Finished building menu.");
    [_currentMenu release];
    _currentMenu = menu;
    return _currentMenu;
}

- (NSMenu *)menuForNoPlayer
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *tempItem;
    ITDebugLog(@"Creating menu for when player isn't running.");
    ITDebugLog(@"Add \"Open %@\" menu item.", [[[MainController sharedController] currentRemote] playerSimpleName]);
    tempItem = [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"open", @"Open"), [[[MainController sharedController] currentRemote] playerSimpleName]] action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuShowPlayerItem];
    [tempItem setTarget:self];
    ITDebugLog(@"Add a separator menu item.");
    [menu addItem:[NSMenuItem separatorItem]];
    ITDebugLog(@"Add \"Preferences...\" menu item.");
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuPreferencesItem];
    [tempItem setTarget:self];
    if ([[MainController sharedController] blingBling] == NO) {
        ITDebugLog(@"Add \"Register MenuTunes...\" menu item.");
        tempItem = [menu addItemWithTitle:NSLocalizedString(@"register", @"Register MenuTunes...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
        [tempItem setTag:MTMenuRegisterItem];
        [tempItem setTarget:self];
    }
    ITDebugLog(@"Add \"Quit\" menu item.");
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuQuitItem];
    [tempItem setTarget:self];
    return [menu autorelease];
}

- (void)rebuildSubmenus
{
    ITDebugLog(@"Rebuilding all of the submenus.");
    
    currentRemote = [[MainController sharedController] currentRemote];
    _currentPlaylist = [currentRemote currentPlaylistIndex];
    _currentTrack = [currentRemote currentSongIndex];
    _playingRadio = ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
    
    [_ratingMenu release];
    [_upcomingSongsMenu release];
    [_playlistsMenu release];
    [_eqMenu release];
    ITDebugLog(@"Beginning Rebuild of \"Song Rating\" submenu.");
    _ratingMenu = [self ratingMenu];
    ITDebugLog(@"Beginning Rebuild of \"Upcoming Songs\" submenu.");
    _upcomingSongsMenu = [self upcomingSongsMenu];
    ITDebugLog(@"Beginning Rebuild of \"Playlists\" submenu.");
    _playlistsMenu = [self playlistsMenu];
    ITDebugLog(@"Beginning Rebuild of \"EQ Presets\" submenu.");
    _eqMenu = [self eqMenu];
    ITDebugLog(@"Done rebuilding all of the submenus.");
}

- (NSMenu *)ratingMenu
{
    NSMenu *ratingMenu = [[NSMenu alloc] initWithTitle:@""];
    NSEnumerator *itemEnum;
    id  anItem;
    int itemTag = 0;
    SEL itemSelector = @selector(performRatingMenuAction:);
    
    ITDebugLog(@"Building \"Song Rating\" menu.");
    
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"☆☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★★"] action:nil keyEquivalent:@""];
    
    itemEnum = [[ratingMenu itemArray] objectEnumerator];
    while ( (anItem = [itemEnum nextObject]) ) {
        ITDebugLog(@"Setting up \"%@\" menu item.", [anItem title]);
        [anItem setAction:itemSelector];
        [anItem setTarget:self];
        [anItem setTag:itemTag];
        itemTag += 20;
    }
    ITDebugLog(@"Done Building \"Song Rating\" menu.");
    return ratingMenu;
}

- (NSMenu *)upcomingSongsMenu
{
    NSMenu *upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:_currentPlaylist];
    int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
    
    ITDebugLog(@"Building \"Upcoming Songs\" menu.");
    
    if (_currentPlaylist && !_playingRadio) {
        if (numSongs > 0) {
            int i;

            for (i = _currentTrack + 1; i <= _currentTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    NSString *curSong = [currentRemote songTitleAtIndex:i];
                    NSMenuItem *songItem;
                    ITDebugLog(@"Adding song: %@", curSong);
                    songItem = [upcomingSongsMenu addItemWithTitle:curSong action:@selector(performUpcomingSongsMenuAction:) keyEquivalent:@""];
                    [songItem setTag:i];
                    [songItem setTarget:self];
                } else {
                    break;
                }
            }
        }
    }
    ITDebugLog(@"Done Building \"Upcoming Songs\" menu.");
    return upcomingSongsMenu;
}

- (NSMenu *)playlistsMenu
{
    NSMenu *playlistsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *playlists = [currentRemote playlists];
    NSMenuItem *tempItem;
    int i;
    
    ITDebugLog(@"Building \"Playlists\" menu.");
    
    for (i = 0; i < [playlists count]; i++) {
        NSString *curPlaylist = [playlists objectAtIndex:i];
        ITDebugLog(@"Adding playlist: %@", curPlaylist);
        tempItem = [playlistsMenu addItemWithTitle:curPlaylist action:@selector(performPlaylistMenuAction:) keyEquivalent:@""];
        [tempItem setTag:i + 1];
        [tempItem setTarget:self];
    }
    
    if (!_playingRadio && _currentPlaylist) {
        [[playlistsMenu itemAtIndex:_currentPlaylist - 1] setState:NSOnState];
    }
    ITDebugLog(@"Done Building \"Playlists\" menu");
    return playlistsMenu;
}

- (NSMenu *)eqMenu
{
    NSMenu *eqMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *eqPresets = [currentRemote eqPresets];
    NSMenuItem *tempItem;
    int i;
    
    ITDebugLog(@"Building \"EQ Presets\" menu.");
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *name;
	   if ( ( name = [eqPresets objectAtIndex:i] ) ) {
            ITDebugLog(@"Adding EQ Preset: %@", name);
            tempItem = [eqMenu addItemWithTitle:name
                    action:@selector(performEqualizerMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:i];
            [tempItem setTarget:self];
	   }
    }
    ITDebugLog(@"Done Building \"EQ Presets\" menu");
    return eqMenu;
}

- (void)performMainMenuAction:(id)sender
{
    switch ( [sender tag] )
    {
        case MTMenuPlayPauseItem:
            ITDebugLog(@"Performing Menu Action: Play/Pause");
            [[MainController sharedController] playPause];
            break;
        case MTMenuFastForwardItem:
            ITDebugLog(@"Performing Menu Action: Fast Forward");
            [[MainController sharedController] fastForward];
            break;
        case MTMenuRewindItem:
            ITDebugLog(@"Performing Menu Action: Rewind");
            [[MainController sharedController] rewind];
            break;
        case MTMenuPreviousTrackItem:
            ITDebugLog(@"Performing Menu Action: Previous Track");
            [[MainController sharedController] prevSong];
            break;
        case MTMenuNextTrackItem:
            ITDebugLog(@"Performing Menu Action: Next Track");
            [[MainController sharedController] nextSong];
            break;
        case MTMenuShowPlayerItem:
            ITDebugLog(@"Performing Menu Action: Show Main Interface");
            [[MainController sharedController] showPlayer];
            break;
        case MTMenuPreferencesItem:
            ITDebugLog(@"Performing Menu Action: Preferences...");
            [[MainController sharedController] showPreferences];
            break;
        case MTMenuQuitItem:
            ITDebugLog(@"Performing Menu Action: Quit");
            [[MainController sharedController] quitMenuTunes];
            break;
        case MTMenuRegisterItem:
            ITDebugLog(@"Performing Menu Action: Register");
            [[MainController sharedController] blingNow];
            break;
        default:
            ITDebugLog(@"Performing Menu Action: Unimplemented Menu Item OR Child-bearing Menu Item");
            break;
    }
}

- (void)performRatingMenuAction:(id)sender
{
    ITDebugLog(@"Rating action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectSongRating:[sender tag]];
}

- (void)performPlaylistMenuAction:(id)sender
{
    ITDebugLog(@"Playlist action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectPlaylistAtIndex:[sender tag]];
}

- (void)performEqualizerMenuAction:(id)sender
{
    ITDebugLog(@"EQ action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectEQPresetAtIndex:[sender tag]];
}

- (void)performUpcomingSongsMenuAction:(id)sender
{
    ITDebugLog(@"Song action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectSongAtIndex:[sender tag]];
}

- (void)updateMenu
{
    ITDebugLog(@"Update Menu");
    [_currentMenu update];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return YES;
}

//This is never used I know, keep it though
- (NSString *)systemUIColor
{
    NSDictionary *tmpDict;
    NSNumber *tmpNumber;
    if ( (tmpDict = [NSDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/.GlobalPreferences.plist" stringByExpandingTildeInPath]]) ) {
        if ( (tmpNumber = [tmpDict objectForKey:@"AppleAquaColorVariant"]) ) {
            if ( ([tmpNumber intValue] == 1) ) {
                return @"Aqua";
            } else {
                return @"Graphite";
            }
        } else {
            return @"Aqua";
        }
    } else {
        return @"Aqua";
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
    
    ITDebugLog(@"Setting Key Equivelent on menu item \"%@\".", [item title]);
    
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
            ITDebugLog(@"Keycode for menu item \"%@\": 36 (Return)", [item title]);
            charcode = '\r';
        break;
        
        case 48:
            ITDebugLog(@"Keycode for menu item \"%@\": 48 (Tab)", [item title]);
            charcode = '\t';
        break;
        
        //Space -- ARGH!
        case 49:
        {
            ITDebugLog(@"Keycode for menu item \"%@\": 49 (Space)", [item title]);
            // Haven't tested this, though it should work.
            // This doesn't work. :'(
            //unichar buffer;
            //[[NSString stringWithString:@"Space"] getCharacters:&buffer];
            //charcode = buffer;
            /*MenuRef menuRef = _NSGetCarbonMenu([item menu]);
            ITDebugLog(@"%@", menuRef);
            SetMenuItemCommandKey(menuRef, 0, NO, 49);
            SetMenuItemModifiers(menuRef, 0, kMenuNoCommandModifier);
            SetMenuItemKeyGlyph(menuRef, 0, kMenuBlankGlyph);
            charcode = 'b';*/
            unichar buffer;
            [[NSString stringWithString:@"_"] getCharacters:&buffer]; // this will have to do for now :(
            charcode = buffer;
        }
        break;
        
        case 51:
            ITDebugLog(@"Keycode for menu item \"%@\": 51 (Delete)", [item title]);
            charcode = NSDeleteFunctionKey;
        break;
        
        case 53:
            ITDebugLog(@"Keycode for menu item \"%@\": 53 (Escape)", [item title]);
            charcode = '\e';
        break;
        
        case 71:
            ITDebugLog(@"Keycode for menu item \"%@\": 71 (Escape)", [item title]);
            charcode = '\e';
        break;
        
        case 76:
            ITDebugLog(@"Keycode for menu item \"%@\": 76 (Return)", [item title]);
            charcode = '\r';
        break;
        
        case 96:
            ITDebugLog(@"Keycode for menu item \"%@\": 96 (F5)", [item title]);
            charcode = NSF5FunctionKey;
        break;
        
        case 97:
            ITDebugLog(@"Keycode for menu item \"%@\": 97 (F6)", [item title]);
            charcode = NSF6FunctionKey;
        break;
        
        case 98:
            ITDebugLog(@"Keycode for menu item \"%@\": 98 (F7)", [item title]);
            charcode = NSF7FunctionKey;
        break;
        
        case 99:
            ITDebugLog(@"Keycode for menu item \"%@\": 99 (F3)", [item title]);
            charcode = NSF3FunctionKey;
        break;
        
        case 100:
            ITDebugLog(@"Keycode for menu item \"%@\": 100 (F8)", [item title]);
            charcode = NSF8FunctionKey;
        break;
        
        case 101:
            ITDebugLog(@"Keycode for menu item \"%@\": 101 (F9)", [item title]);
            charcode = NSF9FunctionKey;
        break;
        
        case 103:
            ITDebugLog(@"Keycode for menu item \"%@\": 103 (F11)", [item title]);
            charcode = NSF11FunctionKey;
        break;
        
        case 105:
            ITDebugLog(@"Keycode for menu item \"%@\": 105 (F3)", [item title]);
            charcode = NSF3FunctionKey;
        break;
        
        case 107:
            ITDebugLog(@"Keycode for menu item \"%@\": 107 (F14)", [item title]);
            charcode = NSF14FunctionKey;
        break;
        
        case 109:
            ITDebugLog(@"Keycode for menu item \"%@\": 109 (F10)", [item title]);
            charcode = NSF10FunctionKey;
        break;
        
        case 111:
            ITDebugLog(@"Keycode for menu item \"%@\": 111 (F12)", [item title]);
            charcode = NSF12FunctionKey;
        break;
        
        case 113:
            ITDebugLog(@"Keycode for menu item \"%@\": 113 (F13)", [item title]);
            charcode = NSF13FunctionKey;
        break;
        
        case 114:
            ITDebugLog(@"Keycode for menu item \"%@\": 114 (Insert)", [item title]);
            charcode = NSInsertFunctionKey;
        break;
        
        case 115:
            ITDebugLog(@"Keycode for menu item \"%@\": 115 (Home)", [item title]);
            charcode = NSHomeFunctionKey;
        break;
        
        case 116:
            ITDebugLog(@"Keycode for menu item \"%@\": 116 (PgUp)", [item title]);
            charcode = NSPageUpFunctionKey;
        break;
        
        case 117:
            ITDebugLog(@"Keycode for menu item \"%@\": 117 (Delete)", [item title]);
            charcode = NSDeleteFunctionKey;
        break;
        
        case 118:
            ITDebugLog(@"Keycode for menu item \"%@\": 118 (F4)", [item title]);
            charcode = NSF4FunctionKey;
        break;
        
        case 119:
            ITDebugLog(@"Keycode for menu item \"%@\": 119 (End)", [item title]);
            charcode = NSEndFunctionKey;
        break;
        
        case 120:
            ITDebugLog(@"Keycode for menu item \"%@\": 120 (F2)", [item title]);
            charcode = NSF2FunctionKey;
        break;
        
        case 121:
            ITDebugLog(@"Keycode for menu item \"%@\": 121 (PgDown)", [item title]);
            charcode = NSPageDownFunctionKey;
        break;
        
        case 122:
            ITDebugLog(@"Keycode for menu item \"%@\": 122 (F1)", [item title]);
            charcode = NSF1FunctionKey;
        break;
        
        case 123:
            ITDebugLog(@"Keycode for menu item \"%@\": 123 (Left Arrow)", [item title]);
            charcode = NSLeftArrowFunctionKey;
        break;
        
        case 124:
            ITDebugLog(@"Keycode for menu item \"%@\": 124 (Right Arrow)", [item title]);
            charcode = NSRightArrowFunctionKey;
        break;
        
        case 125:
            ITDebugLog(@"Keycode for menu item \"%@\": 125 (Down Arrow)", [item title]);
            charcode = NSDownArrowFunctionKey;
        break;
        
        case 126:
            ITDebugLog(@"Keycode for menu item \"%@\": 126 (Up Arrow)", [item title]);
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
        ITDebugLog(@"Keycode for menu item \"%@\": %i (%c)", [item title], code, charCode);
        [item setKeyEquivalent:[NSString stringWithCString:&charCode length:1]];
    } else if (charcode != 'b') {
        [item setKeyEquivalent:[NSString stringWithCharacters:&charcode length:1]];
    }
    ITDebugLog(@"Done setting key equivalent on menu item: %@", [item title]);
}

@end