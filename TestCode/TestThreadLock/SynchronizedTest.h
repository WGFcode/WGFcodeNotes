//
//  SynchronizedTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
/* ⚠️ @synchronized支持递归加锁
 synchronized 是对mutex递归锁的封装
 源码查看:objc4中的objc-sync.mm文件
 @synchronized (obj)内部会生成obj对应的递归锁，然后进行加锁，解锁操作
 
 底层其实调用的是下面两个方法
 objc_sync_enter(id _Nonnull obj)
 objc_sync_exit(id _Nonnull obj)
 
 */
@interface SynchronizedTest : WGBaseTestLock


@end

NS_ASSUME_NONNULL_END
