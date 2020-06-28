//
//  BinaryTree.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/6/27.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BinaryTree : NSObject

@property(nonatomic, assign) NSInteger value;        //根结点值
@property(nonatomic, strong) BinaryTree *leftNode;   //左子树
@property(nonatomic, strong) BinaryTree *rightNode;  //右子树

/// 创建二叉树
+(BinaryTree *)create:(NSArray *)arr;

/// 向二叉排序树中添加一个结点 treeNode:根结点  value:值
+(BinaryTree *)add:(BinaryTree *)treeNode withValue:(NSInteger)value;

/// 先序遍历(前序遍历): 根节点->左子树->右子树 典型的递归思想
+(void)firstOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler;

/// 中序遍历:左子树-> 根节点->右子树
+(void)middleOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler;

/// 后序遍历:左子树-> 右子树->根节点
+(void)afterOrder:(BinaryTree *)rootNode withHandler:(void(^)(BinaryTree *treeNode))handler;
@end

NS_ASSUME_NONNULL_END
