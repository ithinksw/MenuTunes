/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTPlayer.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

#import <ITMTRemote/ITMTRemote.h>

/*!
    @protocol ITMTPlayer
    @abstract Object representation for a controlled player.
    @discussion Object representation for a controlled player. Players can be defined as things that control playlist(s) objects, a pool of track objects, and possibly, equalizer objects.
*/
@protocol ITMTPlayer
/*!
    @method show
*/
- (BOOL)show;

/*!
    @method setValue:forProperty:
*/
- (BOOL)setValue:(id)value forProperty:(ITMTGenericProperty)property;
/*!
    @method valueOfProperty:
*/
- (id)valueOfProperty:(ITMTGenericProperty)property;
/*!
    @method propertiesAndValues
*/
- (NSDictionary *)propertiesAndValues;

/*!
    @method remote
*/
- (ITMTRemote *)remote;

/*!
    @method currentPlaylist
*/
- (ITMTPlaylist *)currentPlaylist;
/*!
    @method currentTrack
*/
- (ITMTTrack *)currentTrack;
/*!
    @method currentEqualizer
*/
- (ITMTEqualizer *)currentEqualizer;

/*!
    @method playlists
*/
- (NSArray *)playlists;

/*!
    @method tracks
*/
- (NSArray *)tracks;
/*!
    @method libraryPlaylist
*/
- (ITMTPlaylist *)libraryPlaylist;

/*!
    @method equalizers
*/
- (NSArray *)equalizers;
@end

/*!
    @class ITMTPlayer
*/
@interface ITMTPlayer : NSObject
@end
