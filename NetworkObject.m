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

- (ITMTRemote *)remote
{
    return [[MainController sharedController] currentRemote];
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
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enableSharingPassword"];
}

- (BOOL)sendPassword:(NSData *)password
{
    if ([password isEqualToData:[[NSUserDefaults standardUserDefaults] dataForKey:@"sharedPlayerPassword"]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
