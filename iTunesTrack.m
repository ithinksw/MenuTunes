//
//  iTunesTrack.m
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "iTunesTrack.h"

@implementation iTunesTrack

+ (id)trackWithDatabaseIndex:(int)index {
    return [[[iTunesTrack alloc] initWithIndex:index] autorelease];
}

- (id)initWithDatabaseIndex:(int)index {
    if ( ( self = [super init] ) ) {
        _index = index;
    }
    return self;
}

@end
