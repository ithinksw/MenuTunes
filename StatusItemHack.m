#import "StatusItemHack.h"
#import "MainController.h"

@implementation StatusItemHack

+ (void)install
{
    [StatusItemHack poseAsClass:[NSStatusBarButton class]];
}

- (void)mouseDown:(NSEvent *)event
{
    [[MainController sharedController] menuClicked];
    [super mouseDown:event];
}

@end
