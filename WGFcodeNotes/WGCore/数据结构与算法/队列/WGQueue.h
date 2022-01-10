//
//  WGQueue.h
//  ZJKBank
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 buybal. All rights reserved.
//
/* 队列
 1. 队列是一种特殊的线性表，只能在头尾两端进行操作
 2. 队尾(rear):只能从队尾添加元素，一般叫做enQuueue入队
 3. 队头(front): 只能从队头移动元素，一般叫做deQueue出队
 4. 先进先出的原则 First In First Out,FIFO
 队列的内部实现是否可以用之前的数据结构来实现？ 可以，动态数组、链表都可以
 但优先使用双向链表，因为队列主要是在头尾操作元素的
 
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGQueue : NSObject
/// 获取队列中元素的个数
-(int)size;

/// 判断队列是否为空
-(BOOL)isEmpty;

/// 入队
-(void)enQueue:(int)element;

/// 出队
-(int)deQueue;

/// 获取队列的头元素
-(int)front;

/// 清空
-(void)clear;
@end

NS_ASSUME_NONNULL_END
