//
//  DispatchSerialQueueTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
// ⚠️使用GCD中的串行队列，也可以实现线程同步

// 利用【串行队列】【同步任务】也可以实现 子线程中任务的同步操作
@interface DispatchSerialQueueTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
