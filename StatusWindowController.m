#import "StatusWindowController.h"
#import "StatusWindow.h"

@implementation StatusWindowController

- (id)init
{
    if ( (self = [super init]) )
    {
        [NSBundle loadNibNamed:@"StatusWindow" owner:self];
        [statusWindow center];
    }
    return self;
}

- (void)setUpcomingSongs:(NSString *)string numSongs:(int)songs
{
    [statusField setStringValue:string];
    [statusWindow setFrame:NSMakeRect(0, 0, 300, 40 + (songs * 17)) display:NO];
    [statusWindow center];
    [statusWindow makeKeyAndOrderFront:nil];
}

- (void)setTrackInfo:(NSString *)string lines:(int)lines
{
    [statusField setStringValue:string];
    [statusWindow setFrame:NSMakeRect(0, 0, 316, 40 + (lines * 17)) display:NO];
    [statusWindow center];
    [statusWindow makeKeyAndOrderFront:nil];
}

- (void)fadeWindowOut
{
    [NSThread detachNewThreadSelector:@selector(fadeOutAux) toTarget:self withObject:nil];
}

- (void)fadeOutAux
{
    NSAutoreleasePool *p00l = [[NSAutoreleasePool alloc] init];
    float i;
    for (i = 1.0; i > 0; i -= .003)
    {
        [statusWindow setAlphaValue:i];
    }
    [statusWindow close];
    [p00l release];
}

@end
