//
//  WGDoubleQueue.m
//  ZJKBank
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGDoubleQueue.h"
#import "WGDoubleList.h"

@interface WGDoubleQueue()
{
    WGDoubleList *list;  //双向队列
}
@end

@implementation WGDoubleQueue

//在WGStack初始化方法中初始化双向链表
-(instancetype)init {
    self = [super init];
    if (self) {
        list = [[WGDoubleList alloc]init];
    }
    return self;
}

/// 获取队列中元素的个数
-(int)size {
    return list.size;
}

/// 判断队列是否为空
-(BOOL)isEmpty {
    return list.isEmpty;
}

/// 入队-从队头入队
-(void)enQueueFront:(int)element {
    [list add:0 withElement:element];
}

/// 入队-从队尾入队
-(void)enQueueRear:(int)element {
    [list add:element];
}

/// 出队-从队头出队
-(int)deQueueFront {
    return [list remove:0];
}

/// 出队-从队尾出队
-(int)deQueueRear {
    return [list remove:list.size-1];
}

/// 获取队列的头元素
-(int)front {
    return [list get:0];
}

/// 获取队列的尾元素
-(int)rear {
    return [list get:list.size-1];
}

/// 清空
-(void)clear {
    [list clear];
}
@end
