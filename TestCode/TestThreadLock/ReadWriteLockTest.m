//
//  ReadWriteLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "ReadWriteLockTest.h"
#import <pthread.h>

@interface ReadWriteLockTest()

@property(nonatomic, assign) pthread_rwlock_t lock;

@end

@implementation ReadWriteLockTest


-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化读写锁
        pthread_rwlock_init(&_lock, NULL);
    }
    return self;
}


-(void)otherTest {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    for (int i = 0 ; i < 10; i++) {
        dispatch_async(queue, ^{
            [self __read];
        });
        dispatch_async(queue, ^{
            [self __write];
        });
    }
}

-(void)__read{
    //读 - 加锁
    pthread_rwlock_rdlock(&_lock);
    sleep(1.0);
    NSLog(@"%s",__func__);
    //读 - 解锁
    pthread_rwlock_unlock(&_lock);
}

-(void)__write {
    //写 - 加锁
    pthread_rwlock_wrlock(&_lock);
    NSLog(@"%s",__func__);
    //写 - 解锁
    pthread_rwlock_unlock(&_lock);
}

@end
