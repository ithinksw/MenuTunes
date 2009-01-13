/*
 *	MenuTunes
 *	StatusWindowController.h
 *
 *	Abstraction layer between MainController and StatusWindow.
 *
 *	Copyright (c) 2003 iThink Software
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

typedef enum {
	StatusWindowNoType = -1,
	StatusWindowTrackInfoType,
	StatusWindowAlbumArtType,
	StatusWindowUpcomingSongsType,
	StatusWindowVolumeType,
	StatusWindowRatingType,
	StatusWindowRepeatType,
	StatusWindowShuffleType,
	StatusWindowShufflabilityType,
	StatusWindowSetupType,
	StatusWindowNetworkType,
	StatusWindowPreferencesType,
	StatusWindowDebugType
} StatusWindowType;

@interface StatusWindowController : NSObject {
    StatusWindow   *_window;
    NSUserDefaults *df;
	NSRange _timeRange;
	StatusWindowType _currentType;
}

+ (StatusWindowController *)sharedController;

- (void)showUpcomingSongsWindowWithTitles:(NSArray *)titleStrings;

- (void)showVolumeWindowWithLevel:(float)level;
- (void)showRatingWindowWithRating:(float)rating;
- (void)showShuffleWindow:(BOOL)shuffle;
- (void)showRepeatWindowWithMode:(StatusWindowRepeatMode)mode;
- (void)showSongShufflabilityWindow:(BOOL)shufflable;
- (void)showSetupQueryWindow;
- (void)showReconnectQueryWindow;
- (void)showNetworkErrorQueryWindow;
- (void)showPreferencesUpdateWindow;
- (void)showDebugModeEnabledWindow;

- (void)showAlbumArtWindowWithImage:(NSImage *)image;
- (void)showAlbumArtWindowWithErrorText:(NSString *)string;
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

- (StatusWindowType)currentStatusWindowType;
- (void)updateTime:(NSString *)time;

@end
