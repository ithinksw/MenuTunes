#import "PreferencesController.h"
#import "MainController.h"
#import "StatusWindow.h"
#import "CustomMenuTableView.h"

#import <ITKit/ITHotKeyCenter.h>
#import <ITKit/ITKeyCombo.h>
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
        [menuTableView reloadData];
        
        //Change the launch player checkbox to the proper name
        [launchPlayerAtLaunchCheckbox setTitle:[NSString stringWithFormat:@"Launch %@ when MenuTunes launches", [[controller currentRemote] playerSimpleName]]]; //This isn't localized...
    }
    
    [window setLevel:NSStatusWindowLevel];
    [window center];
    [window makeKeyAndOrderFront:self];
}

- (IBAction)changeGeneralSetting:(id)sender
{
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

- (IBAction)changeStatusWindowSetting:(id)sender
{
    StatusWindow *sw = [StatusWindow sharedWindow];

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
            NSLog(@"dflhgldf");
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

- (IBAction)changeHotKey:(id)sender
{
    [controller clearHotKeys];
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
            [self setKeyCombo:[hotKeysDictionary objectForKey:@"ShowPlayer"]];
            [self setCurrentHotKey:@"ShowPlayer"];
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
        @"playPause",
        @"prevTrack",
        @"nextTrack",
        @"fastForward",
        @"rewind",
        @"showPlayer",
        @"separator",
        @"songRating",
        @"eqPresets",
        @"playlists",
        @"upcomingSongs",
        @"separator",
        @"preferences",
        @"quit",
        @"separator",
        @"trackInfo",
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
        if (NSRunInformationalAlertPanel(NSLocalizedString(@"autolaunch", @"Auto-launch MenuTunes"), NSLocalizedString(@"autolaunch_msg", @"Would you like MenuTunes to automatically launch at login?"), @"Yes", @"No", nil) == NSOKButton) {
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
    [self setKeyCombo:[ITKeyCombo clearKeyCombo]];
}

- (IBAction)okHotKey:(id)sender
{
    NSString *string = [combo description];
    NSEnumerator *enumerator = [hotKeysDictionary keyEnumerator];
    NSString *enumKey;
    
    if (string == nil) {
        string = @"";
    }
    
    while ( (enumKey = [enumerator nextObject]) ) {
        if (![enumKey isEqualToString:currentHotKey]) {
            if (![combo isEqual:[ITKeyCombo clearKeyCombo]] &&
                 [combo isEqual:[hotKeysDictionary objectForKey:enumKey]]) {
                [window setLevel:NSNormalWindowLevel];
                if ( NSRunAlertPanel(NSLocalizedString(@"duplicateCombo", @"Duplicate Key Combo") , NSLocalizedString(@"duplicateCombo_msg", @"The specified key combo is already in use..."), NSLocalizedString(@"replace", @"Replace"), NSLocalizedString(@"cancel", @"Cancel"), nil) ) {
                    [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:currentHotKey];
                    if ([enumKey isEqualToString:@"PlayPause"]) {
                        [playPauseButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"NextTrack"]) {
                        [nextTrackButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"PrevTrack"]) {
                        [previousTrackButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"ShowPlayer"]) {
                        [showPlayerButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"TrackInfo"]) {
                        [trackInfoButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"UpcomingSongs"]) {
                        [upcomingSongsButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"IncrementVolume"]) {
                        [volumeIncrementButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"DecrementVolume"]) {
                        [volumeDecrementButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"IncrementRating"]) {
                        [ratingIncrementButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"DecrementRating"]) {
                        [ratingDecrementButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"ToggleShuffle"]) {
                        [toggleShuffleButton setTitle:@"(None)"];
                    } else if ([enumKey isEqualToString:@"ToggleLoop"]) {
                        [toggleLoopButton setTitle:@"(None)"];
                    }
                    [df setObject:[[ITKeyCombo clearKeyCombo] plistRepresentation] forKey:enumKey];
                    [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:enumKey];
                } else {
                    return;
                }
                [window setLevel:NSStatusWindowLevel];
            }
        }
    }
    
    [hotKeysDictionary setObject:combo forKey:currentHotKey];
    [df setObject:[combo plistRepresentation] forKey:currentHotKey];
    
    if ([currentHotKey isEqualToString:@"PlayPause"]) {
        [playPauseButton setTitle:string];
    } else if ([currentHotKey isEqualToString:@"NextTrack"]) {
        [nextTrackButton setTitle:string];
    } else if ([currentHotKey isEqualToString:@"PrevTrack"]) {
        [previousTrackButton setTitle:string];
    } else if ([currentHotKey isEqualToString:@"ShowPlayer"]) {
        [showPlayerButton setTitle:string];
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
    [controller setupHotKeys];
    [self cancelHotKey:sender];
}

- (void)deletePressedInTableView:(NSTableView *)tableView
{
    if (tableView == menuTableView) {
        int selRow = [tableView selectedRow];
        if (selRow != - 1) {
            NSString *object = [myItems objectAtIndex:selRow];
            
            if ([object isEqualToString:@"preferences"]) {
                NSBeep();
                return;
            }
            
            if (![object isEqualToString:@"separator"])
                [availableItems addObject:object];
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

- (void)setCurrentHotKey:(NSString *)key
{
    [currentHotKey autorelease];
    currentHotKey = [key copy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyEvent:) name:ITKeyBroadcasterKeyEvent object:nil];
    [NSApp beginSheet:keyComboPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)keyEvent:(NSNotification *)note
{
    [self setKeyCombo:[[[note userInfo] objectForKey:@"keyCombo"] copy]];
}

- (void)setKeyCombo:(ITKeyCombo *)newCombo
{
    NSString *string;
    [combo release];
    combo = [newCombo copy];
    
    string = [combo description];
    if (string == nil) {
        string = @"(None)";
    }
    [keyComboField setStringValue:string];
}


/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE METHOD IMPLEMENTATIONS
/*************************************************************************/

- (void)setupWindow
{
    if (![NSBundle loadNibNamed:@"Preferences" owner:self]) {
        NSLog(@"MenuTunes: Failed to load Preferences.nib");
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
    NSEnumerator *loginEnum;
    id anItem;
    
    // Fill in the number of songs in advance to show field
    [songsInAdvance setIntValue:[df integerForKey:@"SongsInAdvance"]];
    
    // Fill in hot key buttons
    if ([df objectForKey:@"PlayPause"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PlayPause"]];
        [hotKeysDictionary setObject:anItem forKey:@"PlayPause"];
        [playPauseButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"PlayPause"];
        [playPauseButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"NextTrack"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"NextTrack"]];
        [hotKeysDictionary setObject:anItem forKey:@"NextTrack"];
        [nextTrackButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"NextTrack"];
        [nextTrackButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"PrevTrack"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"PrevTrack"]];
        [hotKeysDictionary setObject:anItem forKey:@"PrevTrack"];
        [previousTrackButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"PrevTrack"];
        [previousTrackButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"ShowPlayer"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ShowPlayer"]];
        [hotKeysDictionary setObject:anItem forKey:@"ShowPlayer"];
        [showPlayerButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"ShowPlayer"];
        [showPlayerButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"TrackInfo"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"TrackInfo"]];
        [hotKeysDictionary setObject:anItem forKey:@"TrackInfo"];
        [trackInfoButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"TrackInfo"];
        [trackInfoButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"UpcomingSongs"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"UpcomingSongs"]];
        [hotKeysDictionary setObject:anItem forKey:@"UpcomingSongs"];
        [upcomingSongsButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"UpcomingSongs"];
        [upcomingSongsButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"IncrementVolume"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementVolume"]];
        [hotKeysDictionary setObject:anItem forKey:@"IncrementVolume"];
        [volumeIncrementButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"IncrementVolume"];
        [volumeIncrementButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"DecrementVolume"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementVolume"]];
        [hotKeysDictionary setObject:anItem forKey:@"DecrementVolume"];
        [volumeDecrementButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"DecrementVolume"];
        [volumeDecrementButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"IncrementRating"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"IncrementRating"]];
        [hotKeysDictionary setObject:anItem forKey:@"IncrementRating"];
        [ratingIncrementButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"IncrementRating"];
        [ratingIncrementButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"DecrementRating"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"DecrementRating"]];
        [hotKeysDictionary setObject:anItem forKey:@"DecrementRating"];
        [ratingDecrementButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"DecrementRating"];
        [ratingDecrementButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"ToggleLoop"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleLoop"]];
        [hotKeysDictionary setObject:anItem forKey:@"ToggleLoop"];
        [toggleLoopButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"ToggleLoop"];
        [toggleLoopButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    if ([df objectForKey:@"ToggleShuffle"]) {
        anItem = [ITKeyCombo keyComboWithPlistRepresentation:[df objectForKey:@"ToggleShuffle"]];
        [hotKeysDictionary setObject:anItem forKey:@"ToggleShuffle"];
        [toggleShuffleButton setTitle:[anItem description]];
    } else {
        [hotKeysDictionary setObject:[ITKeyCombo clearKeyCombo] forKey:@"ToggleShuffle"];
        [toggleShuffleButton setTitle:[[ITKeyCombo clearKeyCombo] description]];
    }
    
    // Check current track info buttons
    [albumCheckbox setState:[df boolForKey:@"showAlbum"] ? NSOnState : NSOffState];
    [nameCheckbox setState:NSOnState];  // Song info will ALWAYS show song title.
    [nameCheckbox setEnabled:NO];  // Song info will ALWAYS show song title.
    [artistCheckbox setState:[df boolForKey:@"showArtist"] ? NSOnState : NSOffState];
    [trackTimeCheckbox setState:[df boolForKey:@"showTime"] ? NSOnState : NSOffState];
    [trackNumberCheckbox setState:[df boolForKey:@"showTrackNumber"] ? NSOnState : NSOffState];
    [ratingCheckbox setState:[df boolForKey:@"showTrackRating"] ? NSOnState : NSOffState];
    
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
    NSMutableDictionary *loginwindow;
    NSMutableArray *loginarray;
    
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
                return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"show", @"Show"), [[controller currentRemote] playerSimpleName]];
            }
            return NSLocalizedString(object, @"ERROR");
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
            return NSLocalizedString([availableItems objectAtIndex:rowIndex], @"ERROR");
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
        
        if (tableView == menuTableView) {
            [myItems insertObject:temp atIndex:row];
            if (row > dragRow) {
                [myItems removeObjectAtIndex:dragRow];
            } else {
                [myItems removeObjectAtIndex:dragRow + 1];
            }
        } else {
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
            if ([item isEqualToString:@"preferences"]) {
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
