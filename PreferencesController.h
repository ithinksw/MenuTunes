/*
 *	MenuTunes
 *  PreferencesController
 *    Preferences window controller
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2002 iThink Software.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>

@class MenuTunes, KeyCombo;

@interface PreferencesController : NSObject
{
    IBOutlet NSButton *albumCheckbox;
    IBOutlet NSTableView *allTableView;
    IBOutlet NSButton *artistCheckbox;
    IBOutlet NSTextField *keyComboField;
    IBOutlet NSPanel *keyComboPanel;
    IBOutlet NSButton *launchAtLoginCheckbox;
    IBOutlet NSTableView *menuTableView;
    IBOutlet NSButton *nameCheckbox;
    IBOutlet NSButton *nextTrackButton;
    IBOutlet NSButton *playPauseButton;
    IBOutlet NSButton *previousTrackButton;
    IBOutlet NSTextField *songsInAdvance;
    IBOutlet NSButton *trackInfoButton;
    IBOutlet NSButton *trackTimeCheckbox;
    IBOutlet NSButton *upcomingSongsButton;
    IBOutlet NSWindow *window;
    
    MenuTunes *mt;
    NSMutableArray *availableItems, *myItems;
    NSArray *submenuItems;
    
    KeyCombo *combo, *playPauseCombo, *nextTrackCombo,
             *prevTrackCombo, *trackInfoCombo, *upcomingSongsCombo;
    NSString *setHotKey;
}
- (id)initWithMenuTunes:(MenuTunes *)menutunes;

- (IBAction)apply:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)cancelHotKey:(id)sender;
- (IBAction)clearHotKey:(id)sender;
- (IBAction)okHotKey:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)setCurrentTrackInfo:(id)sender;
- (IBAction)setNextTrack:(id)sender;
- (IBAction)setPlayPause:(id)sender;
- (IBAction)setPreviousTrack:(id)sender;
- (IBAction)setUpcomingSongs:(id)sender;

- (void)setHotKey:(NSString *)key;
- (void)setKeyCombo:(KeyCombo *)newCombo;
@end
