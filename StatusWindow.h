/*
 *	MenuTunes
 *  StatusWindow
 *    ITTransientStatusWindow subclass for MenuTunes
 *
 *  Original Author : Matthew Judy <mjudy@ithinksw.com>
 *   Responsibility : Matthew Judy <mjudy@ithinksw.com>
 *
 *  Copyright (c) 2003 iThink Software.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>
#import <ITKit/ITKit.h>


#define SW_PAD            24.00
#define SW_SPACE          24.00
#define SW_MINW          211.00
#define SW_BORDER         32.00
#define SW_METER_PAD       4.00
#define SW_BUTTON_PAD_R   30.00
#define SW_BUTTON_PAD_B   24.00
#define SW_BUTTON_DIV     12.00
#define SW_BUTTON_EXTRA_W  8.00
#define SW_SHADOW_SAT      1.25

@interface StatusWindow : ITTransientStatusWindow {
    NSImage  *_image;
    BOOL      _locked;
}

- (void)setImage:(NSImage *)newImage;
- (void)setLocked:(BOOL)flag;

- (void)buildTextWindowWithString:(NSString *)text;
- (void)buildMeterWindowWithCharacter:(NSString *)character
                                 size:(float)size
                                count:(int)count
                               active:(int)active;
- (void)buildDialogWindowWithMessage:(NSString *)message
                       defaultButton:(NSString *)title
                     alternateButton:(NSString *)title
                              target:(id)target
                       defaultAction:(SEL)okAction
                     alternateAction:(SEL)alternateAction;           
                         
@end
