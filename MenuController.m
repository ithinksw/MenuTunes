//
//  MenuController.m
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MenuController.h"
#import "NewMainController.h"
#import "ITMTRemote.h"

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
    NSArray *menuArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"];
    NSEnumerator *enumerator = [menuArray objectEnumerator];
    NSString *nextObject;
    ITMTRemote *currentRemote = [[MainController sharedController] currentRemote];
    NSMenuItem *tempItem;
    
    //Get the current playlist, track index, etc.
    int playlistIndex = [currentRemote currentPlaylistIndex];
    //int trackIndex = [currentRemote currentSongIndex];
    
    //create our menu
    while ( (nextObject = [enumerator nextObject]) ) {
        //Main menu items
        if ([nextObject isEqualToString:@"Play/Pause"]) {
            tempItem = [menu addItemWithTitle:@"Play"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPlayPauseItem];
            [tempItem setTarget:self];
            
            switch ([currentRemote playerPlayingState]) {
                case ITMTRemotePlayerPlaying:
                    [tempItem setTitle:@"Pause"];
                break;
                case ITMTRemotePlayerRewinding:
                case ITMTRemotePlayerForwarding:
                    [tempItem setTitle:@"Resume"];
                break;
                default:
                break;
            }
        } else if ([nextObject isEqualToString:@"Next Track"]) {
            tempItem = [menu addItemWithTitle:@"Next Track"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (playlistIndex) {
                [tempItem setTag:MTMenuNextTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"Previous Track"]) {
            tempItem = [menu addItemWithTitle:@"Previous Track"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (playlistIndex) {
                [tempItem setTag:MTMenuPreviousTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"Fast Forward"]) {
            tempItem = [menu addItemWithTitle:@"Fast Forward"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (playlistIndex) {
                [tempItem setTag:MTMenuFastForwardItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"Rewind"]) {
            tempItem = [menu addItemWithTitle:@"Rewind"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (playlistIndex) {
                [tempItem setTag:MTMenuRewindItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"Preferences"]) {
            tempItem = [menu addItemWithTitle:@"Preferences..."
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPreferencesItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"Quit"]) {
            tempItem = [menu addItemWithTitle:@"Quit"
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuQuitItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"Current Track Info"]) {
            if (playlistIndex) {
                NSString *title = [currentRemote currentSongTitle];
                
                [menu addItemWithTitle:@"Now Playing" action:NULL keyEquivalent:@""];
                
                if ([title length] > 0) {
                    [menu addItemWithTitle:[NSString stringWithFormat:@"	 %@", title] action:nil keyEquivalent:@""];
                }
            } else {
                [menu addItemWithTitle:@"No Song" action:NULL keyEquivalent:@""];
            }
        } else if ([nextObject isEqualToString:@"<separator>"]) {
            [menu addItem:[NSMenuItem separatorItem]];
        //Submenu items
        } else if ([nextObject isEqualToString:@"Song Rating"]) {
            tempItem = [menu addItemWithTitle:@"Song Rating"
                    action:nil
                    keyEquivalent:@""];
            //[tempItem setSubmenu:[self ratingMenu]];
        } else if ([nextObject isEqualToString:@"Upcoming Songs"]) {
            tempItem = [menu addItemWithTitle:@"Upcoming Songs"
                    action:nil
                    keyEquivalent:@""];
            //[tempItem setSubmenu:[self upcomingSongsMenu]];
        } else if ([nextObject isEqualToString:@"Playlists"]) {
            tempItem = [menu addItemWithTitle:@"Playlists"
                    action:nil
                    keyEquivalent:@""];
            //[tempItem setSubmenu:[self playlistsMenu]];
        } else if ([nextObject isEqualToString:@"EQ Presets"]) {
            tempItem = [menu addItemWithTitle:@"EQ Presets"
                    action:nil
                    keyEquivalent:@""];
            //[tempItem setSubmenu:[self eqMenu]];
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
    [menu addItemWithTitle:[NSString stringWithFormat:@"Open %@", [[[MainController sharedController] currentRemote] playerSimpleName]] action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    tempItem = [menu addItemWithTitle:@"Preferences" action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuPreferencesItem];
    [tempItem setTarget:self];
    tempItem = [menu addItemWithTitle:@"Quit" action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuQuitItem];
    [tempItem setTarget:self];
    return [menu autorelease];
}

- (void)performMainMenuAction:(id)sender
{
    switch ( [sender tag] )
    {
        case MTMenuPlayPauseItem:
            NSLog(@"MenuController: Play/Pause");
            [[MainController sharedController] playPause];
            //We're gonna have to change the Play menu item to Pause here too.
            break;
        case MTMenuFastForwardItem:
            NSLog(@"MenuController: Fast Forward");
            [[MainController sharedController] fastForward];
            //make sure play/pause item says sane through this
            break;
        case MTMenuRewindItem:
            NSLog(@"MenuController: Rewind");
            [[MainController sharedController] rewind];
            //make sure play/pause item says sane through this
            break;
        case MTMenuPreviousTrackItem:
            NSLog(@"MenuController: Previous Track");
            [[MainController sharedController] prevSong];
            break;
        case MTMenuNextTrackItem:
            NSLog(@"MenuController: Next Track");
            [[MainController sharedController] nextSong];
            break;
        case MTMenuPreferencesItem:
            NSLog(@"MenuController: Preferences...");
            [[MainController sharedController] showPreferences];
            break;
        case MTMenuQuitItem:
            NSLog(@"MenuController: Quit");
            [[MainController sharedController] quitMenuTunes];
            break;
        default:
            NSLog(@"MenuController: Unimplemented Menu Item OR Child-bearing Menu Item");
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
