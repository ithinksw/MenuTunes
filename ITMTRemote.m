#import "ITMTRemote.h"


@implementation ITMTRemote

+ (id)remote
{
    return nil;
}

- (NSString *)title
{
    return nil;
}

- (NSString *)description
{
    return nil;
}

- (NSImage *)icon
{
    return nil;
}

- (NSArray *)sources
{
    return nil;
}

- (NSArray *)playlistsForCurrentSource
{
    return nil;
}


- (NSArray *)songsForCurrentPlaylist
{
    return nil;
}

- (NSString *)currentSongTitle
{
    return nil;
}

- (NSString *)currentSongArtist
{
    return nil;
}

- (NSString *)currentSongAlbum
{
    return nil;
}

- (NSString *)currentSongGenre
{
    return nil;
}

- (NSString *)currentSongLength
{
    return nil;
}

- (NSString *)currentSongRemaining
{
    return nil;
}

- (NSArray *)eqPresets;
{
    return nil;
}

- (BOOL)play
{
    return NO;
}

- (BOOL)pause
{
    return NO;
}

- (BOOL)goToNextSong
{
    return NO;
}

- (BOOL)goToPreviousSong
{
    return NO;
}

- (BOOL)goToNextPlaylist
{
    return NO;
}

- (BOOL)goToPreviousPlaylist
{
    return NO;
}

- (BOOL)switchToSourceAtIndex:(int)index
{
    return NO;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    return NO;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    return NO;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    return NO;
}


@end
