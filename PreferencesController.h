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

@class MainController, KeyCombo;

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
    IBOutlet NSButton *ratingDecrementButton;
    IBOutlet NSButton *ratingIncrementButton;
    IBOutlet NSTextField *songsInAdvance;
    IBOutlet NSButton *toggleLoopButton;
    IBOutlet NSButton *toggleShuffleButton;
    IBOutlet NSButton *trackInfoButton;
    IBOutlet NSButton *trackTimeCheckbox;
    IBOutlet NSButton *upcomingSongsButton;
    IBOutlet NSButton *visualizerButton;
    IBOutlet NSButton *volumeDecrementButton;
    IBOutlet NSButton *volumeIncrementButton;
    IBOutlet NSWindow *window;
    
    MainController *controller;
    NSUserDefaults *df;
    NSMutableArray *availableItems;
    NSMutableArray *myItems;
    NSArray        *submenuItems;

    KeyCombo *combo;
    KeyCombo *playPauseCombo;
    KeyCombo *nextTrackCombo;
    KeyCombo *prevTrackCombo;
    KeyCombo *visualizerCombo;
    KeyCombo *trackInfoCombo;
    KeyCombo *upcomingSongsCombo;
    KeyCombo *volumeIncrementCombo;
    KeyCombo *volumeDecrementCombo;
    KeyCombo *ratingIncrementCombo;
    KeyCombo *ratingDecrementCombo;
    KeyCombo *toggleLoopCombo;
    KeyCombo *toggleShuffleCombo;
    
    NSString *setHotKey;
}

+ (PreferencesController *)sharedPrefs;

- (id)controller;
- (void)setController:(id)object;

- (IBAction)showPrefsWindow:(id)sender;

- (IBAction)changeGeneralSetting:(id)sender;
- (IBAction)changeStatusWindowSetting:(id)sender;
- (IBAction)changeHotKey:(id)sender;

- (void)registerDefaults;

- (IBAction)cancelHotKey:(id)sender;
- (IBAction)clearHotKey:(id)sender;
- (IBAction)okHotKey:(id)sender;

- (void)setHotKey:(NSString *)key;
- (void)setKeyCombo:(KeyCombo *)newCombo;
@end
