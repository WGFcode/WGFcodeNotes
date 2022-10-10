//
//  NSConditionLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
/*
 
 【NSConditionLock】是对【NSCondition】的进一步封装,可以设置具体的条件值
 
  该方法可以实现多条线程间任务按照顺序执行，比如任务1，任务2，任务3按照次序进行执行；【可以设置线程间依赖】
 */
@interface NSConditionLockTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
