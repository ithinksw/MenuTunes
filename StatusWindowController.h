/*
 *	MenuTunes
 *  StatusWindowController
 *    Abstraction layer between MainController and StatusWindow
 *
 *  Original Author : Matthew Judy <mjudy@ithinksw.com>
 *   Responsibility : Matthew Judy <mjudy@ithinksw.com>
 *
 *  Copyright (c) 2003 iThink Software.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>
#import "ITMTRemote.h"


@class StatusWindow;


typedef enum {
    MTStatusWindowLoopModeLoopNone,
    MTStatusWindowLoopModeLoopOne,
    MTStatusWindowLoopModeLoopAll
} MTStatusWindowLoopMode;

typedef enum {
    MTStatusWindowShuffleModeOn,
    MTStatusWindowShuffleModeOff
} MTStatusWindowShuffleMode;


@interface StatusWindowController : NSObject {
    StatusWindow *_window;
    NSUserDefaults *df;
}

- (void)showSongWindowWithTitle:            (NSString *)title
                          album:            (NSString *)album
                         artist:            (NSString *)artist
                           time:            (NSString *)time  // FLOW: Should probably be NSDate or something.
                    trackNumber:                   (int)trackNumber
                     trackTotal:              	   (int)trackTotal
                         rating:                   (int)rating
                         source:(ITMTRemotePlayerSource)source;

- (void)showUpcomingSongsWithTitles:(NSArray *)titleStrings;

- (void)showVolumeWindowWithLevel:(float)level;
- (void)showRatingWindowWithLevel:(int)level;
- (void)showShuffleWindowWithMode:(MTStatusWindowShuffleMode)mode;
- (void)showLoopWindowWithMode:(MTStatusWindowLoopMode)mode;

@end
