#import "iTunesRemote.h"


@implementation iTunesRemote

+ (id)remote
{
    return [[[iTunesRemote alloc] init] autorelease];
}

- (NSString *)title
{
    return nil;
}

- (NSString *)information;
{
    return nil;
}

- (NSImage *)icon
{
    return nil;
}

- (BOOL)begin
{
    return NO;
}

- (BOOL)halt
{
    return NO;
}

- (NSArray *)sources
{
    return nil;
}

- (int)currentSourceIndex
{
    return nil;
}

- (NSArray *)playlistsForCurrentSource
{
    return nil;
}

- (int)currentPlaylistIndex
{
    return nil;
}

- (NSString *)songTitleAtIndex
{
    return nil;
}

- (int)currentSongIndex
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
