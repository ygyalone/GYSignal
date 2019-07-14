//
//  GYSignalTests.m
//  GYSignalTests
//
//  Created by ygyalone on 10/18/2018.
//  Copyright (c) 2018 ygyalone. All rights reserved.
//

@import XCTest;
@import GYSignal;
#import <UIKit/UITextField.h>

@interface GYSignalTests : XCTestCase
@property (nonatomic, copy) NSString *aString;
@property (nonatomic, assign) NSInteger aNumber;
@end

@implementation GYSignalTests

#pragma mark - core tests
- (void)test_sendValue {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"hello"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"value block not executed!"];
    
    [signal subscribeValue:^(id value) {
        XCTAssert([value isEqual:@"hello"], @"send value failed!");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}


- (void)test_sendComplete {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"complete block not executed!"];
    
    [signal subscribeComplete:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}


- (void)test_sendError {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        NSError *error = [NSError errorWithDomain:@"error domain" code:01 userInfo:nil];
        [subscriber sendError:error];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"error block not executed!"];
    
    [signal subscribeError:^(NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}


- (void)test_diffrent {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendValue:@"1"];
        [subscriber sendValue:@"2"];
        [subscriber sendValue:@"3"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    NSMutableArray *recivedValues = @[].mutableCopy;
    [[signal diffrent] subscribeValue:^(id value) {
        [recivedValues addObject:value];
    }];
    
    BOOL isEqual = [recivedValues isEqualToArray:@[@"1",@"2",@"3"]];
    XCTAssert(isEqual, @"test_diffrent failed!");
}


- (void)test_skip {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendValue:@"1"];
        [subscriber sendValue:@"2"];
        [subscriber sendValue:@"3"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    NSMutableArray *recivedValues = @[].mutableCopy;
    [[signal skip:2] subscribeValue:^(id value) {
        [recivedValues addObject:value];
    }];
    
    BOOL isEqual = [recivedValues isEqualToArray:@[@"2",@"3"]];
    XCTAssert(isEqual, @"test_skip failed!");
}


- (void)test_merge {
    GYSignal *signal1 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *signal2 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"2"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *signal3 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"3"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    NSMutableArray *recivedValues = @[].mutableCopy;
    [[signal1 merge:@[signal2, signal3]] subscribeValue:^(id value) {
        [recivedValues addObject:value];
    }];
    
    BOOL valid = [recivedValues containsObject:@"1"] &&
    [recivedValues containsObject:@"2"] &&
    [recivedValues containsObject:@"3"];
    
    XCTAssert(valid, @"test_merge failed!");
}


- (void)test_finally {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_finally failed!"];
    
    [[signal finally:^{
        [expectation fulfill];
    }] subscribeValue:^(id value) {
        //do nothing
    } complete:^{
        //do nothing
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}


- (void)test_map {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    [[signal map:^id(id value) {
        return @{@"key":value};
    }] subscribeValue:^(id value) {
        BOOL isEqual = [[value objectForKey:@"key"] isEqual:@"1"];
        XCTAssert(isEqual, @"test_map failed!");
    }];
}

- (void)test_flattenMap {
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *innerSignal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"newValue"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    [[signal flattenMap:^GYSignal *(id value) {
        return innerSignal;
    }] subscribeValue:^(id value) {
        XCTAssertEqual(value, @"newValue", @"test_flattenMap failed!");
    }];
}


- (void)test_then {
    GYSignal *signal1 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *signal2 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"2"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    [[signal1 then:signal2] subscribeValue:^(id value) {
        XCTAssert([value isEqual:@"2"], @"test_then failed!");
    }];
}


- (void)test_zip {
    GYSignal *signal1 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *signal2 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"2"];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    [[signal1 zip:@[signal2]] subscribeValue:^(GYTuple *value) {
        BOOL valid = [value[0] isEqual:@"1"] && [value[1] isEqual:@"2"];
        XCTAssert(valid, @"test_zip failed!");
    }];
}

- (void)test_dispose {
    XCTestExpectation *expectation = [self expectationWithDescription:@"dispose block not executed!"];
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [GYSignalDisposer disposerWithAction:^{
            [expectation fulfill];
        }];
    }];
    
    [[signal subscribeComplete:nil] dispose];
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}

- (void)test_disposeWhenSubscriberDealloced {
    XCTestExpectation *expectation = [self expectationWithDescription:@"dispose block not executed!"];
    GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [GYSignalDisposer disposerWithAction:^{
            [expectation fulfill];
        }];
    }];
    
    @autoreleasepool {
        [signal subscribeComplete:^{
            //nothing to do
        }];
    }
    
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"%@", error);
    }];
}


#pragma mark - extension tests
- (void)test_kvo {
    GYSignal *stringSignal = [GYObserve(self, aString) skip:1];//忽略初始值
    GYSignal *numberSignal = [GYObserve(self, aNumber) skip:1];//忽略初始值
    [[stringSignal zip:@[numberSignal]] subscribeValue:^(GYTuple *value) {
        BOOL valid = [value[0] isEqual:@"hello"] && [value[1] isEqual:@(666)];
        XCTAssert(valid, @"test_kvo failed!");
    }];
    self.aString = @"hello";
    self.aNumber = 666;
}


- (void)test_textField_kvo {
    UITextField *textField = [UITextField new];
    GYSignal *signal = [textField.gy_textSignal skip:1];
    [signal subscribeValue:^(NSString *value) {
        XCTAssert([value isEqual:@"hello"], @"test_textField_kvo failed!");
    }];
    textField.text = @"hello";
}

@end
