//
//  MenuController.h
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ITMTRemote.h"

// Internal: To be used with NSMenuItems as their tag, for use with the NSMenuValidation stuff.
// Also will be used in supplying the controller with the layout to use for the MenuItems, unless
// we have the controller read the prefs itself.
typedef enum {
    MTMenuSeperator = -1,
    MTMenuTrackInfoHeader,
    MTMenuTrackInfoTitle,
    MTMenuTrackInfoAlbum,
    MTMenuTrackInfoArtist,
    MTMenuTrackInfoTrackTime,
    MTMenuTrackInfoTrackNumber,
    MTMenuTrackInfoRating,
    MTMenuRatingMenu,
    MTMenuPlaylistMenu,
    MTMenuEqualizerMenu,
    MTMenuUpcomingSongsMenu,
    // MTMenuBrowseMenu,
    // MTMenuVolumeMenu,
    // MTMenuSourceMenu,
    MTMenuPlayPauseItem,
    MTMenuFastForwardItem,
    MTMenuRewindItem,
    MTMenuPreviousTrackItem,
    MTMenuNextTrackItem,
    MTMenuShowPlayerItem,
    MTMenuPreferencesItem,
    MTMenuQuitItem
} MTMenuItemTag;

@interface MenuController : NSObject
{
    NSMutableArray *_menuLayout;
    NSMenu *_currentMenu;
    
    ITMTRemote *currentRemote;
    int _currentPlaylist, _currentTrack;
    BOOL _playingRadio;
}

- (NSMenu *)menu;
- (NSMenu *)menuForNoPlayer;

// - (NSArray *)menuLayout;
// - (void)setMenuLayout:(NSArray *)newLayoutArray;

@end
