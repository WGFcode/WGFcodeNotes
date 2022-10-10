//
//  MutextConditionLock.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "MutextConditionLock.h"
#import <pthread.h>

@interface MutextConditionLock()

@property(nonatomic, assign) pthread_mutex_t mutex; //锁
@property(nonatomic, assign) pthread_cond_t cond;   //条件

@property(nonatomic, strong) NSMutableArray *data;
@end

@implementation MutextConditionLock

/// 初始化mutex
-(void)__initMutexLock:(pthread_mutex_t *)mutex {

}

-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化属性
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        //设置属性
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);  //普通锁
        //销毁属性
        pthread_mutexattr_destroy(&mutexattr);
        //初始化锁
        pthread_mutex_init(&_mutex, &mutexattr);
        
        //初始化条件
        //条件属性也可以传NULL
        //pthread_condattr_t condattr;
        pthread_cond_init(&_cond, NULL);
        
    }
    return self;
}


-(void)otherTest {
    [[[NSThread alloc]initWithTarget:self selector:@selector(__remove) object:nil] start];
    sleep(2.0);
    [[[NSThread alloc]initWithTarget:self selector:@selector(__add) object:nil] start];
}


// 有东西才能删除，没有东西就不能删除

/// 添加元素
-(void)__add {
    //加锁
    pthread_mutex_lock(&_mutex);
    
    [self.data addObject:@"1"];
    NSLog(@"add 添加元素");
    //唤醒因为pthread_cond_wait而等待的线程，代码会继续向下走
    pthread_cond_signal(&_cond);
    
    //解锁
    pthread_mutex_unlock(&_mutex);
}
/// 删除元素
-(void)__remove{
    //加锁
    pthread_mutex_lock(&_mutex);
    
    if (self.data.count == 0) {
        // 如果没有数据可以删除，那么线程就会在这个地方睡觉等待，并且会放开这把锁；
        // 等待这个条件被放开(pthread_cond_signal)后会重新加锁
        pthread_cond_wait(&_cond, &_mutex);
    }
    [self.data removeLastObject];
    NSLog(@"remove 删除元素");
    
    //解锁
    pthread_mutex_unlock(&_mutex);
}


/// pthread_mutex_t在不需要的时候是需要销毁的
-(void)dealloc {
    //销毁锁
    pthread_mutex_destroy(&_mutex);
    //销毁条件
    pthread_cond_destroy(&_cond);
}
@end
