//
//  NSObject+GYSignal.h
//  RACDemo
//
//  Created by GuangYu on 2018/8/12.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYSignal.h"

#define GYObserve(target, path) \
[target gy_signalForKeyPath:@GY_KEYPATH(target, path)]

#define GY_KEYPATH(obj, path)  \
(((void)(NO && ((void)obj.path, NO)), #path))

@interface NSObject (GYSignal)
- (GYSignal *)gy_signalForKeyPath:(NSString *)keyPath;
- (GYSignal *)gy_deallocSignal;
@end
