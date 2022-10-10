//
//  ReadWriteLockTest1.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN

/*
 读写锁
 dispatch_barrier_async: 异步栅栏调用
 这个函数传入的并发队列必须是【手动创建的并发队列】，不能是全局的并发队列
 
 */

@interface ReadWriteLockTest1 : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
