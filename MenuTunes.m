#import "MenuTunes.h"
#import "HotKeyCenter.h"

@implementation MenuTunes

- (void)sendEvent:(NSEvent *)event
{
	[[HotKeyCenter sharedCenter] sendEvent:event];
	[super sendEvent:event];
}

@end
