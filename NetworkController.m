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
#import "netinet/in.h"
#import "arpa/inet.h"
#import <ITFoundation/ITDebug.h>
#import <ITFoundation/ITFoundation.h>
#import <ITMTRemote/ITMTRemote.h>

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
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
    if (serverOn) {
        [serverConnection invalidate];
        [serverConnection release];
    }
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
        //Turn on
        NS_DURING
            serverPort = [[NSSocketPort alloc] initWithTCPPort:SERVER_PORT];
            serverConnection = [[NSConnection alloc] initWithReceivePort:serverPort
                                                     sendPort:serverPort];
            [serverConnection setRootObject:[[MainController sharedController] currentRemote]];
            [serverConnection registerName:@"ITMTPlayerHost"];
            [serverConnection setDelegate:self];
        NS_HANDLER
            ITDebugLog(@"Error starting server!");
        NS_ENDHANDLER
        ITDebugLog(@"Started server.");
        if (!name) {
            name = @"MenuTunes Shared Player";
        }
        service = [[NSNetService alloc] initWithDomain:@""
                                        type:@"_mttp._tcp."
                                        name:name
                                        port:SERVER_PORT];
        [service publish];
        serverOn = YES;
    } else if (serverOn && !status && [serverConnection isValid]) {
        //Turn off
        [service stop];
        [serverConnection registerName:nil];
        [serverPort invalidate];
        [serverConnection invalidate];
        [serverConnection release];
        ITDebugLog(@"Stopped server.");
        serverOn = NO;
    }
}

- (BOOL)connectToHost:(NSString *)host
{
    ITDebugLog(@"Connecting to host: %@", host);
    NS_DURING
        clientPort = [[NSSocketPort alloc] initRemoteWithTCPPort:SERVER_PORT
                                           host:host];
        clientConnection = [[NSConnection connectionWithReceivePort:nil sendPort:clientPort] retain];
        clientProxy = [[clientConnection rootProxy] retain];
    NS_HANDLER
        ITDebugLog(@"Connection to host failed: %@", host);
        return NO;
    NS_ENDHANDLER
    [clientConnection setReplyTimeout:5];
    ITDebugLog(@"Connected to host: %@", host);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnect) name:NSConnectionDidDieNotification object:clientConnection];
    connectedToServer = YES;
    return YES;
}

- (BOOL)disconnect
{
    ITDebugLog(@"Disconnecting from host.");
    connectedToServer = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [clientProxy release];
    [clientConnection invalidate];
    [clientConnection release];
    return YES;
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

- (ITMTRemote *)sharedRemote
{
    return (ITMTRemote *)clientProxy;
}

- (NSArray *)remoteServices
{
    return remoteServices;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [aNetService setDelegate:self];
    [aNetService resolve];
    ITDebugLog(@"Found service named %@.", [aNetService name]);
    if (!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTFoundNetService" object:nil];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [remoteServices addObject:[NSDictionary dictionaryWithObjectsAndKeys:[sender name], @"name",
                                                                         [NSString stringWithCString:inet_ntoa((*(struct sockaddr_in*)[[[sender addresses] objectAtIndex:0] bytes]).sin_addr)], @"ip",
                                                                         nil, nil]];
    ITDebugLog(@"Resolved service named %@.", [sender name]);
    NSLog(@"found!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ITMTFoundNetService" object:nil];
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
