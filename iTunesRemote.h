//
//  iTunesRemote.h
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import <ITMTRemote/ITMTRemote.h>

@interface iTunesRemote : ITMTRemote <ITMTRemote> {
    ProcessSerialNumber	_currentPSN;
    iTunesPlayer _player;
    BOOL _activated;
}
- (ProcessSerialNumber)iTunesPSN;
@end
