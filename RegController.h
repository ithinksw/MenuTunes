/*
 *	MenuTunes
 *  StatusWindow
 *    ...
 *
 *  Original Author : Alexander Strange <astrange@ithinksw.com>
 *   Responsibility : Alexander Strange <astrange@ithinksw.com>
 *
 *  Copyright (c) 2002 iThink Software.
 *  All Rights Reserved
 *
 */

#ifdef REGISTRATION
#import <Cocoa/Cocoa.h>
#import "keyverify.h"

@interface RegController : NSObject
{
    IBOutlet NSTextField *keyField;
    IBOutlet NSTextField *nameField;
    IBOutlet NSWindow *f;
    IBOutlet NSWindow *g;
    IBOutlet NSWindow *n;
}
- (IBAction)verifyRegistration:(id)sender;
- (IBAction)dismiss:(id)sender;
@end
#endif