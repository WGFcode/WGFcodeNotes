//
//  WGMonitorManage.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/26.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMonitorManage.h"

@interface WGMonitorManage()
//监控主线程中RunLoop的子线程
@property (nonatomic,strong) NSThread *monitorThread;
//监听主线程中RunLoop状态的观察者
@property (nonatomic,assign) CFRunLoopObserverRef observer;
//在子线程的RunLoop添加一个定时器，来反复的执行【监听主线程中RunLoop对应的状态】的工作
@property (nonatomic,assign) CFRunLoopTimerRef timer;
//定时器间隔时间
@property (nonatomic,assign) NSTimeInterval timerInterval;
//判定为卡顿的时间（例如2s算卡顿）
@property (nonatomic,assign) NSTimeInterval catonTime;
//开始执行的时间
@property (nonatomic,strong) NSDate *startDate;
//执行时长
@property (nonatomic,assign) BOOL excuting;

@end

@implementation WGMonitorManage

static WGMonitorManage *instance = nil;

+(instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.monitorThread = [[NSThread alloc]initWithTarget:self selector:@selector(openMonitorThreadRunLoop) object:nil];
        [instance.monitorThread start];
    });
    return instance;
}
//开启子线程monitorThread的RunLoop
+(void)openMonitorThreadRunLoop {
    @autoreleasepool {
        [[NSRunLoop currentRunLoop] addPort:[[NSMachPort alloc]init] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

//开始监测
-(void)startMonitorWithTimerInterval:(NSTimeInterval)interval withCatonTime:(NSTimeInterval)caton {
    self.timerInterval = interval;
    self.catonTime = caton;
    if (self.observer == nil) {
        return;
    }
    //1创建观察者
    CFRunLoopObserverContext context = {0,(__bridge void*)self, NULL, NULL, NULL};
    self.observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    //2.将observer添加到主线程的RunLoop中
    CFRunLoopAddObserver(CFRunLoopGetMain(), self.observer, kCFRunLoopCommonModes);
    //3.创建一个定时器timer，并添加到子线程的RunLoop中
    [self performSelector:@selector(addTimerToMonitorThread) onThread:self.monitorThread withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

-(void)addTimerToMonitorThread {
    if (self.timer) {
        return;
    }
    //创建定时器
    CFRunLoopTimerContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
    self.timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, self.timerInterval, 0, 0, &runLoopTimerCallBack, &context);
    //将定时器添加到子线程monitorThread的RunLoop中进行监听
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), self.timer, kCFRunLoopCommonModes);
}


//停止监测
-(void)stopMonitor {
    if (self.observer) {
        //1.移除主线程对应RunLoop中的观察者
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), self.observer, kCFRunLoopCommonModes);
        CFRelease(self.observer);
        self.observer = NULL;
    }
    //2.移除子线程对应RunLoop中的定时器
    [self performSelector:@selector(removeTimerInMonitorThread) onThread:self.monitorThread withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

-(void)removeTimerInMonitorThread {
    if (self.timer) {
        CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), self.timer, kCFRunLoopCommonModes);
        CFRelease(self.timer);
        self.timer = NULL;
    }
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    WGMonitorManage *monitor = (__bridge WGMonitorManage*)info;
    NSLog(@"MainRunLoop---%@",[NSThread currentThread]);
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        //BeforeSources和AfterWaiting这两个状态区间时间能够检测到是否卡顿
        case kCFRunLoopBeforeSources:           //触发 Source0 回调
            NSLog(@"kCFRunLoopBeforeSources");
            monitor.startDate = [NSDate date];
            monitor.excuting = YES;
            break;
        case kCFRunLoopBeforeWaiting:          //等待 mach_port 消息
            NSLog(@"kCFRunLoopBeforeWaiting");
            monitor.excuting = NO;
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
            break;
        default:
            break;
    }
}
static void runLoopTimerCallBack(CFRunLoopTimerRef timer, void *info) {
    WGMonitorManage *monitor = (__bridge WGMonitorManage*)info;
    if (!monitor.excuting) {
        return;
    }
    // 如果主线程正在执行任务，并且这一次loop 执行到 现在还没执行完，那就需要计算时间差
    NSTimeInterval excuteTime = [[NSDate date] timeIntervalSinceDate:monitor.startDate];
    NSLog(@"定时器---%@",[NSThread currentThread]);
    NSLog(@"主线程执行了---%f秒",excuteTime);
    if (excuteTime >= monitor.catonTime) {
        NSLog(@"线程卡顿了%f秒",excuteTime);
    }
}
@end
