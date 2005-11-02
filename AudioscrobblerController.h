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

@interface AudioscrobblerController : NSObject {
	BOOL _handshakeCompleted;
	
	NSMutableData *_responseData;
}
+ (AudioscrobblerController *)sharedController;

- (void)attemptHandshake;
- (BOOL)handshakeCompleted;
@end
