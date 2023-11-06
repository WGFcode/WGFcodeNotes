//
//  BinarySearchTree.swift
//  appName
//
//  Created by 白菜 on 2021/12/22.
//  Copyright © 2021 baicai. All rights reserved.
//
/* 二叉搜索树(BST)
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
 二、二叉搜索树的复杂度分析
    1.正常情况下二叉搜索树的时间复杂度和树的高度有关系: O(h) = O(logn)
    2.二叉树搜索树可能退化成链表时(节点只有左子树或右子树)，时间复杂度就变成: O(n)
    当 n 比较大时，两者的性能差异比较大，如果 n = 1000000时，二叉搜索树的最低高度是20
 添加、删除节点时都可能导致二叉搜索树退化成链表，有什么办法能防止二叉搜索树退化成链表，让添加、删除、搜索的时间复杂度维持在O(logn)?

 答案是有的，通过平衡因子来改变
 三、二叉搜索树的平衡
    平衡：当节点数量固定时，左右子树的高度越接近，这颗二叉树就越平衡(高度越低)
    最理想的平衡就是像完全二叉树、满二叉树，高度是最小的
 节点的添加、删除顺序是无法限制的可以认为是随机的，所以改进方案就是：在节点的添加、删除之后，想办法让二叉搜索树恢复平衡（减少树的高度）
 ⚠️：如果一直调整二叉搜索树的高度，完全可以达到理想状态下的平衡，但是付出的代价可能就比较大了
    比如调整的次数多了，反而增加了时间复杂度；所以比较合理的方案就是：用尽量少的调整次数来达到适度平衡即可
    一颗达到适度平衡的二叉搜索树，可以称为平衡二叉搜索树
 四、平衡二叉搜索树(BBST)
    常见的平衡二叉搜索树有；一般也称它们为: 自平衡的二叉搜索树
    1. AVL树:
    2. 红黑树
    继承关系：AVL树/红黑树 : BST(二叉搜索树BinarySearchTree) : 二叉树(BinaryTree)

 */

import Foundation
//MARK: *********************************二叉搜索树(BST)*********************************
public class BinarySearchTree<T: Comparable> : BinaryTree<T> {

    //MARK: 添加元素
    func addElement(element: T) {
        /* 添加步骤:
         1.找到父节点parent
         2.创建新节点newNode
         3.parent.left = newNode 或 parent.right = newNode
         遇到值相等的情况，建议直接覆盖
                         ------------8------------
                         ↓                        ↓
                    -----4-----              -----13
                    ↓          ↓             ↓
                 ---2---    ---6---       ---10---
                 ↓      ↓   ↓     ↓       ↓      ↓
                 1      3   5     7       9   ---12
                                              ↓
                                              11
         */
        if root == nil { //创建的第一个节点
            root = BinaryTreeNode.init(element: element, parentNode: nil)
            size += 1
            return
        }
        //添加的不是第一个节点，开始找父节点,需要拿新添加的元素和根节点进行比较
        var parent = root  //默认是父节点
        var node = root
        while node != nil {
            parent = node
            //若添加的节点 比 当前的节点 大，则去当前节点的右子树继续寻找
            if element > node!.element {
                node = node!.right
            }else if (element < node!.element) { //去左子树上继续寻找
                node = node!.left
            }else { //相等，直接进行覆盖即可,然后直接返回
                node!.element = element
                return
            }
        }
        //创建新节点，和父节点的值进行对比，看是插入到左子节点还是右子节点
        let newNode = BinaryTreeNode.init(element: element, parentNode: parent)
        if element > newNode.element { //插入到父节点的右子节点上
            parent!.right = newNode
        }else { //插入到父节点的左子节点上
            parent!.left = newNode
        }
        size += 1
    }

    
    /*
     删除的是叶子节点
      1.如果node == node.parent.left,则直接node.parent.left = nil即可
      2.如果node == node.parent.right,则直接node.parent.right = nil即可
      3.如果node.parent = nil,删除的肯定就是只有根节点的树了，则直接root = nil即可
     删除度为1的节点(用子节点替代原节点的位置,child是node.left或者child是node.right)
      1.如果node是左子节点，child.parent = node.parent; node.parent.left = child
      2.如果node是右子节点，child.parent = node.parent; node.parent.right = child
      3.如果node是根节点, root = child; child.parent = nil
     删除度为2的节点
      先用前驱或后驱节点的值覆盖原节点的值，然后删除相应的前驱或后继节点
      有个规则：如果一个节点的度为2，那么它的前驱、后继节点的度只可能是1和0
      所以删除度为2的节点其实并不是真正删除该节点，而是删除这个节点的前驱或后继节点
             ------5-----
             ↓          ↓
           --3--      --8--
          ↓     ↓    ↓     ↓
          1--   4    6--   9
             ↓          ↓
             2          7
     中序遍历： 5  3  1  2  4  8   6   7   9
     删除8 前驱节点：4  后继节点: 6
    */
    //MARK: 删除元素
    func removeElement(element: T) {
        removeNode(node: getNodeWithElement(element: element))
    }
    /// 删除指定的节点
    private func removeNode(node: BinaryTreeNode<T>?) {
        guard node != nil else {
            return
        }
        var baseNode = node!
        size = size - 1
        // 度为2的节点
        if baseNode.hasTwoChildNode() {
            //找到后继节点
            let s = successor(node: baseNode)
            //用后继节点的值覆盖度为2的节点的值
            baseNode.element = s!.element
            //删除后继节点
            baseNode = s!
        }
        //删除node节点(node节点的度必然是1或者0)
        let replaceNode = baseNode.left != nil ? baseNode.left : baseNode.right
        if replaceNode != nil { //度为1的节点
            //更改parent
            replaceNode?.parent = baseNode.parent
            //更改parent的left、right的指向
            if baseNode.parent == nil { //node是度为1的节点并且是根节点
                root = replaceNode
            }else if(baseNode == baseNode.parent?.left) {
                baseNode.parent?.left = replaceNode
            }else { // baseNode == baseNode.parent?.right
                baseNode.parent?.right = replaceNode
            }
        }else if baseNode.parent == nil { //node是叶子节点并且是根节点
            root = nil
        }else { //node是叶子节点，但不是根节点
            if baseNode == baseNode.parent?.left {
                baseNode.parent?.left = nil
            }else { // baseNode == baseNode.parent?.right
                baseNode.parent?.right = nil
            }
        }
    }
    /// 根据元素找到对应的节点
    private func getNodeWithElement(element: T) -> BinaryTreeNode<T>? {
        var node = root
        while node != nil {
            if element > node!.element {
                node = node!.right
            }else if element < node!.element {
                node = node!.left
            }else {
                return node
            }
        }
        return nil
    }

    
    //MARK: 是否包含指定的元素
    func containsElement(element: T) -> Bool {
        return getNodeWithElement(element: element) != nil
    }
    
    //MARK: MJBinaryTreeInfo协议
//    public func root() -> Any {
//        return root
//    }
//    public func left(_ node: BinaryTreeNode<T>) -> Any {
//        return node.left
//    }
//    public func right(_ node: BinaryTreeNode<T>) -> Any {
//        return node.right
//    }
//    public func string(_ node: BinaryTreeNode<T>) -> Any {
//        return node.element
//    }
    
//    - (id)left:(MJBSTNode *)node {
//        return node->_left;
//    }
//
//    - (id)right:(MJBSTNode *)node {
//        return node->_right;
//    }
//
//    - (id)string:(MJBSTNode *)node {
//        return node->_element;
//    }
//
//    - (id)root {
//        return _root;
//    }
}


