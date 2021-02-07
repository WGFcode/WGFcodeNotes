//
//  WGPermanentThread.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/2/6.
//  Copyright © 2021 WG. All rights reserved.
//

#import "WGPermanentThreadOC.h"

//将MJThread写在这里是为了方便查看线程销毁,后续项目中也可以直接用NSThread
@interface MJThreadOC : NSThread
@end

@implementation MJThreadOC
-(void)dealloc {
    NSLog(@"永久线程WGPermanentThread销毁了");
}
@end



/// 永久线程类-WGPermanentThread
@interface WGPermanentThreadOC()
@property(nonatomic, strong) MJThreadOC *innerThread; //内部线程
@property(nonatomic, assign, getter=isStopped) BOOL stopped;
@end


@implementation WGPermanentThreadOC

#pragma mark public method
/// 初始化时就创建线程,并添加事件到RunLoop中
-(instancetype)init {
    self = [super init];
    if (self) {
        self.stopped = NO;
        __weak typeof(self) weakSelf = self;
        self.innerThread = [[MJThreadOC alloc]initWithBlock:^{
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            while (weakSelf && !weakSelf.stopped) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }];
        //如果run方法不想写,启动线程也可以写在这个地方
        //[self.innerThread start];
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
-(void)executeTask:(WGPermanentThreadOCTask)task {
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
    self.stopped = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
    self.innerThread = nil;
}

#pragma mark private method 内部方法来执行任务,保证任务是在子线程中执行的
-(void)innerExecuteTask:(WGPermanentThreadOCTask)task{
    task();
}
@end
