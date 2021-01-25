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
@property(nonatomic, strong) dispatch_semaphore_t semaphore;

@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    _ticketCount = 15;
    //1. 初始值设置为1, 代表每次只能有一个线程在执行任务
    _semaphore = dispatch_semaphore_create(1);
    [self testTicket];
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
    //保证testObj对象只会被创建一次
    static NSObject *testObj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testObj = [[NSObject alloc]init];
    });
    @synchronized (testObj) {
        _ticketCount -= 1;
        NSLog(@"还剩%d张票",_ticketCount);
    }
}


//-(void)test {
//    //在不同的子线程中执行增、删操作
//    [[[NSThread alloc] initWithTarget:self selector:@selector(add) object:nil] start];
//    [[[NSThread alloc] initWithTarget:self selector:@selector(remove) object:nil] start];
//}
//
//-(void)add{
//    NSLog(@"添加了元素");
//}
//-(void)remove{
//    NSLog(@"删除了元素");
//}

@end


