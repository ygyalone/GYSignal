//
//  UITextField+GYSignal.h
//  ShortVideo
//
//  Created by ygy on 2018/9/6.
//  Copyright © 2018年 Xunlei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GYSignal.h"

@interface UITextField (GYSignal)
- (GYSignal<NSString *> *)gy_textSignal;
@end
