/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTPlaylist.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

#import <ITMTRemote/ITMTRemote.h>

@protocol ITMTPlaylist
- (BOOL)show; // graphical

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
- (NSArray *)trackArray;
@end

@interface ITMTPlaylist : NSObject
@end
