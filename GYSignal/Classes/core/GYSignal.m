//
//  GYSignal.m
//  RACDemo
//
//  Created by GuangYu on 2018/8/11.
//  Copyright © 2018年 GuangYu. All rights reserved.
//

#import "GYSignal.h"

//空标记
const id GYSignalNilFlag = @__FILE__;

#pragma mark - GYSubscriber
@interface _GYSubscriber : NSObject <GYSubscriber>
@property (nonatomic, copy) void(^valueBlock)(id);
@property (nonatomic, copy) void(^errorBlock)(NSError *);
@property (nonatomic, copy) void(^completeBlock)(void);
@property (nonatomic, strong) GYSignalDisposer *disposer;

+ (instancetype)subscriberWithValue:(void(^)(id))valueBlock
                              error:(void(^)(NSError *))errorBlock
                           complete:(void(^)(void))completeBlock;
@end

@implementation _GYSubscriber
+ (instancetype)subscriberWithValue:(void(^)(id))valueBlock
                              error:(void(^)(NSError *))errorBlock
                           complete:(void(^)(void))completeBlock {
    _GYSubscriber *subscriber = [_GYSubscriber new];
    subscriber.valueBlock = valueBlock;
    subscriber.errorBlock = errorBlock;
    subscriber.completeBlock = completeBlock;
    return subscriber;
}

- (void)dispose {
    _valueBlock = nil;
    _errorBlock = nil;
    _completeBlock = nil;
}

- (void)sendValue:(id)value {
    if (_valueBlock) {
        _valueBlock(value);
    }
}

- (void)sendComplete {
    if (_completeBlock) {
        _completeBlock();
    }
    [self dispose];
}

- (void)sendError:(NSError *)error {
    if (_errorBlock) {
        _errorBlock(error);
    }
    [self dispose];
}

- (void)dealloc {
    if (_disposer) {
        [_disposer dispose];
    }
}

@end

#pragma mark - GYSignalDisposer
@interface GYSignalDisposer()
@property (nonatomic, assign, getter=isDisposed) BOOL disposed;
@property (nonatomic, copy) void(^whenDispose)(void);
@end

@implementation GYSignalDisposer
- (instancetype)init {
    if (self = [super init]) {
        self.disposed = NO;
    }
    return self;
}

+ (instancetype)disposerWithAction:(void (^)(void))action {
    GYSignalDisposer *disposer = [GYSignalDisposer new];
    disposer.whenDispose = action;
    return disposer;
}

- (void)dispose {
    if (!_disposed && _whenDispose) {
        _whenDispose();
        _whenDispose = nil;
    }
    
    _disposed = YES;
}

@end

#pragma mark - GYSignal
@interface GYSignal()
@property (nonatomic, copy) GYSignalDisposer *(^actionBlock)(id<GYSubscriber>); ///<action block
@end

@implementation GYSignal

+ (instancetype)signalWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block {
    return [[GYSignal alloc] initWithAction:block];
}

- (instancetype)initWithAction:(GYSignalDisposer *(^)(id<GYSubscriber> subscriber))block {
    if (self = [super init]) {
        self.actionBlock = block;
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"init method was forbidden!");
    return nil;
}

#pragma mark - subscribe
- (GYSignalDisposer *)subscribeValue:(void(^)(id value))valueBlock {
    return [self _subscribeValue:valueBlock error:nil complete:nil];
}

- (GYSignalDisposer *)subscribeError:(void(^)(NSError *error))errorBlock {
    return [self _subscribeValue:nil error:errorBlock complete:nil];
}

- (GYSignalDisposer *)subscribeComplete:(void(^)(void))completeBlock {
    return [self _subscribeValue:nil error:nil complete:completeBlock];
}

- (GYSignalDisposer *)subscribeValue:(void(^)(id value))valueBlock
                          error:(void(^)(NSError *error))errorBlock {
    return [self _subscribeValue:valueBlock error:errorBlock complete:nil];
}

- (GYSignalDisposer *)subscribeValue:(void(^)(id value))valueBlock
                       complete:(void(^)(void))completeBlock {
    return [self _subscribeValue:valueBlock error:nil complete:completeBlock];
}

- (GYSignalDisposer *)subscribeValue:(void(^)(id value))valueBlock
                          error:(void(^)(NSError *error))errorBlock
                       complete:(void(^)(void))completeBlock {
    return [self _subscribeValue:valueBlock error:errorBlock complete:completeBlock];
}
- (GYSignalDisposer *)_subscribeValue:(void(^)(id value))valueBlock
                               error:(void(^)(NSError *error))errorBlock
                            complete:(void(^)(void))completeBlock {
    _GYSubscriber *subscriber = [_GYSubscriber subscriberWithValue:valueBlock error:errorBlock complete:completeBlock];
    GYSignalDisposer *disposer = self.actionBlock(subscriber);
    __weak typeof(subscriber) weak_subscriber = subscriber;
    subscriber.disposer = [GYSignalDisposer disposerWithAction:^{
        [disposer dispose];
        [weak_subscriber dispose];
    }];
    return subscriber.disposer;
}

#pragma mark - options
+ (instancetype)just:(id)value {
    return [GYSignal signalWithAction:^GYSignalDisposer * _Nonnull(id<GYSubscriber>  _Nonnull subscriber) {
        [subscriber sendValue:value];
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:nil];
    }];
}

- (instancetype)filter:(BOOL (^)(id _Nonnull))block {
    return [GYSignal signalWithAction:^GYSignalDisposer * _Nonnull(id<GYSubscriber>  _Nonnull subscriber) {
        return [self subscribeValue:^(id  _Nullable value) {
            if (block(value) == YES) {
                [subscriber sendValue:value];
            }
        } error:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        } complete:^{
            [subscriber sendComplete];
        }];
    }];
}

- (instancetype)diffrent {
    __block id lastValue = GYSignalNilFlag;
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [self subscribeValue:^(id value) {
            
            if (lastValue == nil) {
                if (value != nil) {
                    lastValue = value;
                    [subscriber sendValue:lastValue];
                }
            }else {
                if ([lastValue isEqual:value] == NO) {
                    lastValue = value;
                    [subscriber sendValue:lastValue];
                }
            }
            
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            [subscriber sendComplete];
        }];
    }];
}

- (GYSignal *)map:(id  _Nonnull (^)(id _Nullable))block {
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [self subscribeValue:^(id value) {
            [subscriber sendValue:block(value)];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            [subscriber sendComplete];
        }];
    }];
}

- (GYSignal *)flattenMap:(GYSignal * _Nonnull (^)(id _Nullable))block {
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        NSMutableArray<GYSignalDisposer *> *disposers = [NSMutableArray array];
        
        [disposers addObject:[self subscribeValue:^(id value) {
            
            GYSignal *flattenMapSignal = block(value);
            [disposers addObject:[flattenMapSignal subscribeValue:^(id value) {
                [subscriber sendValue:value];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            } complete:^{
                [subscriber sendComplete];
            }]];
            
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            [subscriber sendComplete];
        }]];
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
        
    }];
}

- (instancetype)skip:(NSUInteger)skipCount {
    __block NSUInteger count = 0;
    return [self filter:^BOOL(id  _Nonnull value) {
        if (count >= skipCount) {
            return YES;
        }else {
            @synchronized (self) {
                count++;
            }
            return NO;
        }
    }];
}

- (instancetype)take:(NSUInteger)takeCount {
    __block NSUInteger count = 0;
    return [self filter:^BOOL(id  _Nonnull value) {
        if (count < takeCount) {
            @synchronized (self) {
                count++;
            }
            return YES;
        }else {
            return NO;
        }
    }];
}

- (GYSignal *)then:(GYSignal *)signal {
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        NSMutableArray<GYSignalDisposer *> *disposers = [NSMutableArray array];
        [disposers addObject:[self subscribeValue:^(id value) {
            //do nothing
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            
            [disposers addObject:[signal subscribeValue:^(id value) {
                [subscriber sendValue:value];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            } complete:^{
                [subscriber sendComplete];
            }]];
            
        }]];
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
        
    }];
}

- (instancetype)merge:(NSArray *)signals {
    NSAssert(signals != nil, @"merged signals cant be nil!");
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        NSMutableArray *disposers = [NSMutableArray array];
        NSMutableArray *mergedSignals = @[self].mutableCopy;
        [mergedSignals addObjectsFromArray:signals];
        
        for (GYSignal *s in mergedSignals) {
            [disposers addObject:[s subscribeValue:^(id value) {
                [subscriber sendValue:value];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            } complete:^{
                [subscriber sendComplete];
            }]];
        }
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
    }];
}

- (instancetype)finally:(void (^)(void))block {
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [self subscribeValue:^(id value) {
            [subscriber sendValue:value];
        } error:^(NSError *error) {
            [subscriber sendError:error];
            if (block) { block(); }
        } complete:^{
            [subscriber sendComplete];
            if (block) { block(); }
        }];
    }];
}

- (instancetype)retry:(NSUInteger)count {
    return [GYSignal signalWithAction:^GYSignalDisposer * _Nonnull(id<GYSubscriber>  _Nonnull subscriber) {
        return [self _retryWithSubscriber:subscriber count:count+1];
    }];
}

- (GYSignalDisposer *)_retryWithSubscriber:(id<GYSubscriber>)subscriber count:(NSUInteger)count {
    __block NSInteger retryCount = count;
    NSMutableArray<GYSignalDisposer *> *disposers = [NSMutableArray arrayWithCapacity:retryCount];
    
    [disposers addObject:[self subscribeValue:^(id  _Nullable value) {
        [subscriber sendValue:value];
        
    } error:^(NSError * _Nonnull error) {
        @synchronized (self) {
            retryCount--;
        }
        
        if (retryCount == 0) {
            [subscriber sendError:error];
        }else {
            [disposers addObject:[self _retryWithSubscriber:subscriber count:retryCount]];
        }
        
    } complete:^{
        [subscriber sendComplete];
    }]];
    
    return [GYSignalDisposer disposerWithAction:^{
        for (GYSignalDisposer *disposer in disposers) {
            [disposer dispose];
        }
    }];
}

- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals {
    NSMutableArray *zip = [NSMutableArray array];
    [zip addObject:self];
    
    if (signals) {
        [zip addObjectsFromArray:signals];
    }
    
    __block NSInteger wait = zip.count;
    GYTuple *values = [GYTuple tupleWithSize:zip.count];
    NSMutableArray<GYSignalDisposer *> *disposers = [NSMutableArray array];
    
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        for (GYSignal *signal in zip) {
            [disposers addObject:[signal subscribeValue:^(id value) {
                @synchronized(self) {
                    values[[zip indexOfObject:signal]] = value;
                }
                
                if (![values contains:nil]) {
                    [subscriber sendValue:values];
                }
                
            } error:^(NSError *error) {
                [subscriber sendError:error];
                
            } complete:^{
                @synchronized(self) {
                    wait--;
                }
                if (wait==0) {
                    [subscriber sendComplete];
                }
            }]];
        }
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
    }];
}

@end
