/*
 *	MenuTunes
 *	PreferencesController.h
 *
 *	Preferences window controller.
 *
 *	Copyright (c) 2002 iThink Software
 *
 */


#import <Cocoa/Cocoa.h>

@class CustomMenuTableView, MainController, ITKeyCombo;

@interface PreferencesController : NSObject
{
    IBOutlet NSButton *albumArtworkCheckbox;
    IBOutlet NSButton *albumCheckbox;
    IBOutlet NSTableView *allTableView;
    IBOutlet NSPopUpButton *appearanceEffectPopup;
    IBOutlet NSSlider *appearanceSpeedSlider;
    IBOutlet NSButton *artistCheckbox;
	IBOutlet NSButton *audioscrobblerEnabledCheckbox;
	IBOutlet NSTextField *audioscrobblerPasswordTextField;
	IBOutlet NSTextField *audioscrobblerStatusTextField;
	IBOutlet NSButton *audioscrobblerUseCacheCheckbox;
	IBOutlet NSTextField *audioscrobblerUserTextField;
    IBOutlet NSPopUpButton *backgroundStylePopup;
    IBOutlet NSColorWell *backgroundColorWell;
    IBOutlet NSPopUpButton *backgroundColorPopup;
    IBOutlet NSTextField *clientPasswordTextField;
    IBOutlet NSButton *composerCheckbox;
    IBOutlet NSTextField *hostTextField;
    IBOutlet NSTableView *hotKeysTableView;
    IBOutlet NSButton *launchAtLoginCheckbox;
    IBOutlet NSButton *launchPlayerAtLaunchCheckbox;
    IBOutlet NSTextField *locationTextField;
    IBOutlet NSView *manualView;
    IBOutlet CustomMenuTableView *menuTableView;
    IBOutlet NSButton *nameCheckbox;
    IBOutlet NSTextField *nameTextField;
    IBOutlet NSPanel *passwordPanel;
    IBOutlet NSTextField *passwordPanelMessage;
    IBOutlet NSButton *passwordPanelOKButton;
    IBOutlet NSTextField *passwordPanelTextField;
    IBOutlet NSTextField *passwordPanelTitle;
    IBOutlet NSTextField *passwordTextField;
    IBOutlet NSButton *playCountCheckbox;
    IBOutlet NSMatrix *positionMatrix;
    IBOutlet NSButton *ratingCheckbox;
    IBOutlet NSButton *runScriptsCheckbox;
	IBOutlet NSPopUpButton *screenPopup;
    IBOutlet NSTextField *selectedPlayerTextField;
    IBOutlet NSBox *selectPlayerBox;
    IBOutlet NSPanel *selectPlayerSheet;
    IBOutlet NSButton *selectSharedPlayerButton;
    IBOutlet NSButton *shareMenuTunesCheckbox;
    IBOutlet NSButton *sharingPanelOKButton;
    IBOutlet NSTableView *sharingTableView;
    IBOutlet NSButton *showOnChangeCheckbox;
    IBOutlet NSButton *showScriptsButton;
    IBOutlet NSTextField *songsInAdvance;
    IBOutlet NSButton *trackNumberCheckbox;
    IBOutlet NSButton *trackTimeCheckbox;
    IBOutlet NSButton *useSharedMenuTunesCheckbox;
    IBOutlet NSSlider *vanishDelaySlider;
    IBOutlet NSPopUpButton *vanishEffectPopup;
    IBOutlet NSSlider *vanishSpeedSlider;
    IBOutlet NSWindow *window;
    IBOutlet NSPopUpButton *windowSizingPopup;
    IBOutlet NSView *zeroConfView;

    MainController *controller;
    NSUserDefaults *df;
    NSMutableArray *availableItems;
    NSMutableArray *myItems;
    NSArray        *submenuItems;
    NSArray        *effectClasses;
    
    NSArray *hotKeysArray, *hotKeyNamesArray;
    NSMutableDictionary *hotKeysDictionary;
}

+ (PreferencesController *)sharedPrefs;
+ (NSString *)getKeychainItemPasswordForUser:(NSString *)user;

- (id)controller;
- (void)setController:(id)object;

- (BOOL)showPasswordPanel;
- (BOOL)showInvalidPasswordPanel;

- (IBAction)changeGeneralSetting:(id)sender;
- (IBAction)changeSharingSetting:(id)sender;
- (IBAction)changeStatusWindowSetting:(id)sender;
- (void)resetRemotePlayerTextFields;

- (IBAction)clearHotKey:(id)sender;
- (IBAction)editHotKey:(id)sender;
- (IBAction)showPrefsWindow:(id)sender;

- (void)registerDefaults;
- (void)deletePressedInTableView:(NSTableView *)tableView;

@end
