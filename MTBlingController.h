//
//  MTBlingController.h
//  MenuTunes
//
//  Created by Matthew L. Judy on Tue Aug 19 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MTShizzleWindow.h"

@interface MTBlingController : NSObject {

    MTShizzleWindow *window;

    int	checkDone;

}


- (void)showPanel;
- (void)showPanelIfNeeded;

- (void)goToTheStore:(id)sender;
- (void)registerLater:(id)sender;
- (void)verifyKey:(id)sender;

- (int)checkKeyFile;
- (int)checkDone;


@end
