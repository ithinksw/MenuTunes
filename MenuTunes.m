//
//  MenuTunes.m
//
//  iThink Software, Copyright 2002
//
//

/*
Things to do:
• Radio mode makes things ugly
• Add other options to the menu
    - EQ sets
    - set song rating
• Make preferences window pretty
• Hot Keys
    - hot keys can't be set when NSBGOnly is on. The window is not key,
      so the KeyBroadcaster does not pick up key combos. Bad...
    - the hotkey classes are ugly, I didn't write them
• Optimize code
• Apple Events!
*/

#import "MenuTunes.h"
#import "MenuTunesView.h"
#import "PreferencesController.h"
#import "HotKeyCenter.h"
#import "StatusWindowController.h"

@implementation MenuTunes

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    menu = [[NSMenu alloc] initWithTitle:@""];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"menu"])
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:@"Play/Pause", @"Next Track", @"Previous Track", @"Fast Forward", @"Rewind", @"<separator>", @"Upcoming Songs", @"Playlists", @"<separator>", @"Preferences…", @"Quit", @"<separator>", @"Current Track Info", nil] forKey:@"menu"];
    }
    
    iTunesPSN = [self iTunesPSN]; //Get PSN of iTunes if it's running
    [self rebuildMenu]; //Create the status item menu
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"menu.tiff"]];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:menu];
    [statusItem retain];
    
    view = [[MenuTunesView alloc] initWithFrame:[[statusItem view] frame]];
    //[statusItem setView:view];
    
    //If iTunes is running, start the timer
    if (!((iTunesPSN.highLongOfPSN == kNoProcess) && (iTunesPSN.lowLongOfPSN == 0)))
    {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 
target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
    }
    else
    {
        NSMenu *menu2 = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        
        //Register for the workspace note
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(iTunesLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
        refreshTimer = NULL;
        
        [[menu2 addItemWithTitle:@"Open iTunes" action:@selector(openiTunes:) keyEquivalent:@""] setTarget:self];
        [[menu2 addItemWithTitle:@"Preferences" action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        [[menu2 addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""] setTarget:self];
        [statusItem setMenu:menu2];
    }
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self clearHotKeys];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (void)dealloc
{
    if (refreshTimer)
    {
        [refreshTimer invalidate];
    }
    [statusItem release];
    [menu release];
    [view release];
    [super dealloc];
}

//Recreate the status item menu
- (void)rebuildMenu
{
    NSArray *myMenu = [[NSUserDefaults standardUserDefaults] arrayForKey:@"menu"];
    int i;
    trackInfoIndex = -1;
    
    if (!((iTunesPSN.highLongOfPSN == kNoProcess) && (iTunesPSN.lowLongOfPSN == 0)))
    {
        didHaveAlbumName = (([[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn album of current track\nend tell"] length] > 0) ? YES : NO);
    }
    else
    {
        didHaveAlbumName = NO;
    }
    
    while ([menu numberOfItems] > 0)
    {
        [menu removeItemAtIndex:0];
    }
    
    playPauseMenuItem = nil;
    upcomingSongsItem = nil;
    playlistItem = nil;
    
    for (i = 0; i < [myMenu count]; i++)
    {
        NSString *item = [myMenu objectAtIndex:i];
        if ([item isEqualToString:@"Play/Pause"])
        {
            playPauseMenuItem = [menu addItemWithTitle:@"Play" action:@selector(playPause:) keyEquivalent:@""];
            [playPauseMenuItem setTarget:self];
        }
        else if ([item isEqualToString:@"Next Track"])
        {
            [[menu addItemWithTitle:@"Next Track" action:@selector(nextSong:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Previous Track"])
        {
            [[menu addItemWithTitle:@"Previous Track" action:@selector(prevSong:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Fast Forward"])
        {
            [[menu addItemWithTitle:@"Fast Forward" action:@selector(fastForward:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Rewind"])
        {
            [[menu addItemWithTitle:@"Rewind" action:@selector(rewind:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Upcoming Songs"])
        {
            upcomingSongsItem = [menu addItemWithTitle:@"Upcoming Songs" action:NULL keyEquivalent:@""];
        }
        else if ([item isEqualToString:@"Playlists"])
        {
            playlistItem = [menu addItemWithTitle:@"Playlists" action:NULL keyEquivalent:@""];
        }
        else if ([item isEqualToString:@"Preferences…"])
        {
            [[menu addItemWithTitle:@"Preferences…" action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Quit"])
        {
            [[menu addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) keyEquivalent:@""] setTarget:self];
        }
        else if ([item isEqualToString:@"Current Track Info"])
        {
            trackInfoIndex = [menu numberOfItems];
            [menu addItemWithTitle:@"No Song" action:NULL keyEquivalent:@""];
        }
        else if ([item isEqualToString:@"<separator>"])
        {
            [menu addItem:[NSMenuItem separatorItem]];
        }
    }
    curTrackIndex = -1; //Force update of everything
    [self timerUpdate]; //Updates dynamic info in the menu
    
    [self clearHotKeys];
    [self setupHotKeys];
}

//Updates the menu with current player state, song, and upcoming songs
- (void)updateMenu
{
    NSString *curSongName, *curAlbumName;
    NSMenuItem *menuItem;
    
    if ((iTunesPSN.highLongOfPSN == kNoProcess) && (iTunesPSN.lowLongOfPSN == 0))
    {
        return;
    }
    
    //Get the current track name and album.
    curSongName = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn name of current track\nend tell"];
    curAlbumName = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn album of current track\nend tell"];
    
    if (upcomingSongsItem)
    {
        [self rebuildUpcomingSongsMenu];
    }
    if (playlistItem)
    {
        [self rebuildPlaylistMenu];
    }
    
    if ([curSongName length] > 0)
    {
        int index = [menu indexOfItemWithTitle:@"Now Playing"];
        
        if (index > -1)
        {
            [menu removeItemAtIndex:index + 1];
            if (didHaveAlbumName)
            {
                [menu removeItemAtIndex:index + 1];
            }
        }
        
        if ([curAlbumName length] > 0)
        {
            menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"  %@", curAlbumName] action:NULL keyEquivalent:@""];
            [menu insertItem:menuItem atIndex:trackInfoIndex + 1];
            [menuItem release];
        }
        
        menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"  %@", curSongName] action:NULL keyEquivalent:@""];
        [menu insertItem:menuItem atIndex:trackInfoIndex + 1];
        [menuItem release];
        
        if (index == -1)
        {
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Now Playing" action:NULL keyEquivalent:@""];
            [menu removeItemAtIndex:[menu indexOfItemWithTitle:@"No Song"]];
            [menu insertItem:menuItem atIndex:trackInfoIndex];
            [menuItem release];
        }
    }
    else if ([menu indexOfItemWithTitle:@"No Song"] == -1)
    {
        [menu removeItemAtIndex:trackInfoIndex];
        [menu removeItemAtIndex:trackInfoIndex];
        if (didHaveAlbumName)
        {
            [menu removeItemAtIndex:trackInfoIndex];
        }
        menuItem = [[NSMenuItem alloc] initWithTitle:@"No Song" action:NULL keyEquivalent:@""];
        [menu insertItem:menuItem atIndex:trackInfoIndex];
        [menuItem release];
    }
    
    didHaveAlbumName = (([curAlbumName length] > 0) ? YES : NO);
}

//Rebuild the upcoming songs submenu. Can be improved a lot.
- (void)rebuildUpcomingSongsMenu
{
    int numSongs = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn number of tracks in current playlist\nend tell"] intValue];
    int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
    
    if (numSongs > 0)
    {
        int curTrack = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn index of current track\nend tell"] intValue];
        int i;
        
        [upcomingSongsMenu release];
        upcomingSongsMenu = [[NSMenu alloc] initWithTitle:@""];
        
        for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++)
        {
            if (i <= numSongs)
            {
                NSString *curSong = [self runScriptAndReturnResult:[NSString stringWithFormat:@"tell application \"iTunes\"\nreturn name of track %i of current playlist\nend tell", i]];
                NSMenuItem *songItem;
                songItem = [[NSMenuItem alloc] initWithTitle:curSong action:@selector(playTrack:) keyEquivalent:@""];
                [songItem setTarget:self];
                [songItem setRepresentedObject:[NSNumber numberWithInt:i]];
                [upcomingSongsMenu addItem:songItem];
                [songItem release];
            }
            else
            {
                [upcomingSongsMenu addItemWithTitle:@"End of playlist." action:NULL keyEquivalent:@""];
                break;
            }
        }
        [upcomingSongsItem setSubmenu:upcomingSongsMenu];
    }
}

- (void)rebuildPlaylistMenu
{
    int numPlaylists = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn number of playlists\nend tell"] intValue];
    int i;
    
    [playlistMenu release];
    playlistMenu = [[NSMenu alloc] initWithTitle:@""];
    
    for (i = 1; i <= numPlaylists; i++)
    {
        NSString *playlistName = [self runScriptAndReturnResult:[NSString stringWithFormat:@"tell application \"iTunes\"\nreturn name of playlist %i\nend tell", i]];
        NSMenuItem *tempItem;
        tempItem = [[NSMenuItem alloc] initWithTitle:playlistName action:@selector(selectPlaylist:) keyEquivalent:@""];
        [tempItem setTarget:self];
        [tempItem setRepresentedObject:[NSNumber numberWithInt:i]];
        [playlistMenu addItem:tempItem];
        [tempItem release];
    }
    [playlistItem setSubmenu:playlistMenu];
}

- (void)clearHotKeys
{
    [[HotKeyCenter sharedCenter] removeHotKey:@"PlayPause"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"NextTrack"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"PrevTrack"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"TrackInfo"];
    [[HotKeyCenter sharedCenter] removeHotKey:@"UpcomingSongs"];
}

- (void)setupHotKeys
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"PlayPause"] != nil)
    {
        [[HotKeyCenter sharedCenter] addHotKey:@"PlayPause"
                combo:[defaults keyComboForKey:@"PlayPause"]
                target:self action:@selector(playPause:)];
    }
    
    if ([defaults objectForKey:@"NextTrack"] != nil)
    {
        [[HotKeyCenter sharedCenter] addHotKey:@"NextTrack"
                combo:[defaults keyComboForKey:@"NextTrack"]
                target:self action:@selector(nextSong:)];
    }
    
    if ([defaults objectForKey:@"PrevTrack"] != nil)
    {
        [[HotKeyCenter sharedCenter] addHotKey:@"PrevTrack"
                combo:[defaults keyComboForKey:@"PrevTrack"]
                target:self action:@selector(prevSong:)];
    }
    
    if ([defaults objectForKey:@"TrackInfo"] != nil)
    {
        [[HotKeyCenter sharedCenter] addHotKey:@"TrackInfo"
                combo:[defaults keyComboForKey:@"TrackInfo"]
                target:self action:@selector(showCurrentTrackInfo)];
    }
    
    if ([defaults objectForKey:@"UpcomingSongs"] != nil)
    {
        [[HotKeyCenter sharedCenter] addHotKey:@"UpcomingSongs"
               combo:[defaults keyComboForKey:@"UpcomingSongs"]
               target:self action:@selector(showUpcomingSongs)];
    }
}

//Runs an AppleScript and returns the result as an NSString after stripping quotes, if needed.
- (NSString *)runScriptAndReturnResult:(NSString *)script
{
    AEDesc scriptDesc, resultDesc;
    Size length;
    NSString *result;
    Ptr buffer;
    
    AECreateDesc(typeChar, [script cString], [script cStringLength], 
&scriptDesc);
    
    OSADoScript(OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype), &scriptDesc, kOSANullScript, typeChar, kOSAModeCanInteract, &resultDesc);
    
    length = AEGetDescDataSize(&resultDesc);
    buffer = malloc(length);
    
    AEGetDescData(&resultDesc, buffer, length);
    result = [NSString stringWithCString:buffer length:length];
    if (![result isEqualToString:@""] &&
        ([result characterAtIndex:0] == '\"') &&
        ([result characterAtIndex:[result length] - 1] == '\"'))
    {
        result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    }
    free(buffer);
    buffer = NULL;
    return result;
}

//Called when the timer fires.
- (void)timerUpdate
{
    int pid;
    if ((GetProcessPID(&iTunesPSN, &pid) == noErr) && (pid > 0))
    {
        int trackPlayingIndex = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn index of current track\nend tell"] intValue];
        if (trackPlayingIndex != curTrackIndex)
        {
            [self updateMenu];
            curTrackIndex = trackPlayingIndex;
        }
        /*else
        {
            NSString *playlist = [self runScriptAndReturnResult:@"tell application\n\"iTunes\"\nreturn name of current playlist\nend tell"];
            
            if (![playlist isEqualToString:curPlaylist])
            {
                [self updateMenu];
                NSLog(@"update due to playlist change");
                curPlaylist = [NSString stringWithString:playlist];
            }
        }*/
        //Update Play/Pause menu item
        if (playPauseMenuItem)
        {
            if ([[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn player state\nend tell"] isEqualToString:@"playing"])
            {
                [playPauseMenuItem setTitle:@"Pause"];
            }
            else
            {
                [playPauseMenuItem setTitle:@"Play"];
            }
        }
    }
    else
    {
        NSMenu *menu2 = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        
        [refreshTimer invalidate]; //Stop the timer
        refreshTimer = NULL;
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(iTunesLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
        
        [[menu2 addItemWithTitle:@"Open iTunes" 
action:@selector(openiTunes:) keyEquivalent:@""] setTarget:self];
        [[menu2 addItemWithTitle:@"Preferences" 
action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];
        [[menu2 addItemWithTitle:@"Quit" action:@selector(quitMenuTunes:) 
keyEquivalent:@""] setTarget:self];
        [statusItem setMenu:menu2];
    }
}

- (void)iTunesLaunched:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];
    
    iTunesPSN.highLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    iTunesPSN.lowLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    
    //Restart the timer
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES]; 
    
    [self rebuildMenu]; //Rebuild the menu since no songs will be playing
    [statusItem setMenu:menu]; //Set the menu back to the main one
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

//Return the PSN of iTunes, if it's running
- (ProcessSerialNumber)iTunesPSN
{
    ProcessSerialNumber procNum;
    procNum.highLongOfPSN = kNoProcess;
    procNum.lowLongOfPSN = 0;
    
    while ( (GetNextProcess(&procNum) == noErr) ) 
    {
        CFStringRef procName;
        
        if ( (CopyProcessName(&procNum, &procName) == noErr) )
        {
            if ([(NSString *)procName isEqualToString:@"iTunes"])
            {
                return procNum;
            }
            [(NSString *)procName release];
        }
    }
    return procNum;
}

//Send an AppleEvent with a given event ID
- (void)sendAEWithEventClass:(AEEventClass)eventClass 
andEventID:(AEEventID)eventID
{
    OSType iTunesType = 'hook';
    AppleEvent event, reply;
    
    AEBuildAppleEvent(eventClass, eventID, typeApplSignature, &iTunesType, sizeof(iTunesType), kAutoGenerateReturnID, kAnyTransactionID, &event, NULL, "");
    
    AESend(&event, &reply, kAENoReply, kAENormalPriority, kAEDefaultTimeout, nil, nil);
    AEDisposeDesc(&event);
    AEDisposeDesc(&reply);
}

//
// Selectors - called from status item menu
//

- (void)playTrack:(id)sender
{
    [self runScriptAndReturnResult:[NSString stringWithFormat:@"tell application \"iTunes\"\nplay track %i of current playlist\nend tell", [[sender representedObject] intValue]]];
    [self updateMenu];
}

- (void)selectPlaylist:(id)sender
{
    [self runScriptAndReturnResult:[NSString stringWithFormat:@"tell application \"iTunes\"\nplay playlist %i\nend tell", [[sender representedObject] intValue]]];
    [self updateMenu];
}

- (void)playPause:(id)sender
{
    NSString *state = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn player state\nend tell"];
    if ([state isEqualToString:@"playing"])
    {
        [self sendAEWithEventClass:'hook' andEventID:'Paus'];
        [playPauseMenuItem setTitle:@"Play"];
    }
    else if ([state isEqualToString:@"fast forwarding"] || [state 
isEqualToString:@"rewinding"])
    {
        [self sendAEWithEventClass:'hook' andEventID:'Paus'];
        [self sendAEWithEventClass:'hook' andEventID:'Play'];
    }
    else
    {
        [self sendAEWithEventClass:'hook' andEventID:'Play'];
        [playPauseMenuItem setTitle:@"Pause"];
    }
}

- (void)nextSong:(id)sender
{
    [self sendAEWithEventClass:'hook' andEventID:'Next'];
}

- (void)prevSong:(id)sender
{
    [self sendAEWithEventClass:'hook' andEventID:'Prev'];
}

- (void)fastForward:(id)sender
{
    [self sendAEWithEventClass:'hook' andEventID:'Fast'];
}

- (void)rewind:(id)sender
{
    [self sendAEWithEventClass:'hook' andEventID:'Rwnd'];
}

- (void)quitMenuTunes:(id)sender
{
    [NSApp terminate:self];
}

- (void)openiTunes:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"iTunes"];
}

- (void)showPreferences:(id)sender
{
    if (!prefsController)
    {
        prefsController = [[PreferencesController alloc] initWithMenuTunes:self];
        [self clearHotKeys];
    }
}


- (void)closePreferences
{
    [self setupHotKeys];
    [prefsController release];
    prefsController = nil;
}

//
//
// Show Current Track Info And Show Upcoming Songs Floaters
//
//

- (void)showCurrentTrackInfo
{
    NSString *trackName = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn name of current track\nend tell"];
    if (!statusController && [trackName length])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *stringToShow = @"";
        int lines = 1;
        
        if ([defaults boolForKey:@"showName"])
        {
            stringToShow = [stringToShow stringByAppendingString:trackName];
            stringToShow = [stringToShow stringByAppendingString:@"\n"];
            lines++;
        }
        
        if ([defaults boolForKey:@"showArtist"])
        {
            NSString *trackArtist = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn artist of current track\nend tell"];
            stringToShow = [stringToShow stringByAppendingString:trackArtist];
            stringToShow = [stringToShow stringByAppendingString:@"\n"];
            lines++;
        }
        
        if ([defaults boolForKey:@"showAlbum"])
        {
            NSString *trackAlbum = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn album of current track\nend tell"];
            stringToShow = [stringToShow stringByAppendingString:trackAlbum];
            stringToShow = [stringToShow stringByAppendingString:@"\n"];
            lines++;
        }
        
        //Rating - maybe
        //Year - maybe
        
        if ([defaults boolForKey:@"showTime"])
        {
            NSString *trackLength = [self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn time of current track\nend tell"];
            stringToShow = [stringToShow stringByAppendingString:trackLength];
            stringToShow = [stringToShow stringByAppendingString:@"\n"];
            lines++;
        }
        
        {
            int trackTimeLeft = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn (duration of current track) - player position\nend tell"] intValue];
            int minutes = trackTimeLeft / 60, seconds = trackTimeLeft % 60;
            if (seconds < 10)
            {
                stringToShow = [stringToShow stringByAppendingString:
                            [NSString stringWithFormat:@"Time Remaining: %i:0%i", minutes, seconds]];
            }
            else
            {
                stringToShow = [stringToShow stringByAppendingString:
                            [NSString stringWithFormat:@"Time Remaining: %i:%i", minutes, seconds]];
            }
        }
        
        statusController = [[StatusWindowController alloc] init];
        [statusController setTrackInfo:stringToShow lines:lines];
        [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(fadeAndCloseStatusWindow) userInfo:nil repeats:NO];
    }
}

- (void)showUpcomingSongs
{
    if (!statusController)
    {
        int numSongs = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn number of tracks in current playlist\nend tell"] intValue];
        
        if (numSongs > 0)
        {
            int numSongsInAdvance = [[NSUserDefaults standardUserDefaults] integerForKey:@"SongsInAdvance"];
            int curTrack = [[self runScriptAndReturnResult:@"tell application \"iTunes\"\nreturn index of current track\nend tell"] intValue];
            int i;
            NSString *songs = @"";
            
            statusController = [[StatusWindowController alloc] init];
            for (i = curTrack + 1; i <= curTrack + numSongsInAdvance; i++)
            {
                if (i <= numSongs)
                {
                    NSString *curSong = [self runScriptAndReturnResult:[NSString stringWithFormat:@"tell application \"iTunes\"\nreturn name of track %i of current playlist\nend tell", i]];
                    songs = [songs stringByAppendingString:curSong];
                    songs = [songs stringByAppendingString:@"\n"];
                }
            }
            [statusController setUpcomingSongs:songs numSongs:numSongsInAdvance];
            [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(fadeAndCloseStatusWindow) userInfo:nil repeats:NO];
        }
    }
}

- (void)fadeAndCloseStatusWindow
{
    [statusController fadeWindowOut];
    [statusController release];
    statusController = nil;
}

@end
