/* StatusItemHack */

#import <Cocoa/Cocoa.h>

@interface NSStatusBarButton : NSButton
{
}
@end

@interface StatusItemHack : NSStatusBarButton
{
}
+ (void)install;
@end
