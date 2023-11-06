//
//  WGDoubleQueue.h
//  appName
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 baicai. All rights reserved.
//
/* 双端队列： 能在头尾两端进行添加、删除操作
 
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGDoubleQueue : NSObject
/// 获取队列中元素的个数
-(int)size;

/// 判断队列是否为空
-(BOOL)isEmpty;

/// 入队-从队头入队
-(void)enQueueFront:(int)element;


/// 入队-从队尾入队
-(void)enQueueRear:(int)element;


/// 出队-从队头出队
-(int)deQueueFront;

/// 出队-从队尾出队
-(int)deQueueRear;

/// 获取队列的头元素
-(int)front;

/// 获取队列的尾元素
-(int)rear;

/// 清空
-(void)clear;

@end

NS_ASSUME_NONNULL_END
