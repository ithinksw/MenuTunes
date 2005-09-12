//
//  iTunesRemoteControl.h
//  MenuTunes
//
//  Created by Matt L. Judy on Sun Jan 05 2003.
//  Copyright (c) 2003 iThink Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ITMTRemote/ITMTRemote.h>
#import <ITFoundation/ITFoundation.h>
#import <ITMac/ITMac.h>

@class PlaylistNode;

@interface iTunesRemote : ITMTRemote <ITMTRemote>
{
    ProcessSerialNumber savedPSN;
	float _iTunesVersion;
}
- (BOOL)isPlaying;
- (ProcessSerialNumber)iTunesPSN;
- (NSString*)formatTimeInSeconds:(long)seconds;
- (NSString*)zeroSixty:(int)seconds;
@end
