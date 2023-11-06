//
//  WGDoubleNode.m
//  appName
//
//  Created by 白菜 on 2021/11/17.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGDoubleNode.h"

@implementation WGDoubleNode

/// 初始化一个链表中的节点 上一个结点 元素 下一个结点
-(instancetype)initWithPrev:(WGDoubleNode *__nullable)prevv withElement:(int)elementt withNext:(WGDoubleNode *__nullable)nextt {
    self = [super init];
    if (self) {
        prev = prevv;
        element = elementt;
        next = nextt;
    }
    return self;
}

@end
