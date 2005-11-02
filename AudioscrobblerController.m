/*
 *	MenuTunes
 *  AudioscrobblerController
 *    Audioscrobbler Support Class
 *
 *  Original Author : Kent Sutherland <kent.sutherland@ithinksw.com>
 *   Responsibility : Kent Sutherland <kent.sutherland@ithinksw.com>
 *
 *  Copyright (c) 2005 iThink Software.
 *  All Rights Reserved
 *
 */

#import "AudioscrobblerController.h"

static AudioscrobblerController *_sharedController = nil;

@implementation AudioscrobblerController

+ (void)load
{
	//[[AudioscrobblerController sharedController] attemptHandshake];
}

+ (AudioscrobblerController *)sharedController
{
	if (!_sharedController) {
		_sharedController = [[AudioscrobblerController alloc] init];
	}
	return _sharedController;
}

- (id)init
{
	if ( (self = [super init]) ) {
		_handshakeCompleted = NO;
		_responseData = nil;
	}
	return self;
}

- (void)dealloc
{
	[_responseData release];
	[super dealloc];
}

- (void)attemptHandshake
{
	NSString *version = [[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes.app"]] infoDictionary] objectForKey:@"CFBundleVersion"], *user = @"Tristrex";
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.1&c=est&v=\"%@\"&u=\"%@\"", version, user]];
	NSURLConnection *connection;
	
	_responseData = [[NSMutableData alloc] init];
	connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
	
	_handshakeCompleted = YES;
}

- (BOOL)handshakeCompleted
{
	return _handshakeCompleted;
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"Failed with an error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *string = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];
	NSLog(@"Rawr: %@", string);
	[string release];
}

@end
