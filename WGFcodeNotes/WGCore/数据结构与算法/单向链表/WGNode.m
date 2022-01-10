//
//  WGNode.m
//  ZJKBank
//
//  Created by 白菜 on 2021/11/12.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGNode.h"


@implementation WGNode

//MARK: 初始化一个链表中的节点
-(instancetype)initWithElement:(int)elementt withNext:(WGNode *)nextt {
    self = [super init];
    if (self) {
        element = elementt;
        next = nextt;
    }
    return self;
}
@end
