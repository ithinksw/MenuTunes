#import "ITMTRemote.h"

@implementation ITMTRemote

+ (id)remote
{
    return nil;
}

- (NSString *)remoteTitle
{
    return nil;
}

- (NSString *)remoteInformation
{
    return nil;
}

- (NSImage *)remoteIcon
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

- (NSString *)playerFullName
{
    return nil;
}

- (NSString *)playerSimpleName
{
    return nil;
}

- (NSDictionary *)capabilities
{
    return nil;
}

- (ITMTRemotePlayerRunningState)playerRunningState
{
    return nil;
}

- (ITMTRemotePlayerPlayingState)playerPlayingState
{
    return nil;
}

- (NSArray *)playlists
{
    return nil;
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return nil;
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

- (float)currentSongRating
{
    return nil;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    return NO;
}

- (BOOL)equalizerEnabled
{
    return NO;
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
    return NO;
}

- (NSArray *)eqPresets
{
    return nil;
}

- (int)currentEQPresetIndex
{
    return nil;
}

- (float)volume
{
    return nil;
}

- (BOOL)setVolume:(float)volume
{
    return NO;
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

- (BOOL)forward
{
    return NO;
}

- (BOOL)rewind
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
