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

/*
 Swift
 Swift中struct和class有什么区别？
 Swift中的方法调用有哪些形式？
 Swift和OC有什么区别？
 从OC向Swift迁移的时候遇到过什么问题？
 怎么理解面向协议编程？
 OC语法
 Block是如何实现的？Block对应的数据结构是什么样子的？__block的作用是什么？它对应的数据结构又是什么样子的？
 GCD中的Block是在堆上还是栈上？
 NSCoding协议是干什么用的？
 KVO的实现原理
 NSOperation有哪些特性比着GCD有哪些优点，它有哪些API？
 NSNotificaiton是同步还是异步的，如果发通知时在子线程，接收在哪个线程？

 
 UI
 事件响应链是如何传递的？
 什么是异步渲染？
 layoutsubviews是在什么时机调用的？
 一张图片的展示经历了哪些步骤？
 什么是离屏渲染，什么情况会导致离屏渲染？
 CoreAnimation这个框架的作用什么，它跟UIKit的关系是什么？
 
 引用计数
 ARC方案的原理是什么？它是在什么时候做的隐式添加release操作？
 循环引用有哪些场景，如何避免？
 为什么当我们在使用block时外面是weak 声明一个weakSelf，还要在block内部使用strong再持有一下？
 Autoreleasepool是实现机制是什么？它是什么时候释放内部的对象的？它内部的数据结构是什么样的？当我提到哨兵对象时，会继续问哨兵对象的作用是什么，为什么要设计它？
 哪些对象会放入到Autoreleasepool中？
 weak的实现原理是什么？当引用对象销毁是它是如何管理内部的Hash表的？（这里要参阅weak源码）
 
 Runtime
 消息发送的流程是怎样的？
 关联对象时什么情况下会导致内存泄露？
 消息转发的流程是什么？
 category能否添加属性，为什么？能否添加实例变量，为什么？
 元类的作用是什么？
 类方法是存储到什么地方的？类属性呢？
 讲几个runtime的应用场景
 
 Runloop
 讲一下对Runloop的理解？
 可以用Runloop实现什么功能？
 性能优化
 对TableView进行性能优化有哪些方式？
 Xcode的Instruments都有哪些调试的工具？
 讲一下你做过的性能优化的事情。
 如何检测卡顿，都有哪些方法？
 缩小包体积有哪些方案
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
#import "Car.h"
#import "WGFirstVC.h"






@interface WGMainObjcVC()


@end

@implementation WGMainObjcVC

/*


 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;
    /*
     内存泄漏:
     动态分配内存的对象，在使用完后没有被系统回收内存，导致对象一直占据着内存，属于内存管理出错
     僵尸对象:
     已经被销毁的对象(不能再使用的对象),内存已经被回收的对象,引用计数为0对象被释放后就变成僵尸对象了
     野指针:
     野指针[悬挂指针]，出现的原因是因为【指针没有赋值】【指针指向的对象已经释放了, 比如指向僵尸对象】
     野指针可能会指向一块垃圾内存,给野指针发送消息会导致程序崩溃
     空指针:是一个没有指向任何内存的指针,空指针是有效指针,值为nil,NULL,Nil,0等,给空指针发送消息不会报错,不会响应消息
     内存溢出:
     当程序在申请内存时，没有足够的内存空间供其使用,比如申请了一个int,但给它存了long才能存下的数，那就是内存溢出
     
     

   
     
    */
    NSMutableArray *arr = [NSMutableArray new];
    [arr addObject:nil];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}



-(void)test1 {
    Person *person = [[Person alloc]init];
    person.age = 18;
    __weak Person *weakPerson = person;
    person.personBlock = ^{
        __strong Person *strongPerson = weakPerson;
        NSLog(@"1111");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"person age is %d",strongPerson.age);
        });
        NSLog(@"2222");
    };
    person.personBlock();
}



//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.navigationController pushViewController:[[WGFirstVC alloc]init] animated:YES];
//}







@end

