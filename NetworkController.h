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
 
#import <Foundation/Foundation.h>

#define SERVER_PORT 5712

@class ITMTRemote;

@interface NetworkController : NSObject
{
    NSNetService *service;
    NSNetServiceBrowser *browser;
    NSMutableArray *remoteServices;
    
    NSConnection *serverConnection, *clientConnection;
    NSSocketPort *serverPort, *clientPort;
    BOOL serverOn, clientConnected, connectedToServer;
    ITMTRemote *clientProxy;
}
+ (NetworkController *)sharedController;

- (void)startRemoteServerSearch;
- (void)stopRemoteServerSearch;

- (void)setServerStatus:(BOOL)status;
- (BOOL)connectToHost:(NSString *)host;
- (BOOL)disconnect;
- (BOOL)isServerOn;
- (BOOL)isClientConnected;
- (BOOL)isConnectedToServer;

- (ITMTRemote *)sharedRemote;
- (NSArray *)remoteServices;
@end
