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


#define SW_PAD        24.0
#define SW_SPACE      24.0
#define SW_MINW      211.0
#define SW_BORDER     32.0
#define SW_METER_PAD   4.0


@interface StatusWindow : ITTransientStatusWindow {
    NSImage  *_image;
    BOOL      _locked;
}

- (void)setImage:(NSImage *)newImage;
- (void)setLocked:(BOOL)flag;

- (void)buildTextWindowWithString:(NSString *)text;
- (void)buildMeterWindowWithCharacter:(NSString *)character
                                count:(int)count
                               active:(int)active;
- (void)buildDialogWindowWithMessage:(NSString *)message
                       defaultButton:(NSString *)title
                     alternateButton:(NSString *)title
                              target:(id)target
                       defaultAction:(SEL)okAction
                     alternateAction:(SEL)alternateAction;           
                         
@end
