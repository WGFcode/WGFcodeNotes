//
//  WGPermanentThreadC.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/2/6.
//  Copyright © 2021 WG. All rights reserved.
//

#import "WGPermanentThreadC.h"

@interface MJThreadC : NSThread
@end

@implementation MJThreadC
-(void)dealloc {
    NSLog(@"永久线程WGPermanentThread销毁了");
}
@end


@interface WGPermanentThreadC()
@property(nonatomic, strong) MJThreadC *innerThread;
@end


@implementation WGPermanentThreadC

#pragma mark public method
-(instancetype)init {
    self = [super init];
    if (self) {
        self.innerThread = [[MJThreadC alloc]initWithBlock:^{
            // 1.创建上下文 CFRunLoopSourceContext是个结构体,它是一个成员变量,如果不初始化,它可能存放的是内容是不确定的
            //所以这里建议这么写对这个结构体进行初始化
            //CFRunLoopSourceContext context;
            CFRunLoopSourceContext context = {0};
            // 2.创建Source
            CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
            // 3.销毁source
            CFRelease(source);
            // 4.往RunLoop中添加Source
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            /* 5.启动RunLoop 第二个参数值参考的是源码中的值
            //第三个参数returnAfterSourceHandled true:代表执行完source后就会退出当前Loop,设置为true就需要while
             (weakSelf && !weakSelf.stopped)的循环了和OC版本是一样的
             设置为false就不会退出,
            */
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0e10, false);
        }];
    }
    return self;
}

-(void)run {
    // 防止线程已经销毁 仍然调用该方法
    if (self.innerThread == nil) {
        return;
    }
    [self.innerThread start];
}

/// 执行任务 Block形式
-(void)executeTask:(WGPermanentThreadTaskC)task {
    // 防止线程已经销毁 仍然调执行任务
    if (self.innerThread == nil || task == nil) {
        return;
    }
    // 将任务作为参数传递到innerExecuteTask内部方法中 waitUntilDone:这里可以设置为NO,这样就不会阻塞外部线程,让任务异步执行
    [self performSelector:@selector(innerExecuteTask:) onThread:self.innerThread withObject:task waitUntilDone:NO];
}

-(void)stop {
    // 防止线程已经销毁 仍然调用stop方法
    if (self.innerThread == nil) {
        return;
    }
    //切记 waitUntilDone参数要设置为YES
    [self performSelector:@selector(innerThread) onThread:self.innerThread withObject:nil waitUntilDone:YES];
}


//查看该对象是否销毁
-(void)dealloc {
    //这里写了stop,外部使用的VC中的dealloc方法中就不需要再调用stop方法了
    [self stop];
    NSLog(@"------%s-----",__func__);
}


#pragma mark private method 内部方法来停用RunLoop
-(void)innerStop {
    CFRunLoopStop(CFRunLoopGetCurrent());
    self.innerThread = nil;
}

#pragma mark private method 内部方法来执行任务,保证任务是在子线程中执行的
-(void)innerExecuteTask:(WGPermanentThreadTaskC)task{
    task();
}


@end

