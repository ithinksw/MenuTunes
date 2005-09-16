//
//  MenuController.m
//  MenuTunes
//
//  Created by Joseph Spiros on Wed Apr 30 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MenuController.h"
#import "MainController.h"
#import "NetworkController.h"
#import "ITMTRemote.h"
#import "PlaylistNode.h"
#import <ITFoundation/ITDebug.h>
#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITHotKey.h>
#import <ITKit/ITKeyCombo.h>
#import <ITKit/ITCategory-NSMenu.h>
#import <ITKit/ITAboutWindowController.h>

@interface MenuController (SubmenuMethods)
- (NSMenu *)ratingMenu;
- (NSMenu *)upcomingSongsMenu;
- (NSMenu *)playlistsMenu;
- (NSMenu *)eqMenu;
- (NSMenu *)artistsMenu;
- (NSMenu *)albumsMenu;
- (void)playlistsMenuAux:(NSMenu *)menu node:(PlaylistNode *)node tagPrefix:(int)p;
- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(id <NSMenuItem>)item;
- (BOOL)iPodWithNameAutomaticallyUpdates:(NSString *)name;
@end

@implementation MenuController

- (id)init
{
    if ( (self = [super init]) ) {
        _menuLayout = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSMenu *)menu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *menuArray = [defaults arrayForKey:@"menu"];
    NSEnumerator *enumerator = [menuArray objectEnumerator];
    NSString *nextObject;
    id <NSMenuItem> tempItem;
    NSEnumerator *itemEnum;
    ITHotKey *hotKey;
    NSArray *hotKeys = [[ITHotKeyCenter sharedCenter] allHotKeys];
    ITMTRemote *mtr = [[MainController sharedController] currentRemote];
    int currentSongRating = 0;
    
    //Get the information
    NS_DURING
        _currentPlaylist = [mtr currentPlaylistIndex];
        _playingRadio = ([mtr currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
        currentSongRating = ( [mtr currentSongRating] != -1 );
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
	
    ITDebugLog(@"Reset menu if required.");
    
    //Kill the old submenu items
    if ( (tempItem = [_currentMenu itemWithTag:1]) ) {
        ITDebugLog(@"Removing \"Song Rating\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:2]) ) {
        ITDebugLog(@"Removing \"Upcoming Songs\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:3]) ) {
        ITDebugLog(@"Removing \"Playlists\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:4]) ) {
        ITDebugLog(@"Removing \"EQ Presets\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:5]) ) {
        ITDebugLog(@"Removing \"Artists\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    if ( (tempItem = [_currentMenu itemWithTag:6]) ) {
        ITDebugLog(@"Removing \"Albums\" submenu.");
        [tempItem setSubmenu:nil];
    }
    
    ITDebugLog(@"Begin building menu.");
    
    //create our menu
    while ( (nextObject = [enumerator nextObject]) ) {
        //Main menu items
        if ([nextObject isEqualToString:@"playPause"]) {
            ITDebugLog(@"Add \"Play\"/\"Pause\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"play", @"Play")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPlayPauseItem];
            [tempItem setTarget:self];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"PlayPause"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            ITDebugLog(@"Set \"Play\"/\"Pause\" menu item's title to correct state.");
            NS_DURING
                switch ([mtr playerPlayingState]) {
                    case ITMTRemotePlayerPlaying:
                        [tempItem setTitle:NSLocalizedString(@"pause", @"Pause")];
                    break;
                    case ITMTRemotePlayerRewinding:
                    case ITMTRemotePlayerForwarding:
                        [tempItem setTitle:NSLocalizedString(@"resume", @"Resume")];
                    break;
                    default:
                    break;
                }
            NS_HANDLER
                [[MainController sharedController] networkError:localException];
            NS_ENDHANDLER
        } else if ([nextObject isEqualToString:@"nextTrack"]) {
            ITDebugLog(@"Add \"Next Track\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"nextTrack", @"Next Track")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"NextTrack"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuNextTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"prevTrack"]) {
            ITDebugLog(@"Add \"Previous Track\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"prevTrack", @"Previous Track")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"PrevTrack"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuPreviousTrackItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"fastForward"]) {
            ITDebugLog(@"Add \"Fast Forward\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"fastForward", @"Fast Forward")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuFastForwardItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"rewind"]) {
            ITDebugLog(@"Add \"Rewind\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"rewind", @"Rewind")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            if (_currentPlaylist) {
                [tempItem setTag:MTMenuRewindItem];
                [tempItem setTarget:self];
            }
        } else if ([nextObject isEqualToString:@"showPlayer"]) {
            ITDebugLog(@"Add \"Show Player\" menu item.");
            NS_DURING
                tempItem = [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@",
                                NSLocalizedString(@"show", @"Show"),
                                    [mtr playerSimpleName]]
                                action:@selector(performMainMenuAction:)
                                keyEquivalent:@""];
            NS_HANDLER
                [[MainController sharedController] networkError:localException];
            NS_ENDHANDLER
            
            itemEnum = [hotKeys objectEnumerator];
            while ( (hotKey = [itemEnum nextObject]) ) {
                if ([[hotKey name] isEqualToString:@"ShowPlayer"]) {
                    ITKeyCombo *combo = [hotKey keyCombo];
                    [self setKeyEquivalentForCode:[combo keyCode]
                          andModifiers:[combo modifiers]
                          onItem:tempItem];
                }
            }
            
            [tempItem setTarget:self];
            [tempItem setTag:MTMenuShowPlayerItem];
        } else if ([nextObject isEqualToString:@"preferences"]) {
            ITDebugLog(@"Add \"Preferences...\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuPreferencesItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"about"]) {
			ITDebugLog(@"Add \"About MenuTunes...\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"about", @"About MenuTunes...")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuAboutItem];
            [tempItem setTarget:self];
		} else if ([nextObject isEqualToString:@"quit"]) {
            if ([[MainController sharedController] blingBling] == NO) {
                ITDebugLog(@"Add \"Register MenuTunes...\" menu item.");
                tempItem = [menu addItemWithTitle:NSLocalizedString(@"register", @"Register MenuTunes...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
                [tempItem setTag:MTMenuRegisterItem];
                [tempItem setTarget:self];
            }
            ITDebugLog(@"Add \"Quit\" menu item.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit")
                    action:@selector(performMainMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:MTMenuQuitItem];
            [tempItem setTarget:self];
        } else if ([nextObject isEqualToString:@"trackInfo"]) {
            ITDebugLog(@"Check to see if a Track is playing...");
            //Handle playing radio too
            if (_currentTrack != -1 && _currentPlaylist > 0) {
                NSString *title = nil;
                NS_DURING
                    title = [mtr currentSongTitle];
                NS_HANDLER
                    [[MainController sharedController] networkError:localException];
                NS_ENDHANDLER
                ITDebugLog(@"A Track is Playing, Add \"Track Info\" menu items.");
                ITDebugLog(@"Add \"Now Playing\" menu item.");
                [menu addItemWithTitle:NSLocalizedString(@"nowPlaying", @"Now Playing") action:NULL keyEquivalent:@""];
                
                if ([title length] > 0) {
                    ITDebugLog(@"Add Track Title (\"%@\") menu item.", title);
                    [menu indentItem:
                        [menu addItemWithTitle:title action:nil keyEquivalent:@""]];
                }
                
                if (!_playingRadio) {
                    if ([defaults boolForKey:@"showAlbum"]) {
                        NSString *curAlbum = nil;
                        NS_DURING
                            curAlbum = [mtr currentSongAlbum];
                        NS_HANDLER
                            [[MainController sharedController] networkError:localException];
                        NS_ENDHANDLER
                        ITDebugLog(@"Add Track Album (\"%@\") menu item.", curAlbum);
                        if ( curAlbum ) {
                            [menu indentItem:
                                [menu addItemWithTitle:curAlbum action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showArtist"]) {
                        NSString *curArtist = nil;
                        NS_DURING
                            curArtist = [mtr currentSongArtist];
                        NS_HANDLER
                            [[MainController sharedController] networkError:localException];
                        NS_ENDHANDLER
                        ITDebugLog(@"Add Track Artist (\"%@\") menu item.", curArtist);
                        if ( curArtist ) {
                            [menu indentItem:
                                [menu addItemWithTitle:curArtist action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showComposer"]) {
                        NSString *curComposer = nil;
                        NS_DURING
                            curComposer = [mtr currentSongComposer];
                        NS_HANDLER
                            [[MainController sharedController] networkError:localException];
                        NS_ENDHANDLER
                        ITDebugLog(@"Add Track Composer (\"%@\") menu item.", curComposer);
                        if ( curComposer ) {
                            [menu indentItem:
                                [menu addItemWithTitle:curComposer action:nil keyEquivalent:@""]];
                        }
                    }
                    
                    if ([defaults boolForKey:@"showTrackNumber"]) {
                        int track = 0;
                        NS_DURING
                            track = [mtr currentSongTrack];
                        NS_HANDLER
                            [[MainController sharedController] networkError:localException];
                        NS_ENDHANDLER
                        ITDebugLog(@"Add Track Number (\"Track %i\") menu item.", track);
                        if ( track > 0 ) {
                            [menu indentItem:
                                [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %i", NSLocalizedString(@"track", @"Track"), track] action:nil keyEquivalent:@""]];
                        }
                    }
                }
                
                NS_DURING
                    if ([defaults boolForKey:@"showTime"] && ( ([mtr currentSongElapsed] != nil) || ([mtr currentSongLength] != nil) )) {
                        ITDebugLog(@"Add Track Elapsed (\"%@/%@\") menu item.", [mtr currentSongElapsed], [mtr currentSongLength]);
                        [menu indentItem:[menu addItemWithTitle:[NSString stringWithFormat:@"%@/%@", [mtr currentSongElapsed], [mtr currentSongLength]] action:nil keyEquivalent:@""]];
                    }
                NS_HANDLER
                    [[MainController sharedController] networkError:localException];
                NS_ENDHANDLER
                
                if (!_playingRadio) {
                    NS_DURING
                        if ([defaults boolForKey:@"showPlayCount"] && [mtr currentSource] == ITMTRemoteLibrarySource) {
                            [menu indentItem:[menu addItemWithTitle:[NSString stringWithFormat:@"Play Count: %i", [mtr currentSongPlayCount]] action:nil keyEquivalent:@""]];
                        }
                        if ([defaults boolForKey:@"showTrackRating"] && ( [mtr currentSongRating] != -1.0 )) {
                            NSString *string = nil;
                            switch ((int)([mtr currentSongRating] * 5)) {
                                case 0:
                                    string = [NSString stringWithUTF8String:"☆☆☆☆☆"];
                                break;
                                case 1:
                                    string = [NSString stringWithUTF8String:"★☆☆☆☆"];
                                break;
                                case 2:
                                    string = [NSString stringWithUTF8String:"★★☆☆☆"];
                                break;
                                case 3:
                                    string = [NSString stringWithUTF8String:"★★★☆☆"];
                                break;
                                case 4:
                                    string = [NSString stringWithUTF8String:"★★★★☆"];
                                break;
                                case 5:
                                    string = [NSString stringWithUTF8String:"★★★★★"];
                                break;
                            }
                            ITDebugLog(@"Add Track Rating (\"%@\") menu item.", string);
                            [menu indentItem:[menu addItemWithTitle:string action:nil keyEquivalent:@""]];
                        }
                    NS_HANDLER
                        [[MainController sharedController] networkError:localException];
                    NS_ENDHANDLER
                    
                    /*if ([tempItem respondsToSelector:@selector(setAttributedTitle:)] && [defaults boolForKey:@"showAlbumArtwork"] && ![[NetworkController sharedController] isConnectedToServer]) {
                        NSImage *image = [mtr currentSongAlbumArt];
                        if (image) {
                            NSSize oldSize, newSize;
                            oldSize = [image size];
                            if (oldSize.width > oldSize.height) newSize = NSMakeSize(110,oldSize.height * (110.0f / oldSize.width));
                            else newSize = NSMakeSize(oldSize.width * (110.0f / oldSize.height),110);
                            image = [[[[NSImage alloc] initWithData:[image TIFFRepresentation]] autorelease] imageScaledSmoothlyToSize:newSize];
                            
                            tempItem = [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];
                            NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
                            [[attachment attachmentCell] setImage:image];
                            NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
                            [tempItem setAttributedTitle:attrString];
                        }
                    }*/
                }
            } else {
                ITDebugLog(@"No Track is Playing, Add \"No Song\" menu item.");
                [menu addItemWithTitle:NSLocalizedString(@"noSong", @"No Song") action:NULL keyEquivalent:@""];
            }
        } else if ([nextObject isEqualToString:@"separator"]) {
            ITDebugLog(@"Add a separator menu item.");
            [menu addItem:[NSMenuItem separatorItem]];
        //Submenu items
        } else if ([nextObject isEqualToString:@"playlists"]) {
            ITDebugLog(@"Add \"Playlists\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"playlists", @"Playlists")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_playlistsMenu];
            [tempItem setTag:3];
        } else if ([nextObject isEqualToString:@"eqPresets"]) {
            ITDebugLog(@"Add \"EQ Presets\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"eqPresets", @"EQ Presets")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_eqMenu];
            [tempItem setTag:4];
            
            itemEnum = [[_eqMenu itemArray] objectEnumerator];
            while ( (tempItem = [itemEnum nextObject]) ) {
                [tempItem setState:NSOffState];
            }
            NS_DURING
                [[_eqMenu itemAtIndex:0] setState:[mtr equalizerEnabled] ? NSOnState : NSOffState];
                [[_eqMenu itemAtIndex:([mtr currentEQPresetIndex] + 1)] setState:NSOnState];
            NS_HANDLER
                [[MainController sharedController] networkError:localException];
            NS_ENDHANDLER
        } else if ([nextObject isEqualToString:@"songRating"] && currentSongRating) {
            ITDebugLog(@"Add \"Song Rating\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"songRating", @"Song Rating")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_ratingMenu];
            [tempItem setTag:1];
            if (_playingRadio || !_currentPlaylist) {
                [tempItem setEnabled:NO];
            }
            
            itemEnum = [[_ratingMenu itemArray] objectEnumerator];
            while ( (tempItem = [itemEnum nextObject]) ) {
                [tempItem setState:NSOffState];
            }
            
            NS_DURING
                [[_ratingMenu itemAtIndex:([mtr currentSongRating] * 5)] setState:NSOnState];
            NS_HANDLER
                [[MainController sharedController] networkError:localException];
            NS_ENDHANDLER
        } else if ([nextObject isEqualToString:@"upcomingSongs"]) {
            ITDebugLog(@"Add \"Upcoming Songs\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"upcomingSongs", @"Upcoming Songs")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_upcomingSongsMenu];
            [tempItem setTag:2];
            if (_playingRadio || _currentPlaylist < 1) {
                [tempItem setEnabled:NO];
            }
        } else if ([nextObject isEqualToString:@"artists"]) {
            ITDebugLog(@"Add \"Artists\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"artists", @"Artists")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_artistsMenu];
            [tempItem setTag:5];
        } else if ([nextObject isEqualToString:@"albums"]) {
            ITDebugLog(@"Add \"Albums\" submenu.");
            tempItem = [menu addItemWithTitle:NSLocalizedString(@"albums", @"Albums")
                    action:nil
                    keyEquivalent:@""];
            [tempItem setSubmenu:_albumsMenu];
            [tempItem setTag:6];
        }
    }
    ITDebugLog(@"Finished building menu.");
    [_currentMenu release];
    _currentMenu = menu;
    return _currentMenu;
}

- (NSMenu *)menuForNoPlayer
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    id <NSMenuItem> tempItem = nil;
    ITDebugLog(@"Creating menu for when player isn't running.");
    NS_DURING
        ITDebugLog(@"Add \"Open %@\" menu item.", [[[MainController sharedController] currentRemote] playerSimpleName]);
        tempItem = [menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"open", @"Open"), [[[MainController sharedController] currentRemote] playerSimpleName]] action:@selector(performMainMenuAction:) keyEquivalent:@""];
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    [tempItem setTag:MTMenuShowPlayerItem];
    [tempItem setTarget:self];
    ITDebugLog(@"Add a separator menu item.");
    [menu addItem:[NSMenuItem separatorItem]];
    ITDebugLog(@"Add \"Preferences...\" menu item.");
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"preferences", @"Preferences...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuPreferencesItem];
    [tempItem setTarget:self];
    if ([[MainController sharedController] blingBling] == NO) {
        ITDebugLog(@"Add \"Register MenuTunes...\" menu item.");
        tempItem = [menu addItemWithTitle:NSLocalizedString(@"register", @"Register MenuTunes...") action:@selector(performMainMenuAction:) keyEquivalent:@""];
        [tempItem setTag:MTMenuRegisterItem];
        [tempItem setTarget:self];
    }
    ITDebugLog(@"Add \"Quit\" menu item.");
    tempItem = [menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit") action:@selector(performMainMenuAction:) keyEquivalent:@""];
    [tempItem setTag:MTMenuQuitItem];
    [tempItem setTarget:self];
    return [menu autorelease];
}

- (BOOL)rebuildSubmenus
{
    NSArray *menu = [[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"];
    ITDebugLog(@"Rebuilding all of the submenus.");
    NS_DURING
		_currentTrack = [[[MainController sharedController] currentRemote] currentSongIndex];
		if (_currentTrack > -1) {
			_currentPlaylist = [[[MainController sharedController] currentRemote] currentPlaylistIndex];
		}
        _playingRadio = ([[[MainController sharedController] currentRemote] currentPlaylistClass] == ITMTRemotePlayerRadioPlaylist);
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    ITDebugLog(@"Releasing old submenus.");
	_continue = YES;
    ITDebugLog(@" - Rating menu");
    [_ratingMenu release];
	_ratingMenu = nil;
    ITDebugLog(@" - Upcoming songs menu");
    [_upcomingSongsMenu release];
	_upcomingSongsMenu = nil;
    ITDebugLog(@" - Playlists menu");
    [_playlistsMenu release];
	_playlistsMenu = nil;
    ITDebugLog(@" - EQ menu");
    [_eqMenu release];
	_eqMenu = nil;
    
    ITDebugLog(@"Beginning Rebuild of \"Song Rating\" submenu.");
    _ratingMenu = [self ratingMenu];
    ITDebugLog(@"Beginning Rebuild of \"Upcoming Songs\" submenu.");
    _upcomingSongsMenu = [self upcomingSongsMenu];
	if (_continue) {
		ITDebugLog(@"Beginning Rebuild of \"Playlists\" submenu.");
		_playlistsMenu = [self playlistsMenu];
	}
	if (_continue) {
		ITDebugLog(@"Beginning Rebuild of \"EQ Presets\" submenu.");
		_eqMenu = [self eqMenu];
	}
    if (_continue && [menu containsObject:@"artists"]) {
        ITDebugLog(@"Releasing artists menu");
        [_artistsMenu release];
        ITDebugLog(@"Beginning Rebuild of \"Artists\" submenu.");
        _artistsMenu = [self artistsMenu];
    }
    
    if (_continue && [menu containsObject:@"albums"]) {
        ITDebugLog(@"Releasing albums menu");
        [_albumsMenu release];
        ITDebugLog(@"Beginning Rebuild of \"Albums\" submenu.");
        _albumsMenu = [self albumsMenu];
    }
    ITDebugLog(@"Done rebuilding all of the submenus.");
	return _continue;
}

- (NSMenu *)ratingMenu
{
    NSMenu *ratingMenu = [[NSMenu alloc] initWithTitle:@""];
    NSEnumerator *itemEnum;
    id  anItem;
    int itemTag = 0;
    SEL itemSelector = @selector(performRatingMenuAction:);
    
    ITDebugLog(@"Building \"Song Rating\" menu.");
    
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"☆☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★☆☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★☆☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★☆☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★☆"] action:nil keyEquivalent:@""];
    [ratingMenu addItemWithTitle:[NSString stringWithUTF8String:"★★★★★"] action:nil keyEquivalent:@""];
    
    itemEnum = [[ratingMenu itemArray] objectEnumerator];
    while ( (anItem = [itemEnum nextObject]) ) {
        ITDebugLog(@"Setting up \"%@\" menu item.", [anItem title]);
        [anItem setAction:itemSelector];
        [anItem setTarget:self];
        [anItem setTag:itemTag];
        itemTag += 20;
    }
    ITDebugLog(@"Done Building \"Song Rating\" menu.");
    return ratingMenu;
}

- (NSMenu *)upcomingSongsMenu
{
    NSMenu *upcomingSongsMenu;
    int numSongs = 0, numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
	if (_currentTrack == -1) {
		return nil;
	}
    NS_DURING
        numSongs = [[[MainController sharedController] currentRemote] numberOfSongsInPlaylistAtIndex:_currentPlaylist];
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    
	if (numSongs == -1) {
		return nil;
	}
	upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
	NS_DURING
    ITDebugLog(@"Building \"Upcoming Songs\" menu.");
    if (_currentPlaylist && !_playingRadio) {
        if (numSongs > 0) {
            int i;
            for (i = _currentTrack + 1; i <= _currentTrack + numSongsInAdvance && i <= numSongs; i++) {
				BOOL enabled;
				
				//Check if the song at this index is enabled for playback. If it isn't, skip over it
				NS_DURING
					enabled = [[[MainController sharedController] currentRemote] songEnabledAtIndex:i];
				NS_HANDLER
					[[MainController sharedController] networkError:localException];
				NS_ENDHANDLER
				
                if (enabled) {
                    NSString *curSong = nil;
                    NS_DURING
                        curSong = [[[MainController sharedController] currentRemote] songTitleAtIndex:i];
                    NS_HANDLER
                        [[MainController sharedController] networkError:localException];
                    NS_ENDHANDLER
                    id <NSMenuItem> songItem;
                    ITDebugLog(@"Adding song: %@", curSong);
                    songItem = [upcomingSongsMenu addItemWithTitle:curSong action:@selector(performUpcomingSongsMenuAction:) keyEquivalent:@""];
                    [songItem setTag:i];
                    [songItem setTarget:self];
                } else {
					numSongsInAdvance++;
				}
            }
        }
        
        if ([upcomingSongsMenu numberOfItems] == 0) {
            [upcomingSongsMenu addItemWithTitle:NSLocalizedString(@"noUpcomingSongs", @"No upcoming songs.") action:NULL keyEquivalent:@""];
        }
    }
    ITDebugLog(@"Done Building \"Upcoming Songs\" menu.");
	NS_VALUERETURN(upcomingSongsMenu, NSMenu *);
	NS_HANDLER
		[upcomingSongsMenu release];
		_continue = NO;
		NS_VALUERETURN(nil, NSMenu *);
	NS_ENDHANDLER
}

/*- (NSMenu *)playlistsMenu
{
    NSMenu *playlistsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *playlists;
    id <NSMenuItem> tempItem;
    ITMTRemotePlayerSource source = [[[MainController sharedController] currentRemote] currentSource];
    int i;
    NS_DURING
        playlists = [[[MainController sharedController] currentRemote] playlists];
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    
    ITDebugLog(@"Building \"Playlists\" menu.");
    
    for (i = 0; i < [playlists count]; i++) {
        NSString *curPlaylist = [playlists objectAtIndex:i];
        ITDebugLog(@"Adding playlist: %@", curPlaylist);
        tempItem = [playlistsMenu addItemWithTitle:curPlaylist action:@selector(performPlaylistMenuAction:) keyEquivalent:@""];
        [tempItem setTag:i + 1];
        [tempItem setTarget:self];
    }
    
    if (source == ITMTRemoteRadioSource) {
        [[playlistsMenu addItemWithTitle:NSLocalizedString(@"radio", @"Radio") action:NULL keyEquivalent:@""] setState:NSOnState];
    } else if (source == ITMTRemoteGenericDeviceSource) {
        [[playlistsMenu addItemWithTitle:NSLocalizedString(@"genericDevice", @"Generic Device") action:NULL keyEquivalent:@""] setState:NSOnState];
    } else if (source == ITMTRemoteiPodSource) {
        [[playlistsMenu addItemWithTitle:NSLocalizedString(@"iPod", @"iPod") action:NULL keyEquivalent:@""] setState:NSOnState];
    } else if (source == ITMTRemoteCDSource) {
        [[playlistsMenu addItemWithTitle:NSLocalizedString(@"cd", @"CD") action:NULL keyEquivalent:@""] setState:NSOnState];
    } else if (source == ITMTRemoteSharedLibrarySource) {
        [[playlistsMenu addItemWithTitle:NSLocalizedString(@"sharedLibrary", @"Shared Library") action:NULL keyEquivalent:@""] setState:NSOnState];
    } else if (source == ITMTRemoteLibrarySource && _currentPlaylist) {
        [[playlistsMenu itemAtIndex:_currentPlaylist - 1] setState:NSOnState];
    }
    ITDebugLog(@"Done Building \"Playlists\" menu");
    return playlistsMenu;
}*/

- (void)playlistsMenuAux:(NSMenu *)menu node:(PlaylistNode *)node tagPrefix:(int)p
{
	id <NSMenuItem> tempItem;
	int i;
	
	for (i = 0; i < [[node children] count]; i++) {
		PlaylistNode *nextNode = [[node children] objectAtIndex:i];
		if ([nextNode type] == ITMTFolderNode) {
			NSMenu *submenu = [[NSMenu alloc] init];
			tempItem = [menu addItemWithTitle:[nextNode name] action:@selector(performPlaylistMenuAction:) keyEquivalent:@""];
			[tempItem setTag:p + [nextNode index] + 1];
			[tempItem setTarget:self];
			[tempItem setSubmenu:submenu];
			[self playlistsMenuAux:[submenu autorelease] node:nextNode tagPrefix:p];
		} else {
			tempItem = [menu addItemWithTitle:[nextNode name] action:@selector(performPlaylistMenuAction:) keyEquivalent:@""];
			[tempItem setTag:p + [nextNode index] + 1];
			[tempItem setTarget:self];
		}
		
		PlaylistNode *root = node;
		while ([root type] == ITMTPlaylistNode || [root type] == ITMTFolderNode) {
			root = [root parent];
		}
		
		if ([root index] == [[[MainController sharedController] currentRemote] currentSourceIndex] && [nextNode index] == _currentPlaylist) {
			[tempItem setState:NSOnState];
		}
	}
}

- (NSMenu *)playlistsMenu
{
    NSMenu *playlistsMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *playlists = nil;
    id <NSMenuItem> tempItem;
    ITMTRemotePlayerSource source = [[[MainController sharedController] currentRemote] currentSource];
	int i;
    NSMutableArray *indices = [[NSMutableArray alloc] init];
    NS_DURING
        playlists = [[[MainController sharedController] currentRemote] playlists];
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
	
	if (!playlists) {
		[playlistsMenu release];
		return nil;
	}
	NS_DURING
    ITDebugLog(@"Building \"Playlists\" menu.");
    {
		//First we add the main Library source, since it is guaranteed to be there.
        PlaylistNode *library = [playlists objectAtIndex:0];
        ITDebugLog(@"Adding main source: %@", [library name]);
		[self playlistsMenuAux:playlistsMenu node:library tagPrefix:0];
        ITDebugLog(@"Adding index to the index array.");
        [indices addObject:[NSNumber numberWithInt:[library index]]];
    }
	
	//Next go through the other sources
    if ([playlists count] > 1) {
		//Add the radio source if it is playing
        if ([[playlists objectAtIndex:1] sourceType] == ITMTRemoteRadioSource) {
            [indices addObject:[NSNumber numberWithInt:[[playlists objectAtIndex:1] index]]];
            if (source == ITMTRemoteRadioSource) {
                [playlistsMenu addItem:[NSMenuItem separatorItem]];
                [[playlistsMenu addItemWithTitle:NSLocalizedString(@"radio", @"Radio") action:@selector(performPlaylistMenuAction:) keyEquivalent:@""] setState:NSOnState];
            } else if ([playlists count] > 2) {
				[playlistsMenu addItem:[NSMenuItem separatorItem]];
			}
        }
		
		//Add other sources as needed (shared music, iPods, CDs)
        for (i = [playlists count] - 1; i > 1 ; i--) {
            PlaylistNode *nextSource = [playlists objectAtIndex:i];
            if ([nextSource type] != ITMTRemoteRadioSource) {
                NSString *name = [nextSource name];
                ITDebugLog(@"Adding source: %@", name);
                
                if ( ([nextSource type] == ITMTRemoteiPodSource) && [self iPodWithNameAutomaticallyUpdates:name] ) {
                    ITDebugLog(@"Invalid iPod source.");
                    [playlistsMenu addItemWithTitle:name action:NULL keyEquivalent:@""];
                } else {
					NSMenu *menu = [[NSMenu alloc] init];
					[[playlistsMenu addItemWithTitle:name action:NULL keyEquivalent:@""] setSubmenu:[menu autorelease]];
					[self playlistsMenuAux:menu node:nextSource tagPrefix:(i * 1000)];
                }
                ITDebugLog(@"Adding index to the index array.");
                [indices addObject:[NSNumber numberWithInt:[nextSource index]]];
            }
        }
    }
	NS_DURING
	if (_currentPlaylist != -1) {
		if ( (source == ITMTRemoteSharedLibrarySource) || (source == ITMTRemoteiPodSource) || (source == ITMTRemoteGenericDeviceSource) || (source == ITMTRemoteCDSource) ) {
			tempItem = [playlistsMenu itemAtIndex:[playlistsMenu numberOfItems] + [indices indexOfObject:[NSNumber numberWithInt:[[[MainController sharedController] currentRemote] currentSourceIndex]]] - [indices count]];
			[tempItem setState:NSOnState];
		}
	}
	NS_HANDLER
	NS_ENDHANDLER
    [indices release];
    tempItem = [playlistsMenu addItemWithTitle:NSLocalizedString(@"refresh", @"Refresh") action:@selector(rebuildSubmenus) keyEquivalent:@""];
    [tempItem setTarget:self];
    [tempItem setImage:[NSImage imageNamed:@"ChasingArrow"]];
    ITDebugLog(@"Done Building \"Playlists\" menu");
    NS_VALUERETURN(playlistsMenu, NSMenu *);
	NS_HANDLER
		[playlistsMenu release];
		_continue = NO;
		NS_VALUERETURN(nil, NSMenu *);
	NS_ENDHANDLER
}

- (NSMenu *)eqMenu
{
    NSMenu *eqMenu = [[NSMenu alloc] initWithTitle:@""];
    NSArray *eqPresets = nil;
    id <NSMenuItem> tempItem;
    int i;
    
    NS_DURING
        eqPresets = [[[MainController sharedController] currentRemote] eqPresets];
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    
    ITDebugLog(@"Building \"EQ Presets\" menu.");
    
    tempItem = [eqMenu addItemWithTitle:@"Enabled" action:@selector(performEqualizerMenuAction:) keyEquivalent:@""];
    [tempItem setTag:-1];
    [tempItem setTarget:self];
    [eqMenu addItem:[NSMenuItem separatorItem]];
    
    for (i = 0; i < [eqPresets count]; i++) {
        NSString *name;
	   if ( ( name = [eqPresets objectAtIndex:i] ) ) {
            ITDebugLog(@"Adding EQ Preset: %@", name);
            tempItem = [eqMenu addItemWithTitle:name
                    action:@selector(performEqualizerMenuAction:)
                    keyEquivalent:@""];
            [tempItem setTag:i];
            [tempItem setTarget:self];
	   }
    }
    ITDebugLog(@"Done Building \"EQ Presets\" menu");
    return eqMenu;
}

- (NSMenu *)artistsMenu
{
    NSMenu *artistsMenu = [[NSMenu alloc] initWithTitle:@"Artists"];
    NSEnumerator *artistsEnumerator;
    NSString *nextArtist;
    id <NSMenuItem> tempItem;
    ITDebugLog(@"Building \"Artists\" menu.");
    NS_DURING
        artistsEnumerator = [[[[MainController sharedController] currentRemote] artists] objectEnumerator];
        while ( (nextArtist = [artistsEnumerator nextObject]) ) {
            tempItem = [artistsMenu addItemWithTitle:nextArtist action:@selector(performBrowseMenuAction:) keyEquivalent:@""];
            [tempItem setTarget:self];
        }
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    ITDebugLog(@"Done Building \"Artists\" menu");
    return artistsMenu;
}

- (NSMenu *)albumsMenu
{
    NSMenu *albumsMenu = [[NSMenu alloc] initWithTitle:@"Albums"];
    NSEnumerator *albumsEnumerator;
    NSString *nextAlbum;
    id <NSMenuItem> tempItem;
    ITDebugLog(@"Building \"Albums\" menu.");
    NS_DURING
        albumsEnumerator = [[[[MainController sharedController] currentRemote] albums] objectEnumerator];
        while ( (nextAlbum = [albumsEnumerator nextObject]) ) {
            tempItem = [albumsMenu addItemWithTitle:nextAlbum action:@selector(performBrowseMenuAction:) keyEquivalent:@""];
            [tempItem setTarget:self];
        }
    NS_HANDLER
        [[MainController sharedController] networkError:localException];
    NS_ENDHANDLER
    ITDebugLog(@"Done Building \"Albums\" menu");
    return albumsMenu;
}

- (void)performMainMenuAction:(id)sender
{
    switch ( [sender tag] )
    {
        case MTMenuPlayPauseItem:
            ITDebugLog(@"Performing Menu Action: Play/Pause");
            [[MainController sharedController] playPause];
            break;
        case MTMenuFastForwardItem:
            ITDebugLog(@"Performing Menu Action: Fast Forward");
            [[MainController sharedController] fastForward];
            break;
        case MTMenuRewindItem:
            ITDebugLog(@"Performing Menu Action: Rewind");
            [[MainController sharedController] rewind];
            break;
        case MTMenuPreviousTrackItem:
            ITDebugLog(@"Performing Menu Action: Previous Track");
            [[MainController sharedController] prevSong];
            break;
        case MTMenuNextTrackItem:
            ITDebugLog(@"Performing Menu Action: Next Track");
            [[MainController sharedController] nextSong];
            break;
        case MTMenuShowPlayerItem:
            ITDebugLog(@"Performing Menu Action: Show Main Interface");
            [[MainController sharedController] showPlayer];
            break;
        case MTMenuPreferencesItem:
            ITDebugLog(@"Performing Menu Action: Preferences...");
            [[MainController sharedController] showPreferences];
            break;
		case MTMenuAboutItem:
			ITDebugLog(@"Performing Menu Action: About MenuTunes...");
			[[ITAboutWindowController sharedController] showAboutWindow];
			break;
        case MTMenuQuitItem:
            ITDebugLog(@"Performing Menu Action: Quit");
            [[MainController sharedController] quitMenuTunes];
            break;
        case MTMenuRegisterItem:
            ITDebugLog(@"Performing Menu Action: Register");
            [[MainController sharedController] blingNow];
            break;
        default:
            ITDebugLog(@"Performing Menu Action: Unimplemented Menu Item OR Child-bearing Menu Item");
            break;
    }
}

- (void)performRatingMenuAction:(id)sender
{
    ITDebugLog(@"Rating action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectSongRating:[sender tag]];
}

- (void)performPlaylistMenuAction:(id)sender
{
    ITDebugLog(@"Playlist action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectPlaylistAtIndex:[sender tag]];
}

- (void)performEqualizerMenuAction:(id)sender
{
    ITDebugLog(@"EQ action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectEQPresetAtIndex:[sender tag]];
}

- (void)performUpcomingSongsMenuAction:(id)sender
{
    ITDebugLog(@"Song action selected on item with tag %i", [sender tag]);
    [[MainController sharedController] selectSongAtIndex:[sender tag]];
}

- (void)performBrowseMenuAction:(id)sender
{
    ITDebugLog(@"Browse action selected on item named %@", [sender title]);
    /*
    ** 1 - Artist
    ** 2 - Album
    ** 3 - Genre?
    */
    [[MainController sharedController] makePlaylistWithTerm:[sender title] ofType:(([[[sender menu] title] isEqualToString:@"Artists"]) ? 1 : 2)];
}

- (void)updateMenu
{
    ITDebugLog(@"Update Menu");
    [_currentMenu update];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return YES;
}

//This is never used I know, keep it though
- (NSString *)systemUIColor
{
    NSDictionary *tmpDict;
    NSNumber *tmpNumber;
    if ( (tmpDict = [NSDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/.GlobalPreferences.plist" stringByExpandingTildeInPath]]) ) {
        if ( (tmpNumber = [tmpDict objectForKey:@"AppleAquaColorVariant"]) ) {
            if ( ([tmpNumber intValue] == 1) ) {
                return @"Aqua";
            } else {
                return @"Graphite";
            }
        } else {
            return @"Aqua";
        }
    } else {
        return @"Aqua";
    }
}

- (void)setKeyEquivalentForCode:(short)code andModifiers:(long)modifiers
        onItem:(id <NSMenuItem>)item
{
    unichar charcode = 'a';
    int i;
    long cocoaModifiers = 0;
    static long carbonToCocoa[6][2] = 
    {
        { cmdKey, NSCommandKeyMask },
        { optionKey, NSAlternateKeyMask },
        { controlKey, NSControlKeyMask },
        { shiftKey, NSShiftKeyMask },
    };
    
    ITDebugLog(@"Setting Key Equivelent on menu item \"%@\".", [item title]);
    
    for (i = 0; i < 6; i++) {
        if (modifiers & carbonToCocoa[i][0]) {
            cocoaModifiers += carbonToCocoa[i][1];
        }
    }
    [item setKeyEquivalentModifierMask:cocoaModifiers];
    
    //Missing key combos for some keys. Must find them later.
    switch (code)
    {
        case 36:
            ITDebugLog(@"Keycode for menu item \"%@\": 36 (Return)", [item title]);
            charcode = '\r';
        break;
        
        case 48:
            ITDebugLog(@"Keycode for menu item \"%@\": 48 (Tab)", [item title]);
            charcode = '\t';
        break;
        
        //Space -- ARGH!
        case 49:
        {
            ITDebugLog(@"Keycode for menu item \"%@\": 49 (Space)", [item title]);
            // Haven't tested this, though it should work.
            // This doesn't work. :'(
            //unichar buffer;
            //[[NSString stringWithString:@"Space"] getCharacters:&buffer];
            //charcode = buffer;
            /*MenuRef menuRef = _NSGetCarbonMenu([item menu]);
            ITDebugLog(@"%@", menuRef);
            SetMenuItemCommandKey(menuRef, 0, NO, 49);
            SetMenuItemModifiers(menuRef, 0, kMenuNoCommandModifier);
            SetMenuItemKeyGlyph(menuRef, 0, kMenuBlankGlyph);
            charcode = 'b';*/
            unichar buffer;
            [[NSString stringWithString:@" "] getCharacters:&buffer]; // this will have to do for now :(
            charcode = buffer;
        }
        break;
        
        case 51:
            ITDebugLog(@"Keycode for menu item \"%@\": 51 (Delete)", [item title]);
            charcode = NSDeleteFunctionKey;
        break;
        
        case 53:
            ITDebugLog(@"Keycode for menu item \"%@\": 53 (Escape)", [item title]);
            charcode = '\e';
        break;
        
        case 71:
            ITDebugLog(@"Keycode for menu item \"%@\": 71 (Escape)", [item title]);
            charcode = '\e';
        break;
        
        case 76:
            ITDebugLog(@"Keycode for menu item \"%@\": 76 (Return)", [item title]);
            charcode = '\r';
        break;
        
        case 96:
            ITDebugLog(@"Keycode for menu item \"%@\": 96 (F5)", [item title]);
            charcode = NSF5FunctionKey;
        break;
        
        case 97:
            ITDebugLog(@"Keycode for menu item \"%@\": 97 (F6)", [item title]);
            charcode = NSF6FunctionKey;
        break;
        
        case 98:
            ITDebugLog(@"Keycode for menu item \"%@\": 98 (F7)", [item title]);
            charcode = NSF7FunctionKey;
        break;
        
        case 99:
            ITDebugLog(@"Keycode for menu item \"%@\": 99 (F3)", [item title]);
            charcode = NSF3FunctionKey;
        break;
        
        case 100:
            ITDebugLog(@"Keycode for menu item \"%@\": 100 (F8)", [item title]);
            charcode = NSF8FunctionKey;
        break;
        
        case 101:
            ITDebugLog(@"Keycode for menu item \"%@\": 101 (F9)", [item title]);
            charcode = NSF9FunctionKey;
        break;
        
        case 103:
            ITDebugLog(@"Keycode for menu item \"%@\": 103 (F11)", [item title]);
            charcode = NSF11FunctionKey;
        break;
        
        case 105:
            ITDebugLog(@"Keycode for menu item \"%@\": 105 (F13)", [item title]);
            charcode = NSF13FunctionKey;
        break;
        
        case 107:
            ITDebugLog(@"Keycode for menu item \"%@\": 107 (F14)", [item title]);
            charcode = NSF14FunctionKey;
        break;
        
        case 109:
            ITDebugLog(@"Keycode for menu item \"%@\": 109 (F10)", [item title]);
            charcode = NSF10FunctionKey;
        break;
        
        case 111:
            ITDebugLog(@"Keycode for menu item \"%@\": 111 (F12)", [item title]);
            charcode = NSF12FunctionKey;
        break;
        
        case 113:
            ITDebugLog(@"Keycode for menu item \"%@\": 113 (F13)", [item title]);
            charcode = NSF13FunctionKey;
        break;
        
        case 114:
            ITDebugLog(@"Keycode for menu item \"%@\": 114 (Insert)", [item title]);
            charcode = NSInsertFunctionKey;
        break;
        
        case 115:
            ITDebugLog(@"Keycode for menu item \"%@\": 115 (Home)", [item title]);
            charcode = NSHomeFunctionKey;
        break;
        
        case 116:
            ITDebugLog(@"Keycode for menu item \"%@\": 116 (PgUp)", [item title]);
            charcode = NSPageUpFunctionKey;
        break;
        
        case 117:
            ITDebugLog(@"Keycode for menu item \"%@\": 117 (Delete)", [item title]);
            charcode = NSDeleteFunctionKey;
        break;
        
        case 118:
            ITDebugLog(@"Keycode for menu item \"%@\": 118 (F4)", [item title]);
            charcode = NSF4FunctionKey;
        break;
        
        case 119:
            ITDebugLog(@"Keycode for menu item \"%@\": 119 (End)", [item title]);
            charcode = NSEndFunctionKey;
        break;
        
        case 120:
            ITDebugLog(@"Keycode for menu item \"%@\": 120 (F2)", [item title]);
            charcode = NSF2FunctionKey;
        break;
        
        case 121:
            ITDebugLog(@"Keycode for menu item \"%@\": 121 (PgDown)", [item title]);
            charcode = NSPageDownFunctionKey;
        break;
        
        case 122:
            ITDebugLog(@"Keycode for menu item \"%@\": 122 (F1)", [item title]);
            charcode = NSF1FunctionKey;
        break;
        
        case 123:
            ITDebugLog(@"Keycode for menu item \"%@\": 123 (Left Arrow)", [item title]);
            charcode = NSLeftArrowFunctionKey;
        break;
        
        case 124:
            ITDebugLog(@"Keycode for menu item \"%@\": 124 (Right Arrow)", [item title]);
            charcode = NSRightArrowFunctionKey;
        break;
        
        case 125:
            ITDebugLog(@"Keycode for menu item \"%@\": 125 (Down Arrow)", [item title]);
            charcode = NSDownArrowFunctionKey;
        break;
        
        case 126:
            ITDebugLog(@"Keycode for menu item \"%@\": 126 (Up Arrow)", [item title]);
            charcode = NSUpArrowFunctionKey;
        break;
    }
    
    if (charcode == 'a') {
        unsigned long state;
        long keyTrans;
        char charCode;
        Ptr kchr;
        state = 0;
        kchr = (Ptr) GetScriptVariable(smCurrentScript, smKCHRCache);
        keyTrans = KeyTranslate(kchr, code, &state);
        charCode = keyTrans;
        ITDebugLog(@"Keycode for menu item \"%@\": %i (%c)", [item title], code, charCode);
        [item setKeyEquivalent:[NSString stringWithCString:&charCode length:1]];
    } else if (charcode != 'b') {
        [item setKeyEquivalent:[NSString stringWithCharacters:&charcode length:1]];
    }
    ITDebugLog(@"Done setting key equivalent on menu item: %@", [item title]);
}

- (BOOL)iPodWithNameAutomaticallyUpdates:(NSString *)name
{
    NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
    NSEnumerator *volEnum = [volumes objectEnumerator];
    NSString *nextVolume;
    ITDebugLog(@"Looking for an iPod named %@", name);
    while ( (nextVolume = [volEnum nextObject]) ) {
        ITDebugLog(@"- %@", nextVolume);
        if ([nextVolume rangeOfString:name options:nil /*range:NSMakeRange(0, [name length] - 1)*/].location != NSNotFound) {
            NSFileHandle *handle;
            NSData *data;
            NSString *path = [nextVolume stringByAppendingPathComponent:@"/iPod_Control/iTunes/iTunesPrefs"];
            if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) {
                ITDebugLog(@"Error, path isn't an iPod! %@", path);
                return NO;
            }
            handle = [NSFileHandle fileHandleForReadingAtPath:path];
            ITDebugLog(@"File handle: %@", handle);
            [handle seekToFileOffset:10];
            data = [handle readDataOfLength:1];
            ITDebugLog(@"Data: %@", data);
            if ( (*((unsigned char*)[data bytes]) == 0x00) ) {
                ITDebugLog(@"iPod is manually updated. %@", path);
                return NO;
            } else if ( ( *((unsigned char*)[data bytes]) == 0x01 ) ) {
                ITDebugLog(@"iPod is automatically updated. %@", path);
                return YES;
            } else {
                ITDebugLog(@"Error! Value: %h  Desc: %@ Path: %@", *((unsigned char*)[data bytes]), [data description], path);
                return NO;
            }
        }
    }
    return YES;
}

@end