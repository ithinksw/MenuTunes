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
    StatusWindowRepeatNone,
    StatusWindowRepeatGroup,
    StatusWindowRepeatSong
} StatusWindowRepeatMode;


@interface StatusWindowController : NSObject {
    StatusWindow   *_window;
    NSUserDefaults *df;
}

- (void)showUpcomingSongsWindowWithTitles:(NSArray *)titleStrings;

- (void)showVolumeWindowWithLevel:(float)level;
- (void)showRatingWindowWithRating:(int)rating;
- (void)showShuffleWindow:(BOOL)shuffle;
- (void)showRepeatWindowWithMode:(StatusWindowRepeatMode)mode;
- (void)showSetupQueryWindow;

- (void)showSongInfoWindowWithSource:(ITMTRemotePlayerSource)source
                               title:            (NSString *)title
                               album:            (NSString *)album
                              artist:            (NSString *)artist
                                time:            (NSString *)time
                         trackNumber:                   (int)trackNumber
                          trackTotal:              	    (int)trackTotal
                              rating:                   (int)rating;


@end
