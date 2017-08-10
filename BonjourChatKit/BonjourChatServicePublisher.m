//
//  BonjourChatServicePublisher.m
//  BonjourChatKit
//
//  Created by MMM on 7/29/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Publish Process:
//
//    1. Configure a socket for the service
//    2. Init. and publish a network service
//    3. Implement delegate methods
//
//
// Note: Expected flow at this point:
//
//      One server (Chat Service ) published on the network
//      Clients connect to the server by finding the chat
//      service in bonjour.
//
//      Server creates a new connection for each client.
//      Server retrieves the clients info and stores it.
//
//      All the communications from client-to-server and
//      client-to-client will be done through the server.
//      This way we can encrypt the payloads and also store
//      messages when the clients (users) are offline.
//
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "BonjourChatServicePublisher.h"
#import "BonjourChatSocket.h"
#import "BonjourChatConnection.h"
#import "BonjourChatConstants.h"


@interface BonjourChatServicePublisher () <BonjourChatServerSocketDelegate, BonjourChatConnectionDelegate>

@property (nonatomic) BonjourChatSocket *bonjourChatSocket;
@property (nonatomic) NSMutableArray<BonjourChatConnection *> *bonjourChatConnections;

@end

@implementation BonjourChatServicePublisher


#pragma mark - Init.

- (instancetype)initWithServiceName:(NSString *)name
{
    return [self initWithServiceName:name port:0];
}

- (instancetype)initWithServiceName:(NSString *)name port:(int)port
{

    return [self initWithServiceName:name serviceType:BonjourChatServiceType domainName:BonjourChatServiceDomainName port:port];
}

- (instancetype)initWithServiceName:(NSString *)name serviceType:(NSString *)type domainName:(NSString *)domain port:(int)port
{
    if (self = [super init]) {
        
        //----------------------------
        // 1. Configure a socket
        //----------------------------
        _bonjourChatSocket = [[BonjourChatSocket alloc] initWithPort:port];
        [_bonjourChatSocket setServerDelegate:self];
        _bonjourChatConnections = [NSMutableArray array];
        
        //-----------------------------
        // 2. Init. a network service
        //-----------------------------
        _service = [[NSNetService alloc] initWithDomain:domain type:type name:name port:[_bonjourChatSocket port]];
        
        //-----------------------------
        // 3. Set the delegate
        //-----------------------------
        [_service setDelegate:self];
    }
    
    return self;
}

- (void)publishChatService
{
    if ([self service]) {
    
        // User Info
        [self setUserSexTXTRecord:[self userSex]];
        [self setUserAgeTXTRecord:[self userAge]];
        
        [self setUserDesiredSexTXTRecord:[self userDesiredSex]];
        [self setUserDesiredAgeTXTRecord:[self userDesiredAge]];
        
        [[self service] publishWithOptions:0];
    }
}

- (void)stopPublish
{
    [[self service] stop];
}

- (void)updateRecordData:(NSData *)recordData
{
    NSDictionary *txtRecord = [NSNetService dictionaryFromTXTRecordData:recordData];
    if (txtRecord) {
        [[self service] setTXTRecordData:recordData];
    } else {
        NSLog(@"Failed to create a TXT record");
    }
}

- (NSDictionary *)userTXTRecordDictionary
{
    NSDictionary *dictioary = [NSNetService dictionaryFromTXTRecordData:[[self service] TXTRecordData]];
    if (!dictioary) {
        dictioary = [NSDictionary dictionary];
    }
    
    return dictioary;
}

#pragma mark - Char User Info

- (void)setUserSexTXTRecord:(UserSex)userSex
{
    NSMutableDictionary *txtRecordDict = [[self userTXTRecordDictionary] mutableCopy];
    [txtRecordDict setObject:[NSString stringWithFormat:@"%@", @(userSex)]forKey:BonjourChatServiceUserSex];
    [self updateRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDict]];
}

- (UserSex)userSexTXTRecord
{
    NSDictionary *txtRecordDict = [NSNetService dictionaryFromTXTRecordData:[[self service] TXTRecordData]];
    NSData *recordObject = [txtRecordDict objectForKey:BonjourChatServiceUserSex];
    return [[self numberForStringData:recordObject] unsignedCharValue];
}

- (void)setUserAgeTXTRecord:(uint8_t)userAge
{
    NSMutableDictionary *txtRecordDict = [[self userTXTRecordDictionary] mutableCopy];
    [txtRecordDict setObject:[NSString stringWithFormat:@"%@", @(userAge)] forKey:BonjourChatServiceUserAge];
    [self updateRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDict]];
}

- (uint8_t)userAgeTXTRecord
{
    NSDictionary *txtRecordDict = [[self userTXTRecordDictionary] mutableCopy];
    NSData *recordObject = [txtRecordDict objectForKey:BonjourChatServiceUserAge];
    return [[self numberForStringData:recordObject] unsignedCharValue];
}


- (void)setUserDesiredSexTXTRecord:(UserSex)userDesiredSex
{
    NSMutableDictionary *txtRecordDict = [[self userTXTRecordDictionary] mutableCopy];
    [txtRecordDict setObject:[NSString stringWithFormat:@"%@", @(userDesiredSex)] forKey:BonjourChatServiceUserDesiredSex];
    [self updateRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDict]];
}

- (UserSex)userDesiredSexTXTRecord
{
    NSDictionary *txtRecordDict = [self userTXTRecordDictionary];
    NSData *recordObject = [txtRecordDict objectForKey:BonjourChatServiceUserDesiredSex];
    return [[self numberForStringData:recordObject] unsignedCharValue];
}

- (void)setUserDesiredAgeTXTRecord:(uint8_t)userDesiredAge
{
    NSMutableDictionary *txtRecordDict = [[self userTXTRecordDictionary] mutableCopy];
    [txtRecordDict setObject:[NSString stringWithFormat:@"%@", @(userDesiredAge)] forKey:BonjourChatServiceUserDesiredAge];
    [self updateRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDict]];
}

- (uint8_t)userDesiredAgeTXTRecord
{
    NSDictionary *txtRecordDict = [self userTXTRecordDictionary];
    NSData *recordObject = [txtRecordDict objectForKey:BonjourChatServiceUserDesiredAge];
    uint8_t userDesiredAge = [[self numberForStringData:recordObject] unsignedCharValue];
    return userDesiredAge;
}

- (NSNumber *)numberForStringData:(NSData *)numberStringData
{
    NSString *numberString = [[NSString alloc] initWithData:numberStringData encoding:NSUTF8StringEncoding];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [formatter numberFromString:numberString];
}


#pragma mark - BonjourChatConnectionDelegate

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didReceiveData:(NSData *)data
{
    NSLog(@"Did receive data: %@ from %@", data, bonjourChatConnection);
}

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didWriteData:(NSData *)data withError:(NSError *)error
{
}

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didCloseStream:(NSStream *)stream
{
    if ([[self bonjourChatConnections] containsObject:bonjourChatConnection]) {
        [[self bonjourChatConnections] removeObject:bonjourChatConnection];
    }
}

#pragma mark - BonjourChatSocketDelegate

- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didCreateConnection:(BonjourChatConnection *)chatConnection
{
    [[self bonjourChatConnections] addObject:chatConnection];
    [chatConnection setDelegate:self];
    [chatConnection openConnection];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceWillPublish:(NSNetService *)sender
{
    NSLog(@"Will publish service: %@", sender);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"Did publish service: %@", sender);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    NSLog(@"Failed to publish service: %@ with error: %@", sender, errorDict);
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog(@"Did publish service: %@", sender);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"Did resolve service: %@", sender);
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    NSLog(@"Did not resolve service: %@ with error: %@", sender, errorDict);
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog(@"Did stop service: %@", sender);
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    NSDictionary *txtRecord = [NSNetService dictionaryFromTXTRecordData:data];
    NSLog(@"Did update TXT Record: %@", txtRecord);
}


@end
