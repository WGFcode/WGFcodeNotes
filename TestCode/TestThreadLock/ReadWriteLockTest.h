//
//  ReadWriteLockTest.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN

/* ⚠️ios 读写安全方案 -多读单写 经常用于文件等数据的读写操作
 同一时间，只能有一个线程进行写操作
 同一时间，允许有多条线程进行读操作
 同一时间，不允许既有写的操作又又读的操作

 pthread_rwlock: 读写锁（等待锁的线程会进入休眠,【互斥锁】）
 dispatch_barrier_async: 异步栅栏调用
 
 */
@interface ReadWriteLockTest : WGBaseTestLock


@end

NS_ASSUME_NONNULL_END
