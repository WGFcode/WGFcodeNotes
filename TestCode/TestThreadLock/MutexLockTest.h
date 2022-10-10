//
//  PthreadMutexLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN

/*
 普通锁: 
 pthread_mutex_t: 【互斥锁】等待锁的线程会处于休眠状态
 */
@interface MutexLockTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
