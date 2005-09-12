/*
 *	MenuTunes
 *  PlaylistNode
 *    Helper class for keeping track of sources, playlists and folders
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2005 iThink Software.
 *  All Rights Reserved
 *
 */
 
#import <Cocoa/Cocoa.h>
#import <ITMTRemote/ITMTRemote.h>

typedef enum {
    ITMTSourceNode = -1,
	ITMTPlaylistNode,
    ITMTFolderNode,
	ITMTPartyShuffleNode,
	ITMTPodcastsNode,
	ITMTPurchasedMusicNode,
	ITMTVideosNode
} ITMTNodeType;

@interface PlaylistNode : NSObject
{
	NSString *_name;
	ITMTNodeType _type;
	ITMTRemotePlayerSource _sourceType;
	NSMutableArray *_children;
	PlaylistNode *_parent;
	int _index;
}
+ (PlaylistNode *)playlistNodeWithName:(NSString *)n type:(ITMTNodeType)t index:(int)i;

- (id)initWithName:(NSString *)n type:(ITMTNodeType)t index:(int)i;

- (NSString *)name;
- (NSMutableArray *)children;
- (int)index;

- (void)setType:(ITMTNodeType)t;
- (ITMTNodeType)type;

- (PlaylistNode *)parent;
- (void)setParent:(PlaylistNode *)p;

- (ITMTRemotePlayerSource)sourceType;
- (void)setSourceType:(ITMTRemotePlayerSource)t;
@end
