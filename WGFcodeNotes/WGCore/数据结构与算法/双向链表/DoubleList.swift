//
//  DoubleList.swift
//  appName
//
//  Created by 白菜 on 2021/12/17.
//  Copyright © 2021 baicai. All rights reserved.
//

import Foundation

public class DoubleListNode<T: Comparable> {
    /// 存储的节点元素
    var val: T
    /// 上一个节点
    var prev: DoubleListNode?
    /// 下一个节点
    var next: DoubleListNode?
    
    init(_ val: T, _ prev: DoubleListNode?, _ next: DoubleListNode?) {
        self.val = val
        self.prev = prev
        self.next = next
    }
}



//MARK: *********************************双向链表*********************************
public class DoubleList<T: Comparable> {
    
    /// 链表中元素个数
    var size: Int = 0
    /// 指向第一个结点 头结点
    var first: DoubleListNode<T>?
    /// 指向最后一个结点 尾结点
    var last: DoubleListNode<T>?
    
    
    /// 获取链表中元素的个数
    func count() -> Int {
        return size
    }
    
    /// 判断数组是否为空
    func isEmpty() -> Bool {
        return size == 0
    }
    
    /// 判断是否包含某个元素
    func contains(_ val: T) -> Bool {
        return indexOf(val: val) != ELEMENT_NOT_FOUND
    }
    
    /// 添加元素到链表
    func add(val: T) {
        add(val: val, index: size)
    }
    
    /// 向指定位置添加元素
    func add(val: T, index: Int) {
        checkIndexValid_add(index: index)
        if index == size { //向最后面添加元素
            //创建节点
            let oldLast = last
            last = DoubleListNode.init(val, oldLast, nil)
            if oldLast == nil {  //链表添加的第一个元素
                first = last
            }else {
                oldLast?.next  = last
            }
        }else {
            //新添加元素的下一个节点
            let nextNode = getNodeWithIndex(index: index)
            let prevNode = nextNode?.prev
            //创建节点
            let newNode = DoubleListNode.init(val, prevNode, nextNode)
            //让下个节点的prev指向新建的节点
            nextNode?.prev = newNode
            // 让上一个节点的 next指向新建的节点
            if prevNode == nil { // index = 0
                first = newNode
            }else {
                prevNode?.next = newNode
            }
        }
        size += 1
    }
    
    
    /// 获取index位置的元素
    func get(index: Int) -> T? {
        return getNodeWithIndex(index: index)?.val
    }
    
    /// 设置index位置的元素,并返回被覆盖的元素值
    func setValue(val: T, index: Int) -> T? {
        //原来的节点
        let oldNode = getNodeWithIndex(index: index)
        let oldNodeVal = oldNode?.val
        //新的元素覆盖之前的元素
        oldNode?.val = val
        return oldNodeVal
    }
    
    /// 删除index位置的元素,并返回删除的元素
    func remove(index: Int) -> T? {
        checkIndexValid(index: index)
        let node = getNodeWithIndex(index: index)
        let prevNode = node?.prev
        let nextNode = node?.next
        if prevNode == nil { // index = 0
            first = nextNode
        }else {
            prevNode?.next = nextNode
        }
        if nextNode == nil { // index = size - 1
            last = prevNode
        }else {
            nextNode?.prev = prevNode
        }
        size -= 1
        return node?.val
    }
    
    /// 删除指定元素
    func removeValue(val: T) {
        //先找到元素的下标
        let index = indexOf(val: val)
        // 若能找到下标则进行删除操作
        if index != ELEMENT_NOT_FOUND {
            _ = remove(index: index)
        }else {
            NSLog("无法删除:链表中找不到对应的元素:\(val)")
        }
    }
    
    /// 查看元素的位置
    func indexOf(val: T) -> Int {
        //从first链表开头开始遍历，查找相同的元素
        var node = first
        for i in 0..<size {
            if node?.val == val {
                return i
            }
            node = node?.next
        }
        return ELEMENT_NOT_FOUND
    }
    
    /// 清除所有的元素
    func clear() {
        size = 0
        first = nil
        last = nil
    }
    
    /// 打印链表中内容
    func printListElement() {
        var node = first
        var str = "["
        if (size > 0) {
            for _ in 0..<size {
                if let n = node {
                    str = str + "   "
                    str = str + "\(n.prev == nil ? "nil" : String(describing:n.prev!.val))"
                    str = str + "_\(String(describing: n.val))"
                    str = str + "_\(n.next == nil ? "nil" : String(describing:n.next!.val))"
                }
                node = node?.next
            }
        }
        str += "]"
        NSLog("链表中元素个数:\(size)----元素内容:\(str)")
    }
    
    //MARK: 获取index位置的结点SingleListNode
    private func getNodeWithIndex(index: Int) -> DoubleListNode<T>? {
        checkIndexValid(index: index)
        // 判断index是靠近左边还是靠近右边
        if (index < (size >> 1)) { //靠近左边
            var node: DoubleListNode<T>? = first
            for _ in 0..<index {
                node = node?.next
            }
            return node
        }else { //靠近右边
            var node: DoubleListNode<T>? = last
            //for (int i = size - 1; i > index; i--)
            for _ in (index+1..<size).reversed() {
                node = node?.prev
            }
            return node
        }
    }
    
    /// 检查index的有效性 index >= 0 && index <= size
    private func checkIndexValid(index: Int) {
        //断言 若条件不满足则会触发断言
        assert(index >= 0 && index < size, "index is invalid: index:\(index) size:\(size)")
    }
    
    /// 检查index的有效性 index >= 0 && index <= size
    private func checkIndexValid_add(index: Int) {
        //断言 若条件不满足则会触发断言
        assert(index >= 0 && index <= size, "index is invalid: index:\(index) size:\(size)")
    }
}



//MARK: *********************************双向循环链表*********************************
public class DoubleCycleList<T: Comparable> {
    /// 链表中元素个数
    var size: Int = 0
    /// 指向第一个结点 头结点
    var first: DoubleListNode<T>?
    /// 指向最后一个结点 尾结点
    var last: DoubleListNode<T>?
    

    /// 获取链表中元素的个数
    func count() -> Int {
        return size
    }
    
    /// 判断数组是否为空
    func isEmpty() -> Bool {
        return size == 0
    }
    
    /// 判断是否包含某个元素
    func contains(_ val: T) -> Bool {
        return indexOf(val: val) != ELEMENT_NOT_FOUND
    }
    
    /// 添加元素到链表
    func add(val: T) {
        add(val: val, index: size)
    }
    
    //⚠️循环链表和非循环链包差异地方 添加和删除
    /// 向指定位置添加元素
    func add(val: T, index: Int) {
        checkIndexValid_add(index: index)
        if index == size { //向最后面添加元素
            //创建节点
            let oldLast = last
            last = DoubleListNode.init(val, oldLast, first)
            if oldLast == nil {  //链表添加的第一个元素
                first = last
                first?.prev = first
                first?.next = first
            }else {
                oldLast?.next  = last
                first?.prev = last
            }
        }else {
            //新添加元素的下一个节点
            let nextNode = getNodeWithIndex(index: index)
            let prevNode = nextNode?.prev
            //创建节点
            let newNode = DoubleListNode.init(val, prevNode, nextNode)
            nextNode?.prev = newNode
            prevNode?.next = newNode

            if index == 0 { // nextNode == first
                first = newNode
            }
        }
        size += 1
    }
    
    
    /// 获取index位置的元素
    func get(index: Int) -> T? {
        return getNodeWithIndex(index: index)?.val
    }
    
    /// 设置index位置的元素,并返回被覆盖的元素值
    func setValue(val: T, index: Int) -> T? {
        //原来的节点
        let oldNode = getNodeWithIndex(index: index)
        let oldNodeVal = oldNode?.val
        //新的元素覆盖之前的元素
        oldNode?.val = val
        return oldNodeVal
    }
    
    /// 删除index位置的元素,并返回删除的元素
    func remove(index: Int) -> T? {
        checkIndexValid(index: index)
        
        var node = first
        if size == 1 {
            first = nil
            last = nil
        }else {
            node = getNodeWithIndex(index: index)
            let prevNode = node?.prev
            let nextNode = node?.next
            
            prevNode?.next = nextNode
            nextNode?.prev = prevNode
            
            if index == 0 { // node == first
                first = nextNode
            }

            if index == size - 1 { //node == last
                last = prevNode
            }
        }

        size -= 1
        return node?.val
    }
    
    /// 删除指定元素
    func removeValue(val: T) {
        //先找到元素的下标
        let index = indexOf(val: val)
        // 若能找到下标则进行删除操作
        if index != ELEMENT_NOT_FOUND {
            _ = remove(index: index)
        }else {
            NSLog("无法删除:链表中找不到对应的元素:\(val)")
        }
    }
    
    /// 查看元素的位置
    func indexOf(val: T) -> Int {
        //从first链表开头开始遍历，查找相同的元素
        var node = first
        for i in 0..<size {
            if node?.val == val {
                return i
            }
            node = node?.next
        }
        return ELEMENT_NOT_FOUND
    }
    
    /// 清除所有的元素
    func clear() {
        size = 0
        first = nil
        last = nil
    }
    
    /// 打印链表中内容
    func printListElement() {
        var node = first
        var str = "["
        if (size > 0) {
            for _ in 0..<size {
                if let n = node {
                    str = str + "   "
                    str = str + "\(n.prev == nil ? "nil" : String(describing:n.prev!.val))"
                    str = str + "_\(String(describing: n.val))"
                    str = str + "_\(n.next == nil ? "nil" : String(describing:n.next!.val))"
                }
                node = node?.next
            }
        }
        str += "]"
        NSLog("链表中元素个数:\(size)----元素内容:\(str)")
    }
    
    //MARK: 获取index位置的结点SingleListNode
    private func getNodeWithIndex(index: Int) -> DoubleListNode<T>? {
        checkIndexValid(index: index)
        // 判断index是靠近左边还是靠近右边
        if (index < (size >> 1)) { //靠近左边
            var node: DoubleListNode<T>? = first
            for _ in 0..<index {
                node = node?.next
            }
            return node
        }else { //靠近右边
            var node: DoubleListNode<T>? = last
            //for (int i = size - 1; i > index; i--)
            for _ in (index+1..<size).reversed() {
                node = node?.prev
            }
            return node
        }
    }
    
    /// 检查index的有效性 index >= 0 && index <= size
    private func checkIndexValid(index: Int) {
        //断言 若条件不满足则会触发断言
        assert(index >= 0 && index < size, "index is invalid: index:\(index) size:\(size)")
    }
    
    /// 检查index的有效性 index >= 0 && index <= size
    private func checkIndexValid_add(index: Int) {
        //断言 若条件不满足则会触发断言
        assert(index >= 0 && index <= size, "index is invalid: index:\(index) size:\(size)")
    }
}
