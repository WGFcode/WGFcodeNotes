//
//  LeetCodeInvertTree.swift
//  appName
//
//  Created by 白菜 on 2021/12/4.
//  Copyright © 2021 baicai. All rights reserved.
//
/* https://leetcode-cn.com/problems/invert-binary-tree/
 226. 翻转二叉树 保证所有节点的左右子树交换位置
 */
import Foundation
import CoreVideo

//树
public class TreeNode {
     public var val: Int
     public var left: TreeNode?
     public var right: TreeNode?
     public init() {
         self.val = 0
         self.left = nil
         self.right = nil
     }
     public init(_ val: Int) {
         self.val = val
         self.left = nil
         self.right = nil
     }
     public init(_ val: Int, _ left: TreeNode?, _ right: TreeNode?) {
         self.val = val
         self.left = left
         self.right = right
     }
 }
//链表
public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init() {
        self.val = 0;
        self.next = nil;
    }
    public init(_ val: Int) {
        self.val = val;
        self.next = nil;
    }
    public init(_ val: Int, _ next: ListNode?) {
        self.val = val;
        self.next = next;
    }
}



class Solution {
    /*
     226. 翻转二叉树
     https://leetcode-cn.com/problems/invert-binary-tree/
     */
    //方案一: 前序遍历思想
    @discardableResult
    func invertTree1(_ root: TreeNode?) -> TreeNode? {
        if root == nil {
            return root
        }
        //前序遍历 遍历到元素后交换左右子节点的位置
        let tempNode = root?.left
        root?.left = root?.right
        root?.right = tempNode
        
        //这里已经交换位置了，下面的代码不会影响吗？ 不会的，因为下面的只是遍历顺序不一样而已（变成了先遍历右再遍历左，但结果还是前序遍历）
        invertTree1(root?.left)
        invertTree1(root?.right)
        return root
    }
    //方案二: 后序遍历思想
    @discardableResult
    func invertTree2(_ root: TreeNode?) -> TreeNode? {
        if root == nil {
            return root
        }
        invertTree2(root?.left)
        invertTree2(root?.right)
        
        //后续遍历 遍历到元素后交换左右子节点的位置
        let tempNode = root?.left
        root?.left = root?.right
        root?.right = tempNode
        return root
    }
    //方案三: 中序遍历思路
    func invertTree3(_ root: TreeNode?) -> TreeNode? {
        if root == nil {
            return root
        }
        _ = invertTree3(root?.left)
        
        //后续遍历 遍历到元素后交换左右子节点的位置
        let tempNode = root?.left
        root?.left = root?.right
        root?.right = tempNode
        //⚠️这里需要注意，前面已经交换了左右位置，所以不能再写root?.right，而是root?.left
        _ = invertTree3(root?.left)
        return root
    }
    //方案四:层序遍历
    func invertTree4(_ root: TreeNode?) -> TreeNode? {
        if root == nil {
            return root
        }
        //模拟队列 先进先出
        var queue = [TreeNode]()
        //将根节点入队
        queue.append(root!)
        while !queue.isEmpty {
            //将根节点出队
            let node = queue.removeFirst()
            // 进行交换左右子节点
            let temp = node.left
            node.left = node.right
            node.right = temp
            //左右子树不为空，则入队列
            if node.left != nil {
                queue.append(node.left!)
            }
            if node.right != nil {
                queue.append(node.right!)
            }
        }
        return root
    }
    
    
    /*
     1. 144.二叉树的前序遍历(给你二叉树的根节点 root ，返回它节点值的 前序 遍历)
     https://leetcode-cn.com/problems/binary-tree-preorder-traversal/
     给你二叉树的根节点 root ，返回它节点值的 前序 遍历。
     树中节点数目在范围 [0, 100] 内
     -100 <= Node.val <= 100
     根 左 右
     [1,null,2,3]
     */
    func preorderTraversal(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        arr.append(roo.val)
        arr += preorderTraversal(roo.left)
        arr += preorderTraversal(roo.right)
        return arr
    }
    func preorderTraversal1(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        //模拟栈
        var stack = [TreeNode]()
        var node: TreeNode? = roo
        while true {
            if node != nil {
                //访问
                arr.append(node!.val)
                if node!.right != nil {
                    stack.append(node!.right!)
                }
                //一直向左
                node = node!.left
            }else {
                if stack.isEmpty {
                    return arr
                }else {
                    node = stack.popLast()
                }
            }
        }
    }
    
    
    /*
     94. 二叉树的中序遍历(给定一个二叉树的根节点 root ，返回它的 中序 遍历。)
     https://leetcode-cn.com/problems/binary-tree-inorder-traversal/
     */
    func inorderTraversal(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        arr = arr + inorderTraversal(roo.left)
        arr.append(roo.val)
        arr = arr + inorderTraversal(roo.right)
        return arr
    }
    func inorderTraversal1(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        //模拟栈 遇到节点就入栈
        //模拟栈
        var stack = [TreeNode]()
        var node: TreeNode? = roo
        while true {
            if node != nil { //不为空，入栈，继续向左
                stack.append(node!)
                node = node?.left
            }else {
                if stack.isEmpty { //栈为空返回
                    return arr
                }else {
                    //弹出栈顶元素访问 然后让node = node.right
                    node = stack.popLast()
                    arr.append(node!.val)
                    node = node!.right
                }
            }
        }
    }
    
    
    /*
     145. 二叉树的后序遍历(给定一个二叉树，返回它的 后序 遍历。)
     https://leetcode-cn.com/problems/binary-tree-postorder-traversal/
     */
    //方案一
    func postorderTraversal(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        arr = arr + postorderTraversal(roo.left)
        arr = arr + postorderTraversal(roo.right)
        arr.append(roo.val)
        return arr
    }
    /*
             ------8-----
             ↓          ↓
           --4--       13
          ↓     ↓
        --2--   6
       ↓     ↓
       1     3
     利用栈实现（先进后出） 1 3 2 6 4 13 8
     */
    //方案二
    func postorderTraversal1(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        //模拟栈
        var stack = [TreeNode]()
        var node: TreeNode? = roo
        while !stack.isEmpty || node != nil {
            if node != nil {
                arr.insert(node!.val, at: 0)
                stack.append(node!)
                node = node!.right
            }else {
                node = stack.removeLast().left
            }
        }
        return arr
    }
    //方案三
    func postorderTraversal2(_ root: TreeNode?) -> [Int] {
        var arr = [Int]()
        guard let roo = root else {
            return arr
        }
        //1. 将根节点入栈
        var stack = [TreeNode]()
        stack.append(roo)
        //2.记录上次弹出访问的节点
        var prev: TreeNode?
        
        while !stack.isEmpty {
            //偷偷看一眼栈顶元素，如果栈顶元素的右左子树不为空，则入栈
            let topNode = stack[stack.count-1]
            //如果该节点是叶子节点，则弹出访问；或者该节点是上一次弹出节点的父节点，则弹出访问
            if (topNode.left == nil && topNode.right == nil) || (prev != nil && (prev?.val == topNode.left?.val || prev?.val == topNode.right?.val)) { //叶子节点
                prev = stack.popLast()
                //访问节点
                arr.append(prev!.val)
            }else {
                if topNode.right != nil {
                    stack.append(topNode.right!)
                }
                if topNode.left != nil {
                    stack.append(topNode.left!)
                }
            }
        }
        return arr
    }
    
    
    /*
     102. 二叉树的层序遍历(给你一个二叉树，请你返回其按 层序遍历 得到的节点值。 （即逐层地，从左到右访问所有节点）)
     https://leetcode-cn.com/problems/binary-tree-level-order-traversal/
          ------1-----
          ↓          ↓
        --2--      --3--
             ↓          ↓
             4          5
    */
    func levelOrder(_ root: TreeNode?) -> [[Int]] {
        var arr = [[Int]]()
        guard let roo = root else {
            return arr
        }
        //模拟栈
        var stack = [TreeNode]()
        //将根节点入栈
        stack.append(roo)
        //存放当前层元素的数组
        var levelArr = [Int]()
        //当前层节点的数量
        var levelSize = 1
        while !stack.isEmpty {
            //出栈访问
            let node = stack.removeFirst()
            levelArr.append(node.val)
            //出栈后，该层元素数量要-1
            levelSize = levelSize - 1
            //将左右节点入栈
            if node.left != nil {
                stack.append(node.left!)
            }
            if node.right != nil {
                stack.append(node.right!)
            }
            //如果 levelSize = 0 说明该层已经访问完了，下一层元素数量就是战中元素的数量
            if levelSize == 0 {
                arr.append(levelArr)
                levelSize = stack.count
                levelArr.removeAll()
            }
        }
        return arr
    }
    /*
     107. 二叉树的层序遍历 II(给定一个二叉树，返回其节点值自底向上的层序遍历。 （即按从叶子节点所在层到根节点所在的层，逐层从左向右遍历）)
     https://leetcode-cn.com/problems/binary-tree-level-order-traversal-ii/
     */
    func levelOrderBottom(_ root: TreeNode?) -> [[Int]] {
        var arr = [[Int]]()
        guard let roo = root else {
            return arr
        }
        //模拟栈
        var stack = [TreeNode]()
        //将根节点入栈
        stack.append(roo)
        //当前层节点的数量
        var levelSize = 1
        //存放当前层元素的数组
        var levelArr = [Int]()
        while !stack.isEmpty {
            //出栈访问
            let node = stack.removeFirst()
            levelArr.append(node.val)
            //出栈后，该层元素数量要-1
            levelSize = levelSize - 1
            //将左右节点入栈
            if node.left != nil {
                stack.append(node.left!)
            }
            if node.right != nil {
                stack.append(node.right!)
            }
            //如果 levelSize = 0 说明该层已经访问完了，下一层元素数量就是战中元素的数量
            if levelSize == 0 {
                //这里每次都将访问的层添加到数组的最前面
                arr.insert(levelArr, at: 0)
                levelSize = stack.count
                levelArr.removeAll()
            }
        }
        return arr
    }
    
    
    /*
     104. 二叉树的最大深度(给定一个二叉树，找出其最大深度。二叉树的深度为根节点到最远叶子节点的最长路径上的节点数。)
     https://leetcode-cn.com/problems/maximum-depth-of-binary-tree/
     */
    
    func maxDepth1(_ root: TreeNode?) -> Int {
        //最大深度 其实就是左右子树中的最大深度 + 1
        return root == nil ? 0 : max(maxDepth1(root?.left), maxDepth1(root?.right)) + 1
    }
    func maxDepth2(_ root: TreeNode?) -> Int {
        var deep = 0
        guard let roo = root else {
            return deep
        }
        var stack = [TreeNode]()
        stack.append(roo)
        var levelSize = 1
        while !stack.isEmpty {
            let node = stack.removeFirst()
            levelSize = levelSize - 1
            if node.left != nil {
                stack.append(node.left!)
            }
            if node.right != nil {
                stack.append(node.right!)
            }
            if levelSize == 0 {
                deep += 1
                levelSize = stack.count
            }
        }
        return deep
    }
    
    
    /*
     101. 对称二叉树
     https://leetcode-cn.com/problems/symmetric-tree/
     */
    //方案一:递归方式
    func isSymmetric1(_ root: TreeNode?) -> Bool {
        guard let roo = root else {
            return true
        }
        
        return compare(roo.left, rightNode: roo.right)
    }
    private func compare(_ leftNode: TreeNode?, rightNode: TreeNode?) -> Bool {
        if leftNode == nil {
            return rightNode == nil
        }
        //左子节点不为nil;去判断右子节点
        guard rightNode != nil else {
            return false
        }
        //左右都不为nil;判断左右节点的值是否相等
        guard leftNode!.val == rightNode!.val else {
            return false
        }
        //左右子树如果相等,则继续判断它的下一个节点的左右子树是否相等
        return compare(leftNode!.left, rightNode: rightNode!.right) && compare(leftNode!.right, rightNode: rightNode!.left)
    }
    /*
      1
     / \
    2   2
   / \ / \
  3  4 5  3
     */
    //方案二:迭代 思路：将元素按照预设顺序放入队列(最左最右节点入队顺序紧挨着)，然后每次出队列两个元素，比较这两个元素是否相等
    func isSymmetric2(_ root: TreeNode?) -> Bool {
        guard let roo = root else {
            return true
        }
        //模拟队列 先进先出
        var queue = [TreeNode?]()
        //将根节点的左右子节点入队
        queue.append(roo.left)
        queue.append(roo.right)
        // 【left,right】
        while !queue.isEmpty {
            //出队两个元素
            var n1 = queue.removeFirst()  //当初的left节点
            var n2 = queue.removeFirst()  //当初的right节点
            //必须判断，题目描述中是可能有nil节点的；若取出的两个元素都为nil，则进行下一轮循环判断
            //如果没有这个判断会陷入死循环
            if n1 == nil && n2 == nil {
                continue
            }
            // n1 n2不全为nil; 判断两个节点的值是否相等，若不相等，则直接返回false，终止循环
            if n1?.val != n2?.val {
                return false
            }
            //如果两个节点的值相等，则将两个节点的左右子树继续入队列，但是要注意顺序,先将最左最右的节点入队，为了出队时用来比较
            queue.append(n1?.left)
            queue.append(n2?.right)
            queue.append(n1?.right)
            queue.append(n2?.left)
        }
        return true
    }
    
    
    /*
     106. 从中序与后序遍历序列构造二叉树
     https://leetcode-cn.com/problems/construct-binary-tree-from-inorder-and-postorder-traversal/
     中序遍历 inorder = [9,3,15,20,7]  左根右
     后序遍历 postorder = [9,15,7,20,3]  左右根
           3
        9     20
            15   7
     */
    func buildTree(_ inorder: [Int], _ postorder: [Int]) -> TreeNode? {
        return build(inorder: inorder,inStart: 0, inEnd: inorder.count - 1, postorder: postorder, postEnd: postorder.count - 1)
    }
    private func build(inorder:[Int], inStart:Int, inEnd: Int, postorder:[Int], postEnd: Int) -> TreeNode? {
        //若数组下标不符，则直接返回
        if inStart > inEnd {
            return nil
        }
        //创建根节点  根节点一定是后序遍历数组元素中的最后一位元素
        let rootValue = postorder[postEnd]
        let root = TreeNode.init(rootValue)
        //然后开始从中序遍历数组中找到根节点的位置
        var k = 0  //根节点在中序遍历数组中的下标
        for i in 0..<inorder.count {
            if inorder[i] == rootValue {
                k = i
                break
            }
        }
        //中序遍历 inorder = [9,3,15,20,7]  左根右     9    3          15 20 7
        //后序遍历 postorder = [9,15,7,20,3]  左右根   9    15 7 20    3
        // k = 1
        /*
         通过根节点下标，可以在中序遍历中区分左子树【0，k-1】、右子树[k+1,inEnd]的边界
         后序遍历数组是按照左右根存放的，所以可以找到左子树后序遍历的结束位置：
         postEnd - 右子树节点的数量 - 第一个根节点
         */
        let left = build(inorder: inorder, inStart: inStart, inEnd: k-1, postorder: postorder, postEnd: postEnd-(inEnd-k)-1)
        /*
         通过根节点下标，可以在中序遍历中区分左子树【0，k-1】、右子树[k+1,inEnd]的边界
         后序遍历数组是按照左右根存放的，所以可以找到右子树后序遍历的结束位置：
         postEnd - 第一个根节点
         */
        let right = build(inorder: inorder, inStart: k+1, inEnd: inEnd, postorder: postorder, postEnd: postEnd-1)
        root.left = left
        root.right = right
        return root
    }
    
    
    /*
     105. 从前序与中序遍历序列构造二叉树
     https://leetcode-cn.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/
     前序:[3,9,20,15,7]  根左右
     中序: [9,3,15,20,7] 左根右
     */
    func buildTree1(_ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
        return build1(preorder: preorder, preStart: 0, preEnd: preorder.count-1 , inorder: inorder, inStart: 0, inEnd: inorder.count-1)
    }
    private func build1(preorder:[Int], preStart: Int, preEnd: Int, inorder:[Int],inStart:Int, inEnd: Int) -> TreeNode? {
        //若数组下标不符，则直接返回
        if preStart > preEnd {
            return nil
        }
        //找到根节点 根节点就是前序遍历数组中的的第一个元素
        let rootValue = preorder[preStart]
        let root = TreeNode(rootValue)
        
        //从中序遍历数组中找到根节点的下标
        var k = 0
        for i in 0..<inorder.count {
            if inorder[i] == rootValue {
                k = i
                break
            }
        }
        //左子树节点的数量 k = 1
        let leftCount = k - inStart //1
        let left = build1(preorder: preorder, preStart: preStart+1, preEnd: preStart+leftCount, inorder: inorder, inStart: inStart, inEnd: k-1)
        let right = build1(preorder: preorder, preStart: preStart+leftCount+1, preEnd: preEnd, inorder: inorder, inStart: k+1, inEnd: inEnd)
        root.left = left
        root.right = right
        return root
    }
    
    /*
     88. 合并两个有序数组
     https://leetcode-cn.com/problems/merge-sorted-array/
     
     nums1 = [1], m = 1, nums2 = [], n = 0
     */
    func merge(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        //合并数组
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + m
        //1.冒泡排序
        for end in (0..<count).reversed() {
            //第一轮循环可以找到最大的值
            //1...4
            for i in 0..<end {
                if nums1[i] > nums1[i+1] {
                    //交换位置
                    let temp = nums1[i]
                    nums1[i] = nums1[i+1]
                    nums1[i+1] = temp
                }
            }
        }
    }
    //1.冒泡排序-优化版
    func merge1(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        //合并数组
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + m
        for end in (0..<count).reversed() {
            //默认已经排好序了
            var hasSort = true
            //第一轮循环可以找到最大的值
            for i in 0..<end {
                if nums1[i] > nums1[i+1] {
                    //交换位置
                    let temp = nums1[i]
                    nums1[i] = nums1[i+1]
                    nums1[i+1] = temp
                    hasSort = false
                }
            }
            //如果经过一轮排序后，没有发生任何元素交换位置，则认为是已经排序好了，直接结束循环
            if hasSort {
                return
            }
        }
    }
    //2.冒泡排序-优化版 如果数据序列尾部已经局部有序，可以记录最后一次交换的位置，来减少比较次数
    func merge2(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        //合并数组
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + m
        for var end in (0..<count).reversed() {
            var sortIndex = 1
            //第一轮循环可以找到最大的值
            for i in 0..<end {
                if nums1[i] > nums1[i+1] {
                    //交换位置
                    let temp = nums1[i]
                    nums1[i] = nums1[i+1]
                    nums1[i+1] = temp
                    //一旦发生位置交换就保存下下标位置
                    sortIndex = i
                }
            }
            //下次循环从开头位置到sortIndex位置进行循环就行，sortIndex位置后的数据已经排好序了
            end = sortIndex
        }
    }
    //3. 选择排序 从序列中找出最大的那个元素，然后与最末尾的元素交换位置，执行完第一轮后，最末尾的元素就是最大的元素,然后重复执行
    func merge3(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + n
        for end in (1..<count).reversed() {
            //找到最大的值,和最后一位进行交换
            var maxIndex = 0
            for i in 1...end {
                if nums1[maxIndex] < nums1[i] {
                    maxIndex = i
                }
            }
            let temp = nums1[end]
            nums1[end] = nums1[maxIndex]
            nums1[maxIndex] = temp
        }
    }
    //4. 插入排序  插入排序会将序列分为两部分: 头部是已经排好序的，尾部是待排序的
    //从头开始扫描每一个元素，每当扫描到一个元素，就将它插入到头部合适的位置，使得头部数据依然保持有序
    func merge4(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + n
        //这里默认nums[0]是已经排序序的序列
        for i in 1..<count {
            //已经排好序的序列的结束下标
            var cur = i
            while cur > 0 && (nums1[cur-1] > nums1[cur]) {
                //左边比右边的元素大，交换元素位置
                let temp = nums1[cur-1]
                nums1[cur-1] = nums1[cur]
                nums1[cur] = temp
                cur = cur - 1
            }
        }
    }
    
    // 插入排序-优化版（交换元素->移动元素）
    func merge5(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        //合并数组
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + n
        //这里默认nums[0]是已经排序序的序列
        for i in 1..<count {
            //已经排好序的序列的结束下标
            var cur = i
            //先备份待插入的元素
            let waitInsert = nums1[cur]
            //如果待插入的元素比前面元素小，那么就让前面元素向后移动一位
            while cur > 0 && (nums1[cur-1] > waitInsert) {
                nums1[cur] = nums1[cur-1]
                cur = cur - 1
            }
            nums1[cur] = waitInsert
        }
    }
    
    /* 快速排序-1.从序列中选择一个轴点（假设0位置作为轴点）2.利用轴点将序列分成2部分(小于在左边大于在右边等于在那边都可以)，对12步继续进行操作，直到不能再次分割位置
    快速排序的本质就是：逐渐将每个元素都转为轴点元素
     */
    func merge6(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        //合并数组
        for i in 0..<n {
            nums1[m+i] = nums2[i]
        }
        let count = m + n
        quickSort(&nums1, begin: 0, end: count)
    }
    private func quickSort(_ arr: inout [Int], begin: Int, end: Int) {
        if (end - begin < 2) { //(end-begin=元素的个数)
            return;
        }
        let mid = getZhouPointIndex(&arr, begin: begin, end: end)
        //对子序列进行快速排序
        quickSort(&arr, begin: begin, end: mid)
        quickSort(&arr, begin: mid+1, end: end)
    }
    // 获取[begin, end)轴点元素
    private func getZhouPointIndex(_ arr: inout [Int],begin: Int, end: Int) -> Int {
        //轴点元素值
        let pointElement = arr[begin]
        var starIndex = begin
        //endIndex指向最后一个元素的下标
        var endIndex = end - 1
        
        while starIndex < endIndex {
            //从右开始和轴点元素进行比较
            while starIndex < endIndex {
                //右边元素 > 轴点元素, 将元素放在轴点的右边，刚好就在右边，所以不用动，继续下一个元素对比
                if pointElement < arr[endIndex] {
                    endIndex = endIndex - 1
                }else { //右边元素 <= 轴点元素,让右边元素占居当前轴点位置的元素,之前轴点位置元素是被覆盖了，
                    //但是我们已经备份过了pivotElement，所以不用担心，此时end位置应该已经空置出来了，然后让begin++
                    //然后结束此次循环，开始从左边元素开始和轴点元素进行对比
                    arr[starIndex] = arr[endIndex]
                    starIndex = starIndex + 1
                    break
                }
            }
            //从左开始和轴点元素对比
            while starIndex < endIndex {
                //左边元素 < 轴点元素，则该元素位置不需要改动，将start向前移动继续进行比较
                if pointElement > arr[starIndex]  {
                    starIndex = starIndex + 1
                }else { // 左边元素 >= 轴点元素,则将该元素放到最右边(endIndex)位置,然后将end向前一位
                    //结束循环，让序列开始从右边开始和轴点元素对比
                    arr[endIndex] = arr[starIndex]
                    endIndex = endIndex - 1
                    break
                }
            }
        }
        //循环结束后，starIndex = endIndex,此时starIndex(endIndex)就是轴点元素的位置
        //将轴点元素放入轴点位置
        arr[starIndex] = pointElement
        return starIndex
    }
    
    /*
     98. 验证二叉搜索树
     https://leetcode-cn.com/problems/validate-binary-search-tree/
     有效 二叉搜索树定义如下：
         节点的左子树只包含 小于 当前节点的数。
         节点的右子树只包含 大于 当前节点的数。
         所有左子树和右子树自身必须也是二叉搜索树。
            5
        1       4
              3   6
     */   //[5,1,4,null,null,3,6]
    //方案一：二叉搜索树中序遍历是有序数组，若有序则表示是二叉搜索树 左根右
    //思路: 从根节点一路向左，将节点入栈，找到最左的节点，然后弹出栈顶元素进行访问，然后让右子节点重新循环上面的步骤
    func isValidBST(_ root: TreeNode?) -> Bool {
        if root == nil {
            return true
        }
        //中序遍历 将根节点入栈
        var arr = [Int]()
        //模拟栈
        var stack = [TreeNode]()
        var node: TreeNode? = root
        while true {
            if node != nil {
                //将根节点入栈
                stack.append(node!)
                //一路向左
                node = node!.left
            }else {
                if !stack.isEmpty {
                    //弹出栈顶元素访问
                    node = stack.popLast()
                    arr.append(node!.val)
                    //处理右子节点
                    node = node!.right
                }else {
                    break
                }
            }
        }
        //对arr进行判断是否是完全递增的顺序
        for i in 1..<arr.count {
            
            if arr[i] <= arr[i-1] {
                return false
            }
        }
        return true
    }
    //方案二： 递归
    func isValidBST1(_ root: TreeNode?) -> Bool {
        return isValidBSTRecursive(root, leftMin: Int.min, rightMax: Int.max)
    }
    private func isValidBSTRecursive(_ node: TreeNode?, leftMin: Int, rightMax: Int) -> Bool {
        guard let baseNode = node else {
            return true
        }
        //左节点 < 根节点的值  右节点 > 根节点的值
        guard leftMin < baseNode.val  && rightMax > baseNode.val else {
            return false
        }
        //判断左子树是否是完全二叉树： 根节点: baseNode.left  最小值:Int.min 最大值肯定要小于上一个根节点：baseNode.val
        let leftValidBST = isValidBSTRecursive(baseNode.left, leftMin: leftMin, rightMax: baseNode.val)
        //判断右子树是否是完全二叉树： 根节点: baseNode.right  最小值肯定要大于上个根节点的值:baseNode.val   最大值:Int.max
        let rightValidBST = isValidBSTRecursive(baseNode.right, leftMin: baseNode.val, rightMax: rightMax)
        return leftValidBST && rightValidBST
    }
    
    /*
     876. 链表的中间结点
     https://leetcode-cn.com/problems/middle-of-the-linked-list/
     给定一个头结点为 head 的非空单链表，返回链表的中间结点。
     如果有两个中间结点，则返回第二个中间结点。
     给定链表的结点数介于 1 和 100 之间
     */
    func middleNode(_ head: ListNode?) -> ListNode? {
        if head == nil || head?.next == nil {
            return head
        }
        //遍历链表找到结点数量count
        var baseHead = head
        var count = 0
        var arr = [ListNode]()
        while baseHead != nil {
            arr.append(baseHead!)
            baseHead = baseHead!.next
            count = count + 1
        }
        //取中间节点的下标，遍历找到中间节点
        let endIndex = count % 2 == 0 ? count / 2 : count / 2
        return arr[endIndex]
    }
    //方案二
    func middleNode1(_ head: ListNode?) -> ListNode? {
        if head == nil || head?.next == nil {
            return head
        }
        var arr = [ListNode]()
        var baseHead = head
        while baseHead != nil {
            arr.append(baseHead!)
            baseHead = baseHead!.next
        }
        return arr[arr.count / 2]
    }
    //方案三: 快慢指针 用两个指针 slow 与 fast 一起遍历链表。
    //slow 一次走一步，fast 一次走两步。那么当 fast 到达链表的末尾时，slow 必然位于中间。
    func middleNode2(_ head: ListNode?) -> ListNode? {
        if head == nil || head?.next == nil {
            return head
        }
        var slow = head
        var fast = head
        
        while fast != nil && fast?.next != nil {
            slow = slow?.next
            fast = fast?.next?.next
        }
        return slow
    }
    
    
    /*
     02.01. 移除重复节点 编写代码，移除未排序链表中的重复节点。保留最开始出现的节点。
     https://leetcode-cn.com/problems/remove-duplicate-node-lcci/
     链表长度在[0, 20000]范围内。
     链表元素在[0, 20000]范围内。
     [1,1,2]
    */
    func removeDuplicateNodes(_ head: ListNode?) -> ListNode? {
        if head == nil || head?.next == nil {
            return head
        }
        //将头节点插入到set集合中
        var set:Set<Int> = []
        var baseNode = head
        set.insert(baseNode!.val)
        //遍历链表
        while baseNode?.next != nil {
            //若集合中包含该元素，则删除该元素对应的节点
            if set.contains((baseNode?.next?.val)!) {
                baseNode?.next = baseNode?.next?.next
            }else {
                set.insert((baseNode?.next?.val)!)
                baseNode = baseNode?.next
            }
        }
        return head
    }
    
}


