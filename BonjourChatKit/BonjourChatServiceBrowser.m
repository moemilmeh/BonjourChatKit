//
//  BonjourChatServiceBrowser.m
//  BonjourChatKit
//
//  Created by MMM on 8/7/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Source: https://developer.apple.com/library/content/documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/BrowsingForServices.html
//
// Browsing Process:
//
//    1. Init. instance of NSNetServiceBrowser and assign a delegate to it
//    2. Begin searching for service type
//    3. Handle search results
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "BonjourChatServiceBrowser.h"
#import "BonjourChatSocket.h"
#import "BonjourChatConnection.h"
#import "BonjourChatConstants.h"

@interface BonjourChatServiceBrowser () <BonjourChatConnectionDelegate>

@property (nonatomic) NSMutableSet <NSNetService *> *disocveredChatServices;
@property (nonatomic) BonjourChatSocket *bonjourChatSocket;
@property (nonatomic) BonjourChatConnection *bonjourChatConnection;
@property (nonatomic, assign) BOOL connected;

@end

@implementation BonjourChatServiceBrowser

#pragma mark - Init.

- (instancetype)init
{
    if (self = [self initWithServiceType:BonjourChatServiceType domainName:BonjourChatServiceDomainName]) {
        
    }
    
    return self;
}

- (instancetype)initWithServiceType:(NSString *)type domainName:(NSString *)domain
{
    
    if (self = [super init]) {
        
        //----------------------------
        // 1. Init. service browser
        //----------------------------
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [_serviceBrowser setDelegate:self];
        
        _disocveredChatServices = [NSMutableSet set];
        _serviceType = type;
        _serviceDomain = domain;
        _connected = NO;
    }
    
    return self;
    
}

- (void)startBrowsing
{
    if ([self serviceBrowser]) {
        
        NSString *serviceType   = [self serviceType];
        NSString *serviceDomain = [self serviceDomain];
        
        if (serviceType && serviceDomain) {
            [[self serviceBrowser] searchForServicesOfType:serviceType inDomain:serviceDomain];
        
        } else {
            [[self serviceBrowser] searchForBrowsableDomains];
        }
    }
}

- (void)stopBrowsing
{
    if ([self serviceBrowser]) {
        [[self serviceBrowser] stop];
    }
}

- (BOOL)connectToServer
{
    NSNetService *chatService = [self chatServerService];
    NSString *host = [chatService hostName];
    NSInteger port = [chatService port];
    
    if (!host) {
        NSLog(@"Failed to discover the chat server to connect to");
        return NO;
    }
    
    NSLog(@"Trying to connect to the chat service: %@", chatService);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, (UInt32)port, &readStream, &writeStream);
    
    if (!readStream || !writeStream) {
        return NO;
    }
    
    // Set the stream properties: Close the socket when the streams are released
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    _bonjourChatConnection = [[BonjourChatConnection alloc] initWithInputStream:(__bridge_transfer NSInputStream *)readStream outputStream:(__bridge_transfer NSOutputStream *)writeStream];
    [_bonjourChatConnection setDelegate:self];
    [_bonjourChatConnection openConnection];
    
    if (readStream) {
        CFRelease(readStream);
    }
    
    if (writeStream) {
        CFRelease(writeStream);
    }
    
    [self setConnected:YES];
    
    return YES;
}

- (void)disconnectFromServer
{
    [[self bonjourChatConnection] closeConnection];
    [self setConnected:NO];
}


- (NSNetService *)chatServerService
{
    for (NSNetService *service in [[self disocveredChatServices] allObjects]) {
        
        if ([[service type] isEqualToString:BonjourChatServiceType]) {
            return service;
        }
    }
    
    return nil;
}

#pragma mark - BonjourChatConnectionDelegate

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didOpenStream:(NSStream *)stream
{
    
}

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didCloseStream:(NSStream *)stream
{
    
}

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didReceiveData:(NSData *)data
{
    // TODO: Handle incoming data
}

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didWriteData:(NSData *)data withError:(NSError *)error
{
    // TODO: Handle ack. for outgoing data
}


#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"Service browser: %@ will search", browser);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"Service browser: %@ did stop search", browser);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    NSLog(@"Service browser: %@ did not search with error: %@", browser, errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did find domain: %@ and more coming: %@", browser, domainString, @(moreComing));
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did find service: %@ and more coming: %@", browser, [service name], @(moreComing));
    
    if ([[service type] isEqualToString:[self serviceType]]) {
        [[self disocveredChatServices] addObject:service];
    }
    
    if (!moreComing) {
        
        // TODO: Notify delegates its done
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did remove domain: %@ and more coming: %@", browser, domainString, @(moreComing));
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did remove service: %@ and more coming: %@", browser, service, @(moreComing));
    [[self disocveredChatServices] removeObject:service];
}

@end
