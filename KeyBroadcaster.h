/* KeyBroadcaster */

#import <Cocoa/Cocoa.h>

@interface KeyBroadcaster : NSButton
{
}
+ (long)cocoaToCarbonModifiers:(long)modifiers;
@end
