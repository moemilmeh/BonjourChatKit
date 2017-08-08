//
//  BonjourChatServiceBrowser.h
//  BonjourChatKit
//
//  Created by MMM on 8/7/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourChatServiceBrowserDelegate;

@interface BonjourChatServiceBrowser : NSObject <NSNetServiceBrowserDelegate>

@property (nonatomic, readonly) NSNetServiceBrowser *serviceBrowser;

@property (nonatomic, readonly, copy) NSString *serviceType;
@property (nonatomic, readonly, copy) NSString *serviceDomain;

@property (nonatomic, weak) id<BonjourChatServiceBrowserDelegate>delegate;

#pragma mark - Init.

- (instancetype)initWithServiceType:(NSString *)type domainName:(NSString *)domain;

#pragma mark - Methods

- (void)startBrowsing;
- (void)stopBrowsing;

@end

@protocol BonjourChatServiceBrowserDelegate <NSObject>

@optional

@end
