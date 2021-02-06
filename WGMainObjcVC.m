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
#import "WGThread.h"
#import "WGPermanentThreadOC.h"
#import <pthread.h>

@interface WGMainObjcVC()
@property(nonatomic, strong) WGPermanentThreadOC *thread;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.thread = [[WGPermanentThreadOC alloc]init];
    [self.thread run];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    //__weak typeof(self) weakSelf = self;
    [self.thread executeTask:^{
        //[weakSelf XXX]; 如果访问self,就要使用弱引用
        NSLog(@"-------%@",[NSThread currentThread]);
    }];
}

@end


