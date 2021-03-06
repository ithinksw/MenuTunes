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
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool: NO], @"Remote", // Set this to YES for a valid remote, otherwise the remote will be unusable.
                [NSNumber numberWithBool: NO], @"Basic Track Control",
                [NSNumber numberWithBool: NO], @"Track Information",
                [NSNumber numberWithBool: NO], @"Track Navigation",
                [NSNumber numberWithBool: NO], @"Upcoming Songs",
                [NSNumber numberWithBool: NO], @"Playlists",
                [NSNumber numberWithBool: NO], @"Volume",
                [NSNumber numberWithBool: NO], @"Shuffle",
                [NSNumber numberWithBool: NO], @"Repeat Modes",
                [NSNumber numberWithBool: NO], @"Equalizer",
                [NSNumber numberWithBool: NO], @"Track Rating",
                nil];
}

- (BOOL)showPrimaryInterface
{
    return NO;
}

- (ITMTRemotePlayerRunningState)playerRunningState
{
    return ITMTRemotePlayerNotRunning;
}

- (ITMTRemotePlayerPlayingState)playerPlayingState
{
    return ITMTRemotePlayerStopped;
}

- (NSArray *)playlists
{
    return nil;
}

- (NSArray *)artists
{
    return nil;
}

- (NSArray *)albums
{
    return nil;
}

- (int)numberOfSources
{
    return -1;
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return -1;
}

- (ITMTRemotePlayerSource)currentSource
{
    return ITMTRemoteLibrarySource;
}

- (int)currentSourceIndex
{
    return -1;
}

- (ITMTRemotePlayerPlaylistClass)currentPlaylistClass
{
    return ITMTRemotePlayerLibraryPlaylist;
}

- (int)currentPlaylistIndex
{
    return -1;
}

- (NSString *)songTitleAtIndex:(int)index
{
    return nil;
}

- (BOOL)songEnabledAtIndex:(int)index
{
	return NO;
}

- (int)currentAlbumTrackCount
{
    return -1;
}

- (int)currentSongTrack
{
    return -1;
}

- (NSString *)playerStateUniqueIdentifier
{
    return nil;
}

- (int)currentSongIndex
{
    return -1;
}

- (NSString *)currentSongTitle
{
    return nil;
}

- (NSString *)currentSongArtist
{
    return nil;
}

- (NSString *)currentSongComposer
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

- (int)currentSongPlayed
{
	return -1;
}

- (int)currentSongDuration
{
	return -1;
}

- (NSString *)currentSongRemaining
{
    return nil;
}

- (NSString *)currentSongElapsed
{
    return nil;
}

- (NSImage *)currentSongAlbumArt
{
    return nil;
}

- (int)currentSongPlayCount
{
    return 0;
}

- (float)currentSongRating
{
    return 0;
}

- (BOOL)setCurrentSongRating:(float)rating
{
    return NO;
}

- (BOOL)currentSongShufflable
{
	return NO;
}

- (BOOL)setCurrentSongShufflable:(BOOL)shufflable
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
    return 0;
}

- (float)volume
{
    return 0;
}

- (BOOL)setVolume:(float)volume
{
    return NO;
}

- (BOOL)shuffleEnabled
{
    return NO;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    return NO;
}

- (ITMTRemotePlayerRepeatMode)repeatMode
{
    return ITMTRemotePlayerRepeatOff;
}

- (BOOL)setRepeatMode:(ITMTRemotePlayerRepeatMode)repeatMode
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

- (BOOL)switchToPlaylistAtIndex:(int)index ofSourceAtIndex:(int)index2
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

- (BOOL)makePlaylistWithTerm:(NSString *)term ofType:(int)type
{
    return NO;
}

@end
