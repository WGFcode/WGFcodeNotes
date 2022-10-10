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
 NSCondition就是对pthread_mutex中mutex锁和cond条件的封装
 */
@interface NSConditionTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
