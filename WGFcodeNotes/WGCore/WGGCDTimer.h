//
//  WGGCDTimer.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/10/24.
//  Copyright © 2020 WG. All rights reserved.
//

/// 封装GCD定时器: 准时
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGGCDTimer : NSObject

/// task:定时器任务 start:开始时间  interval: 时间间隔 repeats:是否重复  async:是否是异步
//返回的内容: 定时器唯一标识
+(NSString *)handlerTask:(void(^)(void))task start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(BOOL)repeats async:(BOOL)async;

/// 取消任务
+(void)cancelTask:(NSString *)timerName;

@end

NS_ASSUME_NONNULL_END
