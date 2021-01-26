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
@property(atomic, strong) NSMutableArray *data;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];

    //1. 下面的代码相当于调用了属性data的setter方法,所以它是线程安全的
    //[self setData:[NSMutableArray array]];
    self.data = [NSMutableArray array];

    //2. 添加元素相当于先通过getter方法获取到data对象,这一步是线程安全的,但是再调用addObject方法这一步就不是线程安全的了
    //[[self data] addObject:@"1"];
    [self.data addObject:@"1"];
    [self.data addObject:@"2"];
    [self.data addObject:@"3"];
}



@end


