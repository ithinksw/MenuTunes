#import "PreferencesController.h"
#import "MenuTunes.h"
#import "HotKeyCenter.h"

@implementation PreferencesController

- (id)initWithMenuTunes:(MenuTunes *)tunes;
{
    if ( (self = [super init]) )
    {
        int i;
        NSImageCell *imgCell = [[[NSImageCell alloc] init] autorelease];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *temp;
        
        mt = [tunes retain];
        
        //Load the nib
        [NSBundle loadNibNamed:@"Preferences" owner:self];
        
        //Show our window
        [window setLevel:NSStatusWindowLevel];
        [window center];
        [window makeKeyAndOrderFront:nil];
        
        //Set the table view cells up
        [imgCell setImageScaling:NSScaleNone];
        [[menuTableView tableColumnWithIdentifier:@"submenu"] setDataCell:imgCell];
        [[allTableView tableColumnWithIdentifier:@"submenu"] setDataCell:imgCell];
        
        //Register for drag and drop
        [menuTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"MenuTableViewPboardType", @"AllTableViewPboardType", nil]];
        [allTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"MenuTableViewPboardType", @"AllTableViewPboardType", nil]];
        
        //Set the list of items you can have.
        availableItems = [[NSMutableArray alloc] initWithObjects:@"Current Track Info",  @"Upcoming Songs", @"Playlists", @"Play/Pause", @"Next Track", @"Previous Track", @"Fast Forward", @"Rewind", @"<separator>", nil];
        
        //Get our preferred menu
        myItems = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"] mutableCopy];
        if (myItems == nil)
        {
            myItems = [[NSMutableArray alloc] initWithObjects:@"Play/Pause", @"Next Track", @"Previous Track", @"Fast Forward", @"Rewind", @"<separator>", @"Upcoming Songs", @"Playlists", @"<separator>", @"Preferences…", @"Quit", @"<separator>", @"Current Track Info", nil];
            [[NSUserDefaults standardUserDefaults] setObject:myItems forKey:@"menu"];
        }
        
        //Delete items in the availableItems array that are already part of the menu
        for (i = 0; i < [myItems count]; i++)
        {
            NSString *item = [myItems objectAtIndex:i];
            if (![item isEqualToString:@"<separator>"])
            {
                [availableItems removeObject:item];
            }
        }
        
        //Items that show should a submenu image
        submenuItems = [[NSArray alloc] initWithObjects:@"Upcoming Songs", @"Playlists", nil];
        
        //Fill in the number of songs in advance to show field
        if ([defaults integerForKey:@"SongsInAdvance"])
        {
            [songsInAdvance setIntValue:[defaults integerForKey:@"SongsInAdvance"]];
        }
        else
        {
            [songsInAdvance setIntValue:5];
        }
        
        //Fill in hot key buttons
        if ([defaults objectForKey:@"PlayPause"])
        {
            playPauseCombo = [defaults keyComboForKey:@"PlayPause"];
            [playPauseButton setTitle:[playPauseCombo userDisplayRep]];
        }
        else
        {
            playPauseCombo = [[KeyCombo alloc] init];
        }
        
        if ([defaults objectForKey:@"NextTrack"])
        {
            nextTrackCombo = [defaults keyComboForKey:@"NextTrack"];
            [nextTrackButton setTitle:[nextTrackCombo userDisplayRep]];
        }
        else
        {
            nextTrackCombo = [[KeyCombo alloc] init];
        }
        
        if ([defaults objectForKey:@"PrevTrack"])
        {
            prevTrackCombo = [defaults keyComboForKey:@"PrevTrack"];
            [previousTrackButton setTitle:[prevTrackCombo userDisplayRep]];
        }
        else
        {
            prevTrackCombo = [[KeyCombo alloc] init];
        }
        
        if ([defaults objectForKey:@"TrackInfo"])
        {
            trackInfoCombo = [defaults keyComboForKey:@"TrackInfo"];
            [trackInfoButton setTitle:[trackInfoCombo userDisplayRep]];
        }
        else
        {
            trackInfoCombo = [[KeyCombo alloc] init];
        }
        
        if ([defaults objectForKey:@"UpcomingSongs"])
        {
            upcomingSongsCombo = [defaults keyComboForKey:@"UpcomingSongs"];
            [upcomingSongsButton setTitle:[upcomingSongsCombo userDisplayRep]];
        }
        else
        {
            upcomingSongsCombo = [[KeyCombo alloc] init];
        }
        
        //Check current track info buttons
        
        //Album and name get special treatment because they are defaults
        if ( (temp = [defaults stringForKey:@"showAlbum"]) )
        {
            if ((temp == nil) || [temp isEqualToString:@"1"])
            {
                [albumCheckbox setState:NSOnState];
            }
            else
            {
                [albumCheckbox setState:NSOffState];
            }
        }
        
        if ( (temp = [defaults stringForKey:@"showName"]) )
        {
            if ((temp == nil) || [temp isEqualToString:@"1"])
            {
                [nameCheckbox setState:NSOnState];
            }
            else
            {
                [nameCheckbox setState:NSOffState];
            }
        }
        
        [artistCheckbox setState:[defaults boolForKey:@"showArtist"] ? NSOnState : NSOffState];
        [songRatingCheckbox setState:[defaults boolForKey:@"showRating"] ? NSOnState : NSOffState];
        [trackNumberCheckbox setState:[defaults boolForKey:@"showTrackNum"] ? NSOnState : NSOffState];
        [trackTimeCheckbox setState:[defaults boolForKey:@"showTime"] ? NSOnState : NSOffState];
        [yearCheckbox setState:[defaults boolForKey:@"showYear"] ? NSOnState : NSOffState];
    }
    return self;
}

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
    [mt release];
    [availableItems release];
    [submenuItems release];
    [myItems release];
}

- (IBAction)apply:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:myItems forKey:@"menu"];
    
    //Set key combos
    [defaults setKeyCombo:playPauseCombo forKey:@"PlayPause"];
    [defaults setKeyCombo:nextTrackCombo forKey:@"NextTrack"];
    [defaults setKeyCombo:prevTrackCombo forKey:@"PrevTrack"];
    [defaults setKeyCombo:trackInfoCombo forKey:@"TrackInfo"];
    [defaults setKeyCombo:upcomingSongsCombo forKey:@"UpcomingSongs"];
    
    //Set info checkboxes
    [defaults setBool:[albumCheckbox state] forKey:@"showAlbum"];
    [defaults setBool:[nameCheckbox state] forKey:@"showName"];
    [defaults setBool:[artistCheckbox state] forKey:@"showArtist"];
    [defaults setBool:[songRatingCheckbox state] forKey:@"showRating"];
    [defaults setBool:[trackNumberCheckbox state] forKey:@"showTrackNum"];
    [defaults setBool:[trackTimeCheckbox state] forKey:@"showTime"];
    [defaults setBool:[yearCheckbox state] forKey:@"showYear"];
    
    //Set songs in advance
    if ([songsInAdvance intValue])
    {
        [defaults setInteger:[songsInAdvance intValue] forKey:@"SongsInAdvance"];
    }
    else
    {
        [defaults setInteger:5 forKey:@"SongsInAdvance"];
    }
    
    [mt rebuildMenu];
    [mt clearHotKeys];
}

- (IBAction)cancel:(id)sender
{
    [window close];
    [mt closePreferences];
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
    NSString *string;
    if (([combo modifiers] <= 0) && ([combo keyCode] >= 0))
    {
        [window setLevel:NSNormalWindowLevel];
        NSRunAlertPanel(@"Bad Key Combo", @"Please enter a valid key combo. A valid combo must have a modifier key in it. (Command, option, shift, control).", @"OK", nil, nil, nil);
        [window setLevel:NSStatusWindowLevel];
        return;
    }
    
    string = [combo userDisplayRep];
    
    if (string == nil)
    {
        string = @"None";
    }
    if ([setHotKey isEqualToString:@"PlayPause"])
    {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1)))
        {
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        playPauseCombo = [combo copy];
        [playPauseButton setTitle:string];
    }
    else if ([setHotKey isEqualToString:@"NextTrack"])
    {
        if (([combo isEqual:playPauseCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1)))
        {
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        nextTrackCombo = [combo copy];
        [nextTrackButton setTitle:string];
    }
    else if ([setHotKey isEqualToString:@"PrevTrack"])
    {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:playPauseCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1)))
        {
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        prevTrackCombo = [combo copy];
        [previousTrackButton setTitle:string];
    }
    else if ([setHotKey isEqualToString:@"TrackInfo"])
    {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:playPauseCombo] || [combo isEqual:upcomingSongsCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1)))
        {
            [window setLevel:NSNormalWindowLevel];
            NSRunAlertPanel(@"Duplicate Key Combo", @"Please choose a unique key combo.", @"OK", nil, nil, nil);
            [window setLevel:NSStatusWindowLevel];
            return;
        }
        trackInfoCombo = [combo copy];
        [trackInfoButton setTitle:string];
    }
    else if ([setHotKey isEqualToString:@"UpcomingSongs"])
    {
        if (([combo isEqual:nextTrackCombo] || [combo isEqual:prevTrackCombo] ||
            [combo isEqual:trackInfoCombo] || [combo isEqual:playPauseCombo]) && 
            !(([combo modifiers] == -1) && ([combo keyCode] == -1)))
        {
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

- (IBAction)save:(id)sender
{
    [self apply:nil];
    [window close];
    [mt closePreferences];
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
    if (string == nil)
    {
        string = @"";
    }
    [keyComboField setStringValue:string];
}

//
//
// Table View Datasource Methods
//
//

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == menuTableView)
    {
        return [myItems count];
    }
    else
    {
        return [availableItems count];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == menuTableView)
    {
        if ([[aTableColumn identifier] isEqualToString:@"name"])
        {
            return [myItems objectAtIndex:rowIndex];
        }
        else
        {
            if ([submenuItems containsObject:[myItems objectAtIndex:rowIndex]])
            {
                return [NSImage imageNamed:@"submenu"];
            }
            else
            {
                return nil;
            }
        }
    }
    else
    {
        if ([[aTableColumn identifier] isEqualToString:@"name"])
        {
            return [availableItems objectAtIndex:rowIndex];
        }
        else
        {
            if ([submenuItems containsObject:[availableItems objectAtIndex:rowIndex]])
            {
                return [NSImage imageNamed:@"submenu"];
            }
            else
            {
                return nil;
            }
        }
    }
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    if (tableView == menuTableView)
    {
        [pboard declareTypes:[NSArray arrayWithObjects:@"MenuTableViewPboardType", nil] owner:self];
        [pboard setString:[[rows objectAtIndex:0] stringValue] forType:@"MenuTableViewPboardType"];
        return YES;
    }
    
    if (tableView == allTableView)
    {
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
    
    if ([[pb types] containsObject:@"MenuTableViewPboardType"])
    {
        dragData = [pb stringForType:@"MenuTableViewPboardType"];
        dragRow = [dragData intValue];
        temp = [myItems objectAtIndex:dragRow];
        [myItems removeObjectAtIndex:dragRow];
        
        if (tableView == menuTableView)
        {
            if (row > dragRow)
            {
                [myItems insertObject:temp atIndex:row - 1];
            }
            else
            {
                [myItems insertObject:temp atIndex:row];
            }
        }
        else
        {
            if (![temp isEqualToString:@"<separator>"])
            {
                [availableItems addObject:temp];
            }
        }
    }
    else if ([[pb types] containsObject:@"AllTableViewPboardType"])
    {
        dragData = [pb stringForType:@"AllTableViewPboardType"];
        dragRow = [dragData intValue];
        temp = [availableItems objectAtIndex:dragRow];
        
        if (![temp isEqualToString:@"<separator>"])
        {
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
    if (tableView == allTableView)
    {
        if ([[[info draggingPasteboard] types] containsObject:@"AllTableViewPboardType"])
        {
            return NSDragOperationNone;
        }
        
        if ([[[info draggingPasteboard] types] containsObject:@"MenuTableViewPboardType"])
        {
            NSString *item = [myItems objectAtIndex:[[[info draggingPasteboard] stringForType:@"MenuTableViewPboardType"] intValue]];
            if ([item isEqualToString:@"Preferences…"] || [item isEqualToString:@"Quit"])
            {
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

@end
