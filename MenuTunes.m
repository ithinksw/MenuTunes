#import "MenuTunes.h"
#import <ITKit/ITHotKeyCenter.h>

@implementation MenuTunes

- (void)sendEvent:(NSEvent *)event
{
	[[ITHotKeyCenter sharedCenter] sendEvent:event];
	[super sendEvent:event];
}

@end
