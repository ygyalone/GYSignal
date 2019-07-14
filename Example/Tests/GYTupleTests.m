//
//  GYTupleTests.m
//  GYSignal_Tests
//
//  Created by GuangYu on 2019/7/14.
//  Copyright © 2019 ygyalone. All rights reserved.
//

#import <XCTest/XCTest.h>
@import GYSignal;

@interface GYTupleTests : XCTestCase

@end

@implementation GYTupleTests


- (void)test_nil {
    GYTuple *tuple = GYTupleCreate(@"", @1, @2, nil);
    XCTAssertTrue([tuple contains:nil]);
}


@end
