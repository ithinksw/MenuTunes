#import "MenuTunes.h"
#import "HotKeyCenter.h"

@implementation MTApplication

- (void)sendEvent:(NSEvent *)event
{
	[[HotKeyCenter sharedCenter] sendEvent:event];
	[super sendEvent:event];
}

@end
