/****************************************
    ITMTRemote 1.0 (MenuTunes Remotes)
    ITMTEqualizer.h
    
    Responsibility:
        Joseph Spiros <joseph.spiros@ithinksw.com>
    
    Copyright (c) 2002 - 2003 by iThink Software.
    All Rights Reserved.
****************************************/

#import <Cocoa/Cocoa.h>

#import <ITMTRemote/ITMTRemote.h>

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

@protocol ITMTEqualizer
- (BOOL)writable;

- (ITMTPlayer *)player;

- (float)dBForLevel:(ITMTEqualizerLevel)level;
- (BOOL)setdB:(float)dB forLevel:(ITMTEqualizerLevel)level;
@end

@interface ITMTEqualizer : NSObject 
@end
