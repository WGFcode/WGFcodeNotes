//
//  DispatchSemaphoreTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
/* ⚠️ 信号量
      通过设置信号量的初始值为1 ，可以用来保证线程同步
 */

// 信号量 信号量的初始值，可以用来控制线程并发访问的最大数量
@interface DispatchSemaphoreTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
