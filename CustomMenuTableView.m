#import "CustomMenuTableView.h"
#import "PreferencesController.h"

@implementation CustomMenuTableView

- (void)keyDown:(NSEvent *)event
{
    if ([[event characters] characterAtIndex:0] == '\177') {
        [[PreferencesController sharedPrefs] deletePressedInTableView:self];
    } else {
        [super keyDown:event];
    }
}

@end
