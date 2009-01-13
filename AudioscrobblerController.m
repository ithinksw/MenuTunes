#import "AudioscrobblerController.h"
#import "PreferencesController.h"
#import <openssl/evp.h>
#import <ITFoundation/ITDebug.h>

#define AUDIOSCROBBLER_ID @"mtu"
#define AUDIOSCROBBLER_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]

static AudioscrobblerController *_sharedController = nil;

@implementation AudioscrobblerController

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
		
		_delayDate = [[NSDate date] retain];
		_responseData = [[NSMutableData alloc] init];
		_tracks = [[NSMutableArray alloc] init];
		_submitTracks = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioscrobblerNotification:) name:@"AudioscrobblerHandshakeComplete" object:self];
	}
	return self;
}

- (void)dealloc
{
	[_lastStatus release];
	[_md5Challenge release];
	[_postURL release];
	[_responseData release];
	[_submitTracks release];
	[_tracks release];
	[_delayDate release];
	[super dealloc];
}

- (NSString *)lastStatus
{
	return _lastStatus;
}

- (void)attemptHandshake
{
	[self attemptHandshake:NO];
}

- (void)attemptHandshake:(BOOL)force
{
	if (_handshakeCompleted && !force) {
		return;
	}
	
	//If we've already tried to handshake three times in a row unsuccessfully, set the attempt count to -3
	if (_handshakeAttempts > 3) {
		ITDebugLog(@"Audioscrobbler: Maximum handshake limit reached (3). Retrying when handshake attempts reach zero.");
		_handshakeAttempts = -3;
		
		//Remove any tracks we were trying to submit, just to be safe
		[_submitTracks removeAllObjects];
		
		return;
	}
	
	//Increment the number of times we've tried to handshake
	_handshakeAttempts++;
	
	//We're still on our self-imposed cooldown time.
	if (_handshakeAttempts < 0) {
		ITDebugLog(@"Audioscrobbler: Handshake timeout. Retrying when handshake attempts reach zero.");
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
		
		[_lastStatus release];
		_lastStatus = [NSLocalizedString(@"audioscrobbler_handshaking", @"Attempting to handshake with server") retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerStatusChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:_lastStatus forKey:@"StatusString"]];
		
		_currentStatus = AudioscrobblerRequestingHandshakeStatus;
		//_responseData = [[NSMutableData alloc] init];
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
	
	ITDebugLog(@"Audioscrobbler: Submitting queued tracks");
	
	if ([_tracks count] == 0) {
		ITDebugLog(@"Audioscrobbler: No queued tracks to submit.");
		return;
	}
	
	NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"audioscrobblerUser"], *passString = [PreferencesController getKeychainItemPasswordForUser:user];
	char *pass = (char *)[passString UTF8String];
	
	if (passString == nil) {
		ITDebugLog(@"Audioscrobbler: Access denied to user password");
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
		NSString *artistEscaped, *titleEscaped, *albumEscaped, *timeEscaped, *ampersand = @"&";
		
		//Escape each of the individual parameters we're sending
		artistEscaped = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[nextTrack objectForKey:@"artist"], NULL, (CFStringRef)ampersand, kCFStringEncodingUTF8);
		titleEscaped = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[nextTrack objectForKey:@"title"], NULL, (CFStringRef)ampersand, kCFStringEncodingUTF8);
		albumEscaped = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[nextTrack objectForKey:@"album"], NULL, (CFStringRef)ampersand, kCFStringEncodingUTF8);
		timeEscaped = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[nextTrack objectForKey:@"time"], NULL, (CFStringRef)ampersand, kCFStringEncodingUTF8);
		
		[requestString appendString:[NSString stringWithFormat:@"&a[%i]=%@&t[%i]=%@&b[%i]=%@&m[%i]=&l[%i]=%@&i[%i]=%@", i, artistEscaped,
																														i, titleEscaped,
																														i, albumEscaped,
																														i,
																														i, [nextTrack objectForKey:@"length"],
																														i, timeEscaped]];
		
		//Release the escaped strings
		[artistEscaped release];
		[titleEscaped release];
		[albumEscaped release];
		[timeEscaped release];
		
		[_submitTracks addObject:nextTrack];
	}
	
	ITDebugLog(@"Audioscrobbler: Sending track submission request");
	[_lastStatus release];
	_lastStatus = [NSLocalizedString(@"audioscrobbler_submitting", @"Submitting tracks to server") retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerStatusChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:_lastStatus forKey:@"StatusString"]];
	
	//Create and send the request
	NSMutableURLRequest *request = [[NSURLRequest requestWithURL:_postURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15] mutableCopy];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
	_currentStatus = AudioscrobblerSubmittingTracksStatus;
	//_responseData = [[NSMutableData alloc] init];
	[_responseData setData:nil];
	[NSURLConnection connectionWithRequest:request delegate:self];
	[requestString release];
	[request release];
	
	//For now we're not going to cache results, as it is less of a headache
	//[_tracks removeObjectsInArray:_submitTracks];
	[_tracks removeAllObjects];
	//[_submitTracks removeAllObjects];
	
	//If we have tracks left, submit again after the interval seconds
}

- (void)handleAudioscrobblerNotification:(NSNotification *)note
{
	if ([_tracks count] > 0) {
		[self performSelector:@selector(submitTracks) withObject:nil afterDelay:2];
	}
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[_responseData setData:nil];
	[_lastStatus release];
	_lastStatus = [[NSString stringWithFormat:NSLocalizedString(@"audioscrobbler_error", @"Error - %@"), [error localizedDescription]] retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerStatusChanged" object:self userInfo:[NSDictionary dictionaryWithObject:_lastStatus forKey:@"StatusString"]];
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
	NSString *responseAction = nil, *key = nil, *comment = nil;
	
	if ([lines count] > 0) {
		responseAction = [lines objectAtIndex:0];
	}
	ITDebugLog(@"Audioscrobbler: Response %@", string);
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
				key = @"audioscrobbler_handshake_complete";
				comment = @"Handshake complete";
				_handshakeAttempts = 0;
			} else {
				//We have a protocol error
			}
		} else if (([responseAction length] > 5) && [[responseAction substringToIndex:5] isEqualToString:@"FAILED"]) {
			ITDebugLog(@"Audioscrobbler: Handshake failed (%@)", [responseAction substringFromIndex:6]);
			key = @"audioscrobbler_handshake_failed";
			comment = @"Handshake failed";
			//We have a error
		} else if ([responseAction isEqualToString:@"BADUSER"]) {
			ITDebugLog(@"Audioscrobbler: Bad user name");
			key = @"audioscrobbler_bad_user";
			comment = @"Handshake failed - invalid user name";
			//We have a bad user
			
			//Don't count this as a bad handshake attempt
			_handshakeAttempts = 0;
		} else {
			ITDebugLog(@"Audioscrobbler: Handshake failed, protocol error");
			key = @"audioscrobbler_protocol_error";
			comment = @"Internal protocol error";
			//We have a protocol error
		}
	} else if (_currentStatus == AudioscrobblerSubmittingTracksStatus) {
		if ([responseAction isEqualToString:@"OK"]) {
			ITDebugLog(@"Audioscrobbler: Submission successful, clearing queue.");
			/*[_tracks removeObjectsInArray:_submitTracks];
			[_submitTracks removeAllObjects];*/
			[_submitTracks removeAllObjects];
			if ([_tracks count] > 0) {
				ITDebugLog(@"Audioscrobbler: Tracks remaining in queue, submitting remaining tracks");
				[self performSelector:@selector(submitTracks) withObject:nil afterDelay:2];
			}
			key = @"audioscrobbler_submission_ok";
			comment = @"Last track submission successful";
		} else if ([responseAction isEqualToString:@"BADAUTH"]) {
			ITDebugLog(@"Audioscrobbler: Bad password");
			key = @"audioscrobbler_bad_password";
			comment = @"Last track submission failed - invalid password";
			//Bad auth
			
			//Add the tracks we were trying to submit back into the submission queue
			[_tracks addObjectsFromArray:_submitTracks];
			
			_handshakeCompleted = NO;
			
			//If we were previously valid with the same login name, try reauthenticating and sending again
			[self attemptHandshake:YES];
		} else if (([responseAction length] > 5) && [[responseAction substringToIndex:5] isEqualToString:@"FAILED"]) {
			ITDebugLog(@"Audioscrobbler: Submission failed (%@)", [responseAction substringFromIndex:6]);
			key = @"audioscrobbler_submission_failed";
			comment = @"Last track submission failed - see console for error";
			//Failed
			
			//We got an unknown error. To be safe we're going to remove the tracks we tried to submit
			[_submitTracks removeAllObjects];
			
			_handshakeCompleted = NO;
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
	[_lastStatus release];
	_lastStatus = [NSLocalizedString(key, comment) retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AudioscrobblerStatusChanged" object:nil userInfo:[NSDictionary dictionaryWithObject:_lastStatus forKey:@"StatusString"]];
	[string release];
	[_responseData setData:nil];
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//Don't cache any Audioscrobbler communication
	return nil;
}

@end
