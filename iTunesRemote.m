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
    
    //Register for application termination in NSWorkspace
    
    NSLog(@"iTunes Plugin loaded");
    return YES;
}

- (BOOL)halt
{
    iTunesPSN.highLongOfPSN = kNoProcess;
    
    //Unregister for application termination in NSWorkspace
    return YES;
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter]
                    sendAEWithSendStringForNumber:@"cPla"
                    eventClass:@"core" eventID:@"cnte"
                    appPSN:[self iTunesPSN]];
}

- (NSString *)classOfPlaylistAtIndex:(int)index
{
    //Not working yet. It returns the 4 character code instead of a name.
    NSString *result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKey:@"pcls"
                fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd"
                appPSN:[self iTunesPSN]];
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
    return nil; 
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
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pDur"
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
    return nil;
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
    [self numberOfSongsInPlaylistAtIndex:1];
    //[[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Next"
    //        appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)goToPreviousSong
{
    [[ITAppleEventCenter sharedCenter] sendAEWithEventClass:@"hook" eventID:@"Prev"
            appPSN:[self iTunesPSN]];
    return YES;
}

- (BOOL)switchToPlaylistAtIndex:(int)index
{
    return NO;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    return NO;
}

- (BOOL)switchToEQAtIndex:(int)index
{
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

@end
