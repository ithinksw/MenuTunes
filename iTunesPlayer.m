/* Copyright (c) 2002 - 2003 by iThink Software. All Rights Reserved. */

#import "iTunesPlayer.h"

@implementation iTunesPlayer

static iTunesPlayer *_sharediTunesPlayer = nil;

+ (id)sharedPlayer {
    if ( _sharediTunesPlayer ) {
        return _sharediTunesPlayer;
    } else {
        return _sharediTunesPlayer = [[iTunesPlayer alloc] init];
    }
}

@end
