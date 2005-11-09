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
#import "PreferencesController.h"
#import <openssl/evp.h>
#import <ITFoundation/ITDebug.h>

#define AUDIOSCROBBLER_ID @"tst"
#define AUDIOSCROBBLER_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]

static AudioscrobblerController *_sharedController = nil;

@implementation AudioscrobblerController

/*+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[AudioscrobblerController sharedController] submitTrack:@"Immigrant Song" artist:@"Led Zeppelin" album:@"How The West Was Won" length:221];
	[[AudioscrobblerController sharedController] submitTrack:@"Comfortably Numb" artist:@"Pink Floyd" album:@"The Wall" length:384];
	[[AudioscrobblerController sharedController] submitTracks];
	[pool release];
}*/

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
		_md5Challenge = nil;
		_postURL = nil;
		
		/*_handshakeCompleted = YES;
		_md5Challenge = @"rawr";
		_postURL = [NSURL URLWithString:@"http://audioscrobbler.com/"];*/
		
		_delayDate = nil;
		_responseData = nil;
		_tracks = [[NSMutableArray alloc] init];
		_submitTracks = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioscrobblerNotification:) name:nil object:self];
	}
	return self;
}

- (void)dealloc
{
	[_md5Challenge release];
	[_postURL release];
	[_responseData release];
	[_submitTracks release];
	[_tracks release];
	[super dealloc];
}

- (void)attemptHandshake:(BOOL)force
{
	if (_handshakeCompleted && !force) {
		return;
	}
	
	//Delay if we haven't met the interval time limit
	NSTimeInterval interval = [_delayDate timeIntervalSinceNow];
	if (interval > 0) {
		ITDebugLog(@"Audioscrobbler: Delaying handshake attempt for %i seconds", interval);
		[self performSelector:@selector(attemptHandshake) withObject:nil afterDelay:interval + 1];
		return;
	}
	
	NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioscrobblerUser"];
	if (!_handshakeCompleted && user) {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.1&c=%@&v=%@&u=%@", AUDIOSCROBBLER_ID, AUDIOSCROBBLER_VERSION, user]];
		
		_currentStatus = AudioscrobblerRequestingHandshakeStatus;
		_responseData = [[NSMutableData alloc] init];
		[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15] delegate:self];
	}
}

- (BOOL)handshakeCompleted
{
	return _handshakeCompleted;
}

- (void)submitTrack:(NSString *)title artist:(NSString *)artist album:(NSString *)album length:(int)length
{
	ITDebugLog(@"Audioscrobbler: Adding a new track to the submission queue.");
	NSDictionary *newTrack = [NSDictionary dictionaryWithObjectsAndKeys:title,
																		@"title",
																		artist,
																		@"artist",
																		(album == nil) ? @"" : album,
																		@"album",
																		[NSString stringWithFormat:@"%i", length],
																		@"length",
																		[[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil],
																		@"time",
																		nil, nil];
	[_tracks addObject:newTrack];
	[self submitTracks];
}

- (void)submitTracks
{
	if (!_handshakeCompleted) {
		[self attemptHandshake:NO];
		return;
	}
	
	NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioscrobblerUser"], *passString = [PreferencesController getKeychainItemPasswordForUser:user];
	char *pass = (char *)[passString UTF8String];
	
	if (passString == nil) {
		NSLog(@"Audioscrobbler: Access denied to user password");
		return;
	}
	
	NSTimeInterval interval = [_delayDate timeIntervalSinceNow];
	if (interval > 0) {
		ITDebugLog(@"Audioscrobbler: Delaying track submission for %f seconds", interval);
		[self performSelector:@selector(submitTracks) withObject:nil afterDelay:interval + 1];
		return;
	}
	
	int i;
	NSMutableString *requestString;
	NSString *authString, *responseHash = @"";
	unsigned char *buffer;
	EVP_MD_CTX ctx;
	
	ITDebugLog(@"Audioscrobbler: Submitting queued tracks");
	
	if ([_tracks count] == 0) {
		ITDebugLog(@"Audioscrobbler: No queued tracks to submit.");
		return;
	}
	
	//Build the MD5 response string we send along with the request
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
	
	authString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[NSString stringWithFormat:@"u=%@&s=%@", user, responseHash], NULL, NULL, kCFStringEncodingUTF8);
	requestString = [[NSMutableString alloc] initWithString:authString];
	[authString release];
	
	//We can only submit ten tracks at a time
	for (i = 0; (i < [_tracks count]) && (i < 10); i++) {
		NSDictionary *nextTrack = [_tracks objectAtIndex:i];
		NSString *trackString;
		
		trackString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[NSString stringWithFormat:@"&a[%i]=%@&t[%i]=%@&b[%i]=%@&m[%i]=&l[%i]=%@&i[%i]=%@", i, [nextTrack objectForKey:@"artist"], i, [nextTrack objectForKey:@"title"], i, [nextTrack objectForKey:@"album"], i, i, [nextTrack objectForKey:@"length"], i, [nextTrack objectForKey:@"time"]], NULL, NULL, kCFStringEncodingUTF8);
		[requestString appendString:trackString];
		[trackString release];
		[_submitTracks addObject:nextTrack];
	}
	
	//Create and send the request
	NSMutableURLRequest *request = [[NSURLRequest requestWithURL:_postURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15] mutableCopy];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
	_currentStatus = AudioscrobblerSubmittingTracksStatus;
	_responseData = [[NSMutableData alloc] init];
	[NSURLConnection connectionWithRequest:request delegate:self];
	[requestString release];
	[request release];
	
	//If we have tracks left, submit again after the interval seconds
}

- (void)handleAudioscrobblerNotification:(NSNotification *)note
{
	if ([[note name] isEqualToString:@"AudioscrobblerHandshakeComplete"]) {
		if ([_tracks count] > 0) {
			[self performSelector:@selector(submitTracks) withObject:nil afterDelay:2];
		}
	}
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	ITDebugLog(@"Audioscrobbler: Connection error \"%@\"", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *string = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSString *responseAction = nil;
	
	if ([lines count] > 0) {
		responseAction = [lines objectAtIndex:0];
	}
	
	if (_currentStatus == AudioscrobblerRequestingHandshakeStatus) {
		if ([lines count] < 2) {
			//We have a protocol error
		}
		if ([responseAction isEqualToString:@"UPTODATE"] || (([responseAction length] > 5) && [[responseAction substringToIndex:5] isEqualToString:@"UPDATE"])) {
			if ([lines count] >= 4) {
				_md5Challenge = [[lines objectAtIndex:1] retain];
				_postURL = [[NSURL alloc] initWithString:[lines objectAtIndex:2]];
				_handshakeCompleted = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerHandshakeComplete" object:self];
			} else {
				//We have a protocol error
			}
		} else if (([responseAction length] > 5) && [[responseAction substringToIndex:5] isEqualToString:@"FAILED"]) {
			//We have a error
		} else if ([responseAction isEqualToString:@"BADUSER"]) {
			//We have a bad user
		} else {
			//We have a protocol error
		}
	} else if (_currentStatus == AudioscrobblerSubmittingTracksStatus) {
		if ([responseAction isEqualToString:@"OK"]) {
			[_tracks removeObjectsInArray:_submitTracks];
			[_submitTracks removeAllObjects];
		} else if ([responseAction isEqualToString:@"BADAUTH"]) {
			//Bad auth
		} else if (([responseAction length] > 5) && [[responseAction substringToIndex:5] isEqualToString:@"FAILED"]) {
			//Failed
		}
	}
	
	//Handle the final INTERVAL response
	if (([[lines objectAtIndex:[lines count] - 2] length] > 9) && [[[lines objectAtIndex:[lines count] - 2] substringToIndex:8] isEqualToString:@"INTERVAL"]) {
		int seconds = [[[lines objectAtIndex:[lines count] - 2] substringFromIndex:9] intValue];
		ITDebugLog(@"Audioscrobbler: INTERVAL %i", seconds);
		[_delayDate release];
		_delayDate = [[NSDate dateWithTimeIntervalSinceNow:seconds] retain];
	} else {
		ITDebugLog(@"No interval response.");
		//We have a protocol error
	}
	
	[string release];
	[_responseData release];
}

@end
