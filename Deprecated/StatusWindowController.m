#import "StatusWindowController.h"
#import "StatusWindow.h"

@implementation StatusWindowController

- (id)init
{
    if ( (self = [super init]) ) {
        [NSBundle loadNibNamed:@"StatusWindow" owner:self];
        [statusWindow center];
    }
    return self;
}

- (void)setUpcomingSongs:(NSString *)string
{
    int size = 0, i;
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    
    for (i = 0; i < [lines count]; i++) {
        int temp = [[lines objectAtIndex:i] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName]].width;
        
        if (temp > size) {
            size = temp;
        }
    }
    
    if (size < 255) {
        size = 255;
    }
    
    [statusField setStringValue:string];
    [statusWindow setFrame:NSMakeRect(0, 0, size + 45, 40 + ([lines count] * 15)) display:YES];
    [statusWindow center];
    [statusWindow makeKeyAndOrderFront:nil];
}

- (void)setTrackInfo:(NSString *)string
{
    int size = 0, i;
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    
    for (i = 0; i < [lines count]; i++) {
        int temp = [[lines objectAtIndex:i] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName]].width;
        
        if (temp > size) {
            size = temp;
        }
    }
    
    if (size < 285) {
        size = 285;
    }
    
    [statusField setStringValue:string];
    [statusWindow setFrame:NSMakeRect(0, 0, size + 45, 40 + ([lines count] * 16)) display:NO];
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
    for (i = 0.6; i > 0; i -= .004) {
        [statusWindow setAlphaValue:i];
    }
    [statusWindow close];
    [p00l release];
}

@end
