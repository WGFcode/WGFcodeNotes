//
//  NSLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
/*
 NSLock就是对pthread_mutex中普通锁的封装
 */
@interface NSLockTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
