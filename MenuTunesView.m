#import "MenuTunesView.h"


@implementation MenuTunesView

- (id)initWithFrame:(NSRect)frame
{
    if ( (self = [super initWithFrame:frame]) )
    {
        images = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSImage imageNamed:@"menu"], @"normal",
            [NSImage imageNamed:@"selected_image"],	@"selected",
            nil];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSImage *image
    [curImage compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
}

- (void)mouseDown:(NSEvent *)event
{
    curImage = altImage;
    [self setNeedsDisplay:YES];
    [super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event
{
    curImage = image;
    [self setNeedsDisplay:YES];
    [super mouseUp:event];
}

@end
