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

/*
 * TO DO:
 *
 * - Capability methods
 *
 */

/*! @header ITMTRemote
 *  @abstract Declares the necessary protocol and class to implement a MenuTunes Remote.
 */

#import <Cocoa/Cocoa.h>

typedef enum {
    ITMTRemotePlayerNotRunning = -1,
    ITMTRemotePlayerLaunching,
    ITMTRemotePlayerRunning
} ITMTRemotePlayerRunningStatus;

typedef enum {
    ITMTRemotePlayerStopped = -1,
    ITMTRemotePlayerPaused,
    ITMTRemotePlayerPlaying,
    ITMTRemotePlayerRewinding,
    ITMTRemotePlayerForwarding
} ITMTRemotePlayerState;

/*! @protocol ITMTRemote
 *  @abstract Declares what a MenuTunes Remote must be able to do.
 *  @discussion A MenuTunes Remote must be able to return and change state information.
 */
@protocol ITMTRemote


/*! @method remote
 *  @abstract Returns an autoreleased instance of the remote.
 *  @discussion Should be very quick and compact.
 *  EXAMPLE:
 *    + (id)remote
 *    {
 *        return [[[MyRemote alloc] init] autorelease];
 *    }
 *  @result The instance.
 */
+ (id)remote;

/*! @method pluginTitle:
 *  @abstract Returns the title of the plugin, which should be player name.
 *  @result An NSString containing the title.
 */
- (NSString *)pluginTitle;

/*! @method pluginInformation:
 *  @abstract Returns a description of the remote.
 *  @result An NSString containing the description.
 */
- (NSString *)pluginInformation;

/*! @method pluginIcon:
 *  @abstract Returns a icon for the remote.
 *  @result An NSImage containing the icon.
 */
- (NSImage *)pluginIcon;

/*! @method begin:
 *  @abstract Sent when the plugin should begin operation.
 *  @result A result code signifying success.
 */
- (BOOL)begin;

/*! @method halt:
 *  @abstract Sent when the plugin should cease operation.
 *  @result A result code signifying success.
 */
- (BOOL)halt;

- (NSString *)playerFullName;

- (NSString *)playerSimpleName;

/*! @method playerRunningStatus:
 *  @abstract Returns controlled application's running status (is or isn't running).
 *  @result BOOL of the controlled application's running status.
 */
- (ITMTRemotePlayerRunningStatus)playerRunningStatus;

/*! @method playerState:
 *  @abstract Returns controlled application's playing state.
 *  @result ITMTRemotePlayerState of the controlled application's playing state.
 */
- (ITMTRemotePlayerState)playerState;

- (NSArray *)playlists;
- (int)numberOfSongsInPlaylistAtIndex:(int)index;
- (NSString *)classOfPlaylistAtIndex:(int)index;
- (int)currentPlaylistIndex;

- (NSString *)songTitleAtIndex:(int)index;
- (int)currentSongIndex;

- (NSString *)currentSongTitle;
- (NSString *)currentSongArtist;
- (NSString *)currentSongAlbum;
- (NSString *)currentSongGenre;
- (NSString *)currentSongLength;
- (NSString *)currentSongRemaining;

- (float)currentSongRating;
- (BOOL)setCurrentSongRating:(float)rating;

- (NSArray *)eqPresets;
- (int)currentEQPresetIndex;

- (float)volume;
- (BOOL)setVolume:(float)volume;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)goToNextSong;
- (BOOL)goToPreviousSong;
- (BOOL)forward;
- (BOOL)rewind;

- (BOOL)switchToPlaylistAtIndex:(int)index;
- (BOOL)switchToSongAtIndex:(int)index;
- (BOOL)switchToEQAtIndex:(int)index;

@end


@interface ITMTRemote : NSObject <ITMTRemote>

@end
