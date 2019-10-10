//
//  GYSignal.h
//  RACDemo
//
//  Created by GuangYu on 2018/8/11.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYTuple.h"

#define GYWeak(obj) __weak typeof(obj) weak_##obj = obj;
#define GYStrong(obj) __strong typeof(weak_##obj) obj = weak_##obj;

NS_ASSUME_NONNULL_BEGIN

///信号订阅者
@protocol GYSubscriber <NSObject>

/// 发送值事件
/// @param value 值对象
- (void)sendValue:(nullable id)value;

/// 发送完成事件
- (void)sendComplete;

/// 发送失败事件
/// @param error 错误对象
- (void)sendError:(NSError *)error;

@end

///信号销毁者
@interface GYSignalDisposer : NSObject

/// 信号是否被销毁
@property (nonatomic, readonly, getter=isDisposed) BOOL disposed;

/// 创建信号销毁对象
/// @param action 销毁时的自定义操作
+ (instancetype)disposerWithAction:(nullable void (^)(void))action;

/// 销毁操作
- (void)dispose;

@end


///信号
@interface GYSignal<T> : NSObject

/// 创建信号
/// @param block 信号被订阅时的动作
+ (instancetype)signalWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;

/// 创建信号
/// @param block 信号被订阅时的动作
- (instancetype)initWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;

#pragma mark - subscribe

/// 订阅信号
/// @param valueBlock 值回调，可以回调多次
- (GYSignalDisposer *)subscribeValue:(nullable void(^)(_Nullable T value))valueBlock;

/// 订阅信号
/// @param errorBlock 错误回调，最多回调一次，与完成回调互斥
- (GYSignalDisposer *)subscribeError:(nullable void(^)(NSError *error))errorBlock;

/// 订阅信号
/// @param completeBlock 完成回调，最多回调一次，与错误回调互斥
- (GYSignalDisposer *)subscribeComplete:(nullable void(^)(void))completeBlock;

/// 订阅信号
/// @param valueBlock 值回调，可以回调多次
/// @param errorBlock 错误回调，最多回调一次，与完成回调互斥
- (GYSignalDisposer *)subscribeValue:(nullable void(^)(_Nullable T value))valueBlock
                               error:(nullable void(^)(NSError *error))errorBlock;


/// 订阅信号
/// @param valueBlock 值回调，可以执行多次
/// @param completeBlock 完成回调，最多回调一次，与错误回调互斥
- (GYSignalDisposer *)subscribeValue:(nullable void(^)(_Nullable T value))valueBlock
                            complete:(nullable void(^)(void))completeBlock;


/// 订阅信号
/// @param valueBlock 值回调，可以回调多次
/// @param errorBlock 错误回调，最多回调一次，与完成回调互斥
/// @param completeBlock 完成回调，最多回调一次，与错误回调互斥
- (GYSignalDisposer *)subscribeValue:(nullable void(^)(_Nullable T value))valueBlock
                               error:(nullable void(^)(NSError *error))errorBlock
                            complete:(nullable void(^)(void))completeBlock;

#pragma mark - operations

/// 创建固定值信号
/// @param value 值
+ (instancetype)just:(nullable T)value;

/// 值过滤
/// 值回调：当源信号发送值，只有block返回布尔真时订阅者才会触发值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
/// @param block 过滤block
- (instancetype)filter:(BOOL(^)(_Nullable T value))block;

/// 值变化
/// 值回调：当源信号发送值，只有和上一次的值不同时订阅者才会触发值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
- (instancetype)diffrent;

/// 节流
/// 值回调：当源信号发送值，只有 takeCount 参数指定的前几个值才会触发订阅者的值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
/// @param takeCount 获取值次数
- (instancetype)take:(NSUInteger)takeCount;

/// 值忽略
/// 值回调：当源信号发送值，只有超过 skipCount 参数指定的次数才会触发订阅者的值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
/// @param skipCount 忽略值次数
- (instancetype)skip:(NSUInteger)skipCount;

/// 失败重试
/// 值回调：当源信号发送值，订阅者会触发值回调。
/// 错误回调：当源信号发送错误，如果失败次数没有超过重试参数指定的次数，会重新订阅源信号。否则触发订阅者错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
/// @param count 重试次数
- (instancetype)retry:(NSUInteger)count;

/// 最终操作
/// 值回调：当源信号发送值，订阅者会触发值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调，然后执行最终操作。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调，然后执行最终操作。
/// @param block 最终操作
- (instancetype)finally:(void (^)(void))block;

/// 值映射
/// 值回调：当源信号发送值，订阅者会触发值回调，接收到的值为转换之后的值。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会触发完成回调。
/// @param block 值转换操作
- (GYSignal *)map:(_Nullable id (^)(_Nullable T value))block;

/// 信号映射
/// 值回调：当源信号发送值，订阅者会去订阅转换后的信号。
/// 错误回调：当源信号或者转换后的信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号或者转换后的信号发送完成，订阅者会触发完成回调。
/// @param block 信号转换操作
- (GYSignal *)flattenMap:(GYSignal * (^)(_Nullable T value))block;

/// 后续信号
/// 值回调：当源信号发送值，订阅者 不会 触发值回调。
/// 错误回调：当源信号发送错误，订阅者会触发错误回调。
/// 完成回调：当源信号发送完成，订阅者会去订阅参数指定的信号。
/// @param signal 完成之后的信号
- (GYSignal *)then:(GYSignal *)signal;

/// 信号合并
/// 值回调：源信号或者合并的信号发送值，订阅者会触发值回调。
/// 错误回调：源信号或者合并的信号发送错误，订阅者会触发错误回调。
/// 完成回调：源信号或者合并的信号发送完成，订阅者会触发完成回调。
/// @param signals 合并的信号
- (instancetype)merge:(NSArray<GYSignal *> *)signals;

/// 信号打包
/// 值回调：只有打包的信号都至少发送过一次值，订阅者才会触发值回调，每个信号的值通过打包顺序从元组对象中获取。
/// 错误回调：只要有打包信号发送错误，订阅者会触发错误回调。
/// 完成回调：当所有打包的信号都发送完成，订阅者才会触发完成回调。
/// @param signals 完成之后的信号
- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals;

@end

NS_ASSUME_NONNULL_END
