//
//  MutexLockTest2.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "MutexRecursiveLockTest.h"
#import <pthread.h>

@interface MutexRecursiveLockTest()
@property(nonatomic, assign) pthread_mutex_t mutex;
@end


@implementation MutexRecursiveLockTest
/// 初始化mutex
-(void)__initMutexLock:(pthread_mutex_t *)mutex {
    //动态初始化锁
    //初始化属性
    pthread_mutexattr_t mutexattr;
    pthread_mutexattr_init(&mutexattr);
    //设置属性
    /*
     #define PTHREAD_MUTEX_NORMAL        0  普通锁
     #define PTHREAD_MUTEX_ERRORCHECK    1
     #define PTHREAD_MUTEX_RECURSIVE     2  递归锁
     #define PTHREAD_MUTEX_DEFAULT       PTHREAD_MUTEX_NORMAL  默认锁：普通锁就是默认锁
     */
    pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);  //递归锁
    //初始化锁
    pthread_mutex_init(mutex, &mutexattr);
    //销毁属性
    pthread_mutexattr_destroy(&mutexattr);
}

-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化锁
        [self __initMutexLock:&_mutex];
    }
    return self;
}



/*
 如果锁类型是普通锁(PTHREAD_MUTEX_NORMAL),则会导致死锁
 这个地方如果锁是递归锁(PTHREAD_MUTEX_RECURSIVE),则不会出现问题
 */
-(void)otherTest {
    pthread_mutex_lock(&_mutex);
    NSLog(@"%s",__func__);
    static int count = 0;
    if (count < 10) {
        count++;
        [self otherTest];
    }
    pthread_mutex_unlock(&_mutex);
}


/// pthread_mutex_t在不需要的时候是需要销毁的
-(void)dealloc {
    pthread_mutex_destroy(&_mutex);
}
@end
