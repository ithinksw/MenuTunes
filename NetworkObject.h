/*
 *  MenuTunes
 *  NetworkObject
 *    Remote network object that is vended
 *
 *  Original Author : Kent Sutherland <ksutherland@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksutherland@ithinksw.com>
 *
 *  Copyright (c) 2002 - 2003 iThink Software.
 *  All Rights Reserved
 *
 *	This header defines the Objective-C protocol which all MenuTunes Remote
 *  plugins must implement.  To build a remote, create a subclass of this
 *  object, and implement each method in the @protocol below.
 *
 */

#import <Foundation/Foundation.h>

@class ITMTRemote;

@interface NetworkObject : NSObject
{
    BOOL _authenticated, _valid;
}
- (ITMTRemote *)remote;
- (NSString *)serverName;

- (BOOL)requiresPassword;
- (BOOL)sendPassword:(NSData *)password;

- (void)invalidate;
- (BOOL)isValid;
@end
