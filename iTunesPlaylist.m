//
//  iTunesPlaylist.m
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "iTunesPlaylist.h"


@implementation iTunesPlaylist

+ (id)playlistWithIndex:(int)index {
    return [[[iTunesPlaylist alloc] initWithIndex:index] autorelease];
}

- (id)initWithIndex:(int)index {
    if ( ( self = [super init] ) ) {
        _index = index;
    }
    return self;
}

@end