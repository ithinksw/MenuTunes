//
//  iTunesPlaylist.h
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iTunesPlaylist : ITMTPlaylist <ITMTPlaylist> {
    int		_index;
}
+ (id)playlistWithIndex:(int)index;
- (id)initWithIndex:(int)index;
@end