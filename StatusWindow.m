#import "StatusWindow.h"

@implementation StatusWindow

- (id)initWithContentRect:(NSRect)rect styleMask:(unsigned int)mask backing:(NSBackingStoreType)type defer:(BOOL)flag
{
    if ( (self = [super initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:type defer:flag]) )
    {
        [self setHasShadow:NO];
        [self setOpaque:NO];
        [self setLevel:NSStatusWindowLevel];
        [self setIgnoresMouseEvents:YES];
        [self setBackgroundColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.6]];
    }
    return self;
}

@end
