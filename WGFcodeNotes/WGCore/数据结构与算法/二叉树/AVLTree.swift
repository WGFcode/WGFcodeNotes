//
//  AVLTree.swift
//  appName
//
//  Created by 白菜 on 2021/12/28.
//  Copyright © 2021 baicai. All rights reserved.
//
/*
 一、AVL树
    取名为两位苏联发明者的名字，也有人将AVL树成为"艾薇儿树"
    平衡因子: 某节点左右子树的高度差
 AVL树特点：
    1. 每个节点的平衡因子只可能是 1 、0 、-1 (绝对值 <= 1,如果超过1，称为“失衡”)
    2. 每个节点的左右子树高度差不超过1
    3. 添加、删除、搜索的时间复杂度是O(logn)
 
 */
import Foundation

public class AVLTree<T: Comparable> : BinarySearchTree<T> {
    
}
