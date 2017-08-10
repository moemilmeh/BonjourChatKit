//
//  BonjourChatKitTests.m
//  BonjourChatKitTests
//
//  Created by MMM on 7/29/17.
//  Copyright © 2017 MoeMilMeh. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BonjourChatServicePublisher.h"
#import "BonjourChatServiceBrowser.h"

@interface BonjourChatKitTests : XCTestCase

@end

@implementation BonjourChatKitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
//    NSLog(@"Number Age: %zd", [publisher userAgeTXTRecord]);
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    BonjourChatServicePublisher *publisher = [[BonjourChatServicePublisher alloc] initWithServiceName:@"MoeMil"];
    [publisher setUserAge:22];
    [publisher setUserDesiredAge:45];
    [publisher setUserSex:UserSexMale];
    [publisher setUserDesiredSex:UserSexFemale];
    [publisher publishChatService];
    sleep(5);

    
    BonjourChatServiceBrowser *browser = [[BonjourChatServiceBrowser alloc] initWithServiceType:@"_chat._tcp." domainName:@"local"];
    [browser startBrowsing];

    
    [[NSRunLoop mainRunLoop] run];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        

    }];
}

@end
