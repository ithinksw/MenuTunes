//
//  StatusWindow.m
//  MenuTunes
//
//  Created by Matt L. Judy on Sat Feb 22 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import "StatusWindow.h"


#define SW_PAD             24.00
#define SW_SPACE           24.00
#define SW_MINW           211.00
#define SW_BORDER          32.00
#define SW_METER_PAD        4.00
#define SW_BUTTON_PAD_R    30.00
#define SW_BUTTON_PAD_B    24.00
#define SW_BUTTON_DIV      12.00
#define SW_BUTTON_EXTRA_W   8.00
#define SW_SHADOW_SAT       1.25
#define SMALL_DIVISOR       1.33333
#define MINI_DIVISOR        1.66667

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
        _image  = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
        _locked = NO;
        _sizing = ITTransientStatusWindowRegular;
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

- (void)setSizing:(ITTransientStatusWindowSizing)newSizing
{
    _sizing = newSizing;
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
    float        divisor       = 1.0;
    NSRect       imageRect;
    float        imageWidth    = 0.0;
    float        imageHeight   = 0.0;
    float        dataWidth     = dataSize.width;
    float        dataHeight    = dataSize.height;
    float        contentHeight = 0.0;
    float        windowWidth   = 0.0;
    float        windowHeight  = 0.0;
    NSRect       visibleFrame  = [[self screen] visibleFrame];
    NSPoint      screenOrigin  = visibleFrame.origin;
    float        screenWidth   = visibleFrame.size.width;
    float        screenHeight  = visibleFrame.size.height;
    float        maxWidth      = ( screenWidth  - (SW_BORDER * 2) );
    float        maxHeight     = ( screenHeight - (SW_BORDER * 2) );
    float        excessWidth   = 0.0;
    float        excessHeight  = 0.0;
    NSPoint      windowOrigin;
    ITImageView *imageView;
    BOOL         shouldAnimate = ( ! (([self visibilityState] == ITWindowAppearingState) ||
                                      ([self visibilityState] == ITWindowVanishingState)) );
        
    if ( _sizing == ITTransientStatusWindowSmall ) {
        divisor = SMALL_DIVISOR;
    } else if ( _sizing == ITTransientStatusWindowMini ) {
        divisor = MINI_DIVISOR;
    }

//  Get image width and height.
    imageWidth  = ( [_image size].width  / divisor );
    imageHeight = ( [_image size].height / divisor );
    
//  Set the content height to the greater of the text and image heights.
    contentHeight = ( ( imageHeight > dataHeight ) ? imageHeight : dataHeight );

//  Setup the Window, and remove all its contentview's subviews.
    windowWidth  = ( (SW_PAD / divisor) + imageWidth + (SW_SPACE / divisor) + dataWidth + (SW_PAD / divisor) );
    windowHeight = ( (SW_PAD / divisor) + contentHeight + (SW_PAD / divisor) );
    
//  Constrain size to max limits.  Adjust data sizes accordingly.
    excessWidth  = (windowWidth  - maxWidth );
    excessHeight = (windowHeight - maxHeight);

    if ( excessWidth > 0.0 ) {
        windowWidth = maxWidth;
        dataWidth -= excessWidth;
    }
    
    if ( excessHeight > 0.0 ) {
        windowHeight = maxHeight;
        dataHeight -= excessHeight;
    }
    
    if ( [self horizontalPosition] == ITWindowPositionLeft ) {
        windowOrigin.x = ( SW_BORDER + screenOrigin.x );
    } else if ( [self horizontalPosition] == ITWindowPositionCenter ) {
        windowOrigin.x = ( screenOrigin.x + (screenWidth / 2) - (windowWidth / 2) );
    } else if ( [self horizontalPosition] == ITWindowPositionRight ) {
        windowOrigin.x = ( screenOrigin.x + screenWidth - (windowWidth + SW_BORDER) );
    }
    
    if ( [self verticalPosition] == ITWindowPositionTop ) {
        windowOrigin.y = ( screenOrigin.y + screenHeight - (windowHeight + SW_BORDER) );
    } else if ( [self verticalPosition] == ITWindowPositionMiddle ) {
//      Middle-oriented windows should be slightly proud of the screen's middle.
        windowOrigin.y = ( (screenOrigin.y + (screenHeight / 2) - (windowHeight / 2)) + (screenHeight / 8) );
    } else if ( [self verticalPosition] == ITWindowPositionBottom ) {
        windowOrigin.y = ( SW_BORDER + screenOrigin.y );
    }
    
    [self setFrame:NSMakeRect( windowOrigin.x,
                               windowOrigin.y,
                               windowWidth,
                               windowHeight) display:YES animate:shouldAnimate];

    [[[self contentView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
//  Setup, position, fill, and add the image view to the content view.
    imageRect = NSMakeRect( (SW_PAD / divisor) + 4,
                            ((SW_PAD / divisor) + ((contentHeight - imageHeight) / 2)),
                            imageWidth,
                            imageHeight );
    imageView = [[[ITImageView alloc] initWithFrame:imageRect] autorelease];
    [imageView setAutoresizingMask:(NSViewMinYMargin | NSViewMaxYMargin)];
    [imageView setImage:_image];
    [imageView setCastsShadow:YES];
    [[self contentView] addSubview:imageView];

    return NSMakeRect( ((SW_PAD / divisor) + imageWidth + (SW_SPACE / divisor)),
                       ((SW_PAD / divisor) + ((contentHeight - dataHeight) / 2)),
                       dataWidth,
                       dataHeight);
}

- (void)buildTextWindowWithString:(NSString *)text
{
    if ( ! _locked ) {

        float         divisor       = 1.0;
        float         dataWidth     = 0.0;
        float         dataHeight    = 0.0;
        NSRect        dataRect;
        NSArray      *lines         = [text componentsSeparatedByString:@"\n"];
        id			  oneLine       = nil;
        NSEnumerator *lineEnum      = [lines objectEnumerator];
        float         baseFontSize  = 18.0;
        ITTextField  *textField;
        NSFont       *font;
        NSDictionary *attr;

        if ( _sizing == ITTransientStatusWindowSmall ) {
            divisor = SMALL_DIVISOR;
        } else if ( _sizing == ITTransientStatusWindowMini ) {
            divisor = MINI_DIVISOR;
        }

        font = [NSFont fontWithName:@"Lucida Grande Bold" size:(baseFontSize / divisor)];
        attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        
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
        [textField setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setFont:font];
        [textField setTextColor:[NSColor whiteColor]];
        [textField setCastsShadow:YES];
        [[textField cell] setWraps:NO];
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

        float         divisor     = 1.0;
        NSFont       *font;
        NSDictionary *attr;
        NSSize        charSize;
        float         cellHeight;
        float         cellWidth;
        float         dataWidth;
        NSRect        dataRect;
        NSEnumerator *cellEnum    = nil;
        id            aCell       = nil;
        int           activeCount = 0;
        NSColor      *onColor     = [NSColor whiteColor];
        NSColor      *offColor    = [NSColor colorWithCalibratedWhite:0.15 alpha:0.50];
        NSMatrix     *volMatrix;
        
        if ( _sizing == ITTransientStatusWindowSmall ) {
            divisor = SMALL_DIVISOR;
        } else if ( _sizing == ITTransientStatusWindowMini ) {
            divisor = MINI_DIVISOR;
        }
        
        font        = [NSFont fontWithName:@"Lucida Grande Bold" size:( size / divisor )];
        attr        = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        charSize    = [character sizeWithAttributes:attr];
        cellHeight  = ( charSize.height + 4.0 );  // Add 4.0 for shadow
        cellWidth   = ( (charSize.width) + (SW_METER_PAD / divisor) );
        dataWidth   = ( cellWidth * count );
        dataRect    = [self setupWindowWithDataSize:NSMakeSize(dataWidth, cellHeight)];
        volMatrix   = [[[NSMatrix alloc] initWithFrame:dataRect
                                                  mode:NSHighlightModeMatrix
                                             cellClass:NSClassFromString(@"ITTextFieldCell")
                                          numberOfRows:1
                                       numberOfColumns:count] autorelease];
        
        [volMatrix setCellSize:NSMakeSize(cellWidth, cellHeight)];
        [volMatrix setIntercellSpacing:NSMakeSize(0, 0)];
        [volMatrix setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];

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

        float         divisor       = 1.0;
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
        float         baseFontSize  = 18.0;
        ITTextField  *textField;
        ITButton     *okButton;
        ITButton     *cancelButton;
        NSColor      *textColor     = [NSColor whiteColor];
        NSFont       *font;
        NSDictionary *attr;
        NSFont       *buttonFont;
        NSDictionary *buttonAttr;
        
        if ( _sizing == ITTransientStatusWindowSmall ) {
            divisor = SMALL_DIVISOR;
        } else if ( _sizing == ITTransientStatusWindowMini ) {
            divisor = MINI_DIVISOR;
        }
        
        font = [NSFont fontWithName:@"Lucida Grande Bold" size:(baseFontSize / divisor)];
        attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        buttonFont = [NSFont fontWithName:@"Lucida Grande Bold" size:(14 / divisor)];
        buttonAttr = [NSDictionary dictionaryWithObjectsAndKeys:
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
        [okButton     setTarget:target];
        [cancelButton setTarget:target];
        [okButton     setAction:okAction];
        [cancelButton setAction:alternateAction];
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

        [self setIgnoresMouseEvents:NO];
  
//      Display the window.
        [[self contentView] setNeedsDisplay:YES];
    }
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
    return (NSTimeInterval)0.25;
}

@end
