/* Copyright (c) 2002 - 2003 by iThink Software. All Rights Reserved. */

#import "iTunesPlayer.h"

@implementation iTunesPlayer

static iTunesPlayer *_sharediTunesPlayer = nil;

+ (id)sharedPlayerForRemote:(iTunesRemote *)remote {
    if ( _sharediTunesPlayer ) {
        _remote = remote;
        return _sharediTunesPlayer;
    } else {
        _remote = remote;
        return _sharediTunesPlayer = [[iTunesPlayer alloc] init];
    }
}

- (BOOL)writable {
    return NO;
}

- (BOOL)show {
    return NO;
}

- (BOOL)setValue:(id)value forProperty:(ITMTGenericProperty)property {
    return NO;
}

- (id)valueOfProperty:(ITMTGenericProperty)property {
    if ( ( property == ITMTNameProperty ) {
        return @"iTunes";
    } else if ( ( property == ITMTImageProperty ) {
        return nil;
    } else {
        return nil;
    }
}

- (NSDictionary *)propertiesAndValues {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"iTunes",@"ITMTNameProperty",nil,@"ITMTImageProperty"];
}

- (ITMTRemote *)remote {
    return _remote;
}

- (ITMTPlaylist *)currentPlaylist {
    // return dynamically from an AE
    // (ie - [iTunesPlaylist playlistForIndex:<get index from an AE>]
}

- (ITMTTrack *)currentTrack {
    // return dynamically from an AE
}

- (ITMTEqualizer *)currentEqualizer {
    // return dynamically from an AE
}

- (NSArray *)playlists {
    // return dynamically from an AE
}

- (NSArray *)tracks {
    // return dynamically from an AE
}

- (ITMTPlaylist *)libraryPlaylist {
    // return dynamically from an AE
}

- (NSArray *)equalizers {
    // return dynamically from an AE
}

@end
