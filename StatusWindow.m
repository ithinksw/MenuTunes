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
     // Set default values.
        windowMode  = StatusWindowTextMode;
        image       = [NSImage imageNamed:@"NSApplicationIcon"];
        text        = @"No string set yet.";
        volumeLevel = 0.0;
        
        [self buildStatusWindow];
    }
    
    return self;
}

- (void)buildStatusWindow
{
    NSRect        imageRect;
    NSRect        dataRect;
    float         imageWidth    = 0.0;
    float         imageHeight   = 0.0;
    float         dataWidth     = 0.0;
    float         dataHeight    = 0.0;
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

    if ( windowMode == StatusWindowTextMode ) {
     // Iterate over each line to get text width and height
        while ( (oneLine = [lineEnum nextObject]) ) {
         // Get the width of one line, adding 8.0 because Apple sucks donkey rectum.
            float oneLineWidth = ( [oneLine sizeWithAttributes:attr].width + 8.0 );
         // Add the height of this line to the total text height
            dataHeight += [oneLine sizeWithAttributes:attr].height;
         // If this line wider than the last one, set it as the text width.
            dataWidth = ( ( dataWidth > oneLineWidth ) ? dataWidth : oneLineWidth );
        }
        
     // Add 4.0 to the final dataHeight to accomodate the shadow.
        dataHeight += 4.0;
    } else {
        dataHeight = 24.0;
        dataWidth  = 200.0;
    }
    
     // Set the content height to the greater of the text and image heights.
    contentHeight = ( ( imageHeight > dataHeight ) ? imageHeight : dataHeight );
    
     // Setup the Window, and remove all its contentview's subviews.
    windowWidth  = ( SW_PAD + imageWidth + SW_SPACE + dataWidth + SW_PAD );
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

    dataRect = NSMakeRect( (SW_PAD + imageWidth + SW_SPACE),
                           (SW_PAD + ((contentHeight - dataHeight) / 2)),
                           dataWidth,
                           dataHeight);

    if ( windowMode == StatusWindowTextMode ) {
    
     // Setup, position, fill, and add the text view to the content view.
        textField = [[[ITTextField alloc] initWithFrame:dataRect] autorelease];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setFont:[NSFont fontWithName:@"Lucida Grande Bold" size:18]];
        [textField setTextColor:[NSColor whiteColor]];
        [textField setCastsShadow:YES];
        [textField setStringValue:text];
        [[self contentView] addSubview:textField];
        
    } else if ( windowMode == StatusWindowVolumeMode ) {

        NSEnumerator *cellEnum;
        id            aCell;
        int           lights     = ( ceil(volumeLevel * 100) / 10 );
        int           lightCount = 0;

        volMatrix = [[[NSMatrix alloc] initWithFrame:dataRect
                                                mode:NSHighlightModeMatrix
                                           cellClass:NSClassFromString(@"ITTextFieldCell")
                                        numberOfRows:1
                                     numberOfColumns:10] autorelease];

        [volMatrix setCellSize:NSMakeSize(20, 24)];
        [volMatrix setIntercellSpacing:NSMakeSize(0, 0)];

        cellEnum = [[volMatrix cells] objectEnumerator];
        
        while ( (aCell = [cellEnum nextObject]) ) {
            [aCell setEditable:NO];
            [aCell setSelectable:NO];
            [aCell setBordered:NO];
            [aCell setDrawsBackground:NO];
            [aCell setFont:[NSFont fontWithName:@"Lucida Grande Bold" size:18]];
            [aCell setStringValue:[NSString stringWithUTF8String:"▊"]];

            lightCount ++;

            NSLog(@"%f, %i, %i", volumeLevel, lights, lightCount);

            if ( lights >= lightCount ) {
                [aCell setCastsShadow:YES];
                [aCell setTextColor:[NSColor whiteColor]];
            } else {
                [aCell setCastsShadow:NO];
                [aCell setTextColor:[NSColor darkGrayColor]];
            }

        }
        
        [[self contentView] addSubview:volMatrix];
    }

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
    windowMode = StatusWindowTextMode;
    [self buildStatusWindow];
}

- (void)setVolume:(float)level
{
    volumeLevel = level;
    windowMode = StatusWindowVolumeMode;
    [self buildStatusWindow];
}

@end
