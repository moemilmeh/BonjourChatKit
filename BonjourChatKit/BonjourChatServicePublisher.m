//
//  BonjourChatServicePublisher.m
//  BonjourChatKit
//
//  Created by MMM on 7/29/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

//+++++++++++++++++++++++++++++++++++++++++++++++++++++
// Publish Process:
//
//    1. Configure a socket for the service
//    2. Init. and publish a network service
//    3. Implement delegate methods
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "BonjourChatServicePublisher.h"

NSString *const BonjourChatServiceDomainName                = @"";
NSString *const BonjourChatServiceType                      = @"_chat._tcp.";

NSString *const BonjourChatServiceUserSex                   = @"Sex";
NSString *const BonjourChatServiceUserDesiredSex            = @"DSex";

NSString *const BonjourChatServiceUserAge                   = @"Age";
NSString *const BonjourChatServiceUserDesiredAge            = @"DAge";

@interface BonjourChatServicePublisher ()

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
        
        _port = port;
        _service = [[NSNetService alloc] initWithDomain:domain type:type name:name port:port];
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
        
        [[self service] publishWithOptions:NSNetServiceListenForConnections];
    }
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