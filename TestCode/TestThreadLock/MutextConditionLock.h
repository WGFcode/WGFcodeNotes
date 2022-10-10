//
//  MutextConditionLock.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"

NS_ASSUME_NONNULL_BEGIN
/*
 使用场景: 线程依赖
 比如线程1任务 依赖 线程2任务，就可以使用pthread_mutex中的条件锁来进行处理
 案例中很像：生辰者-消费模式 有数据才能删除
 
 */
@interface MutextConditionLock : WGBaseTestLock

@end

NS_ASSUME_NONNULL_END
