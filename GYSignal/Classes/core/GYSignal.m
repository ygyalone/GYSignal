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
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy) void(^valueBlock)(id);
@property (nonatomic, copy) void(^errorBlock)(NSError *);
@property (nonatomic, copy) void(^completeBlock)(void);

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

- (instancetype)init {
    if (self = [super init]) {
        self.enabled = YES;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (_enabled == NO) {
        _valueBlock = nil;
        _errorBlock = nil;
        _completeBlock = nil;
    }
}

- (void)sendValue:(id)value {
    if (_valueBlock) {_valueBlock(value);}
}

- (void)sendComplete {
    if (_completeBlock) {_completeBlock();}
    self.enabled = NO;
}

- (void)sendError:(NSError *)error {
    if (_errorBlock) {_errorBlock(error);}
    self.enabled = NO;
}

@end

#pragma mark - GYSignalDisposer
@interface GYSignalDisposer()
@property (nonatomic, weak) _GYSubscriber *subscriber;
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
    if (_whenDispose) {
        _whenDispose();
        _whenDispose = nil;
    }
    
    _disposed = YES;
    _subscriber.enabled = NO;
    _subscriber = nil;
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
    disposer.subscriber = subscriber;
    return disposer;
}

#pragma mark - options
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

- (GYSignal *)map:(id (^)(id))block {
    NSAssert(block!=nil, @"<GYSignalError: map block cant be nil!>");
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

- (instancetype)skip:(NSUInteger)skipCount {
    __block NSUInteger count = 0;
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        return [self subscribeValue:^(id value) {
            
            if (count >= skipCount) {
                [subscriber sendValue:value];
            }else {
                count++;
            }
            
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            [subscriber sendComplete];
        }];
    }];
}

- (GYSignal *)then:(GYSignal *)signal {
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        NSMutableArray *disposers = [NSMutableArray array];
        __block GYSignalDisposer *thenDisposer;
        GYSignalDisposer *disposer =
        [self subscribeValue:^(id value) {
            //do nothing
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } complete:^{
            
            thenDisposer =
            [signal subscribeValue:^(id value) {
                [subscriber sendValue:value];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            } complete:^{
                [subscriber sendComplete];
            }];
        }];
        
        [disposers addObject:disposer];
        if (thenDisposer) {
            [disposers addObject:thenDisposer];
        }
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
        
    }];
}

- (instancetype)mergeWith:(GYSignal *)signal {
    NSAssert(signal != nil, @"merged signal cant be nil!");
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        NSMutableArray *disposers = [NSMutableArray array];
        for (GYSignal *s in @[self, signal]) {
            GYSignalDisposer *disposer =
            [s subscribeValue:^(id value) {
                [subscriber sendValue:value];
            } error:^(NSError *error) {
                [subscriber sendError:error];
            } complete:^{
                [subscriber sendComplete];
            }];
            [disposers addObject:disposer];
        }
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
    }];
}

- (GYSignal<GYTuple *> *)zip:(NSArray<GYSignal *> *)signals {
    
    NSMutableArray *zip = [NSMutableArray array];
    [zip addObject:self];
    if (signals) {[zip addObjectsFromArray:signals];}
    
    NSMutableArray *values = [NSMutableArray array];
    __block NSInteger wait = zip.count;
    for (int i = 0; i < zip.count; i++) {
        [values addObject:GYSignalNilFlag];
    }
    GYTuple *valueTuple = [GYTuple tupleWithObjectsFromArray:values];
    
    NSMutableArray<GYSignalDisposer *> *disposers = [NSMutableArray array];
    
    return [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        
        for (GYSignal *signal in zip) {
            
            GYSignalDisposer *disposer =
            [signal subscribeValue:^(id value) {
                @synchronized(self) {
                    valueTuple[[zip indexOfObject:signal]] = value;
                }
                
                if (![valueTuple containsObject:GYSignalNilFlag]) {
                    [subscriber sendValue:valueTuple];
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
            }];
            
            [disposers addObject:disposer];
        }
        
        return [GYSignalDisposer disposerWithAction:^{
            for (GYSignalDisposer *disposer in disposers) {
                [disposer dispose];
            }
        }];
    }];
}

- (GYSignal<GYTuple *> *)zipWith:(nonnull GYSignal *)signal {
    return [self zip:@[signal]];
}

@end
