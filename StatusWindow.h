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


#define SW_PAD    24.0
#define SW_SPACE  24.0
#define SW_MINW   211.0
#define SW_BORDER 32.0

typedef enum {
    StatusWindowTextMode,
    StatusWindowVolumeMode
} StatusWindowMode;

@interface StatusWindow : ITTransientStatusWindow {
    NSImage          *image;
    NSString         *text;
    NSImageView      *imageView;
    ITTextField      *textField;
    NSMatrix         *volMatrix;
    StatusWindowMode  windowMode;
    float             volumeLevel;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSString *)newText;
- (void)setVolume:(float)level;

@end
