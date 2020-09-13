//
//  WGRunLoopVC.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/9.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGRunLoopVC.h"
#import "WGThread.h"
#import "WGRunLoopSecondVC.h"
#import "WGProxy.h"

@interface WGRunLoopVC ()
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) WGProxy *proxy;
@property(nonatomic, strong) NSString *name;
@end

@implementation WGRunLoopVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    self.name = @"zhang san";
    //1. 实例化WGProxy,注意它只有alloc方法没有init方法
    self.proxy = [WGProxy alloc];
    self.proxy.target = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.proxy selector:@selector(timerChange) userInfo:nil repeats:YES];
}

-(void)timerChange{
    NSLog(@"timer来了,名字是: %@", self.name);
}

-(void)dealloc {
    NSLog(@"WGRunLoopVC页面销毁了");
    [self.timer invalidate];
    self.timer = nil;
}


//-(void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    [self.timer invalidate];
//    self.timer = nil;
//}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.timer invalidate];
//    self.timer = nil;
//}

@end
