/*
 *	MenuTunes
 *	StatusWindow.h
 *
 *	ITTransientStatusWindow subclass for MenuTunes.
 *
 *	Copyright (c) 2003 iThink Software
 *
 */

#import <Cocoa/Cocoa.h>
#import <ITKit/ITKit.h>

#define SMALL_DIVISOR       1.33333
#define MINI_DIVISOR        1.66667

@interface StatusWindow : ITTransientStatusWindow {
    NSImage            *_image;
    BOOL                _locked;
	NSTextField		   *_textField;
}

- (void)setImage:(NSImage *)newImage;
- (void)setLocked:(BOOL)flag;

- (void)buildImageWindowWithImage:(NSImage *)image;
- (void)buildTextWindowWithString:(id)text;
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

- (void)updateTime:(NSString *)time range:(NSRange)range;
@end
