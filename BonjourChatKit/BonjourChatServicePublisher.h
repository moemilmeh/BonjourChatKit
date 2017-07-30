//
//  BonjourChatServicePublisher.h
//  BonjourChatKit
//
//  Created by MMM on 7/29/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, UserSex)
{
    UserSexMale     = 0,
    UserSexFemale   = 1,
    UserSexAny      = 2,
};

@interface BonjourChatServicePublisher : NSObject <NSNetServiceDelegate>

#pragma mark - Properties

@property (nonatomic, readonly) NSNetService *service;
@property (nonatomic, assign, readonly) int port;

@property (nonatomic) UserSex userSex;
@property (nonatomic) UserSex userDesiredSex;

@property (nonatomic) uint8_t userAge;
@property (nonatomic) uint8_t userDesiredAge;
- (uint8_t)userAgeTXTRecord;

#pragma mark - Init.

- (instancetype)initWithServiceName:(NSString *)name;
- (instancetype)initWithServiceName:(NSString *)name port:(int)port;
- (instancetype)initWithServiceName:(NSString *)name serviceType:(NSString *)type domainName:(NSString *)domain port:(int)port;


#pragma mark - Methods

- (void)publishChatService;


@end
