/*
 *	MenuTunes
 *  NetworkController
 *    Rendezvous network controller
 *
 *  Original Author : Kent Sutherland <ksuther@ithinksw.com>
 *   Responsibility : Kent Sutherland <ksuther@ithinksw.com>
 *
 *  Copyright (c) 2003 iThink Software.
 *  All Rights Reserved
 *
 */

#import "NetworkController.h"
#import "MainController.h"
#import "NetworkObject.h"
#import "PreferencesController.h"
#import <ITFoundation/ITDebug.h>
#import <ITFoundation/ITFoundation.h>

static NetworkController *sharedController;

@implementation NetworkController

+ (NetworkController *)sharedController
{
    return sharedController;
}

- (id)init
{
    if ( (self = [super init]) ) {
        sharedController = self;
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        rootObject = [[NetworkObject alloc] init];
        serverPort = [[NSSocketPort alloc] initWithTCPPort:SERVER_PORT];
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
    if (serverOn) {
        [serverConnection release];
    }
    [serverPass release];
    [clientPass release];
    [serverPort release];
    [rootObject release];
    [clientProxy release];
    [remoteServices release];
    [browser release];
    [service stop];
    [service release];
    [super dealloc];
}

- (void)startRemoteServerSearch
{
    [browser searchForServicesOfType:@"_mttp._tcp." inDomain:@""];
    [remoteServices release];
    remoteServices = [[NSMutableArray alloc] init];
}

- (void)stopRemoteServerSearch
{
    [browser stop];
}

- (void)setServerStatus:(BOOL)status
{
    if (!serverOn && status) {
        NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:@"sharedPlayerName"];
        unsigned char buffer;
        NSData *fullPass;
        //Turn on
        NS_DURING
            serverConnection = [[NSConnection alloc] initWithReceivePort:serverPort
                                                     sendPort:serverPort];
            [serverConnection setRootObject:rootObject];
            [rootObject makeValid];
            [serverConnection registerName:@"ITMTPlayerHost"];
        NS_HANDLER
            [serverConnection setRootObject:nil];
            [serverConnection release];
            [serverPort release];
            ITDebugLog(@"Error starting server!");
            return;
        NS_ENDHANDLER
        ITDebugLog(@"Started server.");
        if (!name) {
            name = @"MenuTunes Shared Player";
        }
        service = [[NSNetService alloc] initWithDomain:@""
                                        type:@"_mttp._tcp."
                                        name:name
                                        port:SERVER_PORT];
        fullPass = [[NSUserDefaults standardUserDefaults] dataForKey:@"sharedPlayerPassword"];
        if ([fullPass length]) {
            [fullPass getBytes:&buffer range:NSMakeRange(6, 4)];
            [serverPass release];
            serverPass = [[NSData alloc] initWithBytes:&buffer length:strlen(&buffer)];
        } else {
            serverPass = nil;
        }
        [service publish];
        serverOn = YES;
        ITDebugLog(@"Server service published.");
    } else if (serverOn && !status && [serverConnection isValid]) {
        //Turn off
        [service stop];
        [service release];
        [rootObject invalidate];
        [serverConnection registerName:nil];
        [serverConnection invalidate];
        //[serverConnection setRootObject:nil];
        //[[serverConnection sendPort] autorelease];
        [serverConnection release];
        ITDebugLog(@"Stopped server.");
        serverOn = NO;
    }
}

- (int)connectToHost:(NSString *)host
{
    NSData *fullPass = [[NSUserDefaults standardUserDefaults] dataForKey:@"connectPassword"];
    unsigned char buffer;
    ITDebugLog(@"Connecting to host: %@", host);
    [remoteHost release];
    remoteHost = [host copy];
    if (fullPass) {
        [fullPass getBytes:&buffer range:NSMakeRange(6, 4)];
        [clientPass release];
        clientPass = [[NSData alloc] initWithBytes:&buffer length:strlen(&buffer)];
    } else {
        clientPass = nil;
    }
    NS_DURING
        clientPort = [[NSSocketPort alloc] initRemoteWithTCPPort:SERVER_PORT
                                           host:host];
        clientConnection = [[NSConnection connectionWithReceivePort:nil sendPort:clientPort] retain];
        [clientConnection setReplyTimeout:5];
        clientProxy = [[clientConnection rootProxy] retain];
        connectedToServer = YES;
    NS_HANDLER
        [clientConnection release];
        [clientPort release];
        ITDebugLog(@"Connection to host failed: %@", host);
        return 0;
    NS_ENDHANDLER
    
    if (!clientProxy) {
        ITDebugLog(@"Null proxy! Couldn't connect!");
        [self disconnect];
        return 0;
    }
    
    if ([clientProxy requiresPassword]) {
        ITDebugLog(@"Server requires password.");
        //Check to see if a password is set in defaults
        if ([[NSUserDefaults standardUserDefaults] dataForKey:@"connectPassword"] == nil) {
            ITDebugLog(@"Asking for password.");
            if (![[PreferencesController sharedPrefs] showPasswordPanel]) {
                ITDebugLog(@"Giving up connection attempt.");
                [self disconnect];
                return -1;
            }
        }
        
        //Send the password
        ITDebugLog(@"Sending password.");
        while (![clientProxy sendPassword:[[NSUserDefaults standardUserDefaults] dataForKey:@"connectPassword"]]) {
            ITDebugLog(@"Invalid password!");
            if (![[PreferencesController sharedPrefs] showInvalidPasswordPanel]) {
                ITDebugLog(@"Giving up connection attempt.");
                [self disconnect];
                return -1;
            }
        }
    }
    
    ITDebugLog(@"Connected to host: %@", host);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnect) name:NSConnectionDidDieNotification object:clientConnection];
    return 1;
}

- (BOOL)disconnect
{
    ITDebugLog(@"Disconnecting from host.");
    connectedToServer = NO;
    [remoteHost release];
    remoteHost = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [clientProxy release];
    [clientConnection release];
    return YES;
}

- (BOOL)checkForServerAtHost:(NSString *)host
{
    NSData *fullPass = [[NSUserDefaults standardUserDefaults] dataForKey:@"connectPassword"];
    unsigned char buffer;
    NSConnection *testConnection = nil;
    NSSocketPort *testPort = nil;
    NetworkObject *tempProxy;
    BOOL valid;
    ITDebugLog(@"Checking for shared remote at %@.", host);
    if (fullPass) {
        [fullPass getBytes:&buffer range:NSMakeRange(6, 4)];
        [clientPass release];
        clientPass = [[NSData alloc] initWithBytes:&buffer length:strlen(&buffer)];
    } else {
        clientPass = nil;
    }
    
    NS_DURING
        testPort = [[NSSocketPort alloc] initRemoteWithTCPPort:SERVER_PORT
                                         host:host];
        testConnection = [[NSConnection connectionWithReceivePort:nil sendPort:testPort] retain];
        [testConnection setReplyTimeout:2];
        [testConnection setRequestTimeout:2];
        tempProxy = (NetworkObject *)[testConnection rootProxy];
        [tempProxy serverName];
        valid = [tempProxy isValid];
    NS_HANDLER
        ITDebugLog(@"Connection to host failed: %@", host);
        [testConnection release];
        [testPort release];
        return NO;
    NS_ENDHANDLER
    
    if (!tempProxy) {
        ITDebugLog(@"Null proxy! Couldn't connect!");
        [testConnection release];
        [testPort release];
        return NO;
    }
    [testConnection release];
    [testPort release];
    return valid;
}

- (void)resetServerName
{
    if ([self isServerOn]) {
        [service stop];
        [service release];
        service = [[NSNetService alloc] initWithDomain:@""
                                        type:@"_mttp._tcp."
                                        name:[[NSUserDefaults standardUserDefaults] stringForKey:@"sharedPlayerName"]
                                        port:SERVER_PORT];
    }
}

- (BOOL)isServerOn
{
    return serverOn;
}

- (BOOL)isClientConnected
{
    return clientConnected;
}

- (BOOL)isConnectedToServer
{
    return connectedToServer;
}

- (NSString *)remoteHost
{
    return remoteHost;
}

- (NetworkObject *)networkObject
{
    return clientProxy;
}

- (NSArray *)remoteServices
{
    return remoteServices;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    ITDebugLog(@"Found service named %@.", [aNetService name]);
    [remoteServices addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService resolve];
    if (!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTFoundNetService" object:nil];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService*)aNetService moreComing:(BOOL)moreComing
{
    ITDebugLog(@"Removed service named %@.", [aNetService name]);
    [remoteServices removeObject:aNetService];
    if (!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTFoundNetService" object:nil];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    ITDebugLog(@"Resolved service named %@.", [sender name]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTFoundNetService" object:nil];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSharedPlayer"] && !connectedToServer) {
        [[MainController sharedController] checkForRemoteServerAndConnectImmediately:NO];
    }
    [sender stop];
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    ITDebugLog(@"Resolving service named %@.", [sender name]);
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    ITDebugLog(@"Error resolving service %@.", errorDict);
}

@end
