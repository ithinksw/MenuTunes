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

#import "NetworkObject.h"
#import "MainController.h"
#import <ITMTRemote/ITMTRemote.h>

@implementation NetworkObject

- (id)init
{
    if ( (self = [super init]) ) {
        _valid = YES;
        if (![self requiresPassword]) {
            _authenticated = YES;
        } else {
            _authenticated = NO;
        }
    }
    return self;
}

- (ITMTRemote *)remote
{
    if (_authenticated && _valid) {
        return [[MainController sharedController] currentRemote];
    } else {
        return nil;
    }
}

- (NSString *)serverName
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:@"sharedPlayerName"];
    if (!name)
        name = @"MenuTunes Shared Player";
    return name;
}

- (BOOL)requiresPassword
{
    return ([[[NSUserDefaults standardUserDefaults] dataForKey:@"sharedPlayerPassword"] length] > 0);
}

- (BOOL)sendPassword:(NSData *)password
{
    if ([password isEqualToData:[[NSUserDefaults standardUserDefaults] dataForKey:@"sharedPlayerPassword"]]) {
        _authenticated = YES;
        return YES;
    } else {
        _authenticated = NO;
        return NO;
    }
}

- (void)invalidate
{
    _valid = NO;
}

- (void)makeValid
{
    _valid = YES;
}

- (BOOL)isValid
{
    return _valid;
}

@end
