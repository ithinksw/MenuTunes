//
//  MenuController.m
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MenuController.h"


@implementation MenuController

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
            break;
        case MTMenuFastForwardItem:
            NSLog(@"MenuController: Fast Forward");
            break;
        case MTMenuRewindItem:
            NSLog(@"MenuController: Rewind");
            break;
        case MTMenuPreviousTrackItem:
            NSLog(@"MenuController: Previous Track");
            break;
        case MTMenuNextTrackItem:
            NSLog(@"MenuController: Next Track");
            break;
        case MTMenuPreferencesItem:
            NSLog(@"MenuController: Preferences...");
            break;
        case MTMenuQuitItem:
            NSLog(@"MenuController: Quit");
            break;
        default:
            NSLog(@"MenuController: Unimplemented Menu Item OR Child-bearing Menu Item");
            break;
    }
}

- (void)performRatingMenuAction
{
}

- (void)performPlaylistMenuAction
{
}

- (void)performEqualizerMenuAction
{
}

- (void)performUpcomingSongsMenuAction
{
}

- (void)updateMenu
{
    [_currentMenu update];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
}

@end
