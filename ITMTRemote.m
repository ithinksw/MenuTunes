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

- (NSArray *)playlists
{
    return nil;
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return 0;
}

- (NSString *)classOfPlaylistAtIndex:(int)index
{
    return nil;
}

- (int)currentPlaylistIndex
{
    return nil;
}

- (NSString *)songTitleAtIndex:(int)index
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

- (int)currentEQPresetIndex
{
    return 0;
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
