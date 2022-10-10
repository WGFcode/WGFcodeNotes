//
//  DispatchSemaphoreTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "DispatchSemaphoreTest.h"
@interface DispatchSemaphoreTest()

@property(nonatomic, strong) dispatch_semaphore_t semp;

@end



@implementation DispatchSemaphoreTest
-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化信号量 最大并发数量是3
        self.semp = dispatch_semaphore_create(3);
    }
   
    return self;
}


-(void)otherTest {
    for (int i = 0; i < 20; i++) {
        [[[NSThread alloc]initWithTarget:self selector:@selector(test) object:nil] start];
    }
}

//最多有3个线程可以同时进来执行这个任务
-(void)test {
    // 如果信号量的值 > 0, 让信号量的值减1，然后继续往下执行代码
    // 如果信号量的值 <= 0，就会休眠等待，直到信号量的值 > 0,就让信号量的值减1，然后继续往下执行代码
    dispatch_semaphore_wait(_semp, DISPATCH_TIME_FOREVER);
    
    NSLog(@"%s",__func__);
    sleep(1.0);
    // 让信号量的值 + 1
    dispatch_semaphore_signal(_semp);
}
@end
