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
                                time:            (NSString *)time  // FLOW: Should probably be NSDate or something.
                               track:            (NSString *)track
                              rating:                   (int)rating
                               image:             (NSImage *)art
{
    NSImage  *image = nil;
    NSString *text  = title;
    
    if ( art != nil ) {
        image = art;
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationLow];
        [image setScalesWhenResized:YES];
        [image setSize:NSMakeSize(110, 110)];
        /*if (size.width > 110 && size.width > size.height) {
            [image setSize:NSMakeSize(110, (size.width / size.height) * 110)];
        } else if (size.height > 110 && size.height > size.width) {
            [image setSize:NSMakeSize((size.height / size.width) * 110, 110)];
        }*/
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
    
    if ( album ) {
        text = [text stringByAppendingString:[@"\n" stringByAppendingString:album]];
    }
    if ( artist ) {
        text = [text stringByAppendingString:[@"\n" stringByAppendingString:artist]];
    }
    if ( time ) {
        text = [text stringByAppendingString:[@"\n" stringByAppendingString:time]];
    }
    if ( track ) {
        text = [text stringByAppendingString:[@"\n" stringByAppendingString:track]];
    }
    if ( rating > -1 ) {

        NSString *ratingString = [NSString string];
        NSString *emptyChar    = [NSString stringWithUTF8String:"☆"];
        NSString *fullChar     = [NSString stringWithUTF8String:"★"];
        int       i;
        
        for ( i = 1; i < 6; i++ ) {
        	
            if ( rating >= i ) {
                ratingString = [ratingString stringByAppendingString:fullChar];
            } else {
                ratingString = [ratingString stringByAppendingString:emptyChar];
            }
        }
    
        text = [text stringByAppendingString:[@"\n" stringByAppendingString:ratingString]];
    }
    
    
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
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
    [_window buildTextWindowWithString:( shuffle ? @"Shuffle On" : @"Shuffle Off")];
    [_window appear:self];
}

- (void)showRepeatWindowWithMode:(StatusWindowRepeatMode)mode
{
    NSString *string = nil;
    
    if ( mode == StatusWindowRepeatNone ) {
        string = @"Repeat Off";
    } else if ( mode == StatusWindowRepeatGroup ) {
        string = @"Repeat Playlist";
    } else if ( mode == StatusWindowRepeatTrack ) {
        string = @"Repeat One Track";
    }
    
    [_window setImage:[NSImage imageNamed:@"Repeat"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildTextWindowWithString:string];
    [_window appear:self];
}

- (void)showSetupQueryWindow
{
    NSString *message = @"Would you like MenuTunes to launch\nautomatically at startup?";

    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:@"Launch at Startup"
                          alternateButton:@"Launch Manually"
                                   target:[PreferencesController sharedPrefs]
                            defaultAction:@selector(autoLaunchOK)
                          alternateAction:@selector(autoLaunchCancel)];

    [_window appear:self];
    [_window setLocked:YES];
}


- (void)showRegistrationQueryWindow
{
    NSString *message = @"Your 7-day unlimited trial period has elapsed.\nYou must register to continue using MenuTunes.";

    [_window setImage:[NSImage imageNamed:@"Register"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:@"Register Now"
                          alternateButton:@"Quit MenuTunes"
                                   target:[MainController sharedController]
                            defaultAction:@selector(registerNowOK)
                          alternateAction:@selector(registerNowCancel)];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showReconnectQueryWindow
{
    NSString *message = @"The selected shared player is available again.\nWould you like to reconnect to it?.";

    [_window setImage:[NSImage imageNamed:@"Register"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:@"Reconnect"
                          alternateButton:@"Ignore"
                                   target:[MainController sharedController]
                            defaultAction:@selector(reconnect)
                          alternateAction:@selector(cancelReconnect)];

    [_window appear:self];
    [_window setLocked:YES];
}

- (void)showPreferencesUpdateWindow
{
    NSString *message = @"The new features in this version of MenuTunes\nrequire you to reconfigure your preferences.";

    [_window setImage:[NSImage imageNamed:@"Setup"]];
    [_window setSizing:(ITTransientStatusWindowSizing)[df integerForKey:@"statusWindowSizing"]];
    [_window buildDialogWindowWithMessage:message
                            defaultButton:@"Show Preferences"
                          alternateButton:@"OK"
                                   target:[MainController sharedController]
                            defaultAction:@selector(showPreferencesAndClose)
                          alternateAction:@selector(cancelReconnect)];

    [_window appear:self];
    [_window setLocked:YES];
}

@end