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
        _locked      = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [_image     release];
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

- (void)setLocked:(BOOL)flag
{
    _locked = flag;
    [self setExitMode:(flag ? ITTransientStatusWindowExitOnCommand : ITTransientStatusWindowExitAfterDelay)];
}


/*************************************************************************/
#pragma mark -
#pragma mark INSTANCE METHODS
/*************************************************************************/

- (void)appear:(id)sender
{
    if ( ! _locked ) {
        [super appear:sender];
    }
}

- (void)vanish:(id)sender
{
    if ( ! _locked ) {
        [super vanish:sender];
    }
}

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
    [self setFrame:NSMakeRect( (SW_BORDER + [[self screen] visibleFrame].origin.x),
                               (SW_BORDER + [[self screen] visibleFrame].origin.y),
                               windowWidth,
                               windowHeight) display:YES];
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
    if ( ! _locked ) {

        float         dataWidth     = 0.0;
        float         dataHeight    = 0.0;
        NSRect        dataRect;
        NSArray      *lines         = [text componentsSeparatedByString:@"\n"];
        id			  oneLine       = nil;
        NSEnumerator *lineEnum      = [lines objectEnumerator];
        NSFont       *font          = [NSFont fontWithName:@"Lucida Grande Bold" size:18];
        NSDictionary *attr          = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        ITTextField  *textField;
        
//      Iterate over each line to get text width and height
        while ( (oneLine = [lineEnum nextObject]) ) {
//          Get the width of one line, adding 8.0 because Apple sucks donkey rectum.
            float oneLineWidth = ( [oneLine sizeWithAttributes:attr].width + 8.0 );
//          Add the height of this line to the total text height
            dataHeight += [oneLine sizeWithAttributes:attr].height;
//          If this line wider than the last one, set it as the text width.
            dataWidth = ( ( dataWidth > oneLineWidth ) ? dataWidth : oneLineWidth );
        }
        
//      Add 4.0 to the final dataHeight to accomodate the shadow.
        dataHeight += 4.0;

        dataRect = [self setupWindowWithDataSize:NSMakeSize(dataWidth, dataHeight)];
        
//      Create, position, setup, fill, and add the text view to the content view.
        textField = [[[ITTextField alloc] initWithFrame:dataRect] autorelease];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setFont:font];
        [textField setTextColor:[NSColor whiteColor]];
        [textField setCastsShadow:YES];
        [textField setStringValue:text];
        [textField setShadowSaturation:SW_SHADOW_SAT];
        [[self contentView] addSubview:textField];
        
//      Display the window.
        [[self contentView] setNeedsDisplay:YES];

    }
}

- (void)buildMeterWindowWithCharacter:(NSString *)character
                                 size:(float)size
                                count:(int)count
                               active:(int)active
{
    if ( ! _locked ) {

        NSFont       *font        = [NSFont fontWithName:@"Lucida Grande Bold" size:size];
        NSDictionary *attr        = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        NSSize        charSize    = [character sizeWithAttributes:attr];
        float         cellHeight  = ( charSize.height + 4.0 );                 // Add 4.0 for shadow
        float         cellWidth   = ( (charSize.width) + SW_METER_PAD ); // Add 8.0 for Apple suck
        float         dataWidth   = ( cellWidth * count );
        NSRect        dataRect    = [self setupWindowWithDataSize:NSMakeSize(dataWidth, cellHeight)];
        NSEnumerator *cellEnum    = nil;
        id            aCell       = nil;
        int           activeCount = 0;
        NSColor      *onColor     = [NSColor whiteColor];
        NSColor      *offColor    = [NSColor colorWithCalibratedWhite:0.15 alpha:0.50];
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
            [aCell setShadowSaturation:SW_SHADOW_SAT];

            activeCount ++;

            if ( active >= activeCount ) {
                [aCell setCastsShadow:YES];
                [aCell setTextColor:onColor];
            } else {
                [aCell setCastsShadow:NO];
                [aCell setTextColor:offColor];
            }

        }

        [[self contentView] addSubview:volMatrix];
        [[self contentView] setNeedsDisplay:YES];
        
    }
}

- (void)buildDialogWindowWithMessage:(NSString *)message
                       defaultButton:(NSString *)defaultTitle
                     alternateButton:(NSString *)alternateTitle
                              target:(id)target
                       defaultAction:(SEL)okAction
                     alternateAction:(SEL)alternateAction
{
    if ( ! _locked ) {

        float         textWidth     = 0.0;
        float         textHeight    = 0.0;
        float         okWidth       = 0.0;
        float         cancelWidth   = 0.0;
        float         wideButtonW   = 0.0;
        float         buttonWidth   = 0.0;
        float         dataHeight    = 0.0;
        float         dataWidth     = 0.0;
        NSRect        dataRect;
        float         textY         = 0.0;
        NSRect        textRect;
        float         textAddBelow  = 32.0;
        float         dataMinH      = 92.0;
        float         textMinH      = 48.0;
        NSArray      *lines         = [message componentsSeparatedByString:@"\n"];
        id			  oneLine       = nil;
        NSEnumerator *lineEnum      = [lines objectEnumerator];
        ITTextField  *textField;
        ITButton     *okButton;
        ITButton     *cancelButton;
        NSColor      *textColor     = [NSColor whiteColor];
        NSFont       *font          = [NSFont fontWithName:@"Lucida Grande Bold" size:18];
        NSDictionary *attr          = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        NSFont       *buttonFont    = [NSFont fontWithName:@"Lucida Grande Bold" size:14];
        NSDictionary *buttonAttr    = [NSDictionary dictionaryWithObjectsAndKeys:
            buttonFont , NSFontAttributeName,
            textColor  , NSForegroundColorAttributeName, 
            nil];
        
//      Iterate over each line to get text width and height
        while ( (oneLine = [lineEnum nextObject]) ) {
//          Get the width of one line, adding 8.0 because Apple sucks donkey rectum.
            float oneLineWidth = ( [oneLine sizeWithAttributes:attr].width + 8.0 );
//          Add the height of this line to the total text height
            textHeight += [oneLine sizeWithAttributes:attr].height;
//          If this line wider than the last one, set it as the text width.
            textWidth = ( ( textWidth > oneLineWidth ) ? textWidth : oneLineWidth );
        }
        
//      Add 4.0 to the final dataHeight to accomodate the shadow.
        textHeight += 4.0;
        
//      Add extra padding below the text
        dataHeight = (textHeight + textAddBelow);
        
//      Test to see if data height is tall enough
        if ( dataHeight < dataMinH ) {
            dataHeight = dataMinH;
        }
        
//      Make the buttons, set the titles, and size them to fit their titles
        okButton     = [[ITButton alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        cancelButton = [[ITButton alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        [okButton     setBezelStyle:ITGrayRoundedBezelStyle];
        [cancelButton setBezelStyle:ITGrayRoundedBezelStyle];
        [okButton     setAlignment:NSRightTextAlignment];
        [cancelButton setAlignment:NSCenterTextAlignment];
        [okButton     setImagePosition:NSNoImage];
        [cancelButton setImagePosition:NSNoImage];
        [okButton     setAttributedTitle:[[[NSAttributedString alloc] initWithString:defaultTitle
                                                                          attributes:buttonAttr] autorelease]];
        [cancelButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:alternateTitle
                                                                          attributes:buttonAttr] autorelease]];
        [okButton     sizeToFit];
        [cancelButton sizeToFit];
        
//      Get the button widths.  Add any extra width here.
        okWidth     = ([okButton     frame].size.width + SW_BUTTON_EXTRA_W);
        cancelWidth = ([cancelButton frame].size.width + SW_BUTTON_EXTRA_W);
        
//      Figure out which button is wider.
        wideButtonW = ( (okWidth > cancelWidth) ? okWidth : cancelWidth );

//      Get the total width of the buttons. Add the divider space.
        buttonWidth = ( (wideButtonW * 2) + SW_BUTTON_DIV );

//      Set the dataWidth to whichever is greater: text width or button width.
        dataWidth = ( (textWidth > buttonWidth) ? textWidth : buttonWidth);
        
//      Setup the window
        dataRect = [self setupWindowWithDataSize:NSMakeSize(dataWidth, dataHeight)];
        
//      Set an initial vertical point for the textRect's origin.
        textY = dataRect.origin.y + textAddBelow;
        
//      Move that point up if the minimimum height of the text area is not occupied.
        if ( textHeight < textMinH ) {
            textY += ( (textMinH - textHeight) / 2 );
        }
        
//      Build the text rect.
        textRect = NSMakeRect(dataRect.origin.x,
                              textY,
                              textWidth,
                              textHeight);
        
//      Create, position, setup, fill, and add the text view to the content view.
        textField = [[[ITTextField alloc] initWithFrame:textRect] autorelease];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setFont:font];
        [textField setTextColor:textColor];
        [textField setCastsShadow:YES];
        [textField setStringValue:message];
        [textField setShadowSaturation:SW_SHADOW_SAT];
        [[self contentView] addSubview:textField];
        
//      Set the button frames, and add them to the content view.
        [okButton setFrame:NSMakeRect( ([[self contentView] frame].size.width - (wideButtonW + SW_BUTTON_PAD_R) ),
                                       SW_BUTTON_PAD_B,
                                       wideButtonW,
                                       24.0)];
        [cancelButton setFrame:NSMakeRect( ([[self contentView] frame].size.width - ((wideButtonW * 2) + SW_BUTTON_DIV + SW_BUTTON_PAD_R) ),
                                           SW_BUTTON_PAD_B,
                                           wideButtonW,
                                           24.0)];
        [[self contentView] addSubview:okButton];
        [[self contentView] addSubview:cancelButton];
        NSLog(@"%@", [[self contentView] description]);

        [self setIgnoresMouseEvents:NO];
  
//      Display the window.
        [[self contentView] setNeedsDisplay:YES];
    }
}


@end
