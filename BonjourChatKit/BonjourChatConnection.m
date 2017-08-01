//
//  BonjourChatConnection.m
//  BonjourChatKit
//
//  Created by MMM on 7/31/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import "BonjourChatConnection.h"

#define MAX_BUFFER_SIZE         40960

static const char *streamQueueString            = "BonjourChatKit.BonjourChatConnection.StreamQ";
static const char *delegateQueueString          = "BonjourChatKit.BonjourChatConnection.DelegateQ";

@interface BonjourChatConnection () <NSStreamDelegate>

@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic) NSMutableData *dataToWrite;

@property (nonatomic) dispatch_queue_t streamQueue;
@property (nonatomic) dispatch_queue_t delegateQueue;

@end

@implementation BonjourChatConnection

- (instancetype)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    if (self = [super init]) {
        
        _dataToWrite = [NSMutableData data];
        _streamQueue = dispatch_queue_create(streamQueueString, DISPATCH_QUEUE_SERIAL);
        _delegateQueue = dispatch_queue_create(delegateQueueString, DISPATCH_QUEUE_CONCURRENT);
        
        //---------------------
        // Input stream
        //---------------------
        [self setInputStream:inputStream];
        [[self inputStream] setDelegate:self];
        [[self inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self inputStream] open];
        
        //---------------------
        // Output stream
        //---------------------
        [self setOutputStream:outputStream];
        [[self outputStream] setDelegate:self];
        [[self outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self outputStream] open];
    }
    
    return self;
}

- (void)openConnection
{
    if ([self inputStream]) {
        [[self inputStream] open];
    }
    
    if ([self outputStream]) {
        [[self outputStream] open];
    }
}

- (void)closeConnection
{
    [self closeStream:[self inputStream]];
    [self setInputStream:nil];
    
    [self closeStream:[self outputStream]];
    [self setOutputStream:nil];
}

- (void)closeStream:(NSStream *)stream
{
    dispatch_async([self streamQueue], ^{
        
        if ([stream streamStatus] != NSStreamStatusClosed) {
            [stream close];
        }
        [stream setDelegate:nil];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        if ([[self delegate] respondsToSelector:@selector(bonjourChatConnection:didCloseStream:)]) {
            dispatch_async([self delegateQueue], ^{
                [[self delegate] bonjourChatConnection:self didCloseStream:stream];
            });
        }
    });
}


#pragma mark - Read Data

- (void)receivedDataFromStram:(NSInputStream *)inputStream
{
    while ([inputStream hasBytesAvailable]) {
        
        uint8_t buffer[MAX_BUFFER_SIZE];
        NSInteger readDataLength = [inputStream read:buffer maxLength:MAX_BUFFER_SIZE];
        
        if (readDataLength == 0) {
            
            // This indicates the socket was closed by the client
            NSLog(@"Socket was closed by the client");
            [self closeStream:inputStream];
            return;
            
        } else if (readDataLength < 0) {
            NSLog(@"Failed to read the data");
            
        } else {
            
            NSData *data = [NSData dataWithBytes:buffer length:readDataLength];
            if ([[self delegate] respondsToSelector:@selector(bonjourChatConnection:didReceiveData:)]) {
                dispatch_async([self delegateQueue], ^{
                    [[self delegate] bonjourChatConnection:self didReceiveData:data];
                });
            }
        }
    }
}


#pragma mark - Write Data

- (void)sendData:(NSData *)data
{
    dispatch_async([self streamQueue], ^{
        [_dataToWrite appendData:data];
        [self _writeData];
    });
}

- (void)writeData
{
    dispatch_async([self streamQueue], ^{
        [self _writeData];
    });
}

- (void)_writeData
{
    // Skip if there are no more data to write
    if (![[self dataToWrite] length]) {
        return;
    }
    
    if ([self outputStream]) {
        
        // TODO: Update error
        NSError *error;
        NSData *dataToWrite = _dataToWrite;
        
        NSUInteger dataLength = [_dataToWrite length];
        NSInteger dataWritten = [[self outputStream] write:[_dataToWrite bytes] maxLength:dataLength];
        
        if (dataWritten <= 0) {
            NSLog(@"Failed to write data: %@", _dataToWrite);
            
        } else {
            
            NSUInteger remainingData = dataLength - dataWritten;
            _dataToWrite = [NSMutableData dataWithData:[dataToWrite subdataWithRange:NSMakeRange(dataWritten, remainingData)]];
        }
        
        if ([[self delegate] respondsToSelector:@selector(bonjourChatConnection:didWriteData:withError:)]) {
            dispatch_async([self delegateQueue], ^{
                [[self delegate] bonjourChatConnection:self didWriteData:dataToWrite withError:error];
            });
        }
    }
}


#pragma mark - NSStreamDelegate Callbacks

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
            
        case NSStreamEventOpenCompleted:
            
            if ([[self delegate] respondsToSelector:@selector(bonjourChatConnection:didOpenStream:)]) {
                dispatch_async([self delegateQueue], ^{
                    [[self delegate] bonjourChatConnection:self didOpenStream:aStream];
                });
            }
            NSLog(@"Stream: %@ did open", aStream);
            break;
            
        case NSStreamEventHasSpaceAvailable:
            
            if ([[self dataToWrite] length]) {
                [self writeData];
            }
            NSLog(@"Stream: %@ has space available", aStream);
            break;
            
        case NSStreamEventHasBytesAvailable:
            
            [self receivedDataFromStram:(NSInputStream *)aStream];
            NSLog(@"Stream: %@ has bytes available", aStream);
            break;
            
        case NSStreamEventErrorOccurred:
            
            NSLog(@"Stream: %@ error occurred: %@", aStream, [aStream streamError]);
            [self closeStream:aStream];
            break;
            
        case NSStreamEventEndEncountered:
            
            NSLog(@"Stream: %@ end oncountered", aStream);
            [self closeStream:aStream];
            break;
            
        default:
            NSLog(@"Stream: %@ received event: %@", aStream, @(eventCode));
            break;
    }
}

@end
