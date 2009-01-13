/*
 *	MenuTunes
 *	NetworkObject.h
 *
 *	Remote network object that is vended.
 *
 *	Copyright (c) 2002-2003 iThink Software
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
- (void)makeValid;
- (BOOL)isValid;
@end
