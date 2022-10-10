//
//  PthreadMutexLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "MutexLockTest.h"
#import <pthread.h>

@interface MutexLockTest()
@property(nonatomic, assign) pthread_mutex_t moneyLock;
@property(nonatomic, assign) pthread_mutex_t ticketsLock;
@end

@implementation MutexLockTest


/// 初始化mutex
-(void)__initMutexLock:(pthread_mutex_t *)mutex {
    
    //静态初始化 #define PTHREAD_MUTEX_INITIALIZER {_PTHREAD_MUTEX_SIG_init, {0}}
    //pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    //⚠️这种方式初始化是不行的，因为它是个结构体，所以不能这样写
    //self.moneyLock = PTHREAD_MUTEX_INITIALIZER;
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
    pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);
    //初始化锁
    pthread_mutex_init(mutex, &mutexattr);
    //销毁属性
    pthread_mutexattr_destroy(&mutexattr);
    /*
     ⚠️如果属性传递的是NULL，那么就是默认锁，即普通锁,其实就是和上面的效果是一样的
     pthread_mutex_init(mutex, NULL);
     */
}


-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化锁
        [self __initMutexLock:&_moneyLock];
        [self __initMutexLock:&_ticketsLock];
    }
    return self;
}

-(void)__saveMoney {
    //加锁
    pthread_mutex_lock(&_moneyLock);
    [super __saveMoney];
    //解锁
    pthread_mutex_unlock(&_moneyLock);
}

-(void)__drawMoney {
    //加锁
    pthread_mutex_lock(&_moneyLock);
    [super __drawMoney];
    //解锁
    pthread_mutex_unlock(&_moneyLock);
}


-(void)__saleTickets {
    //加锁
    pthread_mutex_lock(&_ticketsLock);
    [super __saleTickets];
    //解锁
    pthread_mutex_unlock(&_ticketsLock);
}


/// pthread_mutex_t在不需要的时候是需要销毁的
-(void)dealloc {
    pthread_mutex_destroy(&_moneyLock);
    pthread_mutex_destroy(&_ticketsLock);
}
@end
