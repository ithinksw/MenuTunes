/*
 *	MenuTunes
 *	PlaylistNode.h
 *
 *	Helper class for keeping track of sources, playlists and folders.
 *
 *	Copyright (c) 2005 iThink Software
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
