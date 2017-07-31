//
//  BonjourChatSocket.h
//  BonjourChatKit
//
//  Created by MMM on 7/30/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourChatSocketDelegate;

@interface BonjourChatSocket : NSObject

@property (nonatomic, readonly) int port;
@property (nonatomic, readonly) int ipv6Port;

@property (nonatomic, weak) id<BonjourChatSocketDelegate>delegate;

- (void)writeData:(NSData *)data;

@end

@protocol BonjourChatSocketDelegate <NSObject>


@optional

- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didOpenStream:(NSStream *)stream;
- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didCloseStream:(NSStream *)stream;
- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didReceiveData:(NSData *)data;
- (void)bonjourChatSocket:(BonjourChatSocket *)bonjourChatSocket didWriteData:(NSData *)data withError:(NSError *)error;

@end
