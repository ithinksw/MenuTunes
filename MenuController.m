//
//  MenuController.m
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MenuController.h"
#import "MainController.h"

@implementation MenuController

- (id)init
{
    if ( (self = [super init]) ) {
        _menuLayout = [[NSMutableArray alloc] initWithCapacity:
    }
    return self;
}

- (NSMenu *)menu
{
    // dynamically create menu from supplied data and layout information.
    // ...
    // right before returning the menu, set the created menu to instance variable _currentMenu.
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
    [[MainController sharedController] selectEQItemAtIndex:[sender tag]]
}

- (void)performUpcomingSongsMenuAction:(id)sender
{
    [[MainController sharedController] selectSongAtIndex:[sender tag]]
}

- (void)updateMenu
{
    
    [_currentMenu update];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
}

- (NSString *)systemUIColor
{
    NSDictionary *tmpDict;
    NSNumber *tmpNumber;
    if ( (tmpDict = [NSDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/.GlobalPreferences.plist" stringByExpandingTildeInPath]]) ) {
        if ( (tmpNumber = [tmpDict objectForKey:@"AppleAquaColorVariant"]) ) {
            if ( ([tmpNumber intValue == 1) ) {
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
