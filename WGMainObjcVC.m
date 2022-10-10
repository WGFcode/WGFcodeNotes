//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//
/*
 代码区
 编译之后的代码
 
 数据区
 字符串常量
 已初始化变量: 全局变量/静态变量
 未初始化变量：全局变量/静态变量
 
 
 堆区 👇alloc等动态分配的空间 分配的内存空间越来越大
 
 
 栈区 👆 函数调用开销，比如局部变量，分配的内存地址越来越小
 
 */

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <libkern/OSAtomic.h>
#import "WGBaseTestLock.h"
#import "OSSpinLockTest.h"
#import "OSUnfairLockTest.h"
#import "MutexRecursiveLockTest.h"
#import "MutextConditionLock.h"
#import "MutextConditionLock.h"
#import "NSLockTest.h"
#import "NSRecursiveLockTest.h"
#import "NSConditionTest.h"
#import "NSConditionLockTest.h"
#import "DispatchSerialQueueTest.h"
#import "DispatchSemaphoreTest.h"
#import "SynchronizedTest.h"
#import "ReadWriteLockTest.h"
#import "ReadWriteLockTest1.h"

#import "Person.h"
#import "Student.h"






@interface WGMainObjcVC()

@end

@implementation WGMainObjcVC



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.lightGrayColor;
    NSLog(@"---start");
    //串行队列
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(queue, ^{
        NSLog(@"111111");
    });
    NSLog(@"----end");
}






@end

