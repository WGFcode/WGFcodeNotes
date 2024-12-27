//
//  WGMonitorManageDM.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2024/12/27.
//  Copyright © 2024 WG. All rights reserved.
//
// ⚠️戴铭文章
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <execinfo.h>
#import <sys/time.h>

// 定义 Runloop 模式的枚举
typedef enum {
    eRunloopDefaultMode,  // 默认模式
    eRunloopTrackingMode  // 追踪模式
} RunloopMode;

// 全局变量，用于记录 Runloop 的活动状态和模式
static CFRunLoopActivity g_runLoopActivity;
static RunloopMode g_runLoopMode;
static BOOL g_bRun = NO;  // 标记 Runloop 是否在运行
static struct timeval g_tvRun;  // 记录 Runloop 开始运行的时间


NS_ASSUME_NONNULL_BEGIN

//用于监控卡死情况

@interface WGMonitorManageDM : NSObject

@property (nonatomic, assign) CFRunLoopObserverRef runLoopBeginObserver;  // Runloop 开始观察者
@property (nonatomic, assign) CFRunLoopObserverRef runLoopEndObserver;    // Runloop 结束观察者
@property (nonatomic, strong) dispatch_semaphore_t semaphore;  // 信号量，用于同步
@property (nonatomic, assign) NSTimeInterval timeoutInterval;  // 超时时间
- (void)addRunLoopObserver;  // 添加 Runloop 观察者的方法
- (void)startMonitor;  // 启动监控的方法
- (void)logStackTrace;  // 记录调用栈的方法
- (void)reportHang;  // 上报卡死的方法

@end

NS_ASSUME_NONNULL_END
