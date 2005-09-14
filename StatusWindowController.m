#import "StatusWindowController.h"
#import "StatusWindow.h"
#import "PreferencesController.h"
#import "MainController.h"

#import <ITKit/ITTSWBackgroundView.h>
#import <ITKit/ITWindowEffect.h>
#import <ITKit/ITCutWindowEffect.h>
#import <ITKit/ITDissolveWindowEffect.h>
#import <ITKit/ITSlideHorizontallyWindowEffect.h>
#import <ITKit/ITSlideVerticallyWindowEffect.h>
#import <ITKit/ITPivotWindowEffect.h>

static StatusWindowController *sharedController;

@implementation StatusWindowController


+ (StatusWindowController *)sharedController
{
    if ( ! sharedController ) {
        sharedController = [[StatusWindowController alloc] init];
    }
    
    return sharedController;
}


- (id)init
{
    if ( ( self = [super init] ) ) {
        
        float exitDelay;
        NSString *entryClass;
        NSString *exitClass;
        NSArray  *classList = [ITWindowEffect effectClasses];
        float entrySpeed;
        float exitSpeed;
		NSArray *screens = [NSScreen screens];
		int screenIndex;
        
        NSData *colorData;
        
        ITWindowEffect *entryEffect;
        ITWindowEffect *exitEffect;
        
        _window = [[StatusWindow sharedWindow] retain];
        df = [[NSUserDefaults standardUserDefaults] retain];
        
        exitDelay  = [df floatForKey:@"statusWindowVanishDelay"];
        entryClass = [df stringForKey:@"statusWindowAppearanceEffect"];
        exitClass  = [df stringForKey:@"statusWindowVanishEffect"];
        entrySpeed = [df floatForKey:@"statusWindowAppearanceSpeed"];
        exitSpeed  = [df floatForKey:@"statusWindowVanishSpeed"];
		
		screenIndex = [df integerForKey:@"statusWindowScreenIndex"];
		if (screenIndex >= [screens count]) {
			screenIndex = 0;
		}
		[_window setScreen:[screens objectAtIndex:screenIndex]];
		
        [_window setExitMode:ITTransientStatusWindowExitAfterDelay];
        [_window setExitDelay:(exitDelay ? exitDelay : 4.0)];
        
        [_window setHorizontalPosition:[df integerForKey:@"statusWindowHorizontalPosition"]];
        [_window setVerticalPosition:[df integerForKey:@"statusWindowVerticalPosition"]];
        
        [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
        
        if ( [classList containsObject:NSClassFromString(entryClass)] ) {
            entryEffect = [[[NSClassFromString(entryClass) alloc] initWithWindow:_window] autorelease];
        } else {
            entryEffect = [[[ITCutWindowEffect alloc] initWithWindow:_window] autorelease];
        }
        
        if ( [classList containsObject:NSClassFromString(exitClass)] ) {
            exitEffect = [[[NSClassFromString(exitClass) alloc] initWithWindow:_window] autorelease];
        } else {
            exitEffect = [[[ITDissolveWindowEffect alloc] initWithWindow:_window] autorelease];
        }
        
        [_window setEntryEffect:entryEffect];
        [_window setExitEffect:exitEffect];
        
        [[_window entryEffect] setEffectTime:(entrySpeed ? entrySpeed : 0.8)];
        [[_window exitEffect]  setEffectTime:(exitSpeed  ? exitSpeed  : 0.8)];
        
        [(ITTSWBackgroundView *)[_window contentView]setBackgroundMode:
            (ITTSWBackgroundMode)[df integerForKey:@"statusWindowBackgroundMode"]];
        
        colorData = [df dataForKey:@"statusWindowBackgroundColor"];
        
        if ( colorData ) {
            [(ITTSWBackgroundView *)[_window contentView] setBackgroundColor:
                (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData]];
        } else {
            [(ITTSWBackgroundView *)[_window contentView] setBackgroundColor:[NSColor blueColor]];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (void)showSongInfoWindowWithSource:(ITMTRemotePlayerSource)source
                               title:            (NSString *)title
                               album:            (NSString *)album
                              artist:            (NSString *)artist
                            composer:            (NSString *)composer
                                time:            (NSString *)time  // FLOW: Should probably be NSDate or something.
                               track:            (NSString *)track
                              rating:                   (int)rating
                           playCount:                   (int)playCount
                               image:             (NSImage *)art
{
    NSImage  *image = nil;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:title];
    
    if ( art != nil ) {
        image = art;
    } else if ( source == ITMTRemoteLibrarySource ) {
        image = [NSImage imageNamed:@"Library"];
    } else if ( source == ITMTRemoteCDSource ) {
        image = [NSImage imageNamed:@"CD"];
    } else if ( source == ITMTRemoteRadioSource ) {
        image = [NSImage imageNamed:@"Radio"];
    } else if ( source == ITMTRemoteiPodSource ) {
        image = [NSImage imageNamed:@"iPod"];
    } else if ( source == ITMTRemoteGenericDeviceSource ) {
        image = [NSImage imageNamed:@"MP3Player"];
    } else if ( source == ITMTRemoteSharedLibrarySource ) {
        image = [NSImage imageNamed:@"Library"];
    }
    
    [_window setImage:image];
	[_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    
    if ( album ) {
		[[text mutableString] appendFormat:@"\n%@", album];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:album]];
    }
    if ( artist ) {
		[[text mutableString] appendFormat:@"\n%@", artist];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:artist]];
    }
    if ( composer ) {
		[[text mutableString] appendFormat:@"\n%@", composer];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:composer]];
    }
    if ( time ) {
		_timeRange = NSMakeRange([[text mutableString] length] + 1, [time length]);
		[[text mutableString] appendFormat:@"\n%@", time];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:time]];
    }
    if ( track ) {
		[[text mutableString] appendFormat:@"\n%@", track];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:track]];
    }
    if (playCount > -1) {
		[[text mutableString] appendFormat:@"\n%@: %i", NSLocalizedString(@"playCount", @"Play Count"), playCount];
        //text = [text stringByAppendingString:[NSString stringWithFormat:@"\n%@: %i", NSLocalizedString(@"playCount", @"Play Count"), playCount]];
    }
    if ( rating > -1 ) {

        NSString *ratingString = [NSString string];
        NSString *emptyChar    = [NSString stringWithUTF8String:"☆"];
        NSString *fullChar     = [NSString stringWithUTF8String:"★"];
        int       i, start = [[text mutableString] length], size = 18;
        
        for ( i = 1; i < 6; i++ ) {
        	
            if ( rating >= i ) {
                ratingString = [ratingString stringByAppendingString:fullChar];
            } else {
                ratingString = [ratingString stringByAppendingString:emptyChar];
            }
        }
		
		[[text mutableString] appendFormat:@"\n%@", ratingString];
		if ([_window sizing] == ITTransientStatusWindowSmall) {
			size /= SMALL_DIVISOR;
		} else if ([_window sizing] == ITTransientStatusWindowMini) {
			size /= MINI_DIVISOR;
		}
		[text setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"AppleGothic" size:size], NSFontAttributeName, nil, nil] range:NSMakeRange(start + 1, 5)];
        //text = [text stringByAppendingString:[@"\n" stringByAppendingString:ratingString]];
    }
    
    [_window buildTextWindowWithString:text];
    [_window appear:self];
}

- (void)showUpcomingSongsWindowWithTitles:(NSArray *)titleStrings
{
//  NSString *bull = [NSString stringWithUTF8String:"‣ "];
    NSString *bull = [NSString stringWithUTF8String:"♪ "];
    NSString *end  = [@"\n" stringByAppendingString:bull];
    [_window setImage:[NSImage imageNamed:@"Upcoming"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildTextWindowWithString:[bull stringByAppendingString:[titleStrings componentsJoinedByString:end]]];
    [_window appear:self];
}

- (void)showVolumeWindowWithLevel:(float)level
{
    [_window setImage:[NSImage imageNamed:@"Volume"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildMeterWindowWithCharacter:[NSString stringWithUTF8String:"▊"]
                                      size:18
                                     count:10
                                    active:( ceil(level * 100) / 10 )];
    [_window appear:self];
}

- (void)showRatingWindowWithRating:(float)rating
{
    [_window setImage:[NSImage imageNamed:@"Rating"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildMeterWindowWithCharacter:[NSString stringWithUTF8String:"★"]
                                      size:48
                                     count:5
                                    active:( ceil(rating * 100) / 20 )];
    [_window appear:self];
}

- (void)showShuffleWindow:(BOOL)shuffle
{
    [_window setImage:[NSImage imageNamed:@"Shuffle"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildTextWindowWithString:( shuffle ? NSLocalizedString(@"shuffleOn", @"Shuffle On") : NSLocalizedString(@"shuffleOff", @"Shuffle Off"))];
    [_window appear:self];
}

- (void)showRepeatWindowWithMode:(StatusWindowRepeatMode)mode
{
    NSString *string = nil;
    
    if ( mode == StatusWindowRepeatNone ) {
        string = NSLocalizedString(@"repeatOff", @"Repeat Off");
    } else if ( mode == StatusWindowRepeatGroup ) {
        string = NSLocalizedString(@"repeatPlaylist", @"Repeat Playlist");
    } else if ( mode == StatusWindowRepeatTrack ) {
        string = NSLocalizedString(@"repeatOneTrack", @"Repeat One Track");;
    }
    
    [_window setImage:[NSImage imageNamed:@"Repeat"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildTextWindowWithString:string];
    [_window appear:self];
}

- (void)showSongShufflabilityWindow:(BOOL)shufflable
{
    [_window setImage:[NSImage imageNamed:@"Shuffle"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildTextWindowWithString:( !shufflable ? NSLocalizedString(@"shufflableOn", @"Current Song Skipped When Shuffling") : NSLocalizedString(@"shufflableOff", @"Current Song Not Skipped When Shuffling"))];
    [_window appear:self];
}

- (void)showSetupQueryWindow
{
    NSString *message = NSLocalizedString(@"autolaunch_msg", @"Would you like MenuTunes to launch\nautomatically at startup?");

    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:NSLocalizedString(@"launch_at_startup", @"Launch at Startup")
                          alternateButton:NSLocalizedString(@"launch_manually", @"Launch Manually")
                                   target:[PreferencesController sharedPrefs]
                            defaultAction:@selector(autoLaunchOK)
                          alternateAction:@selector(autoLaunchCancel)];

    [_window appear:self];
    [_window setLocked:YES];
}


- (void)showRegistrationQueryWindow
{
    NSString *message = NSLocalizedString(@"trialexpired_msg", @"Your 7-day unlimited trial period has elapsed.\nYou must register to continue using MenuTunes.");

    [_window setImage:[NSImage imageNamed:@"Register"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:NSLocalizedString(@"registernow", @"Register Now")
                          alternateButton:NSLocalizedString(@"quitmenutunes", @"Quit MenuTunes")
                                   target:[MainController sharedController]
                            defaultAction:@selector(registerNowOK)
                          alternateAction:@selector(registerNowCancel)];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showReconnectQueryWindow
{
    NSString *message = NSLocalizedString(@"sharedplayeravailable_msg", @"The selected shared player is available again.\nWould you like to reconnect to it?");
    [_window setLocked:NO];
    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:NSLocalizedString(@"reconnect", @"Reconnect")
                          alternateButton:NSLocalizedString(@"ignore", @"Ignore")
                                   target:[MainController sharedController]
                            defaultAction:@selector(reconnect)
                          alternateAction:@selector(cancelReconnect)];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showNetworkErrorQueryWindow
{
    NSString *message = NSLocalizedString(@"sharedplayerunreachable_msg", @"The remote MenuTunes server is unreachable.\nMenuTunes will revert back to the local player.");

    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:@" OK "
                          alternateButton:nil
                                   target:[MainController sharedController]
                            defaultAction:@selector(cancelReconnect)
                          alternateAction:nil];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showPreferencesUpdateWindow
{
    NSString *message = NSLocalizedString(@"reconfigureprefs_msg", @"The new features in this version of MenuTunes\nrequire you to reconfigure your preferences.");

    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:NSLocalizedString(@"showpreferences", @"Show Preferences")
                          alternateButton:@"OK"
                                   target:[MainController sharedController]
                            defaultAction:@selector(showPreferencesAndClose)
                          alternateAction:@selector(cancelReconnect)];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showDebugModeEnabledWindow
{
	[_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:NSLocalizedString(@"debugmodeenabled", @"Debug Mode Enabled")
                            defaultButton:@"OK"
                          alternateButton:nil
                                   target:[MainController sharedController]
                            defaultAction:@selector(cancelReconnect)
                          alternateAction:nil];
    [_window appear:self];
	[_window setLocked:YES];
}

- (void)updateTime:(NSString *)time
{
	if (time && [time length]) {
		[_window updateTime:time range:_timeRange];
	}
}

@end