/*
 *	MenuTunes
 *  AudioscrobblerController
 *    Audioscrobbler Support Class
 *
 *  Original Author : Kent Sutherland <kent.sutherland@ithinksw.com>
 *   Responsibility : Kent Sutherland <kent.sutherland@ithinksw.com>
 *
 *  Copyright (c) 2005 iThink Software.
 *  All Rights Reserved
 *
 */

#import <Cocoa/Cocoa.h>

typedef enum {
	AudioscrobblerIdleStatus = -1,
	AudioscrobblerRequestingHandshakeStatus,
	AudioscrobblerCompletedHandshakeStatus,
	AudioscrobblerSubmittingTracksStatus,
	AudioscrobblerWaitingIntervalStatus
} AudioscrobblerStatus;

@interface AudioscrobblerController : NSObject {
	BOOL _handshakeCompleted;
	AudioscrobblerStatus _currentStatus;
	NSMutableArray *_tracks;
	NSDate *_delayDate;
	
	NSString *_md5Challenge;
	NSURL *_postURL;
	NSMutableData *_responseData;
}
+ (AudioscrobblerController *)sharedController;

- (void)attemptHandshake;
- (BOOL)handshakeCompleted;
- (void)submitTrack:(NSString *)title artist:(NSString *)artist album:(NSString *)album length:(int)length;
- (void)submitTracks;
@end
