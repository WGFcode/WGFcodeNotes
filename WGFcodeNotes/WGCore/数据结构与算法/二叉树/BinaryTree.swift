//
//  BinaryTree.swift
//  ZJKBank
//
//  Created by 白菜 on 2021/12/28.
//  Copyright © 2021 buybal. All rights reserved.
//
/*
 1.树的基本概念 【节点、根节点、父节点、子节点、兄弟节点、子树、左子树、右子树】
* 一棵树可以没有任何节点，称为空树；
* 一颗树可以只有一个节点，也就是只有根节点
节点的度(degree): 子树的个数
树的度: 所有节点度中的最大值
叶子节点: 度为0的节点
非叶子节点: 度不为0的节点
层数: 根节点在第1层，根节点的子节点在第2层，依次类推(有些可能是从第0层开始计算)
节点的深度: 从根节点到当前节点的唯一路径上的节点总数
节点的高度: 从当前节点到最远叶子节点的路径上的节点总数
树的深度: 所有节点深度中的最大值
树的高度: 所有节点高度中的最大值
树的深度等于树的高度
2.二叉树的特点
* 每个节点的度最大为2(最多拥有2颗子树)
* 左子树和右子树是有顺序的
* 即使某节点只有一颗子树，也要区分左右子树
* 二叉树是有序树
2.1 二叉树的性质
* 非空二叉树的第i层，最多有2^(i-1)个节点(i>=1)
* 在高度为h的二叉树中，最多有2^h - 1个节点（2^0+2^1+2^2+...2^(h-1) = 2^h - 1）
* 对于任何一颗非空二叉树，如果叶子节点个数为n0,度为2的节点个数为n2,则有n0 = n2 + 1
推导过程：假设度为1的节点有n1个，则总节点树 n = n0 + n1 + n2
 二叉树的边数: 度为1的节点边数只有一个，度为2的节点边数有2条边，度为0的节点没有边，所以总边数 T = n1 + 2n2
 二叉树边数的另一个结算方式,所有节点的上面都有一条边连接，除了根节点，所以 T = n - 1
 T = n1 + 2n2
 T = n - 1
 n1 + 2n2 = n - 1 = n0 + n1 + n2 - 1 ==> n0 = n2 + 1
 3.真二叉树
    所有节点的度要么为0、要么为2
 4.满二叉树
   所有节点的度要么为0、要么为2，且所有的叶子节点都在最后一层
     假设满二叉树的高度为h(h >= 1),那么第i层的节点数量为2^(i-1)
     叶子节点数量: 2^(h-1)
     总节点数量n: n = 2^0 + 2^1 + 2^2 + 2^3 + ... 2^(h-1) = 2^h - 1
     h = log2(n+1)
 5.完全二叉树
 叶子节点只会出现在最后2层,且最后一层的叶子节点都靠左对齐；另一种定义方法(对节点从上到下、从左到右开始编号，其所有编号都能与相同高度的满二叉树中的编号对应)
 * 完全二叉树，从根节点至倒数第2层是一颗满二叉树
 * 满二叉树一定是完全二叉树，完全二叉树不一定是满二叉树
 5.1 完全二叉树的性质
 * 度为1的节点，只有左子树
 * 度为1的节点，要么是1个，要么是0个
 * 同样节点数量的二叉树，完全二叉树的高度最小
 * 假设完全二叉树的高度为h(h >= 1)，那么
    至少有2^(h-1)个节点(2^0 + 2^1 + 2^2 + 2^3 + ... 2^(h-2) + 1)
    最多有2^h - 1个节点(2^0 + 2^1 + 2^2 + 2^3 + ... 2^(h-1)满二叉树)
    总节点数为 n
    2^(h-1) <= n <= 2^h - 1  ===> 2^(h-1) <= n < 2^h  ===>  h - 1 < log2(n) < h  ===> h = floor(log2(n) + 1)
    floot: 向下取整 ceil: 向上取整
 5.2 完全二叉树的性质
 一颗有n个节点的完全二叉树(n > 0),从上到下，从左到右对节点从0开始进行编号，对任意第i个节点
    如果i = 0,它是根节点
    如果i > 0,它的父节点编号为floor( (i-1) / 2 )
    如果2i + 1 <= n - 1,它的左子节点编号为2i + 1
    如果2i + 1 > n - 1,它无左子节点
 
    如果2i + 2 <= n - 1,它的右子节点编号为2i + 2
    如果2i + 2 > n - 1,它无右子节点
 6 面试题
 如果一棵完全二叉树总节点数量768个，求叶子节点数量
 假设叶子节点数是n0,度为1的节点数为n1,度为2的节点数为n2, n = n0 + n1 + n2
 之前结论n0 = n2 + 1， 所以 n = 2n0 + n1 - 1
 完全二叉树度为1的节点要么是1，要么是0，所以 n1 = 0 或 n1 = 1
 若n1 = 0,则n必然是奇数，
 若n1 = 1,则n必然是偶数，
 所以这里 n1 = 1 , n0 = 384,即叶子节点数量为384
 
 7.二叉树的遍历
 线性数据结构的遍历比较简单：正序遍历、逆序遍历
 二叉树的遍历根据节点访问顺序不同分为以下几种
 1. 前序遍历：根节点 -> 左子树 -> 右子树
 2. 中序遍历：左子树 -> 根节点 -> 右子树(二叉搜索树的中序遍历的结果是升序或降序)
 3. 后序遍历：左子树 -> 右子树 -> 根节点
 4. 层序遍历：从上到下、从左到右依次遍历
 注意：这里的前、中、后序遍历，都是根据根节点的位置来定义的
 
 
 8.根据遍历结果重构二叉树
 以下结果可以保证重构出唯一的一棵二叉树
    前序遍历+中序遍历
    后序遍历+中序遍历
 前序遍历+后序遍历： 如果它是一棵真二叉树，结果是唯一的，不然结果不惟一

9.打印二叉树工具（OC版本地址） https://github.com/CoderMJLee/BinaryTrees
 
 

 */

import Foundation

//MARK: *********************************二叉树节点对象*********************************
//因层序遍历中用到队列，队列中需要存放BinaryTreeNode节点类型，所以BinaryTreeNode需要实现Comparable协议
public class BinaryTreeNode<T: Comparable> : Comparable{
    public static func < (lhs: BinaryTreeNode<T>, rhs: BinaryTreeNode<T>) -> Bool {
        return true
    }
    public static func == (lhs: BinaryTreeNode<T>, rhs: BinaryTreeNode<T>) -> Bool {
        return false
    }
    /// 节点元素
    var element: T
    /// 父节点
    var parent: BinaryTreeNode?
    /// 左子节点
    var left: BinaryTreeNode?
    /// 右子节点
    var right: BinaryTreeNode?
    
    init(element: T, parentNode: BinaryTreeNode?) {
        self.element = element
        self.parent = parentNode
    }
    
    /// 是否是叶子节点
    func isLeaf() -> Bool {
        return left == nil && right == nil
    }
    
    /// 是否有2个子节点(度为2的节点)
    func hasTwoChildNode() -> Bool {
        return left != nil && right != nil
    }
}



//MARK: *********************************二叉树对象*********************************
/*
  二叉树中应该包含 获取元素个数、二叉树是否为空、清空二叉树、遍历、前驱节点、后继节点、二叉树的高度
 */
public class BinaryTree<T: Comparable> : NSObject {
    /// 节点的数量
    var size = 0
    /// 根节点
    var root: BinaryTreeNode<T>?
    
    
    //MARK: 获取元素的个数
    func count() -> Int {
        return size
    }

    
    //MARK: 判断是否为空
    func isEmpty() -> Bool{
        return size == 0
    }

    
    //MARK: 清空
    func clear() {
        root = nil
        size = 0
    }
    
    
    //MARK: 前序遍历(递归) 根-左-右
    func preOrderTraverseRecursion() {
        preOrder(node: root)
    }
    private func preOrder(node: BinaryTreeNode<T>?) {
        guard root != nil else {
            return
        }
        //访问节点元素
        NSLog("\(root!.element)")
        preOrder(node: root!.left)
        preOrder(node: root!.right)
    }

    
    //MARK: 中序遍历(递归) 左-根-右
    func inOrderTraverseRecursion() {
        inOrder(node: root)
    }
    private func inOrder(node: BinaryTreeNode<T>?) {
        guard root != nil else {
            return
        }
        inOrder(node: root!.left)
        //访问节点元素
        NSLog("\(root!.element)")
        inOrder(node: root!.right)
    }

    
    //MARK: 后序遍历(递归) 左-右-根
    func postOrderTraversRecursion() {
        postOrder(node: root)
    }
    private func postOrder(node: BinaryTreeNode<T>?) {
        guard root != nil else {
            return
        }
        postOrder(node: root!.left)
        postOrder(node: root!.right)
        //访问节点元素
        NSLog("\(root!.element)")
    }
    
    
    /*
             ------8-----
             ↓          ↓
           --4--       13
          ↓     ↓
        --2--   6
       ↓     ↓
       1     3
     8  4  2  1  3  6  13
     利用栈实现（先进后出）一路向左；遇到节点就访问，并将其右节点入栈
     1. 设置node = root
     2. 循环执行如下操作
        对node进行访问；将node.right入栈； 设置node = node.left
        如果node为空；如果栈为空结束遍历；如果栈不为空，弹出栈顶元素并赋值给node
     */
    //MARK: 前序遍历(非递归)
    func preOrder() {
        guard root != nil else {
            return
        }
        //新建栈对象
        let stack = Stack<BinaryTreeNode<T>>()
        var node = root
        while true {
            if node != nil {
                NSLog("\(node!.element)")
                if node!.right != nil {
                    stack.push(element: node!.right!)
                }
                //一直向左走
                node = node?.left
            }else {
                if stack.isEmpty() {  //栈为空结束遍历
                    return
                }else { //栈不为空，重新将栈元素弹出，然后继续像根节点一样继续向它的左边走去遍历
                    node = stack.pop()
                }
            }
        }
    }
        
        
    /*
             ------8-----
             ↓          ↓
           --4--       13
          ↓     ↓
        --2--   6
       ↓     ↓
       1     3
     1   2   3   4   6   8   13
     利用栈实现（先进后出）
     1. 设置node = root
     2. 循环执行如下操作
        如果node不为空，将node入栈；设置node = node.left
        如果node为空；如果栈为空结束遍历；如果栈不为空，弹出栈顶元素并赋值给node；对node进行访问；设置node = node.right
     */
    //MARK: 中序遍历(非递归)
    func inOrder() {
        guard root != nil else {
            return
        }
        //新建栈对象
        let stack = Stack<BinaryTreeNode<T>>()
        var node = root
        while true {
            if node != nil {
                stack.push(element: node!)
                node = node?.left
            }else {
                if stack.isEmpty() {
                    return
                }else {
                    node = stack.pop()
                    NSLog("\(node!.element)")
                    node = node?.right
                }
            }
        }
    }
        
        
    /*
             ------8-----
             ↓          ↓
           --4--       13
          ↓     ↓
        --2--   6
       ↓     ↓
       1     3
     利用栈实现（先进后出）
     1. 将root入栈
     2. 循环执行如下操作，直到栈为空
        如果栈顶节点是叶子节点 或者 上一次访问的节点是栈顶节点的子节点 则弹出栈顶节点进行访问
        否则，将栈顶节点的right、left入栈
     */
    //MARK: 后序遍历(非递归)
    func postOrder() {
        guard root != nil else {
            return
        }
        //记录上一次弹出访问的节点
        var prev: BinaryTreeNode<T>?
        //新建栈对象
        let stack = Stack<BinaryTreeNode<T>>()
        stack.push(element: root!)
        // 8 13 4 6 2
        while !stack.isEmpty() {
            let topNode = stack.top()
            if topNode!.isLeaf() || (prev != nil && prev?.parent == topNode) {
                prev = stack.pop()
                //访问节点
                NSLog("\(prev!.element)")
            }else {
                if topNode!.right != nil {
                    stack.push(element: topNode!.right!)
                }
                if topNode!.left != nil {
                    stack.push(element: topNode!.left!)
                }
            }
        }
    }
        
        
    /* 实现思路: 使用队列
     1. 将根节点入队
     2.循环执行以下操作，直到队列为空
        将队头节点A出队，进行访问
        将A的左子节点入队
        将A的右子节点入队
                     ------------8------------
                     ↓                        ↓
                -----4-----              -----13
                ↓          ↓             ↓
             ---2---    ---6---       ---10---
     */
    //MARK: 层序遍历 (应用-计算二叉树的高度，判断一棵树是否为完全二叉树)
    func levelOrderTraverse() {
        guard root != nil else {
            return
        }
        // 1.创建队列
        let queue = Queue<BinaryTreeNode<T>>()
        // 2.将根节点入队
        queue.enQueue(element: root!)
        while !queue.isEmpty() {
            //队头出队  进行访问  然后将左右子节点入队
            let node = queue.deQueue()
            NSLog("\(node!.element)")
            if node!.left != nil {
                queue.enQueue(element: node!.left!)
            }
            if node!.right != nil {
                queue.enQueue(element: node!.right!)
            }
        }
    }
        
        
    //MARK: 二叉树的高度(递归)
    func heightWithRecursion() -> Int {
        return height(root)
    }
    private func height(_ node: BinaryTreeNode<T>?) -> Int {
        guard node != nil else {
            return 0
        }
        //左右子树中的最大值
        return 1 + max(height(node?.left), height(node?.right))
    }

    
    //MARK: 二叉树的高度-非递归(利用层序遍历)
    func height() -> Int {
        guard root != nil else {
            return 0
        }
        // 树的高度
        var height = 0
        // 存储每一层的元素数量
        var levelSize = 1
        // 1.创建队列
        let queue = Queue<BinaryTreeNode<T>>()
        // 2.将根节点入队
        queue.enQueue(element: root!)
        while !queue.isEmpty() {
            //队头出队  进行访问  然后将左右子节点入队
            let node = queue.deQueue()
            //每次出队，该层元素数量减少1个
            levelSize = levelSize - 1
            
            if node!.left != nil {
                queue.enQueue(element: node!.left!)
            }
            if node!.right != nil {
                queue.enQueue(element: node!.right!)
            }
            //意味着即将要访问下一层
            if levelSize == 0 {
                //遍历下一层
                height = height + 1
                //levelSize重新赋值
                levelSize = queue.count()
            }
        }
        return height
    }
    
    
    /* 如果树为空，返回false； 如果树不为空，开始层序遍历(用队列)
    如果node.left != nil,将left入队；
    如果node.left = nil && node.right != nil,返回false
    如果node.right != nil,将right入队；
    如果node.right = nil,那么后面遍历的所有节点都是叶子节点才是完全二叉树，否则不是完全二叉树
    遍历结束返回true
     */
    //MARK: 是否是完全二叉树
    func isCompleteBinaryTree() -> Bool {
        guard root != nil else {
            return false
        }
        // 1.创建队列
        let queue = Queue<BinaryTreeNode<T>>()
        // 2.将根节点入队
        queue.enQueue(element: root!)
        // 是否是叶子节点
        var leaf = false
        while !queue.isEmpty() {
            //队头出队  进行访问  然后将左右子节点入队
            let node = queue.deQueue()
            //要求是叶子节点，但是不是叶子节点，直接返回false
            if leaf && !node!.isLeaf() {
                return false
            }
            
            if node?.left != nil {
                queue.enQueue(element: node!.left!)
            }else { // node.left == nil
                if node?.right != nil {
                    return false
                }
            }
            
            if node!.right != nil {
                queue.enQueue(element: node!.right!)
            }else { // node.right == nil
                //后面遍历的应该都是叶子节点
                leaf = true
            }
        }
        return true
    }
    
    
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
    2.如果node.left == nil && node.parent != nil,predecessor = node.parent.parent.parent...,终止条件:node在parent的右子树中
      7的前驱节点就是6， 11的前驱节点就是10
    3.如果node.left == nil && node.parent == nil,那就没有前驱节点
     */
    //MARK: 获取指定节点的前驱节点
    func precursor(node: BinaryTreeNode<T>?) -> BinaryTreeNode<T>? {
        guard node != nil else {
            return nil
        }
        // 1. 前驱节点在左子树上  若左节点不为空，则一直找它的right（prev = node.left.right.right...）
        var prevNode = node!.left
        if prevNode != nil {
            while prevNode?.right != nil {
                prevNode = prevNode?.right
            }
            return prevNode  //如果prevNode.right = nil,则这个就是前驱节点
        }
        
        var baseNode = node  //需要修改函数参数node的值，不想添加inout，所以先用个临时变量来接收
        // 若左子树为nil,则开始判断节点的父节点
        while (baseNode?.parent != nil && baseNode == baseNode?.parent?.left) {
            baseNode = baseNode?.parent
        }
        return baseNode?.parent
    }

    
    /* 后继节点: 中序遍历时的后一个节点,如果是二叉搜索树，前驱节点就是最后一个比它大的节点
     1.如果node.right != nil, successor = node.right.left.left...,终止条件: left为nil
     2.如果node.right == nil && node.parent != nil,successor = node.parent.parent...,终止条件: node在parent的左子树中
     3.如果node.right == nil && node.parent == nil,那就没有后继节点(例如没有右子树的根节点)
     */
    //MARK: 获取指定节点的后继节点
    func successor(node: BinaryTreeNode<T>?) -> BinaryTreeNode<T>? {
        guard node != nil else {
            return nil
        }
        //1. 后继节点一定是在node的右子树上，并且是第一个比node大的节点，即node.right.left.left
        var sucNode = node?.left
        if sucNode != nil {
            while sucNode?.left != nil {
                sucNode = sucNode?.left
            }
            return sucNode
        }
        var baseNode = node //需要修改函数参数node的值，不想添加inout，所以先用个临时变量来接收
        // 若左子树为nil,则开始判断节点的父节点
        while baseNode?.parent != nil && baseNode == baseNode?.parent?.right {
            baseNode = baseNode?.parent
        }
        return baseNode?.parent
    }
    

}
