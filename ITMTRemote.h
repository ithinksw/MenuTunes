/*
    iThink Software
    MenuTunes SDK BETA (SUBJECT TO CHANGE)
    ITMTRemote.h
    
    Copyright 2003 by iThink Software, All Rights Reserved.
    This is under Non-Disclosure
*/

/* 
    Remotes need to include an Info.plist in their
    bundle/wrapper. It needs to have the following keys
    (with string values):
        
        ITMTRemoteName
        ITMTRemoteVersion
        ITMTRemotePublisher
        ITMTRemoteCopyright
        ITMTRemoteDescription
        ITMTRemoteIconFile
        
    It also needs to have an icon file who's filename (Relative)
    is indicated in the ITMTRemoteIconFile value.
*/


#import <Cocoa/Cocoa.h>

typedef enum {
    ITMTRemoteName,
    ITMTRemoteVersion,
    ITMTRemotePublisher,
    ITMTRemoteCopyright,
    ITMTRemoteDescription
} ITMTRemoteInformationString;

typedef enum {
    ITMTRemotePlayerStopped = -1,
    ITMTRemotePlayerPaused,
    ITMTRemotePlayerPlaying,
    ITMTRemotePlayerRewinding,
    ITMTRemotePlayerForwarding
} ITMTRemoteControlState;

typedef enum {
    ITMTRemoteStop = -1,
    ITMTRemotePause,
    ITMTRemotePlay,
    ITMTRemoteRewind,
    ITMTRemoteFastForward,
    ITMTRemotePreviousTrack,
    ITMTRemoteNextTrack
} ITMTRemoteControlAction;

typedef enum {
    ITMTRemoteSinglePlaylist,
    ITMTRemoteLibraryAndPlaylists,
    ITMTRemoteSeperatePlaylists
} ITMTRemotePlaylistMode;

typedef enum {
    ITMTRemoteTrackName,
    ITMTRemoteTrackArtist,
    ITMTRemoteTrackAlbum,
    ITMTRemoteTrackComposer,
    ITMTRemoteTrackNumber,
    ITMTRemoteTrackTotal,
    ITMTRemoteTrackComment,
    ITMTRemoteTrackGenre,
    ITMTRemoteTrackYear,
    ITMTRemoteTrackRating,
    ITMTRemoteTrackArt
} ITMTRemoteTrackProperty;

typedef enum {
    ITMTRemoteRepeatNone,
    ITMTRemoteRepeatAll,
    ITMTRemoteRepeatOne
} ITMTRemoteRepeatMode;

/*enum {
    ITMTRemoteCustomPreset = -1;
}*/

@protocol ITMTRemote
+ (id)remote;
- (NSString*)informationString:(ITMTRemoteInformationString)string;
- (NSImage*)icon;

- (BOOL)begin;
- (BOOL)halt;

- (BOOL)supportsControlAction:(ITMTRemoteControlAction)action;
- (BOOL)sendControlAction:(ITMTRemoteControlAction)action;
- (ITMTRemoteControlState)controlState;

- (ITMTRemotePlaylistMode)playlistMode;
- (NSArray*)playlistNames;
- (BOOL)switchToPlaylist:(int)playlistIndex;
- (BOOL)switchToTrackAtIndex:(int)index;
- (int)indexForTrack:(int)identifier inPlaylist:(int)playlistIndex;
- (int)identifierForTrackAtIndex:(int)index inPlaylist:(int)playlistIndex;

- (BOOL)supportsTrackProperty:(ITMTRemoteTrackProperty)property;
- (id)trackProperty:(ITMTRemoteTrackProperty)property atIndex:(int)index;
- (BOOL)setTrackProperty:(ITMTRemoteTrackProperty)property toValue:(id)value atIndex:(int)index;
/* currently only used to set Ratings... someday, we might provide a full frontend? well, it is possible that other apps could use MT remotes, as such, they might want to set other values. For Rating, send in an NSNumber from a float 0.0 - 1.0. For Art, send in an NSImage... this is also what you'll recieve when using the accessor */


- (BOOL)supportsShuffle;
- (BOOL)setShuffle:(BOOL)toggle;
- (BOOL)shuffle;

- (BOOL)supportsRepeatMode:(ITMTRemoteRepeatMode)repeatMode;
- (BOOL)setRepeatMode:(ITMTRemoteRepeatMode)repeatMode;
- (ITMTRemoteRepeatMode)repeatMode;

- (BOOL)supportsVolume;
- (BOOL)setVolume:(float)volume;
- (float)volume;

- (BOOL)supportsCustomEqualizer;
- (BOOL)showEqualizerWindow;

- (BOOL)supportsEqualizerPresets;
- (NSArray*)equalizerPresetNames;
- (BOOL)switchToEqualizerPreset:(int)index; // ITMTRemoteCustomPreset = Custom

- (BOOL)supportsExternalWindow;
- (NSString*)externalWindowName;
- (BOOL)showExternalWindow;

@end

@interface ITMTRemote : NSObject <ITMTRemote>

@end