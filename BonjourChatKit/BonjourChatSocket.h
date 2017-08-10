//
//  BonjourChatSocket.h
//  BonjourChatKit
//
//  Created by MMM on 7/30/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourChatServerSocketDelegate;

@class BonjourChatConnection;

@interface BonjourChatSocket : NSObject

@property (nonatomic, readonly) int port;

@property (nonatomic, weak) id<BonjourChatServerSocketDelegate>serverDelegate;

- (instancetype)initWithPort:(int)port;

@end


#pragma mark - BonjourChatServerSocketDelegate

@protocol BonjourChatServerSocketDelegate <NSObject>

@optional

- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didCreateConnection:(BonjourChatConnection *)chatConnection;

@end

