# GYSignal

[![CI Status](https://img.shields.io/travis/ygyalone/GYSignal.svg?style=flat)](https://travis-ci.org/ygyalone/GYSignal)
[![Version](https://img.shields.io/cocoapods/v/GYSignal.svg?style=flat)](https://cocoapods.org/pods/GYSignal)
[![License](https://img.shields.io/cocoapods/l/GYSignal.svg?style=flat)](https://cocoapods.org/pods/GYSignal)
[![Platform](https://img.shields.io/cocoapods/p/GYSignal.svg?style=flat)](https://cocoapods.org/pods/GYSignal)

## Introduction
GYSignal是iOS平台下对响应式编程的支持,文档补充中...

## Example

**map(值映射):**

```objc
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
```

**diffrent(当value值与上一次触发不相同时才触发value回调):**

```objc
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
```

**skip(指定忽略值的次数):**

```objc
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
```

**then(当前一个信号执行完毕才会执行下一个信号):**

```objc
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
```

**zip(信号打包):**

```objc
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
```

**zipWith(信号打包):**

```objc
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
    
    [[signal1 zipWith:signal2] subscribeValue:^(GYTuple *value) {
        BOOL valid = [value[0] isEqual:@"1"] && [value[1] isEqual:@"2"];
        XCTAssert(valid, @"test_zip failed!");
    }];
```

**mergeWith(信号组合):**

```objc
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
    
    NSMutableArray *recivedValues = @[].mutableCopy;
    [[signal1 mergeWith:signal2] subscribeValue:^(id value) {
        [recivedValues addObject:value];
    }];
    
    BOOL valid = [recivedValues containsObject:@"1"] && [recivedValues containsObject:@"2"];
    XCTAssert(valid, @"test_skip failed!");
```

**kvo(观察者模式，信号绑定):**

```objc
    GYSignal *stringSignal = [GYObserve(self, aString) skip:1];//忽略初始值
    GYSignal *numberSignal = [GYObserve(self, aNumber) skip:1];//忽略初始值
    [[stringSignal zipWith:numberSignal] subscribeValue:^(GYTuple *value) {
        BOOL valid = [value[0] isEqual:@"hello"] && [value[1] isEqual:@(666)];
        XCTAssert(valid, @"test_kvo failed!");
    }];
    self.aString = @"hello";
    self.aNumber = 666;
```

**UITextField(对text属性的kvo支持):**

```objc
    UITextField *textField = [UITextField new];
    GYSignal *signal = [textField.gy_textSignal skip:1];
    [signal subscribeValue:^(NSString *value) {
        XCTAssert([value isEqual:@"hello"], @"test_textField_kvo failed!");
    }];
    textField.text = @"hello";
```


## Author

ygyalone, yangguangyu@xunlei.com

## License

GYSignal is available under the MIT license. See the LICENSE file for more info.
