/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTRemote.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

#import <ITMTRemote/ITMTPlayer.h>
#import <ITMTRemote/ITMTPlaylist.h>
#import <ITMTRemote/ITMTTrack.h>
#import <ITMTRemote/ITMTEqualizer.h>

/*!
    @typedef ITMTGenericProperty
    @constant ITMTNameProperty The object's human readable name.
    @constant ITMTImageProperty An image that can be associated with the object.
*/
typedef enum {
    ITMTNameProperty,
    ITMTImageProperty
} ITMTGenericProperty;
/*!
    @typedef ITMTRemoteProperty
    @constant ITMTRemoteNameProperty
    @constant ITMTRemoteImageProperty
    @constant ITMTRemoteAuthorProperty
    @constant ITMTRemoteDescriptionProperty
    @constant ITMTRemoteURLProperty
    @constant ITMTRemoteCopyrightProperty
*/
typedef enum {
    ITMTRemoteNameProperty,
    ITMTRemoteImageProperty,
    ITMTRemoteAuthorProperty,
    ITMTRemoteDescriptionProperty,
    ITMTRemoteURLProperty,
    ITMTRemoteCopyrightProperty,
    ITMTRemoteActivationStringProperty,
    ITMTRemoteDeactivationStringProperty
} ITMTRemoteProperty
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

/*!
    @protocol ITMTRemote
    @abstract The ITMTRemote protocol is the protocol that all MenuTunes remotes' primary class must implement.
*/
@protocol ITMTRemote
/*!
    @method remote
    @result Returns an autoreleased instance of the remote.
*/
+ (id)remote;

/*!
    @method valueOfProperty:
*/
- (id)valueOfProperty:(ITMTRemoteProperty)property;

/*!
    @method propertiesAndValues
*/
- (NSDictionary *)propertiesAndValues;

/*!
    @method playerStyle
    @result An ITMTPlayerStyle defining how the remote works with players and playlists.
*/
- (ITMTPlayerStyle)playerStyle;

/*!
    @method activate
    @result A BOOL indicating success or failure.
*/
- (BOOL)activate;
/*!
    @method deactivate
    @result A BOOL indicating success or failure.
*/
- (BOOL)deactivate;

/*!
    @method currentPlayer
    @result An ITMTPlayer object representing the currently active player that the remote is controlling.
*/
- (ITMTPlayer *)currentPlayer
/*!
    @method players
    @result An NSArray filled with ITMTPlayer objects.
*/
- (NSArray *)players;
@end

/*!
    @class ITMTRemote
*/
@interface ITMTRemote : NSObject <ITMTRemote>
@end
