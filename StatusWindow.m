//
//  StatusWindow.m
//  MenuTunes
//
//  Created by Matt L. Judy on Sat Feb 22 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import "StatusWindow.h"


@interface StatusWindow (Private)
- (void)buildStatusWindow;
@end


@implementation StatusWindow

- (id)initWithContentView:(NSView *)contentView
                 exitMode:(ITTransientStatusWindowExitMode)exitMode
           backgroundType:(ITTransientStatusWindowBackgroundType)backgroundType
{
    if ( ( self = [super initWithContentView:contentView
                               exitMode:exitMode
                         backgroundType:backgroundType]) ) {
     // Default images and text.
        image = [NSImage imageNamed:@"NSApplicationIcon"];
        text  = @"No string set yet.";
        [self buildStatusWindow];
    }
    return self;
}

- (void)buildStatusWindow
{
    NSRect        imageRect;
    NSRect        textRect;
    float         imageWidth    = 0.0;
    float         imageHeight   = 0.0;
    float         textWidth     = 0.0;
    float         textHeight    = 0.0;
    float         contentHeight = 0.0;
    float         windowWidth   = 0.0;
    float         windowHeight  = 0.0;
    NSArray      *lines         = [text componentsSeparatedByString:@"\n"];
    id			  oneLine       = nil;
    NSEnumerator *lineEnum      = [lines objectEnumerator];
    NSFont       *font          = [NSFont fontWithName:@"Lucida Grande Bold" size:18];
    NSDictionary *attr          = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    
     // Get image width and height.
    imageWidth  = [image size].width;
    imageHeight = [image size].height;
    
     // Iterate over each line to get text width and height
    while ( oneLine = [lineEnum nextObject] ) {
         // Get the width of one line, adding 8.0 because Apple sucks donkey rectum.
        float oneLineWidth = ( [oneLine sizeWithAttributes:attr].width + 8.0 );
         // Add the height of this line to the total text height
        textHeight += [oneLine sizeWithAttributes:attr].height;
         // If this line wider than the last one, set it as the text width.
        textWidth = ( ( textWidth > oneLineWidth ) ? textWidth : oneLineWidth );
    }
    
     // Add 4.0 to the final textHeight to accomodate the shadow.
    textHeight += 4.0;
    
     // Set the content height to the greater of the text and image heights.
    contentHeight = ( ( imageHeight > textHeight ) ? imageHeight : textHeight );
    
     // Setup the Window, and remove all its contentview's subviews.
    windowWidth  = ( SW_PAD + imageWidth + SW_SPACE + textWidth + SW_PAD );
    windowHeight = ( SW_PAD + contentHeight + SW_PAD );
    [self setFrame:NSMakeRect(SW_BORDER, SW_BORDER, windowWidth, windowHeight) display:YES];
    [[[self contentView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
     // Setup, position, fill, and add the image view to the content view.
    imageRect = NSMakeRect( SW_PAD,
                            (SW_PAD + ((contentHeight - imageHeight) / 2)),
                            imageWidth,
                            imageHeight );
    imageView = [[[NSImageView alloc] initWithFrame:imageRect] autorelease];
    [imageView setImage:image];
    [[self contentView] addSubview:imageView];
    
     // Setup, position, fill, and add the text view to the content view.
    textRect = NSMakeRect( (SW_PAD + imageWidth + SW_SPACE),
                           (SW_PAD + ((contentHeight - textHeight) / 2)),
                           textWidth,
                           textHeight);
    textField = [[[ITTextField alloc] initWithFrame:textRect] autorelease];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setFont:[NSFont fontWithName:@"Lucida Grande Bold" size:18]];
    [textField setTextColor:[NSColor whiteColor]];
    [textField setCastsShadow:YES];
    [textField setStringValue:text];
    [[self contentView] addSubview:textField];

    [[self contentView] setNeedsDisplay:YES];
    
}

- (void)setImage:(NSImage *)newImage
{
    [image autorelease];
    image = [newImage copy];
    [self buildStatusWindow];
}

- (void)setText:(NSString *)newText
{
    [text autorelease];
    text = [newText copy];
    [self buildStatusWindow];
}



@end
