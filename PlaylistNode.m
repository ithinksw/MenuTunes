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

#import "PlaylistNode.h"


@implementation PlaylistNode

+ (PlaylistNode *)playlistNodeWithName:(NSString *)n type:(ITMTNodeType)t index:(int)i
{
	return [[[PlaylistNode alloc] initWithName:n type:t index:i] autorelease];
}

- (id)initWithName:(NSString *)n type:(ITMTNodeType)t index:(int)i
{
	if ( (self = [super init]) ) {
		_name = [n retain];
		_type = t;
		_index = i;
		_children = nil;
		_parent = nil;
	}
	return self;
}

- (void)dealloc
{
	[_name release];
	[_children release];
	[_parent release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"{%@, index: %i, type: %i, parent: %@, children: %@}", _name, _index, _type, [_parent name], _children];
}

- (NSString *)name
{
	return _name;
}

- (NSMutableArray *)children
{
	if (!_children) {
		_children = [[NSMutableArray alloc] init];
	}
	return _children;
}

- (int)index
{
	return _index;
}

- (void)setType:(ITMTNodeType)t
{
	_type = t;
}

- (ITMTNodeType)type
{
	return _type;
}

- (PlaylistNode *)parent
{
	return _parent;
}

- (void)setParent:(PlaylistNode *)p
{
	[_parent release];
	_parent = [p retain];
}

- (ITMTRemotePlayerSource)sourceType
{
	return _sourceType;
}

- (void)setSourceType:(ITMTRemotePlayerSource)t
{
	_sourceType = t;
}

@end
