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

@class CustomMenuTableView, MainController, ITKeyCombo;

@interface PreferencesController : NSObject
{
    IBOutlet NSButton *albumCheckbox;
    IBOutlet NSTableView *allTableView;
    IBOutlet NSPopUpButton *appearanceEffectPopup;
    IBOutlet NSSlider *appearanceSpeedSlider;
    IBOutlet NSButton *artistCheckbox;
    IBOutlet NSTextField *hostTextField;
    IBOutlet NSTableView *hotKeysTableView;
    IBOutlet NSButton *launchAtLoginCheckbox;
    IBOutlet NSButton *launchPlayerAtLaunchCheckbox;
    IBOutlet NSView *manualView;
    IBOutlet CustomMenuTableView *menuTableView;
    IBOutlet NSButton *nameCheckbox;
    IBOutlet NSButton *ratingCheckbox;
    IBOutlet NSBox *selectPlayerBox;
    IBOutlet NSPanel *selectPlayerSheet;
    IBOutlet NSButton *selectSharedPlayerButton;
    IBOutlet NSButton *shareMenuTunesCheckbox;
    IBOutlet NSButton *sharePasswordCheckbox;
    IBOutlet NSTextField *sharePasswordTextField;
    IBOutlet NSTableView *sharingTableView;
    IBOutlet NSButton *showOnChangeCheckbox;
    IBOutlet NSTextField *songsInAdvance;
    IBOutlet NSButton *trackNumberCheckbox;
    IBOutlet NSButton *trackTimeCheckbox;
    IBOutlet NSButton *useSharedMenuTunesCheckbox;
    IBOutlet NSSlider *vanishDelaySlider;
    IBOutlet NSPopUpButton *vanishEffectPopup;
    IBOutlet NSSlider *vanishSpeedSlider;
    IBOutlet NSWindow *window;
    IBOutlet NSView *zeroConfView;

    MainController *controller;
    NSUserDefaults *df;
    NSMutableArray *availableItems;
    NSMutableArray *myItems;
    NSArray        *submenuItems;
    
    NSArray *hotKeysArray, *hotKeyNamesArray;
    NSMutableDictionary *hotKeysDictionary;
}

+ (PreferencesController *)sharedPrefs;

- (id)controller;
- (void)setController:(id)object;

- (IBAction)changeGeneralSetting:(id)sender;
- (IBAction)changeSharingSetting:(id)sender;
- (IBAction)changeStatusWindowSetting:(id)sender;
- (IBAction)clearHotKey:(id)sender;
- (IBAction)editHotKey:(id)sender;
- (IBAction)showPrefsWindow:(id)sender;

- (void)registerDefaults;
- (void)deletePressedInTableView:(NSTableView *)tableView;

@end
