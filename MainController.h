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

#define MT_CURRENT_VERSION 1720

@class StatusWindowController, MenuController, NetworkController;

@interface MainController : NSObject
{
    ITStatusItem   *statusItem;
    NSMutableArray *remoteArray;
    ITMTRemote     *currentRemote;
    
    ITMTRemotePlayerRunningState  playerRunningState;
    ITMTRemotePlayerPlaylistClass latestPlaylistClass;
    
    //Used in updating the menu automatically
    NSTimer *refreshTimer;
    NSString *_latestSongIdentifier, *_toolTip;
	NSDictionary *_lastTrackInfo;

    StatusWindowController *statusWindowController; //Shows status windows
    MenuController *menuController;
    NetworkController *networkController;
    NSUserDefaults *df;
    
    NSTimer *_statusWindowUpdateTimer, *_audioscrobblerTimer;
    BOOL timerUpdating, _checkingForServer, _popped, _open, _needsPolling;
	int _timeUpdateCount; //Keeps track of how many times the time has been updated in the info status window
	int _audioscrobblerInterval;
    NSLock *_serverCheckLock;
}
+ (MainController *)sharedController;

- (void)menuClicked;

- (void)timerUpdate;

- (void)playPause;
- (void)nextSong;
- (void)prevSong;
- (void)fastForward;
- (void)rewind;
- (void)selectPlaylistAtIndex:(int)index;
- (void)selectSongAtIndex:(int)index;
- (void)selectSongRating:(int)rating;
- (void)selectEQPresetAtIndex:(int)index;
- (void)makePlaylistWithTerm:(NSString *)term ofType:(int)type;
- (void)showPlayer;
- (void)showPreferences;
- (void)showTestWindow;
- (void)quitMenuTunes;

//

- (void)setServerStatus:(BOOL)newStatus;
- (int)connectToServer;
- (BOOL)disconnectFromServer;
- (void)checkForRemoteServerAndConnectImmediately:(BOOL)connectImmediately;
- (void)networkError:(NSException *)exception;

//

- (ITMTRemote *)currentRemote;
- (void)clearHotKeys;
- (void)setupHotKeys;
- (void)closePreferences;
- (MenuController *)menuController;

- (void)showCurrentAlbumArt;
- (void)showCurrentTrackInfo;

@end

@interface NSImage (SmoothAdditions)
- (NSImage *)imageScaledSmoothlyToSize:(NSSize)scaledSize;
@end