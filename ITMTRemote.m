#import "ITMTRemote.h"

@implementation ITMTRemote

+ (void)initialize
{
[self setVersion:2];
}

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

- (BOOL)showExternalWindow
{
    return NO;
}

- (NSString*)externalWindowName
{
    return nil;
}

- (BOOL)setShuffle:(BOOL)toggle
{
    return NO;
}

- (BOOL)supportsVolume
{
    return NO;
}

- (BOOL)supportsShuffle
{
    return NO;
}

- (BOOL)shuffle
{
    return NO;
}

- (BOOL)setTrackProperty:(ITMTRemoteTrackProperty)property toValue:(id)value atIndex:(int)index
{
    return NO;
}

- (id)trackProperty:(ITMTRemoteTrackProperty)property atIndex:(int)index
{
    return nil;
}

- (BOOL)supportsTrackProperty:(ITMTRemoteTrackProperty)property
{
    return NO;
}

- (BOOL)supportsRepeatMode:(ITMTRemoteRepeatMode)repeatMode
{
    return NO;
}

- (BOOL)sendControlAction:(ITMTRemoteControlAction)action
{
    return NO;
}

- (BOOL)supportsControlAction:(ITMTRemoteControlAction)action
{
    return NO;
}

- (int)indexForTrack:(int)identifier inPlaylist:(int)playlistIndex
{
    return 0;
}

- (NSImage*)icon
{
    return nil;
}

- (NSArray*)playlistNames
{
    return nil;
}

- (NSString*)informationString:(ITMTRemoteInformationString)string;
{
    return nil;
}

- (BOOL)switchToPlaylist:(int)playlistIndex
{
    return 0;
}

- (BOOL)switchToTrackAtIndex:(int)index
{
    return 0;
}

- (int)identifierForTrackAtIndex:(int)index inPlaylist:(int)playlistIndex
{
    return 0;
}

- (BOOL)supportsCustomEqualizer
{
    return NO;
}

- (BOOL)showEqualizerWindow
{
    return NO;
}

- (BOOL)supportsEqualizerPresets
{
    return NO;
}

- (BOOL)supportsExternalWindow
{
    return NO;
}

- (NSArray*)equalizerPresetNames
{
    return nil;
}

- (BOOL)switchToEqualizerPreset:(int)index
{
    return NO;
}

- (ITMTRemoteControlState)controlState
{
    return nil;
}

- (ITMTRemotePlaylistMode)playlistMode
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

- (int)currentPlaylistIndex
{
    return nil;
}

- (NSString *)songTitleAtIndex:(int)index
{
    return nil;
}

- (int)currentAlbumTrackCount
{
    return nil;
}

- (int)currentSongTrack
{
    return nil;
}

- (NSString *)currentSongUniqueIdentifier
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

/* - (BOOL)equalizerEnabled
{
    return NO;
}

- (BOOL)setEqualizerEnabled:(BOOL)enabled
{
    return NO;
} */

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

- (BOOL)shuffleEnabled
{
    return NO;
}

- (BOOL)setShuffleEnabled:(BOOL)enabled
{
    return NO;
}

- (ITMTRemoteRepeatMode)repeatMode
{
    return ITMTRemoteRepeatNone;
}

- (BOOL)setRepeatMode:(ITMTRemoteRepeatMode)repeatMode
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
