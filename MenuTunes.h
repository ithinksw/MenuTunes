/*
 *	MenuTunes
 *  MenuTunes
 *    App Controller Class
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2002 The iThink Group.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class MenuTunesView, PreferencesController, StatusWindowController;

@interface MenuTunes : NSObject
{
    NSStatusItem *statusItem;
    NSMenu *menu;
    MenuTunesView *view;
    ComponentInstance asComponent;
    
    //Used in updating the menu automatically
    NSTimer *refreshTimer;
    int curTrackIndex;
    int trackInfoIndex;
    
    ProcessSerialNumber iTunesPSN;
    bool didHaveAlbumName; //Helper variable for creating the menu
    
    //For upcoming songs
    NSMenuItem *upcomingSongsItem;
    NSMenu *upcomingSongsMenu;
    
    //For playlist selection
    NSMenuItem *playlistItem;
    NSMenu *playlistMenu;
    
    //For EQ sets
    NSMenuItem *eqItem;
    NSMenu *eqMenu;
    
    NSMenuItem *playPauseMenuItem; //Toggle between 'Play' and 'Pause'
    
    PreferencesController *prefsController;
    StatusWindowController *statusController; //Shows track info and upcoming songs.
}

- (void)rebuildMenu;
- (void)clearHotKeys;
- (ProcessSerialNumber)iTunesPSN;
- (void)closePreferences;

@end
