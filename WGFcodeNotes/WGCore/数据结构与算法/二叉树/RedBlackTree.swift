//
//  RedBlackTree.swift
//  appName
//
//  Created by 白菜 on 2021/12/28.
//  Copyright © 2021 baicai. All rights reserved.
//
/*红黑树
 红黑树也是一种自平衡的二叉搜索树，以前也叫做平衡二叉B树
 
 红黑树必须满足以下5条性质
    1.节点是 RED 或 BLACK
    2.根节点是 BLACK
    3.叶子节点(外部节点、空节点)都是BLACK
    4.RED节点的子节点都是 BLACK
        RED节点的parent都是 BLACK
        从根节点到叶子节点的所有路径上不能有2个连续的 RED 节点
    5.从任一节点到叶子节点的所有路径都包含相同数目的 BLACK 节点
 */
import Foundation

public class RedBlackTree<T: Comparable> : BinarySearchTree<T> {
    
}
