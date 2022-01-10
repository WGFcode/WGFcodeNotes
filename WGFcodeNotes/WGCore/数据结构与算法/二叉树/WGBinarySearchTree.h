//
//  WGSearchTree.h
//  ZJKBank
//
//  Created by 白菜 on 2021/12/1.
//  Copyright © 2021 buybal. All rights reserved.
//
/* 二叉搜索树
 是二叉树的一种，是应用非常广泛的一种二叉树，英文简称为BST，又被称为二叉查找树、二叉排序树，可以大大提高搜索数据的效率
 * 任意一个节点的值都大于其左子树所有节点的值
 * 任意一个节点的值都小于其右子树所有节点的值
 * 它的左右子树也是一棵二叉搜索树
 * 二叉搜索树存储的元素必须具备可比较性；比如int、Double，若是自定义类型需要指定比较方式；不允许为null
 需要注意的是，低于我们现在使用的二叉树，没有索引的概念
 在n个动态的整数中搜索某个整数(查看其是否存在?)
 如果使用动态数组遍历搜索，平均时间复杂度是O(n),
 如果维护的是一个有序的动态数组，使用二分搜素，最坏时间复杂度O(logn)，但是添加、删除的平均时间复杂度是O(n)
 如果使用二叉搜索树，添加、删除、搜索的最坏时间复杂度均可以优化O(logn)
 
                ------------8------------
                ↓                        ↓
           -----4-----              -----13
           ↓          ↓             ↓
        ---2---    ---6---       ---10---
        ↓      ↓   ↓     ↓       ↓      ↓
        1      3   5     7       9      12
                                        ↓
                                    ----
                                    ↓
                                    11
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WGSearchTreeNode;
@interface WGBinarySearchTree : NSObject


/// 获取元素的个数
-(int)size;

/// 判断是否为空
-(BOOL)isEmpty;

/// 添加元素
-(void)addElement:(int)element;

/// 删除元素
-(void)removeElement:(int)element;

/// 是否包含指定的元素
-(BOOL)containsElement:(int)element;

/// 清空
-(void)clear;

/// 前序遍历 根-左-右(应用-树状结构的展示)
-(void)preOrderTraverse;

/// 中序遍历 左-根-右(应用-二叉搜索树中的中序遍历按升序或将序处理节点)
-(void)inOrderTraverse;

/// 后序遍历 左-右-根(应用-适用于一些先子后父的操作)
-(void)postOrderTraverse;

/* 实现思路: 使用队列
 1. 将根节点入队
 2.循环执行以下操作，直到队列为空
    将队头节点A出队，进行访问
    将A的左子节点入队
    将A的右子节点入队
 */
/// 层序遍历 根-左-右 (应用-计算二叉树的高度，判断一棵树是否为完全二叉树)
-(void)levelOrderTraverse;

/* 递归计算二叉树的高度
 计算二叉树的高度，就是计算根节点的高度
 计算根节点的高度就是计算它的左右子节点的高度的最大值
 */
/// 二叉树的高度-递归
-(int)heightWithRecursion;

///二叉树的高度-非递归(利用层序遍历)
-(int)height;


/// 判断一棵二叉树是否是完全二叉树
-(BOOL)isComplete;


/* 前驱节点: 中序遍历(左根右)时的前一个节点
如果是二叉搜索树，前驱节点就是前一个比它小的节点(肯定是在它左子树中的最大值，而左子树中的最大值肯定是在从左子树开始一直找它的右子树的节点)
                ------------8------------
                ↓                        ↓
           -----4-----              -----13
           ↓          ↓             ↓
        ---2---    ---6---       ---10---
        ↓      ↓   ↓     ↓       ↓      ↓
        1      3   5     7       9   ---12
                                     ↓
                                     11
 中序遍历顺序：1 2 3 4 5 6 7 8 9 10 11 12
1. 如果node.left != nil,前驱节点predecessor = node.left.right.right...,终止条件: right = nil
 6的前驱节点就是5: 6的left = 5,5的right=nil,所以前驱节点就是5(predecessor = node.left)
 13的前驱节点就是12，13的left = 10, 10的right = 12， 12的right=nil,所以前驱节点就是12(predecessor = node.left.right)
 8的前驱节点就是7，8的left = 4, 4的right = 6, 6的right = 6, 7的right = nil,所以前驱节点就是7(predecessor = node.left.right.right)
2.如果node.left == nil && node.parent != nil,predecessor = node.parent.parent.parent...,终止条件:node在parent的右子树中
 7的前驱节点就是6，7的left = nil && 7.parent != nil,7.parent = 6,并且7在parent(6)的右子树中，
 所以6就是前驱节点(predecessor = node.parent)
 11的前驱节点就是10，11的left = nil && 11.parent != nil,11的parent = 12,12的parent=10,而节点11在10的右子树上，
 所以前驱节点就是10(predecessor = node.parent.parent)
3.如果node.left == nil && node.parent == nil,那就没有前驱节点
 */
/// 前驱节点
-(WGSearchTreeNode *)predecessor:(WGSearchTreeNode *)node;


/* 后继节点: 中序遍历时的后一个节点,如果是二叉搜索树，后继节点就是最后一个比它大的节点
 1.如果node.right != nil, successor = node.right.left.left...,终止条件: left为nil
 2.如果node.right == nil && node.parent != nil,successor = node.parent.parent...,终止条件: node在parent的左子树中
 3.如果node.right == nil && node.parent == nil,那就没有后继节点(例如没有右子树的根节点)
 */
/// 后继节点
-(WGSearchTreeNode *)successor:(WGSearchTreeNode *)node;

@end

NS_ASSUME_NONNULL_END
