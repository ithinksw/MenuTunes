/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTRemote.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

typedef enum {
    ITMTNameProperty,
    ITMTImageProperty
} ITMTGenericProperty;

typedef enum {
    ITMTRemoteNameProperty,
    ITMTRemoteImageProperty,
    ITMTRemoteAuthorProperty,
    ITMTRemoteDescriptionProperty,
    ITMTRemoteURLProperty,
    ITMTRemoteCopyrightProperty,
    ITMTRemoteActivationStringProperty,
    ITMTRemoteDeactivationStringProperty
} ITMTRemoteProperty;

typedef enum {
    ITMTTrackTitle,
    ITMTTrackArtist,
    ITMTTrackComposer,
    ITMTTrackYear,
    ITMTTrackImage,
    ITMTTrackAlbum,
    ITMTTrackNumber,
    ITMTTrackTotal,
    ITMTDiscNumber,
    ITMTDiscTotal,
    ITMTTrackComments,
    ITMTTrackGenre,
    ITMTTrackRating
} ITMTTrackProperty;

/*!
    @typedef ITMTPlayerStyle
    @constant ITMTSinglePlayerStyle Like iTunes, One player controls all available songs.
    @constant ITMTMultiplePlayerStyle Like Audion, Multiple players control multiple playlists.
    @constant ITMTSinglePlayerSinglePlaylistStyle Like *Amp, XMMS. Not recommended, but instead, developers are urged to use ITMTSinglePlayerStyle with emulated support for multiple playlists.
*/
typedef enum {
    ITMTSinglePlayerStyle,
    ITMTMultiplePlayerStyle,
    ITMTSinglePlayerSinglePlaylistStyle
} ITMTPlayerStyle;

typedef enum {
    ITMT32HzEqualizerBandLevel,
    ITMT64HzEqualizerBandLevel,
    ITMT125HzEqualizerBandLevel,
    ITMT250HzEqualizerBandLevel,
    ITMT500HzEqualizerBandLevel,
    ITMT1kHzEqualizerBandLevel,
    ITMT2kHzEqualizerBandLevel,
    ITMT4kHzEqualizerBandLevel,
    ITMT8kHzEqualizerBandLevel,
    ITMT16kHzEqualizerBandLevel,
    ITMTEqualizerPreampLevel
} ITMTEqualizerLevel;

typedef enum {
    ITMTTrackStopped = -1,
    ITMTTrackPaused,
    ITMTTrackPlaying,
    ITMTTrackForwarding,
    ITMTTrackRewinding
} ITMTTrackState;

typedef enum {
    ITMTRepeatNoneMode,
    ITMTRepeatOneMode,
    ITMTRepeatAllMode
} ITMTRepeatMode;

@class ITMTRemote, ITMTPlayer, ITMTPlaylist, ITMTTrack, ITMTEqualizer;

@protocol ITMTRemote
+ (id)remote;

- (id)valueOfProperty:(ITMTRemoteProperty)property;

- (NSDictionary *)propertiesAndValues;

- (ITMTPlayerStyle)playerStyle;

- (BOOL)activate;
- (BOOL)deactivate;

- (ITMTPlayer *)currentPlayer;
- (BOOL)selectPlayer:(ITMTPlayer *)player;
- (NSArray *)players;
@end

@interface ITMTRemote : NSObject <ITMTRemote>
@end

/*!
    @protocol ITMTPlayer
    @abstract Object representation for a controlled player.
    @discussion Object representation for a controlled player. Players can be defined as things that control playlist(s) objects, a pool of track objects, and possibly, equalizer objects.
*/
@protocol ITMTPlayer
- (BOOL)writable;

- (BOOL)show;

- (BOOL)setValue:(id)value forProperty:(ITMTGenericProperty)property;
- (id)valueOfProperty:(ITMTGenericProperty)property;
- (NSDictionary *)propertiesAndValues;

- (ITMTRemote *)remote;

- (ITMTPlaylist *)currentPlaylist;
- (BOOL)selectPlaylist:(ITMTPlaylist *)playlist;
- (ITMTTrack *)currentTrack;
- (BOOL)selectTrack:(ITMTTrack *)track;
- (ITMTEqualizer *)currentEqualizer;
- (BOOL)selectEqualizer:(ITMTEqualizer *)equalizer;

- (NSArray *)playlists;

- (NSArray *)tracks;
- (ITMTPlaylist *)libraryPlaylist;

- (NSArray *)equalizers;

- (ITMTRepeatMode)repeatMode;
- (BOOL)setRepeatMode:(ITMTRepeatMode)repeatMode;

- (BOOL)shuffleEnabled;
- (BOOL)enableShuffle:(BOOL)shuffle;
@end

@interface ITMTPlayer : NSObject <ITMTPlayer>
@end

@protocol ITMTPlaylist
- (BOOL)isEqualToPlaylist:(ITMTPlaylist *)playlist;

- (BOOL)writable;

- (BOOL)show;

- (BOOL)setValue:(id)value forProperty:(ITMTGenericProperty)property;
- (id)valueOfProperty:(ITMTGenericProperty)property;
- (NSDictionary *)propertiesAndValues;

- (ITMTPlayer *)player;

- (BOOL)addTrack:(ITMTTrack *)track;
- (BOOL)insertTrack:(ITMTTrack *)track atIndex:(int)index;

- (BOOL)removeTrack:(ITMTTrack *)item;
- (BOOL)removeTrackAtIndex:(int)index;

- (ITMTTrack *)trackAtIndex:(int)index;

- (int)indexOfTrack:(ITMTTrack *)track;
- (ITMTTrack *)trackWithProperty:(ITMTTrackProperty)property ofValue:(id)value allowPartialMatch:(BOOL)partial;
- (NSArray *)tracksWithProperty:(ITMTTrackProperty)property ofValue:(id)value allowPartialMatches:(BOOL)partial;
- (int)indexOfTrackWithProperty:(ITMTTrackProperty)property ofValue:(id)value allowPartialMatch:(BOOL)partial;
- (NSArray *)indexesOfTracksWithProperty:(ITMTTrackProperty)property ofValue:(id)value allowPartialMatches:(BOOL)partial;

- (int)trackCount;
- (NSArray *)tracks;

- (ITMTTrack *)currentTrack;
- (int)indexOfCurrentTrack;

- (BOOL)selectTrack:(ITMTTrack *)track;
- (BOOL)selectTrackAtIndex:(int)index;
@end

@interface ITMTPlaylist : NSObject <ITMTPlaylist>
@end

@protocol ITMTTrack
- (BOOL)isEqualToTrack:(ITMTTrack *)track;

- (BOOL)writable;

- (BOOL)addToPlaylist:(ITMTPlaylist *)playlist;
- (BOOL)addToPlaylist:(ITMTPlaylist *)playlist atIndex:(int)index;

- (ITMTPlayer *)player;
- (NSArray *)playlists;
- (ITMTPlaylist *)currentPlaylist;
- (BOOL)setCurrentPlaylist:(ITMTPlaylist *)playlist;

- (BOOL)setValue:(id)value forProperty:(ITMTTrackProperty)property;
- (id)valueOfProperty:(ITMTTrackProperty)property;
- (NSDictionary *)propertiesAndValues;

- (BOOL)setState:(ITMTTrackState)state;
- (ITMTTrackState)state;
@end

@interface ITMTTrack : NSObject <ITMTTrack>
@end

@protocol ITMTEqualizer
- (BOOL)writable;

- (ITMTPlayer *)player;

- (float)dBForLevel:(ITMTEqualizerLevel)level;
- (BOOL)setdB:(float)dB forLevel:(ITMTEqualizerLevel)level;
@end

@interface ITMTEqualizer : NSObject <ITMTEqualizer>
@end