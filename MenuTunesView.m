#import "MenuTunesView.h"

extern NSColor* _NSGetThemePartColorPattern(int, int, int);

@implementation MenuTunesView

- (id)initWithFrame:(NSRect)frame
{
    if ( (self = [super initWithFrame:frame]) )
    {
        image = [NSImage imageNamed:@"menu"];
        altImage = [NSImage imageNamed:@"selected_image"];
        mouseIsPressed = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSImage *icon;
    NSColor *background;
    
    if ( mouseIsPressed ) {
        icon = altImage;
        background = _NSGetThemePartColorPattern(44, 2, 0);
    } else {
        icon = image;
        background = [NSColor clearColor];
    }
    [background set];
    NSRectFill(rect);
    [icon compositeToPoint:NSMakePoint(((rect.size.width - [icon size].width) / 2), 0)
                 operation:NSCompositeSourceOver];
}

- (void)mouseDown:(NSEvent *)event
{
    mouseIsPressed = YES;
    [self setNeedsDisplay:YES];
    [super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event
{
    mouseIsPressed = NO;
    [self setNeedsDisplay:YES];
    [super mouseUp:event];
}

@end
