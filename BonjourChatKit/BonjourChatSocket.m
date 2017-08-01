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
#import "BonjourChatConnection.h"

static const char *delegateQueueString          = "BonjourChatKit.BonjourChatSocket.DelegateQ";

static void socketAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);


@interface BonjourChatSocket () 

@property (nonatomic) CFSocketRef ipv6Socket;
@property (nonatomic) CFSocketRef ipv4Socket;

@property (nonatomic, copy) NSString *ipv4Address;
@property (nonatomic, copy) NSString *ipv6Address;

@property (nonatomic) dispatch_queue_t delegateQueue;

@end

@implementation BonjourChatSocket

- (instancetype)initWithPort:(int)port
{
    if (self = [super init]) {
        
        _delegateQueue = dispatch_queue_create(delegateQueueString, DISPATCH_QUEUE_CONCURRENT);
        if ([self createServerSocketsWithPort:port] == NO) {
            return nil;
        }
    }
    
    return self;
}

- (BOOL)createServerSocketsWithPort:(int)port
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
    sin.sin_port = htons(port);
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
    sin6.sin6_port = htons(port);
    sin6.sin6_addr = in6addr_any;
    
    CFDataRef sin6cfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&sin6, sizeof(sin6));
    if (CFSocketSetAddress(_ipv6Socket, sin6cfd) != kCFSocketSuccess) {
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
    if ([[self delegate] respondsToSelector:@selector(bonjourChatSocket:didCreateConnection:)]) {
        BonjourChatConnection *bonjourChatConnection = [[BonjourChatConnection alloc] initWithInputStream:inputStream outputStream:outputStream];
        dispatch_async([self delegateQueue], ^{
            [[self delegate] bonjourChatSocket:self didCreateConnection:bonjourChatConnection];
        });
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


