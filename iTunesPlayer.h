//
//  iTunesPlayer.h
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ITFoundation/ITFoundation.h>
#import <ITMTRemote/ITMTRemote.h>

@interface iTunesPlayer : ITMTPlayer <ITMTPlayer> {
    iTunesRemote	*_remote;
}

@end
