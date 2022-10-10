//
//  NSConditionLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "NSConditionTest.h"

@interface NSConditionTest()

@property(nonatomic, strong) NSMutableArray *data;
@property(nonatomic, strong) NSCondition *condition;

@end

@implementation NSConditionTest

-(instancetype)init {
    self = [super init];
    if (self) {
        self.data = [NSMutableArray array];
        self.condition = [[NSCondition alloc]init];
    }
    return self;
}

-(void)otherTest {
    [[[NSThread alloc]initWithTarget:self selector:@selector(__remove) object:nil] start];
    [[[NSThread alloc]initWithTarget:self selector:@selector(__add) object:nil] start];
}


// 有东西才能删除，没有东西就不能删除

/// 添加元素
-(void)__add {
    //加锁
    [self.condition lock];
    sleep(1.0);

    [self.data addObject:@"1"];
    NSLog(@"add 添加元素");
    //唤醒因为wait而等待的线程，代码会继续向下走,signal方法其实可以放在unlock后面(根据具体的业务来决定)
    [self.condition signal];
    NSLog(@"唤醒锁，开始执行了");
    sleep(2.0);
    //解锁
    [self.condition unlock];
}

/// 删除元素
-(void)__remove{
    //加锁
    [self.condition lock];
    NSLog(@"remove begin");
    if (self.data.count == 0) {
        // 如果没有数据可以删除，那么线程就会在这个地方睡觉等待，并且会放开这把锁；
        // 等待这个条件被放开(signal)后会重新加锁(前提是signal后的锁已经解锁了)
        [self.condition wait];
    }
    [self.data removeLastObject];
    NSLog(@"remove 删除元素");

    //解锁
    [self.condition unlock];
}

@end
