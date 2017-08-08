//
//  BonjourChatServiceBrowser.m
//  BonjourChatKit
//
//  Created by MMM on 8/7/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Source: https://developer.apple.com/library/content/documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/BrowsingForServices.html
//
// Browsing Process:
//
//    1. Init. instance of NSNetServiceBrowser and assign a delegate to it
//    2. Begin searching for service type
//    3. Handle search results
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "BonjourChatServiceBrowser.h"
#import "BonjourChatConstants.h"

@interface BonjourChatServiceBrowser ()

@property (nonatomic) NSMutableSet *disocveredServices;
@property (atomic, assign) BOOL searching;

@end

@implementation BonjourChatServiceBrowser

#pragma mark - Init.

- (instancetype)init
{
    if (self = [self initWithServiceType:BonjourChatServiceType domainName:BonjourChatServiceDomainName]) {
        
    }
    
    return self;
}

- (instancetype)initWithServiceType:(NSString *)type domainName:(NSString *)domain
{
    
    if (self = [super init]) {
        
        //----------------------------
        // 1. Init. service browser
        //----------------------------
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        _disocveredServices = [NSMutableSet set];
        
        _serviceType = type;
        _serviceDomain = domain;
        _searching = NO;
        [_serviceBrowser setDelegate:self];
    }
    
    return self;
    
}

- (void)startBrowsing
{
    if ([self serviceBrowser]) {
        
        NSString *serviceType   = [self serviceType];
        NSString *serviceDomain = [self serviceDomain];
        
        if (serviceType && serviceDomain) {
            [[self serviceBrowser] searchForServicesOfType:serviceType inDomain:serviceDomain];
        
        } else {
            [[self serviceBrowser] searchForBrowsableDomains];
        }
    }
}

- (void)stopBrowsing
{
    if ([self serviceBrowser]) {
        [[self serviceBrowser] stop];
    }
}


#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"Service browser: %@ will search", browser);
    [self setSearching:YES];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"Service browser: %@ did stop search", browser);
    [self setSearching:NO];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
    NSLog(@"Service browser: %@ did not search with error: %@", browser, errorDict);
    [self setSearching:NO];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did find domain: %@ and more coming: %@", browser, domainString, @(moreComing));
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did find service: %@ and more coming: %@", browser, service, @(moreComing));
    [[self disocveredServices] addObject:service];
    
    if (!moreComing) {
        
        // TODO: Notify delegates its done
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did remove domain: %@ and more coming: %@", browser, domainString, @(moreComing));
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    NSLog(@"Service browser: %@ did remove service: %@ and more coming: %@", browser, service, @(moreComing));
    [[self disocveredServices] removeObject:service];
}

@end
