#import "StatusItemHack.h"
#import "NewMainController.h"

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
