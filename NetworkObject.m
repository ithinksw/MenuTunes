//
//  NetworkObject.m
//  MenuTunes
//
//  Created by Kent Sutherland on Tue Oct 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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

@end
