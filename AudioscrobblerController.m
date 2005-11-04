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
#import <openssl/evp.h>

static AudioscrobblerController *_sharedController = nil;

@implementation AudioscrobblerController

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[AudioscrobblerController sharedController] submitTrack:@"Stairway To Heaven" artist:@"Led Zeppelin" album:@"Led Zeppelin IV" length:483];
	[pool release];
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
		_md5Challenge = nil;
		_postURL = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioscrobblerNotification:) name:nil object:self];
	}
	return self;
}

- (void)dealloc
{
	[_md5Challenge release];
	[_postURL release];
	[_responseData release];
	[super dealloc];
}

- (void)attemptHandshake
{
	NSString *version = [[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes.app"]] infoDictionary] objectForKey:@"CFBundleVersion"], *user = @"Tristrex";
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.1&c=tst&v=%@&u=%@", version, user]];
	NSURLConnection *connection;
	
	_currentStatus = AudioscrobblerRequestingHandshakeStatus;
	_responseData = [[NSMutableData alloc] init];
	connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30] delegate:self];
}

- (BOOL)handshakeCompleted
{
	return _handshakeCompleted;
}

- (void)submitTrack:(NSString *)title artist:(NSString *)artist album:(NSString *)album length:(int)length
{
	if (!_handshakeCompleted) {
		[self attemptHandshake];
		return;
	}
	
	//What we eventually want is a submission list that sends backlogs also
	NSMutableURLRequest *request = [[NSURLRequest requestWithURL:_postURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30] mutableCopy];
	NSString *responseHash = @"", *requestBody;
	
	char *pass = "waffles";
	unsigned char *buffer;
	EVP_MD_CTX ctx;
	int i;
	
	buffer = malloc(EVP_MD_size(EVP_md5()));
	
	EVP_DigestInit(&ctx, EVP_md5());
	EVP_DigestUpdate(&ctx, pass, strlen(pass));
	EVP_DigestFinal(&ctx, buffer, NULL);
	
	for (i = 0; i < 16; i++) {
		responseHash = [responseHash stringByAppendingFormat:@"%0.2x", buffer[i]];
	}
	
	free(buffer);
	buffer = malloc(EVP_MD_size(EVP_md5()));
	char *cat = (char *)[[responseHash stringByAppendingString:_md5Challenge] UTF8String];
	EVP_DigestInit(&ctx, EVP_md5());
	EVP_DigestUpdate(&ctx, cat, strlen(cat));
	EVP_DigestFinal(&ctx, buffer, NULL);
	
	responseHash = @"";
	for (i = 0; i < 16; i++) {
		responseHash = [responseHash stringByAppendingFormat:@"%0.2x", buffer[i]];
	}
	free(buffer);
	
	requestBody = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[NSString stringWithFormat:@"u=%@&s=%@&a[0]=%@&t[0]=%@&b[0]=%@&m[0]=&l[0]=%i&i[0]=%@", @"Tristrex", responseHash, artist, title, album, length, [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil]], NULL, NULL, kCFStringEncodingUTF8);
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
	_currentStatus = AudioscrobblerSubmittingTrackStatus;
	_responseData = [[NSMutableData alloc] init];
	[NSURLConnection connectionWithRequest:request delegate:self];
	CFRelease(requestBody);
	[request release];
}

- (void)handleAudioscrobblerNotification:(NSNotification *)note
{
	if ([[note name] isEqualToString:@"AudioscrobblerHandshakeComplete"]) {
		[[AudioscrobblerController sharedController] submitTrack:@"Good Times Bad Times" artist:@"Led Zeppelin" album:@"Led Zeppelin I" length:166];
	}
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
	
	if (_currentStatus == AudioscrobblerRequestingHandshakeStatus) {
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSString *responseAction;
		if ([lines count] < 2) {
			//We have an error
		}
		responseAction = [lines objectAtIndex:0];
		if ([responseAction isEqualToString:@"UPTODATE"]) {
			if ([lines count] >= 4) {
				_md5Challenge = [[lines objectAtIndex:1] retain];
				_postURL = [[NSURL alloc] initWithString:[lines objectAtIndex:2]];
				_handshakeCompleted = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerHandshakeComplete" object:self];
			} else {
				//We have an error
			}
			//Something
		} else if (([responseAction length] > 6) && [[responseAction substringToIndex:5] isEqualToString:@"UPDATE"]) {
			//Something plus update action
		} else if (([responseAction length] > 6) && [[responseAction substringToIndex:5] isEqualToString:@"FAILED"]) {
			//We have an error
		} else if ([responseAction isEqualToString:@"BADUSER"]) {
			//We have an error
		} else {
			//We have an error
		}
	} else if (_currentStatus == AudioscrobblerSubmittingTrackStatus) {
		NSLog(string);
	}
	
	[string release];
}

@end
