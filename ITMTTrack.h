/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTTrack.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

#import <ITMTRemote/ITMTRemote.h>

@protocol ITMTTrack
- (BOOL)addToPlaylist:(ITMTPlaylist *)playlist;
- (BOOL)addToPlaylist:(ITMTPlaylist *)playlist atIndex:(int)index;

- (ITMTPlayer *)player;
- (NSArray *)playlists;

- (BOOL)setValue:(id)value forProperty:(ITMTTrackProperty)property; // setting nil as value removes value completely
- (id)valueOfProperty:(ITMTTrackProperty)property;
- (NSDictionary *)propertiesAndValues;
@end

@interface ITMTTrack : NSObject
@end