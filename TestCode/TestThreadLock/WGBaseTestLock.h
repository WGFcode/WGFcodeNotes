//
//  WGBaseTestLock.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/9.
//  Copyright © 2022 WG. All rights reserved.
//
/*
一、 线程同步解决方案
 1. OSSpinLock：自旋锁：等待锁的线程会一直处于忙等状态
 2. os_unfair_lock: 互斥锁：等待锁的线程会处于休眠状态
 3. pthread_mutex：互斥锁：等待锁的线程会处于休眠状态
 4. dispatch_semaphore：信号量，可以控制并发执行的最大线程数量
 5. dispatch_queue(DISPATCH_QUEUE_SERIAL)：GCD中串行队列
 6. NSLock：对mutex普通锁的封装
 7. NSRecursiveLock：递归锁，对mutex递归锁的封装
 8. NSCondition：条件锁
 9. NSConditionLock：对NSCondition的封装，可以设置条件值
 10. @synchronized：对mutex递归锁的封装
 
 二、线程同步性能排序
 1. os_unfair_lock
 2. OSSpinLock
 3. dispatch_semaphore
 4. pthread_mutex
 5. dispatch_queue(DISPATCH_QUEUE_SERIAL)
 6. NSLock
 7. NSCondition
 7. pthread_mutex(Recursive递归锁)
 8. NSRecursiveLock
 9. NSConditionLock
 10. @synchronized
 
 ⚠️线程同步方案中更推荐使用信号量dispatch_semaphore和pthread_mutex
 
 
 三、互斥锁和自旋锁对比
 互斥锁：等待锁的线程会处于休眠状态
 使用场景：
 1. 预计线程等待锁的时间很长
 2. 单核处理器
 3. 临界区有IO(文件读写)操作
 4. 临界区代码复杂或者循环最大
 5. 临界区竞争非常激烈
 
 
 自旋锁：等待锁的线程会一直处于忙等状态
 使用场景：
 1. 预计线程等待锁的时间很短(锁内的代码或者任务花费很少的时间,就可以用自旋锁,因为时间短,所以就不需要用互斥锁先进入睡眠,再唤醒,这样也比较消耗性能)
 2. 加锁的代码(临界区)经常被调用,但竞争情况不激烈(很少的线程来抢夺资源)
 3. CPU资源不紧张
 4. 多核处理器
 
 四、atomic/nonatomic
 atomic: 原子性，保证getter/setter方法的线程安全
 nonatomic: 非原子性
 为什么不使用atomic，而是经常使用nonatomic，主要就是加锁解锁比较消耗性能，不加锁也能用，如果真的需要加锁解锁，再进行添加也不迟
 
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGBaseTestLock : NSObject

/// 存钱测试
-(void)moneyTest;


/// 卖票测试
-(void)ticketsTest;



/// 其他测试
-(void)otherTest;



//暴露给子类加锁解锁用

-(void)__saveMoney;
-(void)__drawMoney;
-(void)__saleTickets;

@end

NS_ASSUME_NONNULL_END
