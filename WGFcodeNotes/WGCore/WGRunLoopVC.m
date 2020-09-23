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
@property(nonatomic, strong) WGThread *thread;
@property(nonatomic, strong) NSPort *port;
@property(nonatomic, assign) BOOL stopRunLoop;
@end

@implementation WGRunLoopVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    _port = [NSMachPort port];
    self.stopRunLoop = NO;
    _thread = [[WGThread alloc]initWithTarget:self selector:@selector(threadTest) object:nil];
    [_thread start];

}

-(void)threadTest {
    NSLog(@"当前子线程开始执行任务");
    @autoreleasepool {
        NSRunLoop *currentThreadRunLoop = [NSRunLoop currentRunLoop];
        [currentThreadRunLoop addPort:_port forMode:NSRunLoopCommonModes];
        [self addObserverForCurrentRunloop];
        [self performSelector:@selector(removeThread) withObject:nil afterDelay:10.0];
        while (!self.stopRunLoop) {
            [currentThreadRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        };
        NSLog(@"========");
    }
}

-(void)removeThread {
    NSLog(@"---%s---",__func__);
    _stopRunLoop = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

// 验证子线程并没有销毁
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self performSelector:@selector(threadTask) onThread:self.thread withObject:nil waitUntilDone:NO];
}

-(void)threadTask {
    NSLog(@"在保活的线程下执行了任务");
}

-(void)dealloc {
    NSLog(@"页面销毁了");
}

-(void)addObserverForCurrentRunloop {
    CFRunLoopObserverContext context = { 0, (__bridge void *)(self), NULL, NULL };
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
}

static void runLoopCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    NSString *str;
    switch (activity) {
        case kCFRunLoopEntry:
            str = @"Entry";
            break;
        case kCFRunLoopBeforeTimers:
            str = @"BeforeTimers";
            break;
        case kCFRunLoopBeforeSources:
            str = @"BeforeSources";
            break;
        case kCFRunLoopBeforeWaiting:
            str = @"BeforeWaiting";
            break;
        case kCFRunLoopAfterWaiting:
            str = @"AfterWaiting";
            break;
        case kCFRunLoopExit:
            str = @"Exit";
            break;
        default:
            break;
    }
    NSLog(@"current RunLoop activity: %@",str);
}

@end
