//
//  WGMonitorManage.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/26.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGMonitorManage : NSObject

+(instancetype)shareInstance;
//开始监测
-(void)startMonitorWithTimerInterval:(NSTimeInterval)interval withCatonTime:(NSTimeInterval)caton;
//停止监测
-(void)stopMonitor;

@end

NS_ASSUME_NONNULL_END
