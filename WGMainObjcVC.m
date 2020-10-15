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
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //创建定时器
    /*
     参数1：源的类型
     参数2/参数3: 直接传递0即可
     参数4:设置定时器运行的队列
     */
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    //设置时间
    NSTimeInterval start = 1.0;
    NSTimeInterval interval = 1.0;
    //dispatch_source_set_timer(timer, <#dispatch_time_t start#>, <#uint64_t interval#>, <#uint64_t leeway#>)
    //设置定时器回调方法
    dispatch_source_set_event_handler(timer, ^{
        
    })
    
}


@end


