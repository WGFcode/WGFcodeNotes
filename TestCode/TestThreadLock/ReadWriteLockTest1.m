//
//  ReadWriteLockTest1.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "ReadWriteLockTest1.h"


@interface ReadWriteLockTest1()
@property(nonatomic, strong) dispatch_queue_t queue;
@end

@implementation ReadWriteLockTest1

-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化并发队列
        self.queue = dispatch_queue_create("rw_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)otherTest {
    for (int i = 0 ; i < 10; i++) {
        [self __write];
        [self __read];
        [self __read];
        [self __read];
    }
}

-(void)__read{
    dispatch_async(_queue, ^{
        sleep(1.0);
        NSLog(@"read");
    });
}

-(void)__write {
    dispatch_barrier_async(_queue, ^{
        sleep(1.0);
        NSLog(@"write");
    });
}
@end
