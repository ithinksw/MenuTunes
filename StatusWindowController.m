//
//  StatusWindowController.m
//  MenuTunes
//
//  Created by Matthew L. Judy on Thu Apr 17 2003.
//  Copyright (c) 2003 NibFile.com. All rights reserved.
//

#import "StatusWindowController.h"


@implementation StatusWindowController


- (void)showSongWindowWithTitle:(NSString *)title
                          album:(NSString *)album
                         artist:(NSString *)artist
                           time:(NSString *)time  // FLOW: Should probably be NSDate or something.
                    trackNumber:       (int)trackNumber
                     trackTotal:       (int)trackTotal
                         rating:       (int)rating
{

}

- (void)showUpcomingSongsWithTitles:(NSArray *)titleStrings
{

}

- (void)showVolumeWindowWithLevel:(int)level
{

}

- (void)showRatingWindowWithLevel:(int)level
{

}

- (void)showShuffleWindowWithMode:(MTStatusWindowShuffleMode)mode
{

}

- (void)showLoopWindowWithMode:(MTStatusWindowLoopMode)mode
{

}

@end