//
//  MenuTunesView.m
//  MenuTunes
//
//  Created by Kent Sutherland on Tue Nov 19 2002.
//  Copyright (c) 2002 Kent Sutherland. All rights reserved.
//

#import "MenuTunesView.h"


@implementation MenuTunesView

- (id)initWithFrame:(NSRect)frame
{
    if ( (self = [super initWithFrame:frame]) )
    {
        image = [NSImage imageNamed:@"menu"];
        altImage = [NSImage imageNamed:@"selected_image"];
	curImage = image;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
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
