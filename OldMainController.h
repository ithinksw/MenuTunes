/*
 *	MenuTunes
 *  MainController
 *    App Controller Class
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2002-2003 iThink Software.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ITKit/ITKit.h>
#import <ITFoundation/ITFoundation.h>
#import <ITMTRemote/ITMTRemote.h>
#import <StatusWindow.h>

@class PreferencesController, StatusWindow;

@interface MainController : NSObject
{
    ITStatusItem   *statusItem;
    ITMTRemote     *currentRemote;
    NSMutableArray *remoteArray;
    
    //Used in updating the menu automatically
    NSTimer *refreshTimer;
    int      trackInfoIndex;
    int      lastSongIndex;
    int      lastPlaylistIndex;
    BOOL     isPlayingRadio;
    
    ITMTRemotePlayerRunningState isAppRunning;
    
    PreferencesController *prefsController;
    StatusWindow *statusWindow; //Shows track info and upcoming songs.
}

- (void)applicationLaunched:(NSNotification *)note;
- (void)applicationTerminated:(NSNotification *)note;

- (void)registerDefaults;

- (void)startTimerInNewThread;

- (void)clearHotKeys;
- (void)closePreferences;

- (void)showPlayer:(id)sender;

@end
