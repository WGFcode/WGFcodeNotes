//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGThread
-(void)dealloc {
    NSLog(@"线程销毁了");
}
@end

@interface WGKeepThreadAlive()

//@property(nonatomic, strong) NSThread *thread;
@property(nonatomic, strong) WGThread *thread;
@property(nonatomic, assign, getter=isStop) BOOL stop;

@end

//线程保活类
@implementation WGKeepThreadAlive

-(instancetype)init {
    if (self = [super init]) {
        self.stop = NO;
        __weak typeof(self)weakSelf = self;
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc]initWithBlock:^{
                //给当前线程对应的RunLoop对象添加基于端口的事件源
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                //先判断，如果条件满足再执行循环体内的语句。
                //如果当前weakSelf不为nil，并且变量stop没有声明停止，就进入循环体
                while (weakSelf && !weakSelf.stop) {
                    //如果当前线程下有在NSDefaultRunLoopMode运行模式下的事件，那么RunLoop就会启动并去处理；如果没有事件，那么RunLoop就会处于休眠状态并在每过(多长时间)去启动一次该线程下的RunLoop
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                }
            }];
            [self.thread start];
        } else { /*Fallback on earlier versions */ };
    }
    return self;
}

//在当前子线程下处理一个事件
-(void)handleEvent:(WGHandle)handle {
    if (self.thread != nil && handle != nil) {
        //此方法可以传递参数，将参数放在withObject中;waitUntilDone:NO处理任务的时候，这里不需要等待子线程中的任务执行完成，即仍然异步执行
        [self performSelector:@selector(privateHandleEventInThread:) onThread:self.thread withObject:handle waitUntilDone:NO];
    }
}
-(void)privateHandleEventInThread:(WGHandle)handle{
    handle();
}

//停止当前线程对应的RunLoop循环并销毁线程
-(void)stopRunLoop {
    if (self.thread != nil) {
        [self performSelector:@selector(privateStop) onThread:self.thread withObject:nil waitUntilDone:YES];
    }else {
        NSLog(@"111111");
    }
}
-(void)privateStop {
    self.stop = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
    self.thread = nil;
}

//对象销毁的时候停止RunLoop并销毁线程
-(void)dealloc {
    [self stopRunLoop];
    NSLog(@"对象销毁了");
}
@end

@interface WGMainObjcVC()
@property(nonatomic, strong) WGKeepThreadAlive *alive;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    self.alive =[[WGKeepThreadAlive alloc]init];
    [self.alive handleEvent:^{
        NSLog(@"当前线程是:%@---我的名字叫张三",[NSThread currentThread]);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.alive stopRunLoop];
}


@end


