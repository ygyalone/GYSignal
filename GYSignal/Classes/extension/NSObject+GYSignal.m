//
//  NSObject+GYSignal.m
//  RACDemo
//
//  Created by GuangYu on 2018/8/12.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import "NSObject+GYSignal.h"
#import <objc/runtime.h>

#define kSubscriberKey  @"gy_subscriber"
#define kObserverKey    "gy_observer"

@interface _GYKeyPathObserver : NSObject
@property (nonatomic, unsafe_unretained) NSObject *target;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) void (^valueChanged)(id value);
@end

@implementation _GYKeyPathObserver

- (void)observeTarget:(id)target forKeyPath:(NSString *)keyPath {
    self.target = target;
    self.keyPath = keyPath;
    [_target
     addObserver:self forKeyPath:_keyPath
     options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
     context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == self.target &&
        [keyPath isEqualToString:self.keyPath] &&
        _valueChanged) {
        _valueChanged([self.target valueForKeyPath:keyPath]);
    }
}

- (void)dealloc {
    if (self.target && self.keyPath.length) {
        [self.target removeObserver:self forKeyPath:self.keyPath context:nil];
        self.target = nil;
    }
}

@end


@implementation NSObject (GYSignal)
- (GYSignal *)gy_signalForKeyPath:(NSString *)keyPath {
    
    __weak typeof(self) weak_self = self;
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        const char *key = [NSString stringWithFormat:@"%@_%@",kSubscriberKey , [NSUUID UUID].UUIDString].UTF8String;
        objc_setAssociatedObject(weak_self, key, subscriber, OBJC_ASSOCIATION_RETAIN);
        _GYKeyPathObserver *observer = [_GYKeyPathObserver new];
        objc_setAssociatedObject(subscriber, kObserverKey, observer, OBJC_ASSOCIATION_RETAIN);
        
        __weak typeof(subscriber) weak_subscriber = subscriber;
        [observer setValueChanged:^(id value) {
            [weak_subscriber sendValue:value];
        }];
        [observer observeTarget:weak_self forKeyPath:keyPath];
        
        return [GYSignalDisposer disposerWithAction:^{
            objc_setAssociatedObject(weak_self, key, nil, OBJC_ASSOCIATION_RETAIN);
        }];
    }];
}

- (GYSignal *)gy_deallocSignal {
    NSAssert(NO, @"gy_deallocSignal not implemented yet!");
    return nil;
}

@end
