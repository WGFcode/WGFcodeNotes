//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import "Person.h"
#import <objc/runtime.h>
#import "Student.h"
#import <malloc/malloc.h>
#import "WGTargetProxy.h"
#import "Person+PersonTest.h"

#import <pthread.h>

@interface WGMainObjcVC()
@property(nonatomic, assign) int ticketCount;
@property(nonatomic, assign) pthread_mutex_t mutex;
@property(nonatomic, strong) NSMutableArray *data;
@property(nonatomic, assign) pthread_cond_t cond;
@property(nonatomic, strong) NSConditionLock *lock;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    _ticketCount = 15;
    _data = [NSMutableArray array];
    
    _lock = [[NSCondition alloc]init];
    
    //1. 静态初始化
    //pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    //初始化属性
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);
    //2.初始化锁
    pthread_mutex_init(&_mutex, &attr);
    /*
     #define PTHREAD_MUTEX_NORMAL        0          普通锁
     #define PTHREAD_MUTEX_ERRORCHECK    1          检测错误锁(一般用不上)
     #define PTHREAD_MUTEX_RECURSIVE        2       递归锁
     #define PTHREAD_MUTEX_DEFAULT        PTHREAD_MUTEX_NORMAL  普通锁
     */
    //3.销毁属性
    pthread_mutexattr_destroy(&attr);
    
    //初始化条件
    pthread_cond_init(&_cond, NULL);
    
    [self test];
}

-(void)testTicket {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self saleTicket];
        }
    });
}
-(void)saleTicket{
    //2. 加锁
    [_lock lock];
    _ticketCount -= 1;
    NSLog(@"还剩%d张票",_ticketCount);
    //3. 解锁
    [_lock unlock];
}

-(void)dealloc {
    //4.销毁锁
    pthread_mutex_destroy(&_mutex);
    //5.销毁条件
    pthread_cond_destroy(&_cond);
}

-(void)test {
    //在不同的子线程中执行增、删操作
    [[[NSThread alloc] initWithTarget:self selector:@selector(add) object:nil] start];
    [[[NSThread alloc] initWithTarget:self selector:@selector(remove) object:nil] start];
}

-(void)add{
    [_lock lock];
    [_data addObject:@"123"];
    sleep(3);
    NSLog(@"添加了元素");
    //唤醒刚刚因为pthread_cond_wait而睡眠的线程
    [_lock signal];
    [_lock unlock];
}
-(void)remove{
    [_lock lock];
    if (_data.count == 0) {
        [_lock wait];
    }
    [_data removeLastObject];
    NSLog(@"删除了元素");
    [_lock unlock];
}

@end


