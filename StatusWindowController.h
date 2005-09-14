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
#import "StatusWindow.h"


typedef enum {
    StatusWindowRepeatNone = -1,
    StatusWindowRepeatGroup,
    StatusWindowRepeatTrack
} StatusWindowRepeatMode;


@interface StatusWindowController : NSObject {
    StatusWindow   *_window;
    NSUserDefaults *df;
	NSRange _timeRange;
}

+ (StatusWindowController *)sharedController;

- (void)showUpcomingSongsWindowWithTitles:(NSArray *)titleStrings;

- (void)showVolumeWindowWithLevel:(float)level;
- (void)showRatingWindowWithRating:(float)rating;
- (void)showShuffleWindow:(BOOL)shuffle;
- (void)showRepeatWindowWithMode:(StatusWindowRepeatMode)mode;
- (void)showSongShufflabilityWindow:(BOOL)shufflable;
- (void)showSetupQueryWindow;
- (void)showRegistrationQueryWindow;
- (void)showReconnectQueryWindow;
- (void)showNetworkErrorQueryWindow;
- (void)showPreferencesUpdateWindow;
- (void)showDebugModeEnabledWindow;

- (void)showSongInfoWindowWithSource:(ITMTRemotePlayerSource)source
                               title:            (NSString *)title
                               album:            (NSString *)album
                              artist:            (NSString *)artist
                            composer:            (NSString *)composer
                                time:            (NSString *)time  // FLOW: Should probably be NSDate or something.
                               track:            (NSString *)track
                              rating:                   (int)rating
                           playCount:                   (int)playCount
                               image:             (NSImage *)art;

- (void)updateTime:(NSString *)time;

@end
