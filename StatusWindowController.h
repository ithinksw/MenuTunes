/*
 *	MenuTunes
 *  StatusWindowController
 *    ...
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2002 iThink Software.
 *  All Rights Reserved
 *
 */


#import <Cocoa/Cocoa.h>

@class StatusWindow;

@interface StatusWindowController : NSObject
{
    IBOutlet NSTextField *statusField;
    IBOutlet StatusWindow *statusWindow;
}
- (void)setUpcomingSongs:(NSString *)string numSongs:(int)songs;
- (void)setTrackInfo:(NSString *)string lines:(int)lines;
- (void)fadeWindowOut;
@end
