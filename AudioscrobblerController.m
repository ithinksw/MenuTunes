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
		
		//Test variables
		_md5Challenge = @"315EFDA9FDA6A24B421BE991511DEE90";
		_postURL = [[NSURL alloc] initWithString:@"http://62.216.251.205:80/protocol_1.1"];
		_handshakeCompleted = YES;
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
	NSString *responseHash, *requestBody;
	
	char *pass = "waffles";
	unsigned char *buffer, *buffer2, buffer3[16];
	EVP_MD_CTX ctx;
	int i;
	
	buffer = malloc(EVP_MD_size(EVP_md5()));
	//buffer3 = malloc(EVP_MD_size(EVP_md5()));
	
	EVP_DigestInit(&ctx, EVP_md5());
	EVP_DigestUpdate(&ctx, pass, strlen(pass));
	EVP_DigestUpdate(&ctx, [_md5Challenge UTF8String], strlen([_md5Challenge UTF8String]));
	EVP_DigestFinal(&ctx, buffer, NULL);
	
	for (i = 0; i < 16; i++) {
		char hex1, hex2;
		hex1 = toascii(48+ (buffer[i] / 16));
		if (hex1 > 57) {
			hex1 = hex1 + 39;
		}
		hex2 = toascii(48 + (buffer[i] % 16));
		if (hex2 > 57) {
			hex2 = hex2 + 39;
		}
		
		buffer3[i] = hex1;
		buffer3[i + 1] = hex2;
	}
	
	NSLog(@"%s", buffer3);
	
	/*unsigned char *cat = strcat(buffer3, [[_md5Challenge lowercaseString] UTF8String]);
	
	EVP_DigestInit(&ctx, EVP_md5());
	EVP_DigestUpdate(&ctx, cat, strlen(cat));
	EVP_DigestFinal(&ctx, buffer2, NULL);
	
	for (i = 0; i < 16; i++) {
		char hex1, hex2;
		hex1 = toascii(48+ (buffer2[i] / 16));
		if (hex1 > 57) {
			hex1 = hex1 + 39;
		}
		hex2 = toascii(48 + (buffer2[i] % 16));
		if (hex2 > 57) {
			hex2 = hex2 + 39;
		}
		buffer3[i] = hex1;
		buffer3[i + 1] = hex2;
	}
	NSLog(@"%s", buffer3);*/
	
	if ([NSString respondsToSelector:@selector(stringWithCString:encoding:)]) {
		responseHash = [NSString stringWithCString:buffer3 encoding:NSASCIIStringEncoding];
	} else {
		responseHash = [NSString stringWithCString:buffer3 length:strlen(buffer)];
	}
	
	requestBody = [NSString stringWithFormat:@"u=%@&s=%@&a[0]=%@&t[0]=%@&b[0]=%@&m[0]=&l[0]=%i&i[0]=%@", @"Tristrex", @"rawr", responseHash, title, album, length, [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	_currentStatus = AudioscrobblerSubmittingTrackStatus;
	_responseData = [[NSMutableData alloc] init];
	[NSURLConnection connectionWithRequest:request delegate:self];
	[request release];
}

- (void)handleAudioscrobblerNotification:(NSNotification *)note
{
	if ([[note name] isEqualToString:@"AudioscrobblerHandshakeComplete"]) {
		[[AudioscrobblerController sharedController] submitTrack:@"Stairway To Heaven" artist:@"Led Zeppelin" album:@"Led Zeppelin IV" length:483];
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
				NSLog(@"%@", _md5Challenge);
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
