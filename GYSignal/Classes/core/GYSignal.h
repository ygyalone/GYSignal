//
//  GYSignal.h
//  RACDemo
//
//  Created by GuangYu on 2018/8/11.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYTuple.h"

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
/// 值回调：源信号发送值，只有block返回布尔真时订阅者才会触发值回调
/// 错误回调：源信号发送错误，订阅者触发错误回调
/// 完成回调：源信号发送完成，订阅者触发完成回调
/// @param block 过滤block
- (instancetype)filter:(BOOL(^)(T value))block;

- (instancetype)diffrent;

/// 值节流
/// 值回调：源信号发送值，只有block返回布尔真时订阅者才会触发值回调
/// 错误回调：源信号发送错误，订阅者触发错误回调
/// 完成回调：源信号发送完成，订阅者触发完成回调
/// @param takeCount 获取值次数
- (instancetype)take:(NSUInteger)takeCount;

- (instancetype)skip:(NSUInteger)skipCount;

/// 失败重试
/// @param count 重试次数
- (instancetype)retry:(NSUInteger)count;

- (instancetype)merge:(NSArray<GYSignal<T> *> *)signals;

- (instancetype)finally:(void (^)(void))block;

/// 值转换
- (GYSignal *)map:(id (^)(_Nullable T value))block;

/// 信号转换
- (GYSignal *)flattenMap:(GYSignal * (^)(_Nullable T value))block;

- (GYSignal *)then:(nonnull GYSignal *)signal;

- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals;

@end

NS_ASSUME_NONNULL_END
