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
    
    //Kill the old submenu items
    if ( (tempItem = [_currentMenu itemWithTag:1]) ) {
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:2]) ) {
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:3]) ) {
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:4]) ) {
        [tempItem setSubmenu:nil];
    }
    
    //create our menu
    while ( (nextObject = [enumerator nextObject]) ) {
        //Main menu items
        if ([nextObject isEqualToString:@"playPause"]) {
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
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"fastForward", @"Fast Forward")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuFastForwardItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"rewind"]) {
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"rewind", @"Rewind")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuRewindItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"showPlayer"]) {
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
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPreferencesItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"quit"]) {
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuQuitItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"trackInfo"]) {
            //Handle playing radio too
            if (_currentPlaylist) {
                NSString *title = [currentRemote currentSongTitle];
                
                [menu addItemWithTitle:NSLocalizedString(@"nowPlaying", @"Now Playing") action:NULL keyEquivalent:@""];
                
                if ([title length] > 0) {
                    [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@", title]
                            action:nil
                            keyEquivalent:@""];
                }
                
                if ([defaults boolForKey:@"showAlbum"]) {
                    NSString *curAlbum = [currentRemote currentSongAlbum];
                    if ([curAlbum length]) {
                        [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@", curAlbum]
                                action:nil
                                keyEquivalent:@""];
                    }
                }
                
                if ([defaults boolForKey:@"showArtist"]) {
                    NSString *curArtist = [currentRemote currentSongArtist];
                    if ([curArtist length]) {
                        [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@", curArtist]
                                action:nil
                                keyEquivalent:@""];
                    }
                }
                
                if ([defaults boolForKey:@"showTrackNumber"]) {
                    int track = [currentRemote currentSongTrack];
                    if (track) {
                        [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@ %i", NSLocalizedString(@"track", @"Track"), track]
                            action:nil
                            keyEquivalent:@""];
                    }
                }
                
                if ([defaults boolForKey:@"showTime"]) {
                    int left = [[currentRemote currentSongRemaining] intValue];
                    NSString *remaining = [NSString stringWithFormat:@"%i:%02i", left / 60, left % 60];
                    [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@/%@", remaining, [currentRemote currentSongLength]]
                            action:nil
                            keyEquivalent:@""];
                }
            } else {
                [menu addItemWithTitle:NSLocalizedString(@"noSong", @"No Song") action:NULL keyEquivalent:@""];
            }
        } else if ([nextObject isEqualToString:@"separator"]) {
            [menu addItem:[NSMenuItem separatorItem]];
        //Submenu items
        } else if ([nextObject isEqualToString:@"songRating"]) {
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
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"upcomingSongs", @"Upcoming Songs")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_upcomingSongsMenu];
            [tempItem setTag:2];
            if (_playingRadio || !_currentPlaylist) {
                [tempItem setEnabled:NO];
            }
        } else if ([nextObject isEqualToString:@"playlists"]) {
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"playlists", @"Playlists")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_playlistsMenu];
            [tempItem setTag:3];
        } else if ([nextObject isEqualToString:@"eqPresets"]) {
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
        }
    }
    [_currentMenu release];
    _currentMenu = menu;
    return _currentMenu;
}

- (NSMenu *)menuForNoPlayer
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *tempItem;
    tempItem = [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"open", @"Open"), [[[MainController sharedController] currentRemote] playerSimpleName]] action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuShowPlayerItem];
    [tempItem setTarget:self];
    [menu addItem:[NSMenuItem separatorItem]];
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuPreferencesItem];
    [tempItem setTarget:self];
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuQuitItem];
    [tempItem setTarget:self];
    return [menu autorelease];
}

- (void)rebuildSubmenus
{
    currentRemote = [[MainController sharedController] currentRemote];
    _currentPlaylist = [currentRemote currentPlaylistIndex];
    _currentTrack = [currentRemote currentSongIndex];
    _playingRadio = ([currentRemote currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
    
    [_ratingMenu release];
    [_upcomingSongsMenu release];
    [_playlistsMenu release];
    [_eqMenu release];
    _ratingMenu = [self ratingMenu];
    _upcomingSongsMenu = [self upcomingSongsMenu];
    _playlistsMenu = [self playlistsMenu];
    _eqMenu = [self eqMenu];
}

- (NSMenu *)ratingMenu
{
    NSMenu *ratingMenu = [[NSMenu alloc] initWithTitle:@""];
    NSEnumerator *itemEnum;
    id  anItem;
    int itemTag = 0;
    SEL itemSelector = @selector(performRatingMenuAction:);
    
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"☆☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★★"] action:nil keyEquivalent:@""];
    
    itemEnum = [[ratingMenu itemArray] objectEnumerator];
    while ( (anItem = [itemEnum nextObject]) ) {
        [anItem setAction:itemSelector];
        [anItem setTarget:self];
        [anItem setTag:itemTag];
        itemTag += 20;
    }
    return ratingMenu;
}

- (NSMenu *)upcomingSongsMenu
{
    NSMenu *upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
    int numSongs = [currentRemote numberOfSongsInPlaylistAtIndex:_currentPlaylist];
    int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
    
    if (_currentPlaylist && !_playingRadio) {
        if (numSongs > 0) {
            int i;
            
            for (i = _currentTrack + 1; i <= _currentTrack + numSongsInAdvance; i++) {
                if (i <= numSongs) {
                    NSString *curSong = [currentRemote songTitleAtIndex:i];
                    NSMenuItem *songItem;
                    songItem = [upcomingSongsMenu addItemWithTitle:curSong action:@selector(performUpcomingSongsMenuAction:) keyEquivalent:@""];
                    [songItem setTag:i];
                    [songItem setTarget:self];
                } else {
                    break;
                }
            }
        }
    }
    return upcomingSongsMenu;
}

- (NSMenu *)playlistsMenu
{
    NSMenu *playlistsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *playlists = [currentRemote playlists];
    NSMenuItem *tempItem;
    int i;
    
    for (i = 0; i < [playlists count]; i++) {
        tempItem = [playlistsMenu addItemWithTitle:[playlists objectAtIndex:i] action:@selector(performPlaylistMenuAction:) keyEquivalent:@""];
        [tempItem setTag:i + 1];
        [tempItem setTarget:self];
    }
    
    if (!_playingRadio && _currentPlaylist) {
        [[playlistsMenu itemAtIndex:_currentPlaylist - 1] setState:NSOnState];
    }
    return playlistsMenu;
}

- (NSMenu *)eqMenu
{
    NSMenu *eqMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *eqPresets = [currentRemote eqPresets];
    NSMenuItem *tempItem;
    int i;
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *name;
	if ( ( name = [eqPresets objectAtIndex:i] ) ) {
            tempItem = [eqMenu addItemWithTitle:name action:@selector(performEqualizerMenuAction:) keyEquivalent:@""];
            [tempItem setTag:i];
            [tempItem setTarget:self];
	}
    }
    return eqMenu;
}

- (void)performMainMenuAction:(id)sender
{
    switch ( [sender tag] )
    {
        case MTMenuPlayPauseItem:
            ITDebugLog(@"MenuController: Play/Pause");
            [[MainController sharedController] playPause];
            break;
        case MTMenuFastForwardItem:
            ITDebugLog(@"MenuController: Fast Forward");
            [[MainController sharedController] fastForward];
            break;
        case MTMenuRewindItem:
            ITDebugLog(@"MenuController: Rewind");
            [[MainController sharedController] rewind];
            break;
        case MTMenuPreviousTrackItem:
            ITDebugLog(@"MenuController: Previous Track");
            [[MainController sharedController] prevSong];
            break;
        case MTMenuNextTrackItem:
            ITDebugLog(@"MenuController: Next Track");
            [[MainController sharedController] nextSong];
            break;
        case MTMenuShowPlayerItem:
            ITDebugLog(@"MainController: Show Main Interface");
            [[MainController sharedController] showPlayer];
            break;
        case MTMenuPreferencesItem:
            ITDebugLog(@"MenuController: Preferences...");
            [[MainController sharedController] showPreferences];
            break;
        case MTMenuQuitItem:
            ITDebugLog(@"MenuController: Quit");
            [[MainController sharedController] quitMenuTunes];
            break;
        default:
            ITDebugLog(@"MenuController: Unimplemented Menu Item OR Child-bearing Menu Item");
            break;
    }
}

- (void)performRatingMenuAction:(id)sender
{
    [[MainController sharedController] selectSongRating:[sender tag]];
}

- (void)performPlaylistMenuAction:(id)sender
{
    [[MainController sharedController] selectPlaylistAtIndex:[sender tag]];
}

- (void)performEqualizerMenuAction:(id)sender
{
    [[MainController sharedController] selectEQPresetAtIndex:[sender tag]];
}

- (void)performUpcomingSongsMenuAction:(id)sender
{
    [[MainController sharedController] selectSongAtIndex:[sender tag]];
}

- (void)updateMenu
{
    
    [_currentMenu update];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return YES;
}

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
            // This doesn't work. :'(
            unichar buffer;
            [[NSString stringWithString:@"Space"] getCharacters:&buffer];
            charcode = buffer;
            /*MenuRef menuRef = _NSGetCarbonMenu([item menu]);
            ITDebugLog(@"%@", menuRef);
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