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

/*! @protocol ITMTRemote
 *  @abstract Declares what a MenuTunes Remote must be able to do.
 *  @discussion A MenuTunes Remote must be able to return and change state information.
 */

@protocol ITMTRemote
/*! @method remote:
 *  @abstract Return an autoreleased instance of the remote.
 *  @discussion Should be very quick and compact.
 * EXAMPLE:
 *   + (id)remote
 *   {
 *       return [[[MyRemote alloc] init] autorelease];
 *   }
 * @result The instance.
 */
+ (id)remote;

- (NSString *)title;
// Return the title of the remote.

- (NSString *)description;
// Return a short description of the remote.

- (NSImage *)icon;
// Return a 16x16 icon representation for the remote.

- (BOOL)begin;
// Sent to the plugin when it should begin operation.

- (BOOL)halt;
// Sent to the plugin when it should cease operation.

- (NSArray *)sources;
- (int)currentSourceIndex;

- (NSArray *)playlistsForCurrentSource;
- (int)currentPlaylistIndex;

- (NSString *)songTitleAtIndex;
- (int)currentSongIndex;

- (NSString *)currentSongTitle;
- (NSString *)currentSongArtist;
- (NSString *)currentSongAlbum;
- (NSString *)currentSongGenre;
- (NSString *)currentSongLength;
- (NSString *)currentSongRemaining;

- (NSArray *)eqPresets;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)goToNextSong;
- (BOOL)goToPreviousSong;
- (BOOL)goToNextPlaylist;
- (BOOL)goToPreviousPlaylist;

- (BOOL)switchToSourceAtIndex:(int)index;
- (BOOL)switchToPlaylistAtIndex:(int)index;
- (BOOL)switchToSongAtIndex:(int)index;
- (BOOL)switchToEQAtIndex:(int)index;

@end


@interface ITMTRemote : NSObject <ITMTRemote>

@end
