//
//  NSConditionLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "NSConditionLockTest.h"

@interface NSConditionLockTest()
@property(nonatomic, strong) NSConditionLock *lock;

@end

@implementation NSConditionLockTest

-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化条件锁，传入初始化条件值 如果没有传递条件值，则默认的条件值是: 0
        self.lock = [[NSConditionLock alloc]initWithCondition:1];
//        self.lock = [[NSConditionLock alloc]init];
    }
    return self;
}

-(void)otherTest {
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    [[[NSThread alloc]initWithTarget:self selector:@selector(__one) object:nil] start];
    [[[NSThread alloc]initWithTarget:self selector:@selector(__two) object:nil] start];
    [[[NSThread alloc]initWithTarget:self selector:@selector(__three) object:nil] start];
}


-(void)__one{
    
    //加锁(当这个锁的内部条件值==1时才开始加锁)
    [self.lock lockWhenCondition:1];
    sleep(3);
    NSLog(@"__one--");
    //设置内部条件值为2，并且将这把锁放开
    [self.lock unlockWithCondition:2];
}

-(void)__two {
    //加锁
    [self.lock lockWhenCondition:2];

    NSLog(@"__two--");
    
    //解锁
    [self.lock unlockWithCondition:3];
}

-(void)__three {
    //加锁
    [self.lock lockWhenCondition:3];

    NSLog(@"__three--");
    
    //解锁
    [self.lock unlock];
}


@end
