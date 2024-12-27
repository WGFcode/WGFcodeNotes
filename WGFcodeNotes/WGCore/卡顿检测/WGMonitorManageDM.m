//
//  WGMonitorManageDM.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2024/12/27.
//  Copyright © 2024 WG. All rights reserved.
//

#import "WGMonitorManageDM.h"

@implementation WGMonitorManageDM

// 单例模式，确保 HangMonitor 只有一个实例
+ (instancetype)sharedInstance {
    static WGMonitorManageDM *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WGMonitorManageDM alloc] init];
    });
    return instance;
}

// 初始化方法
- (instancetype)init {
    self = [super init];
    if (self) {
        _timeoutInterval = 6.0;  // 设置超时时间为6秒
        _semaphore = dispatch_semaphore_create(0);  // 创建信号量
        [self addRunLoopObserver];  // 添加 Runloop 观察者
        [self startMonitor];  // 启动监控
    }
    return self;
}

// 添加 Runloop 观察者的方法
- (void)addRunLoopObserver {
    NSRunLoop *curRunLoop = [NSRunLoop currentRunLoop];  // 获取当前 Runloop

    // 创建第一个观察者，监控 Runloop 是否处于运行状态
    CFRunLoopObserverContext context = {0, (__bridge void *) self, NULL, NULL, NULL};
    CFRunLoopObserverRef beginObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, LONG_MIN, &myRunLoopBeginCallback, &context);
    CFRetain(beginObserver);  // 保留观察者，防止被释放
    self.runLoopBeginObserver = beginObserver;

    // 创建第二个观察者，监控 Runloop 是否处于睡眠状态
    CFRunLoopObserverRef endObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, LONG_MAX, &myRunLoopEndCallback, &context);
    CFRetain(endObserver);  // 保留观察者，防止被释放
    self.runLoopEndObserver = endObserver;

    // 将观察者添加到当前 Runloop 中
    CFRunLoopRef runloop = [curRunLoop getCFRunLoop];
    CFRunLoopAddObserver(runloop, beginObserver, kCFRunLoopCommonModes);
    CFRunLoopAddObserver(runloop, endObserver, kCFRunLoopCommonModes);
}

// 第一个观察者的回调函数，监控 Runloop 是否处于运行状态
void myRunLoopBeginCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    WGMonitorManageDM *monitor = (__bridge WGMonitorManageDM *)info;
    g_runLoopActivity = activity;  // 更新全局变量，记录当前的 Runloop 活动状态
    g_runLoopMode = eRunloopDefaultMode;  // 更新全局变量，记录当前的 Runloop 模式
    switch (activity) {
        case kCFRunLoopEntry:
            g_bRun = YES;  // 标记 Runloop 进入运行状态
            break;
        case kCFRunLoopBeforeTimers:
        case kCFRunLoopBeforeSources:
        case kCFRunLoopAfterWaiting:
            if (g_bRun == NO) {
                gettimeofday(&g_tvRun, NULL);  // 记录 Runloop 开始运行的时间
            }
            g_bRun = YES;  // 标记 Runloop 处于运行状态
            break;
        case kCFRunLoopAllActivities:
            break;
        default:
            break;
    }
    dispatch_semaphore_signal(monitor.semaphore);  // 发送信号量
}

// 第二个观察者的回调函数，监控 Runloop 是否处于睡眠状态
void myRunLoopEndCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    WGMonitorManageDM *monitor = (__bridge WGMonitorManageDM *)info;
    g_runLoopActivity = activity;  // 更新全局变量，记录当前的 Runloop 活动状态
    g_runLoopMode = eRunloopDefaultMode;  // 更新全局变量，记录当前的 Runloop 模式
    switch (activity) {
        case kCFRunLoopBeforeWaiting:
            gettimeofday(&g_tvRun, NULL);  // 记录 Runloop 进入睡眠状态的时间
            g_bRun = NO;  // 标记 Runloop 进入睡眠状态
            break;
        case kCFRunLoopExit:
            g_bRun = NO;  // 标记 Runloop 退出运行状态
            break;
        case kCFRunLoopAllActivities:
            break;
        default:
            break;
    }
    dispatch_semaphore_signal(monitor.semaphore);  // 发送信号量
}

// 启动监控的方法
- (void)startMonitor {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (YES) {
            long result = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, self.timeoutInterval * NSEC_PER_SEC));
            if (result != 0) {
                if (g_runLoopActivity == kCFRunLoopBeforeSources || g_runLoopActivity == kCFRunLoopAfterWaiting) {
                    [self logStackTrace];  // 记录调用栈
                    [self reportHang];  // 上报卡死
                }
            }
        }
    });
}

// 记录调用栈的方法
- (void)logStackTrace {
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    NSMutableString *stackTrace = [NSMutableString stringWithString:@"\n"];
    for (int i = 0; i < frames; i++) {
        [stackTrace appendFormat:@"%s\n", strs[i]];
    }
    free(strs);
    NSLog(@"%@", stackTrace);
}

// 上报卡死的方法
- (void)reportHang {
    // 在这里实现上报后台分析的逻辑
    NSLog(@"检测到卡死崩溃，进行上报");
}

@end
