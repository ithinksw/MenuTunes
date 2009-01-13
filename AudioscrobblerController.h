/*
 *	MenuTunes
 *	AudioscrobblerController.h
 *
 *	Audioscrobbler Support Class.
 *
 *	Copyright (c) 2005 iThink Software
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
	int _handshakeAttempts;
	AudioscrobblerStatus _currentStatus;
	NSMutableArray *_tracks, *_submitTracks;
	NSDate *_delayDate;
	
	NSString *_md5Challenge, *_lastStatus;
	NSURL *_postURL;
	NSMutableData *_responseData;
}
+ (AudioscrobblerController *)sharedController;

- (NSString *)lastStatus;
- (void)attemptHandshake;
- (void)attemptHandshake:(BOOL)force;
- (BOOL)handshakeCompleted;
- (void)submitTrack:(NSString *)title artist:(NSString *)artist album:(NSString *)album length:(int)length;
- (void)submitTracks;
@end
