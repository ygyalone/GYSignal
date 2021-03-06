//
//  GYTuple.h
//  GYBase
//
//  Created by GuangYu on 2017/7/19.
//  Copyright © 2017年 GuangYu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///可变参数终止标记
extern const id GYTupleEndFlag;

#define GYTupleCreate(...) [GYTuple tupleWithObjects:__VA_ARGS__, GYTupleEndFlag]

@interface GYTuple : NSObject

@property (nonatomic, readonly) NSArray *args;
@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic, readonly) id first;
@property (nonatomic, readonly) id second;
@property (nonatomic, readonly) id third;
@property (nonatomic, readonly) id fourth;
@property (nonatomic, readonly) id fifth;
@property (nonatomic, readonly) id last;

+ (instancetype)tupleWithObjects:(id)first, ...;
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)objs;
+ (instancetype)tupleWithSize:(NSUInteger)size;
- (nullable id)objectAtIndex:(NSUInteger)index;
- (nullable id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(nullable id)obj atIndexedSubscript:(NSUInteger)index;
- (BOOL)contains:(nullable id)obj;
@end

NS_ASSUME_NONNULL_END
