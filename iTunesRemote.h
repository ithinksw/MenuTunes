//
//  iTunesRemoteControl.h
//  MenuTunes
//
//  Created by Matt L. Judy on Sun Jan 05 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ITMTRemote/ITMTRemote.h>
#import <ITFoundation/ITFoundation.h>

@interface iTunesRemote : ITMTRemote <ITMTRemote>
{
}
- (ProcessSerialNumber)iTunesPSN;
@end
