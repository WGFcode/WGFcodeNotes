//
//  BinaryTree.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/6/27.
//  Copyright © 2020 WG. All rights reserved.
//

#import "BinaryTree.h"


@implementation BinaryTree

/// 创建二叉树 @[123, 324,34,23,11,2,4]
+(BinaryTree *)create:(NSArray *)arr {
    BinaryTree *root = nil;
    for (int i = 0; i < arr.count; i++) {
        NSInteger value = [(NSNumber *)[arr objectAtIndex:i] integerValue];
        root = [BinaryTree add:root withValue:value];
    }
    return root;
}

/// 向二叉排序树中添加一个结点 treeNode:根结点  value:值
+(BinaryTree *)add:(BinaryTree *)treeNode withValue:(NSInteger)value {
    if (treeNode == nil) { //根结点不存在，就创建根结点
        treeNode = [BinaryTree new];
        treeNode.value = value;
    }else if (value <= treeNode.value) { //小于根结点的值，那么就作为根结点的左子树
        treeNode.leftNode = [BinaryTree add:treeNode.leftNode withValue:value];
    }else { //大于根结点,就作为根结点的右子树
        treeNode.rightNode = [BinaryTree add:treeNode.rightNode withValue:value];
    }
    return treeNode;
}

/// 先序遍历(前序遍历): 根节点->左子树->右子树 典型的递归思想
+(void)firstOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler {
    if (rootNode != nil) {
        if (handler != nil) {
            handler(rootNode);
        }
        [BinaryTree firstOrder:rootNode.leftNode withHandler:handler];
        [BinaryTree firstOrder:rootNode.rightNode withHandler:handler];
    }
}

/// 中序遍历:左子树-> 根节点->右子树
+(void)middleOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler {
    if (rootNode != nil) {
        [BinaryTree firstOrder:rootNode.leftNode withHandler:handler];
        if (handler != nil) {
            handler(rootNode);
        }
        [BinaryTree firstOrder:rootNode.rightNode withHandler:handler];
    }
}

/// 后序遍历:左子树-> 右子树->根节点
+(void)afterOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler {
    if (rootNode != nil) {
        [BinaryTree firstOrder:rootNode.leftNode withHandler:handler];
        [BinaryTree firstOrder:rootNode.rightNode withHandler:handler];
        if (handler != nil) {
            handler(rootNode);
        }
    }
}


@end
