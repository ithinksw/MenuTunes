#import "iTunesRemote.h"

@implementation iTunesRemote

+ (id)remote
{
    return [[[iTunesRemote alloc] init] autorelease];
}

- (NSString *)title
{
    return @"iTunes Plug-in";
}

- (NSString *)information;
{
    return @"Default MenuTunes plugin to control iTunes.";
}

- (NSImage *)icon
{
    return nil;
}

- (BOOL)begin
{
    iTunesPSN = [self iTunesPSN];
    asComponent = OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype);
    
    //Register for application termination in NSWorkspace
    
    NSLog(@"iTunes Plugin loaded");
    return YES;
}

- (BOOL)halt
{
    iTunesPSN.highLongOfPSN = kNoProcess;
    CloseComponent(asComponent);
    
    //Unregister for application termination in NSWorkspace
    return YES;
}

- (PlayerState)playerState
{
    NSString *result = [self runScriptAndReturnResult:@"get player state"];
    
    if ([result isEqualToString:@"playing"]) {
        return playing;
    } else if ([result isEqualToString:@"paused"]) {
        return paused;
    } else if ([result isEqualToString:@"stopped"]) {
        return stopped;
    } else if ([result isEqualToString:@"rewinding"]) {
        return rewinding;
    } else if ([result isEqualToString:@"fast forwarding"]) {
        return forwarding;
    }
    
    return stopped;
}

- (NSArray *)playlists
{
    int i;
    int numPresets = [[self runScriptAndReturnResult:@"get number of playlists"] intValue];
    NSMutableArray *presets = [[NSMutableArray alloc] init];
    
    for (i = 0; i < numPresets; i++) {
        [presets addObject:[self runScriptAndReturnResult:[NSString stringWithFormat:@"get name of playlist %i", i]]];
    }
    
    return [NSArray arrayWithArray:presets];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    NSString *result = [self runScriptAndReturnResult:[NSString stringWithFormat:@"get number of tracks in playlist %i", index]];
    return [result intValue];
}

- (NSString *)classOfPlaylistAtIndex:(int)index
{
    //Not working yet. It returns the 4 character code instead of a name.
    /*NSString *result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKey:@"pcls"
                fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];*/
    NSString *result = [self runScriptAndReturnResult:[NSString stringWithFormat:@"get class of playlist %i", index]];
    return result;
}

- (int)currentPlaylistIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx"
                fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
    return result;
}

- (NSString *)songTitleAtIndex:(int)index
{
    NSString *result = [self runScriptAndReturnResult:[NSString stringWithFormat:@"get name of track %i of current playlist", index]];
    return result;
}

- (int)currentSongIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
    return result;
}

- (NSString *)currentSongTitle
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pnam"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongArtist
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pArt"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongAlbum
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pAlb"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongGenre
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pGen"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongLength
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pTim"
                fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongRemaining
{
    long duration = [[ITAppleEventCenter sharedCenter]
                        sendTwoTierAEWithRequestedKeyForNumber:@"pDur"
                        fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd"
                        appPSN:[self iTunesPSN]];
    long current = [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pPos"
                        eventClass:@"core" eventID:@"getd"
                        appPSN:[self iTunesPSN]];
    
    return [[NSNumber numberWithLong:duration - current] stringValue];
}

- (NSArray *)eqPresets;
{
    int i;
    int numPresets = [[self runScriptAndReturnResult:@"get number of EQ presets"] intValue];
    NSMutableArray *presets = [[NSMutableArray alloc] init];
    
    for (i = 0; i < numPresets; i++) {
        [presets addObject:[self runScriptAndReturnResult:[NSString stringWithFormat:@"get name of EQ preset %i", i]]];
    }
    
    return [NSArray arrayWithArray:presets];
}

- (int)currentEQPresetIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx"
                fromObjectByKey:@"pEQP" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
    return result;
}

- (BOOL)play
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Play"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)pause
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Paus"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)goToNextSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Next"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)goToPreviousSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Prev"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)fastForward
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Fast"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)rewind
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Rwnd"
            appPSN:[self iTunesPSN]];
    return YES;
}


- (BOOL)switchToPlaylistAtIndex:(int)index
{
    [self runScriptAndReturnResult:[NSString stringWithFormat:
        @"play playlist %i", index]];
    return NO;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    [self runScriptAndReturnResult:[NSString stringWithFormat:
        @"play track %i of current playlist", index]];
    return NO;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    [self runScriptAndReturnResult:[NSString stringWithFormat:
        @"set current EQ preset to EQ preset %i", index]];
    [self runScriptAndReturnResult:@"set EQ enabled to 1"];
    return NO;
}

- (ProcessSerialNumber)iTunesPSN
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    ProcessSerialNumber number;
    int i;
    
    number.highLongOfPSN = kNoProcess;
    
    for (i = 0; i < [apps count]; i++)
    {
        NSDictionary *curApp = [apps objectAtIndex:i];
        
        if ([[curApp objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"])
        {
            number.highLongOfPSN = [[curApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] intValue];
            number.lowLongOfPSN = [[curApp objectForKey:@"NSApplicationProcessSerialNumberLow"] intValue];
        }
    }
    return number;
}

- (NSString *)runScriptAndReturnResult:(NSString *)script
{
    AEDesc scriptDesc, resultDesc;
    Size length;
    NSString *result;
    Ptr buffer;
    
    script = [NSString stringWithFormat:@"tell application \"iTunes\"\n%@\nend tell", script];
    
    AECreateDesc(typeChar, [script cString], [script cStringLength], 
&scriptDesc);
    
    OSADoScript(asComponent, &scriptDesc, kOSANullScript, typeChar, kOSAModeCanInteract, &resultDesc);
    
    length = AEGetDescDataSize(&resultDesc);
    buffer = malloc(length);
    
    AEGetDescData(&resultDesc, buffer, length);
    AEDisposeDesc(&scriptDesc);
    AEDisposeDesc(&resultDesc);
    result = [NSString stringWithCString:buffer length:length];
    if ( (! [result isEqualToString:@""])      &&
         ([result characterAtIndex:0] == '\"') &&
         ([result characterAtIndex:[result length] - 1] == '\"') ) {
        result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    }
    free(buffer);
    buffer = nil;
    return result;
}

@end
