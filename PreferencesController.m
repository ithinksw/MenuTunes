#import "PreferencesController.h"
#import "MainController.h"
#import "NetworkController.h"
#import "NetworkObject.h"
#import "StatusWindow.h"
#import "StatusWindowController.h"
#import "CustomMenuTableView.h"

#import <netinet/in.h>
#import <arpa/inet.h>
#import <openssl/sha.h>

#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITKeyCombo.h>
#import <ITKit/ITKeyComboPanel.h>
#import <ITKit/ITWindowPositioning.h>
#import <ITKit/ITKeyBroadcaster.h>

#import <ITKit/ITCutWindowEffect.h>
#import <ITKit/ITDissolveWindowEffect.h>
#import <ITKit/ITSlideHorizontallyWindowEffect.h>
#import <ITKit/ITSlideVerticallyWindowEffect.h>
#import <ITKit/ITPivotWindowEffect.h>


#define SENDER_STATE (([sender state] == NSOnState) ? YES : NO)

/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE INTERFACE
/*************************************************************************/

@interface PreferencesController (Private)
- (void)setupWindow;
- (void)setupCustomizationTables;
- (void)setupMenuItems;
- (void)setupUI;
- (IBAction)changeMenus:(id)sender;
- (void)setLaunchesAtLogin:(BOOL)flag;
@end


@implementation PreferencesController


/*************************************************************************/
#pragma mark -
#pragma mark STATIC VARIABLES
/*************************************************************************/

static PreferencesController *prefs = nil;


/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION METHODS
/*************************************************************************/

+ (PreferencesController *)sharedPrefs;
{
    if (! prefs) {
        prefs = [[self alloc] init];
    }
    return prefs;
}

- (id)init
{
    if ( (self = [super init]) ) {
        ITDebugLog(@"Preferences initialized.");
        df = [[NSUserDefaults standardUserDefaults] retain];
        hotKeysArray = [[NSArray alloc] initWithObjects:@"PlayPause",
                                                       @"NextTrack",
                                                       @"PrevTrack",
                                                       @"ShowPlayer",
                                                       @"TrackInfo",
                                                       @"UpcomingSongs",
                                                       @"IncrementVolume",
                                                       @"DecrementVolume",
                                                       @"IncrementRating",
                                                       @"DecrementRating",
                                                       @"ToggleShuffle",
                                                       @"ToggleLoop",
                                                       nil];
        
        hotKeyNamesArray = [[NSArray alloc] initWithObjects:@"Play/Pause",
                                                       @"Next Track",
                                                       @"Previous Track",
                                                       @"Show Player",
                                                       @"Track Info",
                                                       @"Upcoming Songs",
                                                       @"Increment Volume",
                                                       @"Decrement Volume",
                                                       @"Increment Rating",
                                                       @"Decrement Rating",
                                                       @"Toggle Shuffle",
                                                       @"Toggle Loop",
                                                       nil];
        hotKeysDictionary = [[NSMutableDictionary alloc] init];
        controller = nil;
    }
    return self;
}


/*************************************************************************/
#pragma mark -
#pragma mark ACCESSOR METHODS
/*************************************************************************/

- (id)controller
{
    return controller;
}

- (void)setController:(id)object
{
    [controller autorelease];
    controller = [object retain];
}


/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (IBAction)showPrefsWindow:(id)sender
{
    ITDebugLog(@"Showing preferences window.");
    if (! window) {  // If window does not exist yet, then the nib hasn't been loaded.
        ITDebugLog(@"Window doesn't exist, initial setup.");
        [self setupWindow];  // Load in the nib, and perform any initial setup.
        [self setupCustomizationTables];  // Setup the DnD manu config tables.
        [self setupMenuItems];  // Setup the arrays of menu items
        [self setupUI]; // Sets up additional UI
        [window setDelegate:self];
        [menuTableView reloadData];
        [hotKeysTableView setDoubleAction:@selector(hotKeysTableViewDoubleClicked:)];
        
        //Change the launch player checkbox to the proper name
        NS_DURING
            [launchPlayerAtLaunchCheckbox setTitle:[NSString stringWithFormat:@"Launch %@ when MenuTunes launches", [[controller currentRemote] playerSimpleName]]]; //This isn't localized...
        NS_HANDLER
            [controller networkError:localException];
        NS_ENDHANDLER
    }

    [window center];
    [NSApp activateIgnoringOtherApps:YES];
    [window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.0];
}

- (IBAction)changeGeneralSetting:(id)sender
{
    ITDebugLog(@"Changing general setting of tag %i.", [sender tag]);
    if ( [sender tag] == 1010) {
        [self setLaunchesAtLogin:SENDER_STATE];
    } else if ( [sender tag] == 1020) {
        [df setBool:SENDER_STATE forKey:@"LaunchPlayerWithMT"];
    } else if ( [sender tag] == 1030) {
        [df setInteger:[sender intValue] forKey:@"SongsInAdvance"];

    } else if ( [sender tag] == 1040) {
        // This will not be executed.  Song info always shows the title of the song.
        // [df setBool:SENDER_STATE forKey:@"showName"];
    } else if ( [sender tag] == 1050) {
        [df setBool:SENDER_STATE forKey:@"showArtist"];
    } else if ( [sender tag] == 1060) {
        [df setBool:SENDER_STATE forKey:@"showAlbum"];
    } else if ( [sender tag] == 1070) {
        [df setBool:SENDER_STATE forKey:@"showTime"];
    } else if ( [sender tag] == 1080) {
        [df setBool:SENDER_STATE forKey:@"showTrackNumber"];
    } else if ( [sender tag] == 1090) {
        [df setBool:SENDER_STATE forKey:@"showTrackRating"];
    }
    [df synchronize];
}

- (IBAction)changeSharingSetting:(id)sender
{
    ITDebugLog(@"Changing sharing setting of tag %i.", [sender tag]);
    if ( [sender tag] == 5010 ) {
        BOOL state = SENDER_STATE;
        [df setBool:state forKey:@"enableSharing"];
        //Disable/enable the use of shared player options
        [useSharedMenuTunesCheckbox setEnabled:!state];
        [usePasswordCheckbox setEnabled:state];
        [passwordTextField setEnabled:state];
        [nameTextField setEnabled:state];
        [selectSharedPlayerButton setEnabled:NO];
        [controller setServerStatus:state]; //Set server status
    } else if ( [sender tag] == 5015 ) {
        [df setObject:[sender stringValue] forKey:@"sharedPlayerName"];
    } else if ( [sender tag] == 5020 ) {
        [df setBool:SENDER_STATE forKey:@"enableSharingPassword"];
    } else if ( [sender tag] == 5030 ) {
        //Set the server password
        const char *instring = [[sender stringValue] UTF8String];
        const char *password = "password";
        unsigned char *result;
        NSData *hashedPass, *passwordStringHash;
        result = SHA1(instring, strlen(instring), NULL);
        hashedPass = [NSData dataWithBytes:result length:strlen(result)];
        result = SHA1(password, strlen(password), NULL);
        passwordStringHash = [NSData dataWithBytes:result length:strlen(result)];
        if (![hashedPass isEqualToData:passwordStringHash]) {
            [df setObject:hashedPass forKey:@"sharedPlayerPassword"];
            [sender setStringValue:@"password"];
        }
    } else if ( [sender tag] == 5040 ) {
        BOOL state = SENDER_STATE;
        [df setBool:state forKey:@"useSharedPlayer"];
        //Disable/enable the use of sharing options
        [shareMenuTunesCheckbox setEnabled:!state];
        [usePasswordCheckbox setEnabled:NO];
        [passwordTextField setEnabled:NO];
        [nameTextField setEnabled:NO];
        [selectSharedPlayerButton setEnabled:state];
        
        if (state) {
            [selectedPlayerTextField setStringValue:[[[NetworkController sharedController] networkObject] serverName]];
            [locationTextField setStringValue:[[NetworkController sharedController] remoteHost]];
            [controller connectToServer];
        } else {
            [selectedPlayerTextField setStringValue:@"No shared player selected."];
            [locationTextField setStringValue:@"-"];
            [controller disconnectFromServer];
            
        }
    } else if ( [sender tag] == 5050 ) {
        //Do nothing on table view click
    } else if ( [sender tag] == 5051 ) {
        [df setObject:[sender stringValue] forKey:@"sharedPlayerHost"];
    } else if ( [sender tag] == 5060 ) {
        //Show selection sheet
        [NSApp beginSheet:selectPlayerSheet modalForWindow:window modalDelegate:self didEndSelector:NULL contextInfo:nil];
    } else if ( [sender tag] == 5100 ) {
        //Change view
        if ( ([sender indexOfItem:[sender selectedItem]] == 0) && ([selectPlayerBox contentView] != zeroConfView) ) {
            NSRect frame = [selectPlayerSheet frame];
            frame.origin.y -= 58;
            frame.size.height = 273;
            [selectPlayerBox setContentView:zeroConfView];
            [selectPlayerSheet setFrame:frame display:YES animate:YES];
        } else if ( ([sender indexOfItem:[sender selectedItem]] == 1) && ([selectPlayerBox contentView] != manualView) ){
            NSRect frame = [selectPlayerSheet frame];
            frame.origin.y += 58;
            frame.size.height = 215;
            //[window makeFirstResponder:hostTextField];
            [selectPlayerBox setContentView:manualView];
            [selectPlayerSheet setFrame:frame display:YES animate:YES];
            [hostTextField selectText:nil];
        }
    } else if ( [sender tag] == 5150 ) {
        const char *instring = [[sender stringValue] UTF8String];
        unsigned char *result;
        result = SHA1(instring, strlen(instring), NULL);
        [df setObject:[NSData dataWithBytes:result length:strlen(result)] forKey:@"connectPassword"];
    } else if ( [sender tag] == 5110 ) {
        //Cancel
        [NSApp endSheet:selectPlayerSheet];
        [selectPlayerSheet orderOut:nil];
        if ([selectPlayerBox contentView] == manualView) {
            [hostTextField setStringValue:[df stringForKey:@"sharedPlayerHost"]];
        } else {
        }
    } else if ( [sender tag] == 5120 ) {
        //OK, try to connect
        [NSApp endSheet:selectPlayerSheet];
        [selectPlayerSheet orderOut:nil];
        
        [self changeSharingSetting:clientPasswordTextField];
        
        if ([selectPlayerBox contentView] == manualView) {
            [df setObject:[hostTextField stringValue] forKey:@"sharedPlayerHost"];
        } else {
            if ([sharingTableView selectedRow] > -1) {
                [df setObject:[NSString stringWithCString:inet_ntoa((*(struct sockaddr_in*)[[[[[[NetworkController sharedController] remoteServices] objectAtIndex:[sharingTableView selectedRow]] addresses] objectAtIndex:0] bytes]).sin_addr)] forKey:@"sharedPlayerHost"];
            }
        }
        
        if ([controller connectToServer]) {
            [useSharedMenuTunesCheckbox setState:NSOnState];
            [selectedPlayerTextField setStringValue:[[[NetworkController sharedController] networkObject] serverName]];
            [locationTextField setStringValue:[[NetworkController sharedController] remoteHost]];
        } else {
            NSRunAlertPanel(@"Connection error.", @"The MenuTunes server you attempted to connect to was not responding. MenuTunes will revert back to the local player.", @"OK", nil, nil);
        }
    }
    [df synchronize];
}

- (IBAction)changeStatusWindowSetting:(id)sender
{
    StatusWindow *sw = [StatusWindow sharedWindow];
    ITDebugLog(@"Changing status window setting of tag %i", [sender tag]);
    if ( [sender tag] == 2010) {
        [df setInteger:[sender selectedRow] forKey:@"statusWindowVerticalPosition"];
        [df setInteger:[sender selectedColumn] forKey:@"statusWindowHorizontalPosition"];
        // update the window's position here
    } else if ( [sender tag] == 2020) {
        // update screen selection
    } else if ( [sender tag] == 2030) {
        int effectTag = [[sender selectedItem] tag];
        float time = ([df floatForKey:@"statusWindowAppearanceSpeed"] ? [df floatForKey:@"statusWindowAppearanceSpeed"] : 0.8);
        [df setInteger:effectTag forKey:@"statusWindowAppearanceEffect"];

        if ( effectTag == 2100 ) {
            [sw setEntryEffect:[[[ITCutWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2101 ) {
            [sw setEntryEffect:[[[ITDissolveWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2102 ) {
            [sw setEntryEffect:[[[ITSlideVerticallyWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2103 ) {
            [sw setEntryEffect:[[[ITSlideHorizontallyWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2104 ) {
            [sw setEntryEffect:[[[ITPivotWindowEffect alloc] initWithWindow:sw] autorelease]];
        }

        [[sw entryEffect] setEffectTime:time];
        
    } else if ( [sender tag] == 2040) {
        int effectTag = [[sender selectedItem] tag];
        float time = ([df floatForKey:@"statusWindowVanishSpeed"] ? [df floatForKey:@"statusWindowVanishSpeed"] : 0.8);
        
        [df setInteger:[[sender selectedItem] tag] forKey:@"statusWindowVanishEffect"];
        
        if ( effectTag == 2100 ) {
            [sw setExitEffect:[[[ITCutWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2101 ) {
            [sw setExitEffect:[[[ITDissolveWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2102 ) {
            [sw setExitEffect:[[[ITSlideVerticallyWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2103 ) {
            [sw setExitEffect:[[[ITSlideHorizontallyWindowEffect alloc] initWithWindow:sw] autorelease]];
        } else if ( effectTag == 2104 ) {
            [sw setExitEffect:[[[ITPivotWindowEffect alloc] initWithWindow:sw] autorelease]];
        }

        [[sw exitEffect] setEffectTime:time];

    } else if ( [sender tag] == 2050) {
        float newTime = (-([sender floatValue]));
        [df setFloat:newTime forKey:@"statusWindowAppearanceSpeed"];
        [[sw entryEffect] setEffectTime:newTime];
    } else if ( [sender tag] == 2060) {
        float newTime = (-([sender floatValue]));
        [df setFloat:newTime forKey:@"statusWindowVanishSpeed"];
        [[sw exitEffect] setEffectTime:newTime];
    } else if ( [sender tag] == 2070) {
        [df setFloat:[sender floatValue] forKey:@"statusWindowVanishDelay"];
        [sw setExitDelay:[sender floatValue]];
    } else if ( [sender tag] == 2080) {
        [df setBool:SENDER_STATE forKey:@"showSongInfoOnChange"];
    }
    [df synchronize];
}

- (void)registerDefaults
{
    BOOL found = NO;
    NSMutableDictionary *loginWindow;
    NSMutableArray *loginArray;
    NSEnumerator *loginEnum;
    id anItem;
    ITDebugLog(@"Registering defaults.");
    [df setObject:[NSArray arrayWithObjects:
        @"trackInfo",
        @"separator",
        @"playPause",
        @"prevTrack",
        @"nextTrack",
        @"separator",
        @"playlists",
        @"upcomingSongs",
        @"separator",
        @"preferences",
        @"quit",
        nil] forKey:@"menu"];

    [df setInteger:5 forKey:@"SongsInAdvance"];
    // [df setBool:YES forKey:@"showName"];  // Song info will always show song title.
    [df setBool:YES forKey:@"showArtist"];
    [df setBool:NO forKey:@"showAlbum"];
    [df setBool:NO forKey:@"showTime"];

    [df setInteger:2100 forKey:@"statusWindowAppearanceEffect"];
    [df setInteger:2101 forKey:@"statusWindowVanishEffect"];
    [df setFloat:0.8 forKey:@"statusWindowAppearanceSpeed"];
    [df setFloat:0.8 forKey:@"statusWindowVanishSpeed"];
    [df setFloat:4.0 forKey:@"statusWindowVanishDelay"];
    [df setBool:YES forKey:@"showSongInfoOnChange"];

    [df synchronize];
    
    loginWindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
    loginArray = [loginWindow objectForKey:@"AutoLaunchedApplicationDictionary"];
    loginEnum = [loginArray objectEnumerator];

    while ( (anItem = [loginEnum nextObject]) ) {
        if ( [[[anItem objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]] ) {
            found = YES;
        }
    }
    [loginWindow release];
    
    if (!found) {
        [[StatusWindowController sharedController] showSetupQueryWindow];
    }
}

- (void)autoLaunchOK
{
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
    
    [self setLaunchesAtLogin:YES];
}

- (void)autoLaunchCancel
{
    [[StatusWindow sharedWindow] setLocked:NO];
    [[StatusWindow sharedWindow] vanish:self];
    [[StatusWindow sharedWindow] setIgnoresMouseEvents:YES];
}

- (void)deletePressedInTableView:(NSTableView *)tableView
{
    if (tableView == menuTableView) {
        int selRow = [tableView selectedRow];
        ITDebugLog(@"Delete pressed in menu table view.");
        if (selRow != - 1) {
            NSString *object = [myItems objectAtIndex:selRow];
            
            if ([object isEqualToString:@"preferences"]) {
                NSBeep();
                return;
            }
            
            if (![object isEqualToString:@"separator"])
                [availableItems addObject:object];
            ITDebugLog(@"Removing object named %@", object);
            [myItems removeObjectAtIndex:selRow];
            [menuTableView reloadData];
            [allTableView reloadData];
        }
        [self changeMenus:self];
    }
}

/*************************************************************************/
#pragma mark -
#pragma mark HOTKEY SUPPORT METHODS
/*************************************************************************/

- (IBAction)clearHotKey:(id)sender
{
    [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:[hotKeysArray objectAtIndex:[hotKeysTableView selectedRow]]];
    [df setObject:[[ITKeyCombo clearKeyCombo] plistRepresentation] forKey:[hotKeysArray objectAtIndex:[hotKeysTableView selectedRow]]];
    [controller setupHotKeys];
    [hotKeysTableView reloadData];
}

- (IBAction)editHotKey:(id)sender
{
    ITKeyComboPanel *panel = [ITKeyComboPanel sharedPanel];
    NSString *keyComboKey = [hotKeysArray objectAtIndex:[hotKeysTableView selectedRow]];
    ITKeyCombo *keyCombo;
    
    ITDebugLog(@"Setting key combo on hot key %@.", keyComboKey);
    [controller clearHotKeys];
    [panel setKeyCombo:[hotKeysDictionary objectForKey:[hotKeysArray objectAtIndex:[hotKeysTableView selectedRow]]]];
    [panel setKeyBindingName:[hotKeyNamesArray objectAtIndex:[hotKeysTableView selectedRow]]];
    if ([panel runModal] == NSOKButton) {
        NSEnumerator *keyEnumerator = [[hotKeysDictionary allKeys] objectEnumerator];
        NSString *nextKey;
        keyCombo = [panel keyCombo];
        
        //Check for duplicate key combo
        while ( (nextKey = [keyEnumerator nextObject]) ) {
            if ([[hotKeysDictionary objectForKey:nextKey] isEqual:keyCombo] &&
                ![keyCombo isEqual:[ITKeyCombo clearKeyCombo]]) {
                [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo]
                                   forKey:nextKey];
                [df setObject:[[ITKeyCombo clearKeyCombo] plistRepresentation]
                    forKey:nextKey];
            }
        }
        
        [hotKeysDictionary setObject:keyCombo forKey:keyComboKey];
        [df setObject:[keyCombo plistRepresentation] forKey:keyComboKey];
        [controller setupHotKeys];
        [hotKeysTableView reloadData];
        ITDebugLog(@"Set combo %@ on hot key %@.", keyCombo, keyComboKey);
    } else {
        ITDebugLog(@"Hot key setting on hot key %@ cancelled.", keyComboKey);
    }
}

- (void)hotKeysTableViewDoubleClicked:(id)sender
{
    if ([sender clickedRow] > -1) {
        [self editHotKey:sender];
    }
}

/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE METHOD IMPLEMENTATIONS
/*************************************************************************/

- (void)setupWindow
{
    ITDebugLog(@"Loading Preferences.nib.");
    if (![NSBundle loadNibNamed:@"Preferences" owner:self]) {
        ITDebugLog(@"Failed to load Preferences.nib.");
        NSBeep();
        return;
    }
}

- (void)setupCustomizationTables
{
    NSImageCell *imgCell = [[[NSImageCell alloc] initImageCell:nil] autorelease];
    ITDebugLog(@"Setting up table views.");
    // Set the table view cells up
    [imgCell setImageScaling:NSScaleNone];
    [[menuTableView tableColumnWithIdentifier:@"submenu"] setDataCell:imgCell];
    [[allTableView tableColumnWithIdentifier:@"submenu"] setDataCell:imgCell];

    // Register for drag and drop
    [menuTableView registerForDraggedTypes:[NSArray arrayWithObjects:
        @"MenuTableViewPboardType",
        @"AllTableViewPboardType",
        nil]];
    [allTableView registerForDraggedTypes:[NSArray arrayWithObjects:
        @"MenuTableViewPboardType",
        @"AllTableViewPboardType",
        nil]];
}

- (void)setupMenuItems
{
    NSEnumerator *itemEnum;
    id            anItem;
    ITDebugLog(@"Setting up table view arrays.");
    // Set the list of items you can have.
    availableItems = [[NSMutableArray alloc] initWithObjects:
        @"separator",
        @"trackInfo",
        @"upcomingSongs",
        @"playlists",
        @"eqPresets",
        @"songRating",
        @"playPause",
        @"nextTrack",
        @"prevTrack",
        @"fastForward",
        @"rewind",
        @"showPlayer",
        @"quit",
        nil];
    
    // Get our preferred menu
    myItems = [[df arrayForKey:@"menu"] mutableCopy];
    
    // Delete items in the availableItems array that are already part of the menu
    itemEnum = [myItems objectEnumerator];
    while ( (anItem = [itemEnum nextObject]) ) {
        if (![anItem isEqualToString:@"separator"]) {
            [availableItems removeObject:anItem];
        }
    }
    
    // Items that show should a submenu image
    submenuItems = [[NSArray alloc] initWithObjects:
        @"upcomingSongs",
        @"playlists",
        @"eqPresets",
        @"songRating",
        nil];
}

- (void)setupUI
{
    NSMutableDictionary *loginwindow;
    NSMutableArray *loginarray;
    NSEnumerator *loginEnum, *keyArrayEnum;
    NSString *serverName;
    id anItem;
    
    ITDebugLog(@"Setting up preferences UI.");
    // Fill in the number of songs in advance to show field
    [songsInAdvance setIntValue:[df integerForKey:@"SongsInAdvance"]];
    
    // Fill hot key array
    keyArrayEnum = [hotKeysArray objectEnumerator];
    
    while ( (anItem = [keyArrayEnum nextObject]) ) {
        if ([df objectForKey:anItem]) {
            ITDebugLog(@"Setting up \"%@\" hot key.", anItem);
            [hotKeysDictionary setObject:[ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:anItem]] forKey:anItem];
        } else {
            [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:anItem];
        }
    }
    
    ITDebugLog(@"Setting up track info checkboxes.");
    // Check current track info buttons
    [albumCheckbox setState:[df boolForKey:@"showAlbum"] ? NSOnState : NSOffState];
    [nameCheckbox setState:NSOnState];  // Song info will ALWAYS show song title.
    [nameCheckbox setEnabled:NO];  // Song info will ALWAYS show song title.
    [artistCheckbox setState:[df boolForKey:@"showArtist"] ? NSOnState : NSOffState];
    [trackTimeCheckbox setState:[df boolForKey:@"showTime"] ? NSOnState : NSOffState];
    [trackNumberCheckbox setState:[df boolForKey:@"showTrackNumber"] ? NSOnState : NSOffState];
    [ratingCheckbox setState:[df boolForKey:@"showTrackRating"] ? NSOnState : NSOffState];
    
    // Set the launch at login checkbox state
    ITDebugLog(@"Setting launch at login state.");
    [df synchronize];
    loginwindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
    loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];
    
    loginEnum = [loginarray objectEnumerator];
    while ( (anItem = [loginEnum nextObject]) ) {
        if ([[[anItem objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
            [launchAtLoginCheckbox setState:NSOnState];
        }
    }
    
    // Set the launch player checkbox state
    ITDebugLog(@"Setting launch player with MenuTunes state.");
    [launchPlayerAtLaunchCheckbox setState:[df boolForKey:@"LaunchPlayerWithMT"] ? NSOnState : NSOffState];
    
    // Setup the positioning controls
    
    // Setup effects controls
    [appearanceEffectPopup selectItem:[appearanceEffectPopup itemAtIndex:[appearanceEffectPopup indexOfItemWithTag:[df integerForKey:@"statusWindowAppearanceEffect"]]]];
    [vanishEffectPopup     selectItem:[vanishEffectPopup     itemAtIndex:[vanishEffectPopup     indexOfItemWithTag:[df integerForKey:@"statusWindowVanishEffect"]]]];
    [appearanceSpeedSlider setFloatValue:-([df floatForKey:@"statusWindowAppearanceSpeed"])];
    [vanishSpeedSlider     setFloatValue:-([df floatForKey:@"statusWindowVanishSpeed"])];
    [vanishDelaySlider     setFloatValue:[df floatForKey:@"statusWindowVanishDelay"]];
    [showOnChangeCheckbox  setState:([df boolForKey:@"showSongInfoOnChange"] ? NSOnState : NSOffState)];
    
    // Setup the sharing controls
    if ([df boolForKey:@"enableSharing"]) {
        [shareMenuTunesCheckbox setState:NSOnState];
        [useSharedMenuTunesCheckbox setEnabled:NO];
        [selectSharedPlayerButton setEnabled:NO];
        [passwordTextField setEnabled:YES];
        [usePasswordCheckbox setEnabled:YES];
        [nameTextField setEnabled:YES];
    } else if ([df boolForKey:@"useSharedPlayer"]) {
        [useSharedMenuTunesCheckbox setState:NSOnState];
        [shareMenuTunesCheckbox setEnabled:NO];
        [selectSharedPlayerButton setEnabled:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:sharingTableView selector:@selector(reloadData) name:@"ITMTFoundNetService" object:nil];
    
    serverName = [df stringForKey:@"sharedPlayerName"];
    if (!serverName || [serverName length] == 0) {
        serverName = @"MenuTunes Shared Player";
    }
    [nameTextField setStringValue:serverName];
    
    [selectPlayerBox setContentView:zeroConfView];
    [usePasswordCheckbox setState:([df boolForKey:@"enableSharingPassword"] ? NSOnState : NSOffState)];
    if ([df dataForKey:@"sharedPlayerPassword"]) {
        [passwordTextField setStringValue:@"password"];
    }
    if ([df stringForKey:@"sharedPlayerHost"]) {
        [hostTextField setStringValue:[df stringForKey:@"sharedPlayerHost"]];
    }
    
    if ([[NetworkController sharedController] isConnectedToServer]) {
        [selectedPlayerTextField setStringValue:[[[NetworkController sharedController] networkObject] serverName]];
        [locationTextField setStringValue:[[NetworkController sharedController] remoteHost]];
    } else {
        [selectedPlayerTextField setStringValue:@"No shared player selected."];
        [locationTextField setStringValue:@"-"];
    }
}

- (IBAction)changeMenus:(id)sender
{
    ITDebugLog(@"Synchronizing menus");
    [df setObject:myItems forKey:@"menu"];
    [df synchronize];
}

- (void)setLaunchesAtLogin:(BOOL)flag
{
    NSMutableDictionary *loginwindow;
    NSMutableArray *loginarray;
    ITDebugLog(@"Setting launches at login: %i", flag);
    [df synchronize];
    loginwindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
    loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];
    
    if (flag) {
        NSDictionary *itemDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [[NSBundle mainBundle] bundlePath], @"Path",
        [NSNumber numberWithInt:0], @"Hide", nil];
        [loginarray addObject:itemDict];
    } else {
        int i;
        for (i = 0; i < [loginarray count]; i++) {
            NSDictionary *tempDict = [loginarray objectAtIndex:i];
            if ([[[tempDict objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
                [loginarray removeObjectAtIndex:i];
                break;
            }
        }
    }
    [df setPersistentDomain:loginwindow forName:@"loginwindow"];
    [df synchronize];
    [loginwindow release];
    ITDebugLog(@"Finished setting launches at login.");
}


/*************************************************************************/
#pragma mark -
#pragma mark NSWindow DELEGATE METHODS
/*************************************************************************/

- (void)windowWillClose:(NSNotification *)note
{
    [(MainController *)controller closePreferences]; 
}


/*************************************************************************/
#pragma mark -
#pragma mark NSTableView DATASOURCE METHODS
/*************************************************************************/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == menuTableView) {
        return [myItems count];
    } else if (aTableView == allTableView) {
        return [availableItems count];
    } else if (aTableView == hotKeysTableView) {
        return [hotKeysArray count];
    } else {
        return [[[NetworkController sharedController] remoteServices] count];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == menuTableView) {
        NSString *object = [myItems objectAtIndex:rowIndex];
        if ([[aTableColumn identifier] isEqualToString:@"name"]) {
            if ([object isEqualToString:@"showPlayer"]) {
                NSString *string;
                NS_DURING
                    string = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"show", @"Show"), [[controller currentRemote] playerSimpleName]];
                NS_HANDLER
                    [controller networkError:localException];
                NS_ENDHANDLER
                return string;
            }
            return NSLocalizedString(object, @"ERROR");
        } else {
            if ([submenuItems containsObject:object])
            {
                return [NSImage imageNamed:@"submenu"];
            } else {
                return nil;
            }
        }
    } else if (aTableView == allTableView) {
        NSString *object = [availableItems objectAtIndex:rowIndex];
        if ([[aTableColumn identifier] isEqualToString:@"name"]) {
            if ([object isEqualToString:@"showPlayer"]) {
                NSString *string;
                NS_DURING
                    string = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"show", @"Show"), [[controller currentRemote] playerSimpleName]];
                NS_HANDLER
                    [controller networkError:localException];
                NS_ENDHANDLER
                return string;
            }
            return NSLocalizedString(object, @"ERROR");
        } else {
            if ([submenuItems containsObject:object]) {
                return [NSImage imageNamed:@"submenu"];
            } else {
                return nil;
            }
        }
    } else if (aTableView == hotKeysTableView) {
        if ([[aTableColumn identifier] isEqualToString:@"name"]) {
            return [hotKeyNamesArray objectAtIndex:rowIndex];
        } else {
            return [[hotKeysDictionary objectForKey:[hotKeysArray objectAtIndex:rowIndex]] description];
        }
    } else {
        return [[[[NetworkController sharedController] remoteServices] objectAtIndex:rowIndex] name];
    }
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    if (tableView == menuTableView) {
        [pboard declareTypes:[NSArray arrayWithObjects:@"MenuTableViewPboardType", nil] owner:self];
        [pboard setString:[[rows objectAtIndex:0] stringValue] forType:@"MenuTableViewPboardType"];
        return YES;
    }
    
    if (tableView == allTableView) {
        [pboard declareTypes:[NSArray arrayWithObjects:@"AllTableViewPboardType", nil] owner:self];
        [pboard setString:[[rows objectAtIndex:0] stringValue] forType:@"AllTableViewPboardType"];
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pb;
    int dragRow;
    NSString *dragData, *temp;
    
    pb = [info draggingPasteboard];
    
    if ([[pb types] containsObject:@"MenuTableViewPboardType"]) {
        dragData = [pb stringForType:@"MenuTableViewPboardType"];
        dragRow = [dragData intValue];
        temp = [myItems objectAtIndex:dragRow];
        
        if (tableView == menuTableView) {
            [myItems insertObject:temp atIndex:row];
            if (row > dragRow) {
                [myItems removeObjectAtIndex:dragRow];
            } else {
                [myItems removeObjectAtIndex:dragRow + 1];
            }
        } else if (tableView == allTableView) {
            if (![temp isEqualToString:@"separator"]) {
                [availableItems addObject:temp];
            }
            [myItems removeObjectAtIndex:dragRow];
        }
    } else if ([[pb types] containsObject:@"AllTableViewPboardType"]) {
        dragData = [pb stringForType:@"AllTableViewPboardType"];
        dragRow = [dragData intValue];
        temp = [availableItems objectAtIndex:dragRow];
        
        [myItems insertObject:temp atIndex:row];
        
        if (![temp isEqualToString:@"separator"]) {
            [availableItems removeObjectAtIndex:dragRow];
        }
    }
    
    [menuTableView reloadData];
    [allTableView reloadData];
    [self changeMenus:self];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (tableView == allTableView) {
        if ([[[info draggingPasteboard] types] containsObject:@"AllTableViewPboardType"]) {
            return NSDragOperationNone;
        }
        
        if ([[[info draggingPasteboard] types] containsObject:@"MenuTableViewPboardType"]) {
            NSString *item = [myItems objectAtIndex:[[[info draggingPasteboard] stringForType:@"MenuTableViewPboardType"] intValue]];
            if ([item isEqualToString:@"preferences"] || [item isEqualToString:@"quit"]) {
                return NSDragOperationNone;
            }
        }
        
        [tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationGeneric;
    }
    
    if (operation == NSTableViewDropOn || row == -1)
    {
        return NSDragOperationNone;
    }
    return NSDragOperationGeneric;
}


/*************************************************************************/
#pragma mark -
#pragma mark DEALLOCATION METHODS
/*************************************************************************/

- (void)dealloc
{
    [hotKeysArray release];
    [hotKeysDictionary release];
    [menuTableView setDataSource:nil];
    [allTableView setDataSource:nil];
    [controller release];
    [availableItems release];
    [submenuItems release];
    [myItems release];
    [df release];
}

@end
