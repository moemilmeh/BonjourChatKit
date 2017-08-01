//
//  BonjourChatSocket.h
//  BonjourChatKit
//
//  Created by MMM on 7/30/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourChatSocketDelegate;

@class BonjourChatConnection;

@interface BonjourChatSocket : NSObject

@property (nonatomic, readonly) int port;
@property (nonatomic, readonly) int ipv6Port;

@property (nonatomic, weak) id<BonjourChatSocketDelegate>delegate;

- (instancetype)initWithPort:(int)port;

@end


#pragma mark - BonjourChatSocketDelegate

@protocol BonjourChatSocketDelegate <NSObject>

@optional

- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didCreateConnection:(BonjourChatConnection *)chatConnection;

@end
