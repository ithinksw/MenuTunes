/*
 *	MenuTunes
 *	StatusItemHack.h
 *
 *	Copyright (c) 2003 iThink Software
 *
 */

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
