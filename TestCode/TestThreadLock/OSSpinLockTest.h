//
//  OSSpinLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/9.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN

/*【自旋锁】：等待锁的线程会一直处于忙等状态，一直占用者CPU资源
 目前已经不安全了，可能会出现优先级反转问题:如果等待锁的线程优先级比较高，一直占用者CPU资源，导致优先级低的锁无法释放锁
 */
@interface OSSpinLockTest : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
