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

@class NetworkObject;

@interface NetworkController : NSObject
{
    NSNetService *service;
    NSNetServiceBrowser *browser;
    NSMutableArray *remoteServices;
    
    NSConnection *serverConnection, *clientConnection;
    NSSocketPort *clientPort, *serverPort;
    NSString *remoteHost;
    BOOL serverOn, clientConnected, connectedToServer;
    NSData *serverPass, *clientPass;
    NetworkObject *rootObject, *clientProxy;
}
+ (NetworkController *)sharedController;

- (void)startRemoteServerSearch;
- (void)stopRemoteServerSearch;

- (void)setServerStatus:(BOOL)status;
- (int)connectToHost:(NSString *)host;
- (BOOL)checkForServerAtHost:(NSString *)host;
- (BOOL)disconnect;
- (BOOL)isServerOn;
- (BOOL)isClientConnected;
- (BOOL)isConnectedToServer;
- (NSString *)remoteHost;

- (NetworkObject *)networkObject;
- (NSArray *)remoteServices;
@end
