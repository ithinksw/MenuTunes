/*
 *  MenuTunes
 *  ITMTRemote
 *    Plugin definition for audio player control via MenuTunes
 *
 *  Original Author : Matt Judy <mjudy@ithinksw.com>
 *   Responsibility : Matt Judy <mjudy@ithinksw.com>
 *
 *  Copyright (c) 2002 - 2003 iThink Software.
 *  All Rights Reserved
 *
 *	This header defines the Objective-C protocol which all MenuTunes Remote
 *  plugins must implement.  To build a remote, create a subclass of this
 *  object, and implement each method in the @protocol below.
 *
 */

/*!
 * @header ITMTRemote
 * @discussion This header defines the Objective-C protocol which all MenuTunes Remote plugins must implement.  To build a remote, create a subclass of the ITMTRemote object, and implement each method in the ITMTRemote protocol.
 */
#import <Cocoa/Cocoa.h>

/*!
 * @enum ITMTRemotePlayerRunningState
 * @abstract Possible running states for the remote's player.
 * @discussion Used in fuctions that report or take the running state of the remote's player application.
 * @constant ITMTRemotePlayerNotRunning The remote's player isn't running.
 * @constant ITMTRemotePlayerLaunching The remote's player is starting up, or is running, but not yet accepting remote commands.
 * @constant ITMTRemotePlayerRunning The remote's player is running, and as such, is accepting remote commands.
 */
typedef enum {
    ITMTRemotePlayerNotRunning = -1,
    ITMTRemotePlayerLaunching,
    ITMTRemotePlayerRunning
} ITMTRemotePlayerRunningState;

/*!
 * @enum ITMTRemotePlayerPlayingState
 * @abstract Possible playing states for the remote's player.
 * @discussion Used in functions that report or take the playing state of the remote's player application.
 * @constant ITMTRemotePlayerStopped The remote's player is stopped.
 * @constant ITMTRemotePlayerPaused The remote's player is paused.
 * @constant ITMTRemotePlayerPlaying The remote's player is playing.
 * @constant ITMTRemotePlayerRewinding The remote's player is rewinding.
 * @constant ITMTRemotePlayerForwarding The remote's player is forwarding.
 */
typedef enum {
    ITMTRemotePlayerStopped = -1,
    ITMTRemotePlayerPaused,
    ITMTRemotePlayerPlaying,
    ITMTRemotePlayerRewinding,
    ITMTRemotePlayerForwarding
} ITMTRemotePlayerPlayingState;

/*!
 * @enum ITMTRemotePlayerPlaylistClass
 * @abstract Possible playlist classes used by a remote's player
 * @discussion Used in functions that report the class of a playlist to MenuTunes. While we borrow the terms/descriptions from iTunes, these should work fine with any other player. If your player doesn't support a given type of playlist, then just return ITMTRemotePlayerPlaylist.
 * @constant ITMTRemotePlayerLibraryPlaylist For players that have one playlist that contains all of a user's music, or for players that don't have the concept of multiple playlists, this is the class for that "Master" list.
 * @constant ITMTRemotePlayerPlaylist The generic playlist. Created and maintained by the user.
 * @constant ITMTRemotePlayerSmartPlaylist A smart playlist is a playlist who's contents are dynamic, based on a set of criteria or updated by a script. These are usually not edited directly by the user, but instead maintained by the player.
 * @constant ITMTRemotePlayerRadioPlaylist This is for when playing tracks off of (online) radio stations.
 */
typedef enum {
    ITMTRemotePlayerLibraryPlaylist = -1,
    ITMTRemotePlayerPlaylist,
    ITMTRemotePlayerSmartPlaylist,
    ITMTRemotePlayerRadioPlaylist
} ITMTRemotePlayerPlaylistClass;

/*!
 * @enum ITMTRemotePlayerRepeatMode
 * @abstract Possible repeat modes for the remote's player.
 * @discussion Used in functions that report or set the remote's player's repeat mode.
 * @constant ITMTRemotePlayerRepeatOff The player plays all of the songs in a playlist through to the end, and then stops.
 * @constant ITMTRemotePlayerRepeatAll The player plays all of the songs in a playlist through to the end, and then starts over again from the beginning.
 * @constant ITMTRemotePlayerRepeatOne The player loops playing the selected song.
 */
typedef enum {
    ITMTRemotePlayerRepeatOff = -1,
    ITMTRemotePlayerRepeatAll,
    ITMTRemotePlayerRepeatOne
} ITMTRemotePlayerRepeatMode;

/*!
 * @protocol ITMTRemote
 * @discussion The Objective-C protocol which all MenuTunes remotes must implement.
 */
@protocol ITMTRemote

/*!
 * @method remote
 * @abstract Returns an autoreleased instance of the remote.
 * @discussion Should be very quick and compact.
 *
 * EXAMPLE:<br>
 * + (id)remote<br>
 * {<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return [[[MyRemote alloc] init] autorelease];<br>
 * }
 *
 * @result An instance of the remote.
 */
+ (id)remote;

/*!
 * @method remoteTitle
 * @abstract Returns the remote's title/name.
 * @discussion This title is shown while the user is selecting which remote to use. This is for informational purposes only.
 * @result An NSString containing the title/name of the remote.
 */
- (NSString *)remoteTitle;

/*!
 * @method remoteInformation
 * @abstract Returns the remote's information.
 * @discussion Information on the remote that the user will see when selecting which remote to use. The information returned here has no bearing on how the remote works, it's simply here for informing the user.
 * @result An NSString containing the information for the remote.
 */
- (NSString *)remoteInformation;

/*!
 * @method remoteIcon
 * @abstract Returns the remote's icon.
 * @discussion This icon is shown while the user is selecting which remote to use. Typically, this is the remote's player's application icon, however it can be anything you like.
 * @result An NSImage containing the icon of the remote.
 */
- (NSImage *)remoteIcon;

/*!
 * @method begin
 * @abstract Sent when the remote should begin operation.
 * @result A result code signifying success.
 */
- (BOOL)begin;

/*!
 * @method halt
 * @abstract Sent when the remote should cease operation.
 * @result A result code signifying success.
 */
- (BOOL)halt;

/*!
 * @method playerFullName
 * @abstract Returns the remote's player's application filename.
 * @discussion This string should be the name typically used by the remote's player's application bundle/file. For example, Panic's Audion audio player is known simply as "Audion", however, the application bundle is called "Audion 3" for version 3 of their application. This should return "Audion 3", not simply "Audion". See playerSimpleName.
 * @result An NSString containing the remote's player's application filename
 */
- (NSString *)playerFullName;

/*!
 * @method playerSimpleName
 * @abstract Returns the simplified name of the remote's player.
 * @discussion This is the name used in the User Interface for when referring to the remote's player. Continuing the example from the playerFullName method, this method would return simply "Audion", as that is how the player is known.
 * @result An NSString containing the simplified name of the remote's player.
 */
- (NSString *)playerSimpleName;

/*!
 * @method capabilities
 * @abstract Returns a dictionary defining the capabilities of the remote and it's player.
 * @discussion Discussion Forthcoming.
 * @result An NSDictionary defining the capabilities of the remote and it's player.
 */
- (NSDictionary *)capabilities;

/*!
 * @method showPrimaryInterface
 */
- (BOOL)showPrimaryInterface;

/*!
 * @method playerRunningState
 * @abstract Returns the running state of the remote's player.
 * @discussion While most remotes will use only ITMTRemotePlayerNotRunning or ITMTRemotePlayerRunning, we have included support for ITMTRemotePlayerLaunching (see ITMTRemotePlayerRunningState) for remotes that want the most precise control over their player's process managment.
 * @result An ITMTRemotePlayerRunningState defining the running state of the remote's player.
 */
- (ITMTRemotePlayerRunningState)playerRunningState;

/*!
 * @method playerPlayingState
 */
- (ITMTRemotePlayerPlayingState)playerPlayingState;

/*!
 * @method playlists
 */
- (NSArray *)playlists;

/*!
 * @method numberOfSongsInPlaylistAtIndex:
 */
- (int)numberOfSongsInPlaylistAtIndex:(int)index;

/*!
 * @method currentPlaylistClass
 */
- (ITMTRemotePlayerPlaylistClass)currentPlaylistClass;

/*!
 * @method currentPlaylistIndex
 */
- (int)currentPlaylistIndex;

/*!
 * @method songTitleAtIndex:
 */
- (NSString *)songTitleAtIndex:(int)index;

/*!
 * @method currentAlbumTrackCount:
 */
- (int)currentAlbumTrackCount;

/*!
 * @method currentSongTrack:
 */
- (int)currentSongTrack;

/*!
 * @method playerStateUniqueIdentifier:
 */
- (NSString *)playerStateUniqueIdentifier;

/*!
 * @method currentSongIndex
 */
- (int)currentSongIndex;

/*!
 * @method currentSongTitle
 */
- (NSString *)currentSongTitle;

/*!
 * @method currentSongArtist
 */
- (NSString *)currentSongArtist;

/*!
 * @method currentSongAlbum
 */
- (NSString *)currentSongAlbum;

/*!
 * @method currentSongGenre
 */
- (NSString *)currentSongGenre;

/*!
 * @method currentSongLength
 */
- (NSString *)currentSongLength;

/*!
 * @method currentSongRemaining
 */
- (NSString *)currentSongRemaining;

/*!
 * @method currentSongRating
 */
- (float)currentSongRating;

/*!
 * @method setCurrentSongRating:
 */
- (BOOL)setCurrentSongRating:(float)rating;

/*!
 * @method eqPresets
 */
- (NSArray *)eqPresets;

/*!
 * @method currentEQPresetIndex
 */
- (int)currentEQPresetIndex;

/*!
 * @method volume
 */
- (float)volume;

/*!
 * @method setVolume:
 */
- (BOOL)setVolume:(float)volume;

/*!
 * @method shuffleEnabled
 */
- (BOOL)shuffleEnabled;

/*!
 * @method setShuffleEnabled:
 */
- (BOOL)setShuffleEnabled:(BOOL)enabled;

/*!
 * @method repeatMode
 */
- (ITMTRemotePlayerRepeatMode)repeatMode;

/*!
 * @method setRepeatMode:
 */
- (BOOL)setRepeatMode:(ITMTRemotePlayerRepeatMode)repeatMode;

/*!
 * @method play
 */
- (BOOL)play;

/*!
 * @method pause
 */
- (BOOL)pause;

/*!
 * @method goToNextSong
 */
- (BOOL)goToNextSong;

/*!
 * @method goToPreviousSong
 */
- (BOOL)goToPreviousSong;

/*!
 * @method forward
 */
- (BOOL)forward;

/*!
 * @method rewind
 */
- (BOOL)rewind;

/*!
 * @method switchToPlaylistAtIndex:
 */
- (BOOL)switchToPlaylistAtIndex:(int)index;

/*!
 * @method switchToSongAtIndex:
 */
- (BOOL)switchToSongAtIndex:(int)index;

/*!
 * @method switchToEQAtIndex:
 */
- (BOOL)switchToEQAtIndex:(int)index;

@end

/*!
 * @class ITMTRemote
 */
@interface ITMTRemote : NSObject <ITMTRemote>

@end
