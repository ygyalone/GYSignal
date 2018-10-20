//
//  GYSignal.h
//  RACDemo
//
//  Created by GuangYu on 2018/8/11.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYTuple.h"

///信号订阅者
@protocol GYSubscriber <NSObject>
- (void)sendValue:(id)value;///<发送值
- (void)sendComplete;///<发送完成
- (void)sendError:(NSError *)error;///<发送失败
@end

///信号销毁者
@interface GYSignalDisposer : NSObject
@property (nonatomic, readonly, getter=isDisposed) BOOL disposed;///<信号是否被销毁

/**
 创建信号销毁对象

 @param action 销毁时的自定义操作
 @return 信号销毁对象
 */
+ (instancetype)disposerWithAction:(void (^)(void))action;

/**
 销毁操作
 */
- (void)dispose;
@end


///信号
@interface GYSignal<T> : NSObject

/**
 创建信号

 @param block 信号被订阅时触发
 @return 信号
 */
+ (instancetype)signalWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;

/**
 创建信号
 
 @param block 信号被订阅时触发
 @return 信号
 */
- (instancetype)initWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;

#pragma mark - subscribe
/**
 订阅信号

 @param valueBlock 当信号发送值时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock;

/**
 订阅信号

 @param errorBlock 当信号发送失败时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeError:(void(^)(NSError *error))errorBlock;

/**
 订阅信号

 @param completeBlock 当信号发送完成时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeComplete:(void(^)(void))completeBlock;

/**
 订阅信号

 @param valueBlock 当信号发送值时触发
 @param errorBlock 当信号发送失败时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                           error:(void(^)(NSError *error))errorBlock;

/**
 订阅信号

 @param valueBlock 当信号发送值时触发
 @param completeBlock 当信号发送完成时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                        complete:(void(^)(void))completeBlock;

/**
 订阅信号

 @param valueBlock 当信号发送值时触发
 @param errorBlock 当信号发送失败时触发
 @param completeBlock 当信号发送完成时触发
 @return 信号销毁者
 */
- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                          error:(void(^)(NSError *error))errorBlock
                       complete:(void(^)(void))completeBlock;

#pragma mark - operations

/**
 确保值不同
 onValue:当原信号发送的值和上次不同时，订阅者才会收到值。
 onError:当原信号发送失败时，订阅者会收到失败。
 onComplete:当原信号发送完成时，订阅者会收到完成。

 @return 新的信号
 */
- (instancetype)diffrent;

/**
 指定忽略次数
 onValue:当原信号发送的值超过忽略次数后，订阅者才会收到值。
 onError:当原信号发送失败时，订阅者会收到失败。
 onComplete:当原信号发送完成时，订阅者会收到完成。

 @param skipCount 忽略次数
 @return 新的信号
 */
- (instancetype)skip:(NSUInteger)skipCount;

/**
 信号组合:
 onValue:当组合的信号发送值时，订阅者会收到值。
 onError:当组合的信号发送失败时，订阅者会收到失败。
 onComplete:当组合的信号发送完成时，订阅者会收到完成。

 @param signals 被组合的信号数组
 @return 新的信号
 */
- (instancetype)merge:(NSArray<GYSignal<T> *> *)signals;

/**
 信号组合:
 onValue:当组合的信号发送值时，订阅者会收到值。
 onError:当组合的信号发送失败时，订阅者会收到失败。
 onComplete:当组合的信号发送完成时，订阅者会收到完成。
 
 @param signal 被组合的信号
 @return 新的信号
 */
- (instancetype)mergeWith:(GYSignal<T> *)signal;

/**
 指定最终操作:
 onValue:当原信号发送值时，订阅者会收到值。
 onError:当原信号发送失败时，订阅者会收到失败，接着执行最终操作。
 onComplete:当原信号发送完成时，订阅者会收到完成，接着执行最终操作。

 @param block 自定义最终操作
 @return 新的信号
 */
- (instancetype)finally:(void (^)(void))block;

/**
 值映射:
 onValue:当原信号发送值时，订阅者会收到映射之后的值。
 onError:当原信号发送失败时，订阅者会收到失败。
 onComplete:当原信号发送完成时，订阅者会收到完成。

 @param block 映射block
 @return 新的信号
 */
- (GYSignal *)map:(id (^)(id value))block;

/**
 信号映射:
 onValue:当原信号发送值时，订阅者会去订阅信号映射返回的信号。
 onError:当原信号发送失败时，订阅者会收到失败。
 onComplete:当原信号发送完成时，订阅者会收到完成。

 @param block 映射block
 @return 新的信号
 */
- (GYSignal *)flattenMap:(GYSignal * (^)(id value))block;

/**
 指定后续信号:
 onValue:当原信号发送值时，订阅者不会收到值。
 onError:当原信号发送失败时，订阅者会收到失败。
 onComplete:当原信号发送完成时，订阅者会去订阅后续信号。

 @param signal 后续信号
 @return 新的信号
 */
- (GYSignal *)then:(nonnull GYSignal *)signal;

/**
 信号打包:
 onValue:只有打包的信号中都至少发送过一次值，新的信号才会发送值，并且订阅者收到的值是一个元组对象，可以根据打包时的顺序在元组中取值。
 onError:只要有一个打包的信号发送失败，这个新的信号就会发送失败。
 onComplete:当所有打包的信号都发送完成时，这个新的信号才会发送完成。

 @param signals 被打包的信号数组
 @return 新的信号
 */
- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals;

/**
 信号打包:
 onValue:只有打包的信号中都至少发送过一次值，新的信号才会发送值，并且订阅者收到的值是一个元组对象，可以根据打包时的顺序在元组中取值。
 onError:只要有一个打包的信号发送失败，这个新的信号就会发送失败。
 onComplete:当所有打包的信号都发送完成时，这个新的信号才会发送完成。

 @param signal 被打包的信号
 @return 新的信号
 */
- (GYSignal<GYTuple *> *)zipWith:(nonnull GYSignal *)signal;

@end
