/* StatusWindowController */

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
