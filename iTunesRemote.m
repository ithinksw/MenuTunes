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
    return @"Default MenuTunes plugin to control iTunes. Written by iThink Software.";
}

- (NSImage *)icon
{
    return nil;
}

- (BOOL)begin
{
    iTunesPSN = [self iTunesPSN];

    //Register for application termination in NSWorkspace
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];

    return YES;
}

- (BOOL)halt
{
    iTunesPSN.highLongOfPSN = kNoProcess;

    //Unregister for application termination in NSWorkspace
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    return YES;
}

- (BOOL)isAppRunning
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    int i,count = [apps count];

    for (i = 0; i < count; i++) {
        if ([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"]
                isEqualToString:@"iTunes"]) {
            return YES;
        }
    }
    return NO;
}

- (PlayerState)playerState
{
    long result = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"'----':obj { form:'prop', want:type('prop'), seld:type('pPlS'), from:'null'() }" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
    
    switch (result)
    {
        default:
        case 'kPSS':
            return stopped;
        case 'kPSP':
            return paused;
        case 'kPSp':
            return playing;
        case 'kPSR':
            return rewinding;
        case 'kPSF':
            return forwarding;
    }
    
    return stopped;
}

- (NSArray *)playlists
{
    long i = 0;
    const signed long numPlaylists = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cPly'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:[self iTunesPSN]];
    NSMutableArray *playlists = [[NSMutableArray alloc] initWithCapacity:numPlaylists];
    NSLog(@"entered playlist");

	   for (i = 1; i <= numPlaylists; i++) {
		  const long j = i;
		  NSString *sendStr = [NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cPly'), seld:%lu, from:'null'() } }",(unsigned long)j];
		  NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:sendStr eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
		  NSLog(@"sent event cur %d max %d",i,numPlaylists);
		  [playlists addObject:theObj];
	   }
	   NSLog(@"playlists end");
	   return [playlists autorelease];
}

- (int)numberOfSongsInPlaylistAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:[NSString stringWithFormat:@"kocl:'cTrk', '----':obj { form:'indx', want:type('cPly'), seld:%i, from:'null'() }",index] eventClass:@"core" eventID:@"cnte" appPSN:[self iTunesPSN]];
}

- (NSString *)classOfPlaylistAtIndex:(int)index
{
    int realResult = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pcls" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];

    if (realResult == 'cRTP') return @"radio tuner playlist";
    else return @"playlist";
}

- (int)currentPlaylistIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter]
                sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pPla" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
    return result;
}

- (NSString *)songTitleAtIndex:(int)index
{
    return [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cTrk'), seld:%i, from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } } }",index] eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (int)currentSongIndex
{
    int result;
    result = [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKeyForNumber:@"pidx" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
    return result;
}

- (NSString *)currentSongTitle
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pnam" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongArtist
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pArt" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongAlbum
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pAlb" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongGenre
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pGen" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongLength
{
    return [[ITAppleEventCenter sharedCenter] sendTwoTierAEWithRequestedKey:@"pTim" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
}

- (NSString *)currentSongRemaining
{
    long duration = [[ITAppleEventCenter sharedCenter]
                        sendTwoTierAEWithRequestedKeyForNumber:@"pDur" fromObjectByKey:@"pTrk" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
    long current = [[ITAppleEventCenter sharedCenter]
                        sendAEWithRequestedKeyForNumber:@"pPos" eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];

    return [[NSNumber numberWithLong:duration - current] stringValue];
}

- (NSArray *)eqPresets;
{
    int i;
    long numPresets = [[ITAppleEventCenter sharedCenter] sendAEWithSendStringForNumber:@"kocl:type('cEQP'), '----':(), &subj:()" eventClass:@"core" eventID:@"cnte" appPSN:[self iTunesPSN]];
    NSMutableArray *presets = [[NSMutableArray alloc] initWithCapacity:numPresets];


	   for (i = 0; i < numPresets; i++) {
		  NSString *theObj = [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'prop', want:type('prop'), seld:type('pnam'), from:obj { form:'indx', want:type('cEQP'), seld:%d, from:'null'() } }",i] eventClass:@"core" eventID:@"getd" appPSN:[self iTunesPSN]];
		  [presets addObject:theObj];
	   }
	   return [presets autorelease];
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
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'name', want:type('cPly'), seld:%i, from:'null'() }",index] eventClass:@"hook" eventID:@"Play" appPSN:[self iTunesPSN]];
    return NO;
}

- (BOOL)switchToSongAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"'----':obj { form:'indx', want:type('cTrk'), seld:%i, from:obj { form:'prop', want:type('prop'), seld:type('pPla'), from:'null'() } }",index] eventClass:@"hook" eventID:@"Play" appPSN:[self iTunesPSN]];
    return NO;
}

- (BOOL)switchToEQAtIndex:(int)index
{
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:[NSString stringWithFormat:@"data:obj { form:'name', want:type('cEQP'), seld:%i, from:'null'() }, '----':obj { form:'prop', want:type('prop'), seld:type('pEQP'), from:'null'() }",index] eventClass:@"core" eventID:@"setd" appPSN:[self iTunesPSN]];
    [[ITAppleEventCenter sharedCenter] sendAEWithSendString:@"data:1, '----':obj { form:'prop', want:type('prop'), seld:type('pEQ '), from:'null'() }" eventClass:@"core" eventID:@"setd" appPSN:[self iTunesPSN]];
    return NO;
}

- (ProcessSerialNumber)iTunesPSN
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    ProcessSerialNumber number;
    int i, count = [apps count];

	       number.highLongOfPSN = kNoProcess;

	       for (i = 0; i < count; i++)
		      {
			  NSDictionary *curApp = [apps objectAtIndex:i];
			 
				 if ([[curApp objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"])
				     {
					        number.highLongOfPSN = [[curApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] intValue];
					        number.lowLongOfPSN = [[curApp objectForKey:@"NSApplicationProcessSerialNumberLow"] intValue];
					    }
			     }
    return number;}

- (void)applicationLaunched:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];

    if ([[info objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
        iTunesPSN.highLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
        iTunesPSN.lowLongOfPSN = [[info objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTRemoteAppDidLaunchNotification" object:nil];
    }
}

- (void)applicationTerminated:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];

    if ([[info objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"]) {
        iTunesPSN.highLongOfPSN = kNoProcess;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTRemoteAppDidTerminateNotification" object:nil];
    }
}

@end
