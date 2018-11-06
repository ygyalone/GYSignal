//
//  UITextField+GYSignal.m
//  ShortVideo
//
//  Created by ygy on 2018/9/6.
//  Copyright © 2018年 Xunlei. All rights reserved.
//

#import "UITextField+GYSignal.h"
#import "NSObject+GYSignal.h"
#import <objc/runtime.h>

#define kSubscriberBagKey   "gy_subscriberBag"
@implementation UITextField (GYSignal)

- (NSMutableArray<id<GYSubscriber>> *)gy_subscriberBag {
    NSMutableArray *bag = objc_getAssociatedObject(self, kSubscriberBagKey);
    
    if (!bag) {
        bag = [NSMutableArray array];
        objc_setAssociatedObject(self, kSubscriberBagKey, bag, OBJC_ASSOCIATION_RETAIN);
        SEL sel = @selector(gy_textDidChangeAction);
        UIControlEvents event = UIControlEventAllEditingEvents;
        [self addTarget:self action:sel forControlEvents:event];
    }
    
    return bag;
}

- (GYSignal<NSString *> *)gy_textSignal {
    __weak typeof(self) weak_self = self;
    return [[GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [[weak_self gy_subscriberBag] addObject:subscriber];
        return [GYSignalDisposer disposerWithAction:^{
            [[weak_self gy_subscriberBag] removeObject:subscriber];
        }];
    }] merge:@[GYObserve(self, text)]];
}

- (void)gy_textDidChangeAction {
    for (id<GYSubscriber>subscriber in [self gy_subscriberBag]) {
        [subscriber sendValue:self.text];
    }
}

@end
