//
//  StatusWindowController.m
//  MenuTunes
//
//  Created by Matthew L. Judy on Thu Apr 17 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import "StatusWindowController.h"
#import "StatusWindow.h"

#import <ITKit/ITWindowEffect.h>
#import <ITKit/ITCutWindowEffect.h>
#import <ITKit/ITDissolveWindowEffect.h>
#import <ITKit/ITSlideHorizontallyWindowEffect.h>
#import <ITKit/ITSlideVerticallyWindowEffect.h>
#import <ITKit/ITPivotWindowEffect.h>

@implementation StatusWindowController


- (id)init
{
    if ( ( self = [super init] ) ) {
    
        float exitDelay;
        int entryTag;
        int exitTag;
        float entrySpeed;
        float exitSpeed;
        
        ITWindowEffect *entryEffect;
        ITWindowEffect *exitEffect;

        _window = [[StatusWindow sharedWindow] retain];
        df = [[NSUserDefaults standardUserDefaults] retain];

        exitDelay  = [df floatForKey:@"statusWindowVanishDelay"];
        entryTag   = [df integerForKey:@"statusWindowAppearanceEffect"];
        exitTag    = [df integerForKey:@"statusWindowVanishEffect"];
        entrySpeed = [df floatForKey:@"statusWindowAppearanceSpeed"];
        exitSpeed  = [df floatForKey:@"statusWindowVanishSpeed"];

        [_window setExitMode:ITTransientStatusWindowExitAfterDelay];
        [_window setExitDelay:(exitDelay ? exitDelay : 4.0)];

        if ( entryTag == 2101 ) {
            entryEffect = [[[ITDissolveWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( entryTag == 2102 ) {
            entryEffect = [[[ITSlideVerticallyWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( entryTag == 2103 ) {
            entryEffect = [[[ITSlideHorizontallyWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( entryTag == 2104 ) {
            entryEffect = [[[ITPivotWindowEffect alloc] initWithWindow:_window] autorelease];
        } else {
            entryEffect = [[[ITCutWindowEffect alloc] initWithWindow:_window] autorelease];
        }

        [_window setEntryEffect:entryEffect];

        if ( exitTag == 2100 ) {
            exitEffect = [[[ITCutWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( exitTag == 2102 ) {
            exitEffect = [[[ITSlideVerticallyWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( exitTag == 2103 ) {
            exitEffect = [[[ITSlideHorizontallyWindowEffect alloc] initWithWindow:_window] autorelease];
        } else if ( exitTag == 2104 ) {
            exitEffect = [[[ITPivotWindowEffect alloc] initWithWindow:_window] autorelease];
        } else {
            exitEffect = [[[ITDissolveWindowEffect alloc] initWithWindow:_window] autorelease];
        }

        [_window setExitEffect:exitEffect];

        [[_window entryEffect] setEffectTime:(entrySpeed ? entrySpeed : 0.8)];
        [[_window exitEffect]  setEffectTime:(exitSpeed  ? exitSpeed  : 0.8)];
    }
    
    return self;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (void)showSongWindowWithTitle:            (NSString *)title
                          album:            (NSString *)album
                         artist:            (NSString *)artist
                           time:            (NSString *)time  // FLOW: Should probably be NSDate or something.
                    trackNumber:                   (int)trackNumber
                     trackTotal:              	   (int)trackTotal
                         rating:                   (int)rating
                         source:(ITMTRemotePlayerSource)source
{
    [_window setImage:[NSImage imageNamed:@"Library"]];
    [_window setText:title];
    [_window appear:self];
}

- (void)showUpcomingSongsWithTitles:(NSArray *)titleStrings
{

}

- (void)showVolumeWindowWithLevel:(int)level
{

}

- (void)showRatingWindowWithLevel:(int)level
{

}

- (void)showShuffleWindowWithMode:(MTStatusWindowShuffleMode)mode
{

}

- (void)showLoopWindowWithMode:(MTStatusWindowLoopMode)mode
{

}

@end