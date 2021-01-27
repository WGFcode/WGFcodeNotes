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
@property(nonatomic, strong) dispatch_queue_t queue;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];

    //1. 手动创建的并发队列
    self.queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_CONCURRENT);

    for (int i = 0; i < 10; i++) {
        [self read];
        [self write];
    }
}

//从文件中读取内容
-(void)read {
    //2. 读时:
    dispatch_async(self.queue, ^{
        sleep(1);
        NSLog(@"read");
    });
}

//往文件中写入内容
-(void)write {
    //3. 写时: 调用dispatch_barrier_async函数
    dispatch_barrier_async(self.queue, ^{
        sleep(1);
        NSLog(@"write");
    });
}

@end


