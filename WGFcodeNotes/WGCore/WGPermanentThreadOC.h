//
//  WGPermanentThread.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/2/6.
//  Copyright © 2021 WG. All rights reserved.
//

/*
 MJ底层原理班封装--永久线程类
 1. 为什么不是继承自NSThread,而是NSObject? 如果继承自NSThread,那么外部调用就有可能会调用NSThread的API,破坏封装性
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^WGPermanentThreadOCTask)(void);
@interface WGPermanentThreadOC : NSObject

//该方法也可以不用,直接在WGPermanentThread初始化时,启动线程即可
/// 1.开启一个线程
-(void)run;

/// 2 执行任务 Block形式
-(void)executeTask:(WGPermanentThreadOCTask)task;

/// 3.结束一个线程
-(void)stop;

@end

NS_ASSUME_NONNULL_END
