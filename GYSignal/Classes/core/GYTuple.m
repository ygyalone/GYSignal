//
//  GYTuple.m
//  GYBase
//
//  Created by GuangYu on 2017/7/19.
//  Copyright © 2017年 GuangYu. All rights reserved.
//

#import "GYTuple.h"
#pragma mark - _GYTupleNil
@interface _GYTupleNil : NSObject
+ (instancetype)tupleNil;
@end

@implementation _GYTupleNil
+ (instancetype)tupleNil; {
    static _GYTupleNil *tupleNil = nil;
        @synchronized(self) {
            if (!tupleNil) {
                tupleNil = [_GYTupleNil new];
            }
        }
    return tupleNil;
}
@end

#pragma mark - GYTuple
const id GYTupleEndFlag = @__FILE__;
@interface GYTuple ()
@property (nonatomic, strong) NSMutableArray *args;
@end

@implementation GYTuple
#pragma mark - override method
- (instancetype)init {
    if (self = [super init]) {
        _args = [NSMutableArray array];
    }
    return self;
}

- (NSString *)description {
    return _args.description;
}

#pragma mark - public method
+ (instancetype)tupleWithObjects:(id)first, ... {
    NSMutableArray *arguments = [NSMutableArray array];
    
    va_list args;
    va_start(args, first);
    for (id currentObject = first; currentObject != GYTupleEndFlag; currentObject = va_arg(args, id)) {
        [arguments addObject:currentObject?:_GYTupleNil.tupleNil];
    }
    va_end(args);
    
    GYTuple *tuple = [GYTuple new];
    tuple.args = arguments.copy;
    return tuple;
}

+ (instancetype)tupleWithObjectsFromArray:(NSArray *)objs {
    GYTuple *tuple = [GYTuple new];
    tuple.args = objs.mutableCopy;
    return tuple;
}

+ (instancetype)tupleWithSize:(NSUInteger)size {
    GYTuple *tuple = [GYTuple new];
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:size];
    for (int i = 0; i < size; i++) {
        args[i] = _GYTupleNil.tupleNil;
    }
    tuple.args = args.mutableCopy;
    return tuple;
}

- (NSUInteger)count {
    return self.args.count;
}

- (id)objectAtIndex:(NSUInteger)index {
    if (index < self.args.count) {
        id obj = self.args[index];
        return obj == _GYTupleNil.tupleNil?nil:obj;
    }
    return nil;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)index {
    _args[index] = obj?:_GYTupleNil.tupleNil;
}

- (BOOL)contains:(id)obj {
    return [self.args containsObject:obj?:_GYTupleNil.tupleNil];
}

- (id)first {
    return self[0];
}

- (id)second {
    return self[1];
}

- (id)third {
    return self[2];
}

- (id)fourth {
    return self[3];
}

- (id)fifth {
    return self[4];
}

- (id)last {
    return self[self.count - 1];
}

@end
