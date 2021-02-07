//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>

#import "WGThread.h"

@interface WGMainObjcVC()
@property(nonatomic, strong) WGThread *thread;

@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.thread = [[WGThread alloc]initWithTarget:self selector:@selector(execureTask) object:nil];
    
    [self.thread start];
}

-(void)execureTask {
    NSLog(@"-------执行子线程任务----%@",[NSThread currentThread]);
    
    //保住线程的命
//    [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSRunLoopCommonModes];
//    [[NSRunLoop currentRunLoop] run];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"-----%@",self.thread);
    //[self performSelector: @selector(test) onThread:self.thread withObject:nil waitUntilDone:NO];
}

-(void)test{
    NSLog(@"----%s",__func__);
}


-(void)dealloc {
    
    NSLog(@"-------%s",__func__);
}


@end


