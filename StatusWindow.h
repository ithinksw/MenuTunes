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

@interface StatusWindow : ITTransientStatusWindow {
    NSImage            *_image;
    BOOL                _locked;
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
