//
//  GYSignal.h
//  RACDemo
//
//  Created by GuangYu on 2018/8/11.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYTuple.h"

@protocol GYSubscriber <NSObject>
- (void)sendValue:(id)value;
- (void)sendComplete;
- (void)sendError:(NSError *)error;
@end

@interface GYSignalDisposer : NSObject
@property (nonatomic, readonly, getter=isDisposed) BOOL disposed;
+ (instancetype)disposerWithAction:(void (^)(void))action;
- (void)dispose;
@end

@interface GYSignal<T> : NSObject

+ (instancetype)signalWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;
- (instancetype)initWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block;

#pragma mark - subscribe
- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock;

- (GYSignalDisposer *)subscribeError:(void(^)(NSError *error))errorBlock;

- (GYSignalDisposer *)subscribeComplete:(void(^)(void))completeBlock;

- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                           error:(void(^)(NSError *error))errorBlock;

- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                        complete:(void(^)(void))completeBlock;

- (GYSignalDisposer *)subscribeValue:(void(^)(T value))valueBlock
                          error:(void(^)(NSError *error))errorBlock
                       complete:(void(^)(void))completeBlock;

#pragma mark - operations
- (instancetype)diffrent;
- (instancetype)skip:(NSUInteger)skipCount;
- (instancetype)mergeWith:(GYSignal<T> *)signal;
- (GYSignal *)map:(id (^)(id value))block;
- (GYSignal *)then:(nonnull GYSignal *)signal;
- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals;
- (GYSignal<GYTuple *> *)zipWith:(nonnull GYSignal *)signal;

@end
