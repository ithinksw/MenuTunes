#import "PreferencesController.h"
#import "MainController.h"
#import "HotKeyCenter.h"

/*************************************************************************/
#pragma mark -
#pragma mark PRIVATE INTERFACE
/*************************************************************************/

@interface PreferencesController (Private)
- (void)setupWindow;
- (void)setupCustomizationTables;
- (void)setupMenuItems;
- (void)setupUI;
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
NSLog(@"foo");
    [controller autorelease];
    controller = [object retain];
NSLog(@"bar");
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

- (IBAction)apply:(id)sender
{
    [df setObject:myItems forKey:@"menu"];
    
    //Set key combos
    [df setKeyCombo:playPauseCombo forKey:@"PlayPause"];
    [df setKeyCombo:nextTrackCombo forKey:@"NextTrack"];
    [df setKeyCombo:prevTrackCombo forKey:@"PrevTrack"];
    [df setKeyCombo:trackInfoCombo forKey:@"TrackInfo"];
    [df setKeyCombo:upcomingSongsCombo forKey:@"UpcomingSongs"];
    
    //Set info checkboxes
    [df setBool:[albumCheckbox state] forKey:@"showAlbum"];
    [df setBool:[nameCheckbox state] forKey:@"showName"];
    [df setBool:[artistCheckbox state] forKey:@"showArtist"];
    [df setBool:[trackTimeCheckbox state] forKey:@"showTime"];
    
    //Here we set whether we will launch at login by modifying loginwindow.plist
    if ([launchAtLoginCheckbox state] == NSOnState) {
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
    
    //Set songs in advance
    if ([songsInAdvance intValue]) {
        [df setInteger:[songsInAdvance intValue] forKey:@"SongsInAdvance"];
    } else {
        [df setInteger:5 forKey:@"SongsInAdvance"];
    }
    
    /*{
        NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
        int i;
        
        for (i = 0; i < [apps count]; i++) {
            if ([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"]
                    isEqualToString:@"iTunes"]) {
                [controller rebuildMenu];
            }
        }
    }*/
    [controller clearHotKeys];
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
    
    if (string == nil) {
        string = @"";
    }
    if ([setHotKey isEqualToString:@"PlayPause"]) {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) &&
            !(([combo modifiers] == -1) && ([combo keyCode] == -1))) {
            
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        playPauseCombo = [combo copy];
        [playPauseButton setTitle:string];
    } else if ([setHotKey isEqualToString:@"NextTrack"]) {
        if (([combo isEqual:playPauseCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1))) {
            
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        nextTrackCombo = [combo copy];
        [nextTrackButton setTitle:string];
    } else if ([setHotKey isEqualToString:@"PrevTrack"]) {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:playPauseCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1))) {
            
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        prevTrackCombo = [combo copy];
        [previousTrackButton setTitle:string];
    } else if ([setHotKey isEqualToString:@"TrackInfo"]) {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:playPauseCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1))) {
            
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        trackInfoCombo = [combo copy];
        [trackInfoButton setTitle:string];
    } else if ([setHotKey isEqualToString:@"UpcomingSongs"]) {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:playPauseCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1))) {
            
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        upcomingSongsCombo = [combo copy];
        [upcomingSongsButton setTitle:string];
    }
    [self cancelHotKey:sender];
}

- (IBAction)setCurrentTrackInfo:(id)sender
{
    [self setKeyCombo:trackInfoCombo];
    [self setHotKey:@"TrackInfo"];
}

- (IBAction)setNextTrack:(id)sender
{
    [self setKeyCombo:nextTrackCombo];
    [self setHotKey:@"NextTrack"];
}

- (IBAction)setPlayPause:(id)sender
{
    [self setKeyCombo:playPauseCombo];
    [self setHotKey:@"PlayPause"];
}

- (IBAction)setPreviousTrack:(id)sender
{
    [self setKeyCombo:prevTrackCombo];
    [self setHotKey:@"PrevTrack"];
}

- (IBAction)setUpcomingSongs:(id)sender
{
    [self setKeyCombo:upcomingSongsCombo];
    [self setHotKey:@"UpcomingSongs"];
}


/*************************************************************************/
#pragma mark -
#pragma mark HOTKEY SUPPORT METHODS
/*************************************************************************/

- (void)setHotKey:(NSString *)key
{
    setHotKey = key;
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
        playPauseCombo = [df keyComboForKey:@"PlayPause"];
        [playPauseButton setTitle:[playPauseCombo userDisplayRep]];
    } else {
        playPauseCombo = [[KeyCombo alloc] init];
    }

    if ([df objectForKey:@"NextTrack"]) {
        nextTrackCombo = [df keyComboForKey:@"NextTrack"];
        [nextTrackButton setTitle:[nextTrackCombo userDisplayRep]];
    } else {
        nextTrackCombo = [[KeyCombo alloc] init];
    }

    if ([df objectForKey:@"PrevTrack"]) {
        prevTrackCombo = [df keyComboForKey:@"PrevTrack"];
        [previousTrackButton setTitle:[prevTrackCombo userDisplayRep]];
    } else {
        prevTrackCombo = [[KeyCombo alloc] init];
    }

    if ([df objectForKey:@"TrackInfo"]) {
        trackInfoCombo = [df keyComboForKey:@"TrackInfo"];
        [trackInfoButton setTitle:[trackInfoCombo userDisplayRep]];
    } else {
        trackInfoCombo = [[KeyCombo alloc] init];
    }

    if ([df objectForKey:@"UpcomingSongs"]) {
        upcomingSongsCombo = [df keyComboForKey:@"UpcomingSongs"];
        [upcomingSongsButton setTitle:[upcomingSongsCombo userDisplayRep]];
    } else {
        upcomingSongsCombo = [[KeyCombo alloc] init];
    }
    
    // Check current track info buttons
    [albumCheckbox setState:[df boolForKey:@"showAlbum"] ? NSOnState : NSOffState];
    [nameCheckbox setState:[df boolForKey:@"showName"] ? NSOnState : NSOffState];
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
            return [myItems objectAtIndex:rowIndex];
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
            if ([item isEqualToString:@"Preferences…"] || [item isEqualToString:@"Quit"]) {
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
    [playPauseCombo release];
    [nextTrackCombo release];
    [prevTrackCombo release];
    [trackInfoCombo release];
    [upcomingSongsCombo release];
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
