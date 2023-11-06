//
//  WGSearchTreeNode.m
//  appName
//
//  Created by 白菜 on 2021/12/2.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGSearchTreeNode.h"

@implementation WGSearchTreeNode

//MARK: 初始化一个节点 指定它的元素、父节点
-(instancetype)initWithElement:(int)elementt withParentNode:(WGSearchTreeNode *)node {
    self = [super init];
    if (self) {
        element = elementt;
        parent = node;
    }
    return self;
}

/// 判断是否是叶子节点
-(BOOL)isLeaf {
    return left == nil && right == nil;
}

/// 判断是否有2个子节点(度为2的节点)
-(BOOL)hasTwoChildren {
    return left != nil && right != nil;
}
@end
