//
//  StatusWindow.m
//  MenuTunes
//
//  Created by Matt L. Judy on Sat Feb 22 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import "StatusWindow.h"

@interface StatusWindow (Private)
- (NSRect)setupWindowWithDataSize:(NSSize)dataSize;
@end

@implementation StatusWindow

/*************************************************************************/
#pragma mark -
#pragma mark INITIALIZATION / DEALLOCATION METHODS
/*************************************************************************/

- (id)initWithContentView:(NSView *)contentView
                 exitMode:(ITTransientStatusWindowExitMode)exitMode
           backgroundType:(ITTransientStatusWindowBackgroundType)backgroundType
{
    if ( ( self = [super initWithContentView:contentView
                               exitMode:exitMode
                         backgroundType:backgroundType] ) ) {
     // Set default values.
        _image       = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
        _groupNoun   = [@"Playlist" retain];
        _locked      = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [_image     release];
    [_groupNoun release];
    [super dealloc];
}


/*************************************************************************/
#pragma mark -
#pragma mark ACCESSOR METHODS
/*************************************************************************/

- (void)setImage:(NSImage *)newImage
{
    [_image autorelease];
    _image = [newImage copy];
}

- (void)setGroupNoun:(NSString *)newNoun;
{
    [_groupNoun autorelease];
    _groupNoun = [newNoun copy];
}

- (void)setLocked:(BOOL)flag
{
    _locked = flag;
}


/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (NSRect)setupWindowWithDataSize:(NSSize)dataSize
{
    NSRect       imageRect;
    float        imageWidth    = 0.0;
    float        imageHeight   = 0.0;
    float        dataWidth     = dataSize.width;
    float        dataHeight    = dataSize.height;
    float        contentHeight = 0.0;
    float        windowWidth   = 0.0;
    float        windowHeight  = 0.0;
    NSImageView *imageView;

//  Get image width and height.
    imageWidth  = [_image size].width;
    imageHeight = [_image size].height;
    
//  Set the content height to the greater of the text and image heights.
    contentHeight = ( ( imageHeight > dataHeight ) ? imageHeight : dataHeight );

//  Setup the Window, and remove all its contentview's subviews.
    windowWidth  = ( SW_PAD + imageWidth + SW_SPACE + dataWidth + SW_PAD );
    windowHeight = ( SW_PAD + contentHeight + SW_PAD );
    [self setFrame:NSMakeRect(SW_BORDER, SW_BORDER, windowWidth, windowHeight) display:YES];
    [[[self contentView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

//  Setup, position, fill, and add the image view to the content view.
    imageRect = NSMakeRect( SW_PAD,
                            (SW_PAD + ((contentHeight - imageHeight) / 2)),
                            imageWidth,
                            imageHeight );
    imageView = [[[NSImageView alloc] initWithFrame:imageRect] autorelease];
    [imageView setImage:_image];
    [[self contentView] addSubview:imageView];

    return NSMakeRect( (SW_PAD + imageWidth + SW_SPACE),
                       (SW_PAD + ((contentHeight - dataHeight) / 2)),
                       dataWidth,
                       dataHeight);
}

- (void)buildTextWindowWithString:(NSString *)text
{
    float         dataWidth     = 0.0;
    float         dataHeight    = 0.0;
    NSRect        dataRect;
    NSArray      *lines         = [text componentsSeparatedByString:@"\n"];
    id			  oneLine       = nil;
    NSEnumerator *lineEnum      = [lines objectEnumerator];
    NSFont       *font          = [NSFont fontWithName:@"Lucida Grande Bold" size:18];
    NSDictionary *attr          = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    ITTextField  *textField;
    
//  Iterate over each line to get text width and height
    while ( (oneLine = [lineEnum nextObject]) ) {
//      Get the width of one line, adding 8.0 because Apple sucks donkey rectum.
        float oneLineWidth = ( [oneLine sizeWithAttributes:attr].width + 8.0 );
//      Add the height of this line to the total text height
        dataHeight += [oneLine sizeWithAttributes:attr].height;
//      If this line wider than the last one, set it as the text width.
        dataWidth = ( ( dataWidth > oneLineWidth ) ? dataWidth : oneLineWidth );
    }
        
//  Add 4.0 to the final dataHeight to accomodate the shadow.
    dataHeight += 4.0;
    
    dataRect = [self setupWindowWithDataSize:NSMakeSize(dataWidth, dataHeight)];
    
//  Create, position, setup, fill, and add the text view to the content view.
    textField = [[[ITTextField alloc] initWithFrame:dataRect] autorelease];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setFont:font];
    [textField setTextColor:[NSColor whiteColor]];
    [textField setCastsShadow:YES];
    [textField setStringValue:text];
    [[self contentView] addSubview:textField];
    
//  Display the window.
    [[self contentView] setNeedsDisplay:YES];
}

- (void)buildMeterWindowWithCharacter:(NSString *)character
                                count:(int)count
                               active:(int)active
{
    NSFont       *font        = [NSFont fontWithName:@"Lucida Grande Bold" size:18];
    NSDictionary *attr        = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSSize        charSize    = [character sizeWithAttributes:attr];
    float         cellHeight  = ( charSize.height + 4.0 );                 // Add 4.0 for shadow
    float         cellWidth   = ( (charSize.width) + SW_METER_PAD ); // Add 8.0 for Apple suck
    float         dataWidth   = ( cellWidth * count );
    NSRect        dataRect    = [self setupWindowWithDataSize:NSMakeSize(dataWidth, cellHeight)];
    NSEnumerator *cellEnum    = nil;
    id            aCell       = nil;
    int           activeCount = 0;
    NSMatrix     *volMatrix   = [[[NSMatrix alloc] initWithFrame:dataRect
                                                            mode:NSHighlightModeMatrix
                                                       cellClass:NSClassFromString(@"ITTextFieldCell")
                                                    numberOfRows:1
                                                 numberOfColumns:count] autorelease];

    [volMatrix setCellSize:NSMakeSize(cellWidth, cellHeight)];
    [volMatrix setIntercellSpacing:NSMakeSize(0, 0)];

    cellEnum = [[volMatrix cells] objectEnumerator];

    while ( (aCell = [cellEnum nextObject]) ) {
        [aCell setEditable:NO];
        [aCell setSelectable:NO];
        [aCell setBordered:NO];
        [aCell setDrawsBackground:NO];
        [aCell setAlignment:NSCenterTextAlignment];
        [aCell setFont:font];
        [aCell setStringValue:character];

        activeCount ++;
        
        if ( active >= activeCount ) {
            [aCell setCastsShadow:YES];
            [aCell setTextColor:[NSColor whiteColor]];
        } else {
            [aCell setCastsShadow:NO];
            [aCell setTextColor:[NSColor darkGrayColor]];
        }
        
    }

    [[self contentView] addSubview:volMatrix];
    [[self contentView] setNeedsDisplay:YES];
}

- (void)buildDialogWindowWithMessage:(NSString *)message
                       defaultButton:(NSString *)defaultTitle
                     alternateButton:(NSString *)alternateTitle
                              target:(id)target
                       defaultAction:(SEL)okAction
                     alternateAction:(SEL)alternateAction
{

}


@end
