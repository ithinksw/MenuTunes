#import "KeyBroadcaster.h"
#import <Carbon/Carbon.h>

@interface KeyBroadcaster (Private)
- (void)_broadcastKeyCode:(short)keyCode andModifiers:(long)modifiers;
@end

@implementation KeyBroadcaster

- (void)keyDown:(NSEvent *)event
{
    short keyCode;
    long modifiers;
    
    keyCode = [event keyCode];
    modifiers = [event modifierFlags];
    
    modifiers = [KeyBroadcaster cocoaToCarbonModifiers:modifiers];
    if (modifiers > 0) {
        [self _broadcastKeyCode:keyCode andModifiers:modifiers];
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    [self keyDown:event];
    return YES;
}

- (void)_broadcastKeyCode:(short)keyCode andModifiers:(long)modifiers
{
    NSNumber *keycodeNum = [NSNumber numberWithShort:keyCode];
    NSNumber *modifiersNum = [NSNumber numberWithLong:modifiers];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                    keycodeNum, @"KeyCode", modifiersNum, @"Modifiers", nil, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"KeyBroadcasterEvent" object:self userInfo:info];
}

+ (long)cocoaToCarbonModifiers:(long)modifiers
{
    long carbonModifiers = 0;
    int i;
    static long cocoaToCarbon[6][2] = 
    {
        { NSCommandKeyMask, cmdKey },
        { NSAlternateKeyMask, optionKey },
        { NSControlKeyMask, controlKey },
        { NSShiftKeyMask, shiftKey },
    };
    for (i = 0; i < 6; i++)
    {
        if (modifiers & cocoaToCarbon[i][0])
        {
            carbonModifiers += cocoaToCarbon[i][1];
        }
    }
    return carbonModifiers;
}

@end
