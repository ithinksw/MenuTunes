#import "MyTableView.h"
#import "PreferencesController.h"

@implementation MyTableView

- (void)keyDown:(NSEvent *)event
{
    if ([[event characters] characterAtIndex:0] == '\177') {
        [[PreferencesController sharedPrefs] deletePressedInTableView:self];
    } else {
        [super keyDown:event];
    }
}

@end
