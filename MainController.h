/*
 *	MenuTunes
 *  MainController
 *    App Controller Class
 *
 *  Original Author : Matthew Judy <mjudy@ithinksw.com>
 *   Responsibility : Matthew Judy <mjudy@ithinksw.com>
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

@class StatusWindowController, MenuController;

@interface MainController : NSObject
{
    ITStatusItem   *statusItem;
    NSMutableArray *remoteArray;
    ITMTRemote     *currentRemote;
    
    ITMTRemotePlayerRunningState  playerRunningState;
    ITMTRemotePlayerPlaylistClass latestPlaylistClass;
    
    //Used in updating the menu automatically
    NSTimer *refreshTimer;
    NSString *_latestSongIdentifier;
    
    StatusWindowController *statusWindowController; //Shows status windows
    MenuController *menuController;
    NSUserDefaults *df;
}
+ (MainController *)sharedController;

- (void)menuClicked;

//Methods called from MenuController by menu items
- (void)playPause;
- (void)nextSong;
- (void)prevSong;
- (void)fastForward;
- (void)rewind;
- (void)selectPlaylistAtIndex:(int)index;
- (void)selectSongAtIndex:(int)index;
- (void)selectSongRating:(int)rating;
- (void)selectEQPresetAtIndex:(int)index;
- (void)showPlayer;
- (void)showPreferences;
- (void)quitMenuTunes;

//

- (ITMTRemote *)currentRemote;
- (void)clearHotKeys;
- (void)setupHotKeys;
- (void)closePreferences;

@end
