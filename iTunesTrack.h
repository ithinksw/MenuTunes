//
//  iTunesTrack.h
//  MenuTunes
//
//  Created by Joseph Spiros on Sat Sep 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iTunesTrack : ITMTTrack <ITMTTrack> {
    int		_index;
}
+ (id)trackWithDatabaseIndex:(int)index;
- (id)initWithDatabaseIndex:(int)index;
@end