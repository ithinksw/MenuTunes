#import "StatusItemHack.h"
#import "MainController.h"

@implementation StatusItemHack

+ (void)install
{
    [StatusItemHack poseAsClass:[NSStatusBarButton class]];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([self isEnabled]) {
		[[MainController sharedController] menuClicked];
	}
    [super mouseDown:event];
}

@end
