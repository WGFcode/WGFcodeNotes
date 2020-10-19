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


@interface WGMainObjcVC()
//必须强引用这个定时器，否则定时器是不会工作的
@property(nonatomic, strong) dispatch_source_t timer;
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"-------begin-------");
    //创建队列:主队列就是在主线程下，非主队列都是在子线程中
    dispatch_queue_t queue = dispatch_get_main_queue();
    //创建定时器
    /*
     参数1：源的类型
     参数2/参数3: 直接传递0即可
     参数4:设置定时器运行的队列
     */
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //设置时间
    NSTimeInterval start = 3.0;
    NSTimeInterval interval = 1.0;
    /*
     参数1: 设置哪个定时器
     参数2: 开始时间，必须是dispatch_time(参数1,开始的时间) NSEC_PER_SEC：纳秒
     参数3: 间隔多长时间执行一次定时器任务
     参数4: 误差，设置为0即可
     */
    dispatch_source_set_timer(self.timer,
                              dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC),
                              interval * NSEC_PER_SEC,
                              0);
    //设置定时器回调方法一：通过Block方式
//    dispatch_source_set_event_handler(self.timer, ^{
//        NSLog(@"1111--current Threaad:%@",[NSThread currentThread]);
//    });
    //设置定时器回调方法二：通过Block方式
    dispatch_source_set_event_handler_f(self.timer, timerTest);
    //启动定时器
    dispatch_resume(self.timer);
}

//typedef void (*dispatch_function_t)(void *_Nullable);
void timerTest(void* paramer) {
    NSLog(@"1111--current Threaad:%@",[NSThread currentThread]);
}

@end


