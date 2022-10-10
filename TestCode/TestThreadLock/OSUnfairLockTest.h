//
//  OSUnfairLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN

///  os_unfair_lock 【互斥锁】等待锁的线程会进入休眠状态
@interface OSUnfairLockTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
