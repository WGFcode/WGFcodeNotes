//
//  WGQueue.m
//  appName
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGQueue.h"
#import "WGDoubleList.h"

@interface WGQueue()
{
    WGDoubleList *list;
}
@end

@implementation WGQueue

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

/// 入队
-(void)enQueue:(int)element {
    //只能从队尾入队
    [list add:element];
}

/// 出队
-(int)deQueue {
    //只能从队头出队
    return [list remove:0];
}

/// 获取队列的头元素
-(int)front {
    return [list get:0];
}

/// 清空
-(void)clear {
    [list clear];
}
@end
