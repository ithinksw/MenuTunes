#import "PreferencesController.h"
#import "MainController.h"
#import "HotKeyCenter.h"
#import <ITKit/ITWindowPositioning.h>

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
        df = [[NSUserDefaults standardUserDefaults] retain];
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
    if (! window) {  // If window does not exist yet, then the nib hasn't been loaded.
        [self setupWindow];  // Load in the nib, and perform any initial setup.
        [self setupCustomizationTables];  // Setup the DnD manu config tables.
        [self setupMenuItems];  // Setup the arrays of menu items
        [self setupUI]; // Sets up additional UI
        [window setDelegate:self];
    }
    
    [window setLevel:NSStatusWindowLevel];
    [window center];
    [window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)changeGeneralSetting:(id)sender
{
    BOOL rebuildRequired = NO;

    if ( [sender tag] == 1010) {
        [self setLaunchesAtLogin:SENDER_STATE];
    } else if ( [sender tag] == 1020) {
        [df setBool:SENDER_STATE forKey:@"LaunchPlayerWithMT"];
    } else if ( [sender tag] == 1030) {
        [df setInteger:[sender intValue] forKey:@"SongsInAdvance"];
        rebuildRequired = YES;
    } else if ( [sender tag] == 1040) {
        // This will not be executed.  Song info always shows the title of the song.
        // [df setBool:SENDER_STATE forKey:@"showName"];
        // rebuildRequired = YES;
    } else if ( [sender tag] == 1050) {
        [df setBool:SENDER_STATE forKey:@"showArtist"];
        rebuildRequired = YES;
    } else if ( [sender tag] == 1060) {
        [df setBool:SENDER_STATE forKey:@"showAlbum"];
        rebuildRequired = YES;
    } else if ( [sender tag] == 1070) {
        [df setBool:SENDER_STATE forKey:@"showTime"];
        rebuildRequired = YES;
    } else if ( [sender tag] == 1080) {
        [df setBool:SENDER_STATE forKey:@"showTrackNumber"];
        rebuildRequired = YES;
    } else if ( [sender tag] == 1090) {
        [df setBool:SENDER_STATE forKey:@"showTrackRating"];
        rebuildRequired = YES;
    }

    if ( rebuildRequired ) {
        //[controller rebuildMenu];
        // redraw song info status window, or upcoming songs here
    }

    [df synchronize];
}

- (IBAction)changeStatusWindowSetting:(id)sender
{
    if ( [sender tag] == 2010) {
        [df setInteger:[sender selectedRow] forKey:@"statusWindowVerticalPosition"];
        [df setInteger:[sender selectedColumn] forKey:@"statusWindowHorizontalPosition"];
        // update the window's position here
    } else if ( [sender tag] == 2020) {
        // update screen selection
    } else if ( [sender tag] == 2030) {
        // Update appearance effect
    } else if ( [sender tag] == 2040) {
        // Update Vanish Effect
    } else if ( [sender tag] == 2050) {
        // Update appearance speed
    } else if ( [sender tag] == 2060) {
        // Update vanish speed
    } else if ( [sender tag] == 2070) {
        // Update vanish delay
    } else if ( [sender tag] == 2080) {
        // Update "Song Info window when song changes" setting.
        [df setBool:SENDER_STATE forKey:@"showSongInfoOnChange"];
    }
}

- (IBAction)changeHotKey:(id)sender
{
    switch ([sender tag])
    {
        case 4010:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"PlayPause"]];
            [self setCurrentHotKey:@"PlayPause"];
            break;
        case 4020:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"NextTrack"]];
            [self setCurrentHotKey:@"NextTrack"];
            break;
        case 4030:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"PrevTrack"]];
            [self setCurrentHotKey:@"PrevTrack"];
            break;
        case 4035:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"ToggleVisualizer"]];
            [self setCurrentHotKey:@"ToggleVisualizer"];
            break;
        case 4040:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"ToggleLoop"]];
            [self setCurrentHotKey:@"ToggleLoop"];
            break;
        case 4050:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"ToggleShuffle"]];
            [self setCurrentHotKey:@"ToggleShuffle"];
            break;
        case 4060:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"TrackInfo"]];
            [self setCurrentHotKey:@"TrackInfo"];
            break;
        case 4070:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"UpcomingSongs"]];
            [self setCurrentHotKey:@"UpcomingSongs"];
            break;
        case 4080:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"IncrementVolume"]];
            [self setCurrentHotKey:@"IncrementVolume"];
            break;
        case 4090:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"DecrementVolume"]];
            [self setCurrentHotKey:@"DecrementVolume"];
            break;
        case 4100:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"IncrementRating"]];
            [self setCurrentHotKey:@"IncrementRating"];
            break;
        case 4110:
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"DecrementRating"]];
            [self setCurrentHotKey:@"DecrementRating"];
            break;
    }
}

- (void)registerDefaults
{
    BOOL found = NO;
    NSMutableDictionary *loginWindow;
    NSMutableArray *loginArray;
    NSEnumerator *loginEnum;
    id anItem;

    [df setObject:[NSArray arrayWithObjects:
        @"Play/Pause",
        @"Next Track",
        @"Previous Track",
        @"Fast Forward",
        @"Rewind",
        @"Show Player",
        @"<separator>",
        @"Upcoming Songs",
        @"Playlists",
        @"Song Rating",
        @"<separator>",
        @"Preferences",
        @"Quit",
        @"<separator>",
        @"Current Track Info",
        nil] forKey:@"menu"];

    [df setInteger:5 forKey:@"SongsInAdvance"];
    // [df setBool:YES forKey:@"showName"];  // Song info will always show song title.
    [df setBool:YES forKey:@"showArtist"];
    [df setBool:NO forKey:@"showAlbum"];
    [df setBool:NO forKey:@"showTime"];

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
    
    // This is teh sux
    // We must fix it so it is no longer suxy
    if (!found) {
        if (NSRunInformationalAlertPanel(@"Auto-launch MenuTunes", @"Would you like MenuTunes to automatically launch at login?", @"Yes", @"No", nil) == NSOKButton) {
            AEDesc scriptDesc, resultDesc;
            NSString *script = [NSString stringWithFormat:@"tell application \"System Events\"\nmake new login item at end of login items with properties {path:\"%@\", kind:\"APPLICATION\"}\nend tell", [[NSBundle mainBundle] bundlePath]];
            ComponentInstance asComponent = OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype);

            AECreateDesc(typeChar, [script cString], [script cStringLength],
                         &scriptDesc);

            OSADoScript(asComponent, &scriptDesc, kOSANullScript, typeChar, kOSAModeCanInteract, &resultDesc);

            AEDisposeDesc(&scriptDesc);
            AEDisposeDesc(&resultDesc);

            CloseComponent(asComponent);
        }
    }
}

- (IBAction)cancelHotKey:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSApp endSheet:keyComboPanel];
    [keyComboPanel orderOut:nil];
}

- (IBAction)clearHotKey:(id)sender
{
    [self setKeyCombo:[KeyCombo clearKeyCombo]];
}

- (IBAction)okHotKey:(id)sender
{
    NSString *string = [combo userDisplayRep];
    NSEnumerator *enumerator = [hotKeysDictionary keyEnumerator];
    NSString *enumKey;
    BOOL duplicateCombo = NO;
    
    if (string == nil) {
        string = @"";
    }
    
    while ( (enumKey = [enumerator nextObject]) ) {
        if (![enumKey isEqualToString:currentHotKey]) {
            if (![combo isEqual:[KeyCombo clearKeyCombo]] &&
                 [combo isEqual:[hotKeysDictionary objectForKey:enumKey]]) {
                [window setLevel:NSNormalWindowLevel];
                if ( NSRunAlertPanel(@"Duplicate Key Combo", @"The specified key combo is already in use...", @"Replace", @"Cancel", nil) ) {
                    [hotKeysDictionary setObject:[KeyCombo clearKeyCombo] forKey:currentHotKey];
                    if ([enumKey isEqualToString:@"PlayPause"]) {
                        [playPauseButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"NextTrack"]) {
                        [nextTrackButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"PrevTrack"]) {
                        [previousTrackButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"ToggleVisualizer"]) {
                        [visualizerButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"TrackInfo"]) {
                        [trackInfoButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"UpcomingSongs"]) {
                        [upcomingSongsButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"IncrementVolume"]) {
                        [volumeIncrementButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"DecrementVolume"]) {
                        [volumeDecrementButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"IncrementRating"]) {
                        [ratingIncrementButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"DecrementRating"]) {
                        [ratingDecrementButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"ToggleShuffle"]) {
                        [toggleShuffleButton setTitle:@""];
                    } else if ([enumKey isEqualToString:@"ToggleLoop"]) {
                        [toggleLoopButton setTitle:@""];
                    }
                    [df setKeyCombo:[KeyCombo clearKeyCombo] forKey:enumKey];
                } else {
                    return;
                }
                [window setLevel:NSStatusWindowLevel];
            }
        }
    }
    
    if (!duplicateCombo) {
        [hotKeysDictionary setObject:combo forKey:currentHotKey];
        [df setKeyCombo:combo forKey:currentHotKey];
        
        if ([currentHotKey isEqualToString:@"PlayPause"]) {
            [playPauseButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"NextTrack"]) {
            [nextTrackButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"PrevTrack"]) {
            [previousTrackButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"ToggleVisualizer"]) {
            [visualizerButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"TrackInfo"]) {
            [trackInfoButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"UpcomingSongs"]) {
            [upcomingSongsButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"IncrementVolume"]) {
            [volumeIncrementButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"DecrementVolume"]) {
            [volumeDecrementButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"IncrementRating"]) {
            [ratingIncrementButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"DecrementRating"]) {
            [ratingDecrementButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"ToggleShuffle"]) {
            [toggleShuffleButton setTitle:string];
        } else if ([currentHotKey isEqualToString:@"ToggleLoop"]) {
            [toggleLoopButton setTitle:string];
        }
    }
    [self cancelHotKey:sender];
}



/*************************************************************************/
#pragma mark -
#pragma mark HOTKEY SUPPORT METHODS
/*************************************************************************/

- (void)setCurrentHotKey:(NSString *)key
{
    [currentHotKey autorelease];
    currentHotKey = [key copy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyEvent:) name:@"KeyBroadcasterEvent" object:nil];
    [NSApp beginSheet:keyComboPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)keyEvent:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];
    short keyCode;
    long modifiers;
    KeyCombo *newCombo;
    
    keyCode = [[info objectForKey:@"KeyCode"] shortValue];
    modifiers = [[info objectForKey:@"Modifiers"] longValue];
    
    newCombo = [[KeyCombo alloc] initWithKeyCode:keyCode andModifiers:modifiers];
    [self setKeyCombo:newCombo];
}

- (void)setKeyCombo:(KeyCombo *)newCombo
{
    NSString *string;
    [combo release];
    combo = [newCombo copy];
    
    string = [combo userDisplayRep];
    if (string == nil) {
        string = @"";
    }
    [keyComboField setStringValue:string];
}


/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE METHOD IMPLEMENTATIONS
/*************************************************************************/

- (void)setupWindow
{
    if ( ! [NSBundle loadNibNamed:@"Preferences" owner:self] ) {
        NSLog( @"Failed to load Preferences.nib" );
        NSBeep();
        return;
    }
}

- (void)setupCustomizationTables
{
    NSImageCell *imgCell = [[[NSImageCell alloc] initImageCell:nil] autorelease];
    
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
    // Set the list of items you can have.
    availableItems = [[NSMutableArray alloc] initWithObjects:
        @"Current Track Info",
        @"Upcoming Songs",
        @"Playlists",
        @"EQ Presets",
        @"Song Rating",
        @"Play/Pause",
        @"Next Track",
        @"Previous Track",
        @"Fast Forward",
        @"Rewind",
        @"Show Player",
        @"<separator>",
        nil];
    
    // Get our preferred menu
    myItems = [[df arrayForKey:@"menu"] mutableCopy];
    
    // Delete items in the availableItems array that are already part of the menu
    itemEnum = [myItems objectEnumerator];
    while ( (anItem = [itemEnum nextObject]) ) {
        if ( ! [anItem isEqualToString:@"<separator>"] ) {
            [availableItems removeObject:anItem];
        }
    }
    
    // Items that show should a submenu image
    submenuItems = [[NSArray alloc] initWithObjects:
        @"Upcoming Songs",
        @"Playlists",
        @"EQ Presets",
        @"Song Rating",
        nil];
}

- (void)setupUI
{
    NSMutableDictionary *loginwindow;
    NSMutableArray *loginarray;
    NSEnumerator *loginEnum;
    id anItem;
    
    // Fill in the number of songs in advance to show field
    [songsInAdvance setIntValue:[df integerForKey:@"SongsInAdvance"]];
    
    // Fill in hot key buttons
    if ([df objectForKey:@"PlayPause"]){
        anItem = [df keyComboForKey:@"PlayPause"];
        [hotKeysDictionary setObject:anItem forKey:@"PlayPause"];
        [playPauseButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"PlayPause"];
    }
    
    if ([df objectForKey:@"NextTrack"]) {
        anItem = [df keyComboForKey:@"NextTrack"];
        [hotKeysDictionary setObject:anItem forKey:@"NextTrack"];
        [nextTrackButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"NextTrack"];
    }
    
    if ([df objectForKey:@"PrevTrack"]) {
        anItem = [df keyComboForKey:@"PrevTrack"];
        [hotKeysDictionary setObject:anItem forKey:@"PrevTrack"];
        [previousTrackButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"PrevTrack"];
    }
    
    if ([df objectForKey:@"ToggleVisualizer"]) {
        anItem = [df keyComboForKey:@"ToggleVisualizer"];
        [hotKeysDictionary setObject:anItem forKey:@"ToggleVisualizer"];
        [visualizerButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"ToggleVisualizer"];
    }
    
    if ([df objectForKey:@"TrackInfo"]) {
        anItem = [df keyComboForKey:@"TrackInfo"];
        [hotKeysDictionary setObject:anItem forKey:@"TrackInfo"];
        [trackInfoButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"TrackInfo"];
    }
    
    if ([df objectForKey:@"UpcomingSongs"]) {
        anItem = [df keyComboForKey:@"UpcomingSongs"];
        [hotKeysDictionary setObject:anItem forKey:@"UpcomingSongs"];
        [upcomingSongsButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"UpcomingSongs"];
    }
    
    if ([df objectForKey:@"IncrementVolume"]) {
        anItem = [df keyComboForKey:@"IncrementVolume"];
        [hotKeysDictionary setObject:anItem forKey:@"IncrementVolume"];
        [volumeIncrementButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"IncrementVolume"];
    }
    
    if ([df objectForKey:@"DecrementVolume"]) {
        anItem = [df keyComboForKey:@"DecrementVolume"];
        [hotKeysDictionary setObject:anItem forKey:@"DecrementVolume"];
        [volumeDecrementButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"DecrementVolume"];
    }
    
    if ([df objectForKey:@"IncrementRating"]) {
        anItem = [df keyComboForKey:@"IncrementRating"];
        [hotKeysDictionary setObject:anItem forKey:@"IncrementRating"];
        [ratingIncrementButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"IncrementRating"];
    }
    
    if ([df objectForKey:@"DecrementRating"]) {
        anItem = [df keyComboForKey:@"DecrementRating"];
        [hotKeysDictionary setObject:anItem forKey:@"DecrementRating"];
        [ratingDecrementButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"DecrementRating"];
    }
    
    if ([df objectForKey:@"ToggleLoop"]) {
        anItem = [df keyComboForKey:@"ToggleLoop"];
        [hotKeysDictionary setObject:anItem forKey:@"ToggleLoop"];
        [toggleLoopButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"ToggleLoop"];
    }
    
    if ([df objectForKey:@"ToggleShuffle"]) {
        anItem = [df keyComboForKey:@"ToggleShuffle"];
        [hotKeysDictionary setObject:anItem forKey:@"ToggleShuffle"];
        [toggleShuffleButton setTitle:[anItem userDisplayRep]];
    } else {
        [hotKeysDictionary setObject:[KeyCombo keyCombo] forKey:@"ToggleShuffle"];
    }
    
    // Check current track info buttons
    [albumCheckbox setState:[df boolForKey:@"showAlbum"] ? NSOnState : NSOffState];
    [nameCheckbox setState:NSOnState];  // Song info will ALWAYS show song title.
    [nameCheckbox setEnabled:NO];  // Song info will ALWAYS show song title.
    [artistCheckbox setState:[df boolForKey:@"showArtist"] ? NSOnState : NSOffState];
    [trackTimeCheckbox setState:[df boolForKey:@"showTime"] ? NSOnState : NSOffState];
    
    // Set the launch at login checkbox state
    [df synchronize];
    loginwindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
    loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];
    
    loginEnum = [loginarray objectEnumerator];
    while ( (anItem = [loginEnum nextObject]) ) {
        if ([[[anItem objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
            [launchAtLoginCheckbox setState:NSOnState];
        }
    }
}

- (IBAction)changeMenus:(id)sender
{
    [df setObject:myItems forKey:@"menu"];
    [df synchronize];
}

- (void)setLaunchesAtLogin:(BOOL)flag
{
    if ( flag ) {
        NSMutableDictionary *loginwindow;
        NSMutableArray *loginarray;
        ComponentInstance temp = OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype);;
        int i;
        BOOL skip = NO;

        [df synchronize];
        loginwindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
        loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];

        for (i = 0; i < [loginarray count]; i++) {
            NSDictionary *tempDict = [loginarray objectAtIndex:i];
            if ([[[tempDict objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
                skip = YES;
            }
        }

        if (!skip) {
            AEDesc scriptDesc, resultDesc;
            NSString *script = [NSString stringWithFormat:@"tell application \"System Events\"\nmake new login item at end of login items with properties {path:\"%@\", kind:\"APPLICATION\"}\nend tell", [[NSBundle mainBundle] bundlePath]];

            AECreateDesc(typeChar, [script cString], [script cStringLength],
                         &scriptDesc);

            OSADoScript(temp, &scriptDesc, kOSANullScript, typeChar, kOSAModeCanInteract, &resultDesc);

            AEDisposeDesc(&scriptDesc);
            AEDisposeDesc(&resultDesc);
            CloseComponent(temp);
        }

    } else {
        NSMutableDictionary *loginwindow;
        NSMutableArray *loginarray;
        int i;

        [df synchronize];
        loginwindow = [[df persistentDomainForName:@"loginwindow"] mutableCopy];
        loginarray = [loginwindow objectForKey:@"AutoLaunchedApplicationDictionary"];

        for (i = 0; i < [loginarray count]; i++) {
            NSDictionary *tempDict = [loginarray objectAtIndex:i];
            if ([[[tempDict objectForKey:@"Path"] lastPathComponent] isEqualToString:[[[NSBundle mainBundle] bundlePath] lastPathComponent]]) {
                [loginarray removeObjectAtIndex:i];
                [df setPersistentDomain:loginwindow forName:@"loginwindow"];
                [df synchronize];
                break;
            }
        }
    }
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
    } else {
        return [availableItems count];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == menuTableView) {
        if ([[aTableColumn identifier] isEqualToString:@"name"]) {
            NSString *object = [myItems objectAtIndex:rowIndex];
            if ([object isEqualToString:@"Show Player"]) {
                return [NSString stringWithFormat:@"Show %@", [[controller currentRemote] playerSimpleName]];
            }
            return object;
        } else {
            if ([submenuItems containsObject:[myItems objectAtIndex:rowIndex]])
            {
                return [NSImage imageNamed:@"submenu"];
            } else {
                return nil;
            }
        }
    } else {
        if ([[aTableColumn identifier] isEqualToString:@"name"]) {
            return [availableItems objectAtIndex:rowIndex];
        } else {
            if ([submenuItems containsObject:[availableItems objectAtIndex:rowIndex]]) {
                return [NSImage imageNamed:@"submenu"];
            } else {
                return nil;
            }
        }
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
        [myItems removeObjectAtIndex:dragRow];
        
        if (tableView == menuTableView) {
            if (row > dragRow) {
                [myItems insertObject:temp atIndex:row - 1];
            } else {
                [myItems insertObject:temp atIndex:row];
            }
        } else {
            if (![temp isEqualToString:@"<separator>"]) {
                [availableItems addObject:temp];
            }
        }
    } else if ([[pb types] containsObject:@"AllTableViewPboardType"]) {
        dragData = [pb stringForType:@"AllTableViewPboardType"];
        dragRow = [dragData intValue];
        temp = [availableItems objectAtIndex:dragRow];
        
        if (![temp isEqualToString:@"<separator>"]) {
            [availableItems removeObjectAtIndex:dragRow];
        }
        [myItems insertObject:temp atIndex:row];
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
            if ([item isEqualToString:@"Preferences"] || [item isEqualToString:@"Quit"]) {
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
    [self setKeyCombo:nil];
    [hotKeysDictionary release];
    [keyComboPanel release];
    [menuTableView setDataSource:nil];
    [allTableView setDataSource:nil];
    [controller release];
    [availableItems release];
    [submenuItems release];
    [myItems release];
    [df release];
}


@end
