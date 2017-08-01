//
//  BonjourChatConnection.h
//  BonjourChatKit
//
//  Created by MMM on 7/31/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourChatConnectionDelegate;

@interface BonjourChatConnection : NSObject

@property (nonatomic, weak) id<BonjourChatConnectionDelegate>delegate;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

- (void)openConnection;
- (void)closeConnection;
- (void)closeStream:(NSStream *)stream;

- (void)sendData:(NSData *)data;

@end

@protocol BonjourChatConnectionDelegate <NSObject>

@optional

- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didOpenStream:(NSStream *)stream;
- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didCloseStream:(NSStream *)stream;
- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didReceiveData:(NSData *)data;
- (void)bonjourChatConnection:(BonjourChatConnection *)bonjourChatConnection didWriteData:(NSData *)data withError:(NSError *)error;

@end
