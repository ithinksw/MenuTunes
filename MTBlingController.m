//
//  MTBlingController.m
//  MenuTunes
//
//  Created by Matthew L. Judy on Tue Aug 19 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//

#import "MTBlingController.h"
#import "MTeSerialNumber.h"
#import "MainController.h"

#define APP_SUPPORT_PATH_STRING [@"~/Library/Application Support/MenuTunes/" stringByExpandingTildeInPath]
#define LICENSE_PATH_STRING [APP_SUPPORT_PATH_STRING stringByAppendingString:@"/.license"]


@interface MTBlingController (Private)
- (void)showPanel;
@end


@implementation MTBlingController


- (void)_HEY {}
- (void)_SUCKA {}
- (void)_QUIT {}
- (void)_HACKING {}
- (void)_AND {}
- (void)_GO {}
- (void)_BUY {}
- (void)_IT {}
- (void)_YOU {}
- (void)_TIGHTWAD {}
- (void)_HAHAHA {}
- (void)_LOLOL {}
- (void)_FIVERSKATES {}

- (id)init
{
    if ( ( self = [super init] ) ) {
        checkDone = 0;
    }
    return self;
}


- (void)showPanel
{
    if ( ! window ) {
        window = [MTShizzleWindow sharedWindowForSender:self];
    }

    [window center];
    [window makeKeyAndOrderFront:nil];
//  [window setLevel:NSStatusWindowLevel];
}

- (void)showPanelIfNeeded
{
    if ( ! (checkDone == 2475) ) {
        if ( ! ([self checkKeyFile] == 7465) ) {
            [self showPanel];
        } else {
            checkDone = 2475;
        }
    }
}

- (void)goToTheStore:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://store.eSellerate.net/s.asp?s=STR090894476"]];
}

- (void)registerLater:(id)sender
{
    [window orderOut:self];
}

- (void)verifyKey:(id)sender
{
    NSString *o = [window owner];
    NSString *k = [window key];

    MTeSerialNumber *s = [[[MTeSerialNumber alloc] initWithSerialNumber:k
                                                                   name:o
                                                                  extra:nil
                                                              publisher:@"04611"] autorelease];
    if ( ([s isValid] == ITeSerialNumberIsValid) && ( [[[s infoDictionary] objectForKey:@"appIdentifier"] isEqualToString:@"MT"] ) ) {
    
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ( ! [fm fileExistsAtPath:APP_SUPPORT_PATH_STRING] ) {
            [fm createDirectoryAtPath:APP_SUPPORT_PATH_STRING attributes:nil];
        }
        
        [[NSDictionary dictionaryWithObjectsAndKeys:
            o, @"Owner",
            k, @"Key",
            nil] writeToFile:LICENSE_PATH_STRING atomically:YES];

        checkDone = 2475;

        NSBeginInformationalAlertSheet(NSLocalizedString(@"validated_title", @"Validated Title"),
                                       @"Thank You!", nil, nil,
                                       window,
                                       self,
                                       @selector(finishValidSheet:returnCode:contextInfo:),
                                       nil,
                                       nil,
                                       NSLocalizedString(@"validated_msg", @"Validated Message"));

    } else {
    
        NSBeginAlertSheet(NSLocalizedString(@"failed_title", @"Failed Title"),
                          @"Try Again", nil, nil,
                          window,
                          self,
                          nil, nil, nil,
                          NSLocalizedString(@"failed_msg", @"Failed Message"));
    }
    [[MainController sharedController] blingTime];
}

- (int)checkKeyFile
{
    NSString        *p = LICENSE_PATH_STRING;
    MTeSerialNumber *k = [[[MTeSerialNumber alloc] initWithContentsOfFile:p
                                                                    extra:@""
                                                                publisher:@"04611"] autorelease];
    if ( k && ([k isValid] == ITeSerialNumberIsValid) && ( [[[k infoDictionary] objectForKey:@"appIdentifier"] isEqualToString:@"MT"] )) {
        return 7465;
    } else {
        [[NSFileManager defaultManager] removeFileAtPath:p handler:nil];
        return 0;
    }

}

- (int)checkDone
{
    if ( ! (checkDone == 2475) ) {
        if ( ! ([self checkKeyFile] == 7465) ) {
            checkDone = 0;
        } else {
            checkDone = 2475;
        }
    }
    return checkDone;
}

- (void)finishValidSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [window orderOut:self];
}

@end
