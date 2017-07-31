//
//  BonjourChatSocket.m
//  BonjourChatKit
//
//  Created by MMM on 7/30/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Source:
// https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/UsingSocketsandSocketStreams.html
// http://archive.oreilly.com/pub/a/iphone/excerpts/iphone-sdk/network-programming.html
//
// Client:
//
//
// Server:
//
//    1. Create socket objects for ipv4 and ipv6
//    2. Bind the sockets
//    3. Start listening on a socket after adding it to a run loop
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "BonjourChatSocket.h"
#import <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#import <CFNetwork/CFNetwork.h>

#define MAX_BUFFER_SIZE         40960

static void socketAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

static const char *streamQueueString            = "BonjourChatKit.BonjourChatSocket.StreamQ";
static const char *delegateQueueString          = "BonjourChatKit.BonjourChatSocket.DelegateQ";


@interface BonjourChatSocket () <NSStreamDelegate>

@property (nonatomic) CFSocketRef ipv6Socket;
@property (nonatomic) CFSocketRef ipv4Socket;

@property (nonatomic, copy) NSString *ipv4Address;
@property (nonatomic, copy) NSString *ipv6Address;

@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic) NSMutableData *dataToWrite;

@property (nonatomic) dispatch_queue_t streamQueue;
@property (nonatomic) dispatch_queue_t delegateQueue;

@end

@implementation BonjourChatSocket

- (instancetype)init
{
    if (self = [super init]) {
    
        _dataToWrite = [NSMutableData data];
        _streamQueue = dispatch_queue_create(streamQueueString, DISPATCH_QUEUE_SERIAL);
        _delegateQueue = dispatch_queue_create(delegateQueueString, DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (BOOL)createServerSockets
{
    //-------------------------------------------
    // 1. Create socket objects
    //-------------------------------------------
    
    CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    _ipv4Socket = CFSocketCreate(kCFAllocatorDefault , PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&socketAcceptCallback, &socketContext);
    _ipv6Socket = CFSocketCreate(kCFAllocatorDefault , PF_INET6, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&socketAcceptCallback, &socketContext);
    if (_ipv4Socket == NULL || _ipv6Socket == NULL) {
        NSLog(@"Failed to create a socket for %@", _ipv4Socket == NULL ? @"ipv4" : @"ipv6");
        return NO;
    }
    
    //-------------------------------------------
    // 2. Bind sockets with an address
    //-------------------------------------------
    
    // ipv4
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(0);
    sin.sin_addr.s_addr = INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&sin, sizeof(sin));
    if (CFSocketSetAddress(_ipv4Socket, sincfd) != kCFSocketSuccess) {
        
        NSLog(@"Failed to bind a local address to ipv4 socket");
        if (_ipv4Socket) {
            CFRelease(_ipv4Socket);
            _ipv4Socket = NULL;
        }
        
        return NO;
    }
    
    NSData *ipv4Addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4Socket);
    memcpy(&sin, [ipv4Addr bytes], [ipv4Addr length]);
    
    _port = ntohs(sin.sin_port);
    char ipv4Address[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &(sin.sin_addr), ipv4Address, sizeof(ipv4Address));
    _ipv4Address = [NSString stringWithFormat:@"%s", ipv4Address];
    CFRelease(sincfd);
    
    // ipv6
    struct sockaddr_in6 sin6;
    memset(&sin6, 0, sizeof(sin6));
    
    sin6.sin6_len = sizeof(sin6);
    sin6.sin6_family = AF_INET6;
    sin6.sin6_port = htons(0);
    sin6.sin6_addr = in6addr_any;
    
    CFDataRef sin6cfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&sin6, sizeof(sin6));
    if (CFSocketSetAddress(_ipv6Socket, sincfd) != kCFSocketSuccess) {
        NSLog(@"Failed to bind a local address to ipv6 socket");
        if (_ipv6Socket) {
            CFRelease(_ipv6Socket);
            _ipv6Socket = NULL;
        }
        
        return NO;
    }
    
    NSData *ipv6Addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv6Socket);
    memcpy(&sin6, [ipv6Addr bytes], [ipv4Addr length]);
    _ipv6Port = ntohs(sin6.sin6_port);
    
    
    char ipv6Address[INET6_ADDRSTRLEN];
    inet_ntop(AF_INET6, &(sin6.sin6_addr), ipv6Address, sizeof(ipv6Address));
    _ipv6Address = [NSString stringWithFormat:@"%s", ipv6Address];
    CFRelease(sin6cfd);
    
    //-------------------------------------------
    // 3. Create a run loop and start listening
    //-------------------------------------------
    CFRunLoopSourceRef ipv4SocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4Socket, 0);
    CFRunLoopSourceRef ipv6SocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6Socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), ipv4SocketSource, kCFRunLoopDefaultMode);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), ipv6SocketSource, kCFRunLoopDefaultMode);
    
    return YES;
}

- (void)createConnetionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    //---------------------
    // Input stream
    //---------------------
    if ([self inputStream]) {
        [self closeStream:self.inputStream];
    }
    [self setInputStream:inputStream];
    [[self inputStream] setDelegate:self];
    [[self inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self inputStream] open];
    
    //---------------------
    // Output stream
    //---------------------
    if ([self outputStream]) {
        [self closeStream:self.outputStream];
    }
    [self setOutputStream:outputStream];
    [[self outputStream] setDelegate:self];
    [[self outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self outputStream] open];
}

- (void)closeStream:(NSStream *)stream
{
    if ([stream streamStatus] != NSStreamStatusClosed) {
        [stream close];
    }
    [stream setDelegate:nil];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if ([[self delegate] respondsToSelector:@selector(bonjourChatSocket:didCloseStream:)]) {
        dispatch_async([self delegateQueue], ^{
            [[self delegate] bonjourChatSocket:self didCloseStream:stream];
        });
    }
}

#pragma mark - Read Data

- (void)readDataFromStram:(NSInputStream *)inputStream
{
    while ([inputStream hasBytesAvailable]) {
        
        uint8_t buffer[MAX_BUFFER_SIZE];
        NSInteger readDataLength = [inputStream read:buffer maxLength:MAX_BUFFER_SIZE];
        
        if (readDataLength == 0) {
            
            // This indicates the socket was closed by the client
            NSLog(@"Socket was closed by the client");
            
            // TODO: Close the streams
            return;
        
        } else if (readDataLength < 0) {
            NSLog(@"Failed to read the data");
        
        } else {
            
            NSData *data = [NSData dataWithBytes:buffer length:readDataLength];
            
            if ([[self delegate] respondsToSelector:@selector(bonjourChatSocket:didReceiveData:)]) {
                dispatch_async([self delegateQueue], ^{
                    [[self delegate] bonjourChatSocket:self didReceiveData:data];
                });
            }
        }
    }
}


#pragma mark - Write Data

- (void)writeData:(NSData *)data
{
    dispatch_async([self streamQueue], ^{
        [_dataToWrite appendData:data];
    });
}

- (void)writeData
{
    dispatch_async([self streamQueue], ^{
        
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
            
            if ([[self delegate] respondsToSelector:@selector(bonjourChatSocket:didWriteData:withError:)]) {
                dispatch_async([self delegateQueue], ^{
                    [[self delegate] bonjourChatSocket:self didWriteData:dataToWrite withError:error];
                });
            }
        }
    });
}

#pragma mark - NSStreamDelegate Callbacks

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        
        case NSStreamEventOpenCompleted:
            
            if ([[self delegate] respondsToSelector:@selector(bonjourChatSocket:didOpenStream:)]) {
                dispatch_async([self delegateQueue], ^{
                    [[self delegate] bonjourChatSocket:self didOpenStream:aStream];
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
            
            [self readDataFromStram:(NSInputStream *)aStream];
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



#pragma mark - C Callback

static void socketAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    
    CFSocketContext localContext;
    CFSocketGetContext(s, &localContext);
    
    BonjourChatSocket *bonjourChatSocket = (__bridge BonjourChatSocket *)info;//localContext.info;
    
    switch (type) {
        
        case kCFSocketAcceptCallBack:
        {
            
            CFReadStreamRef readStream = NULL;
            CFWriteStreamRef writeStream = NULL;

            NSData *addressData = (__bridge_transfer NSData *)address;
            struct sockaddr_in sockAddr;
            memcpy(&sockAddr, [addressData bytes], [addressData length]);
            
            // Create the read and write streams for the socket
            CFSocketNativeHandle sock = *(CFSocketNativeHandle *)data;
            
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock, &readStream, &writeStream);
            
            if (!readStream || !writeStream) {
                close(sock);
                NSLog(@"Failed to create read and write streams");
                
                return;
            }
            
            // Set the stream properties: Close the socket when the streams are released
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

            // Setup the input and output streams
            [bonjourChatSocket createConnetionWithInputStream:(__bridge_transfer NSInputStream*)readStream outputStream:(__bridge_transfer NSOutputStream *)writeStream];
            
            
            if (readStream) {
                CFRelease(readStream);
            }
            
            if (writeStream) {
                CFRelease(writeStream);
            }
            
        }
            break;
            
        default:
            NSLog(@"Recevied invalid callback type: %@", @(type));
            break;
    }
}


