//
//  SingleList.swift
//  appName
//
//  Created by 白菜 on 2021/12/17.
//  Copyright © 2021 baicai. All rights reserved.
//

import Foundation

/// 找不到元素提供默认值
let ELEMENT_NOT_FOUND = -1

public class SingleListNode<T: Comparable> {
    /// 存储的节点元素
    var val: T
    /// 下一个节点
    var next: SingleListNode?
    
    init() {
        self.val = -1 as! T
        self.next = nil
    }
    init(_ val: T) {
        self.val = val
        self.next = nil
    }
    init(_ val: T, _ next: SingleListNode?) {
        self.val = val
        self.next = next
    }
}

//MARK: *********************************单向链表*********************************
public class SingleList<T: Comparable>{
    /// 链表中元素个数
    var size: Int = 0
    /// 指向第一个结点
    var first: SingleListNode<T>?
    
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
        if index == 0 {
            let newNode = SingleListNode.init(val, first)
            first = newNode
        }else {
            //先获取到index节点对象的上一个节点
            let prev = getNodeWithIndex(index: index-1)
            //新建节点
            let newNode = SingleListNode.init(val, prev?.next)
            // 让上一个节点的next指向新创建的节点
            prev?.next = newNode
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
        //被删除元素的节点
        var oldNode = first
        if index == 0 {
            first = first?.next
        }else {
            //先获取到index节点对象的上一个节点
            let prev = getNodeWithIndex(index: index-1)
            //被删除元素的节点
            oldNode = prev?.next
            prev?.next = oldNode?.next
        }
        size -= 1
        return oldNode?.val
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
    }
    
    /// 打印链表中内容
    func printListElement() {
        var node = first
        var str = "["
        if (size > 0) {
            str = str + "\(String(describing: node!.val))"
            for _ in 0..<size {
                node = node?.next
                if let n = node {
                    str = str + "->\(String(describing: n.val))"
                }
            }
        }
        str += "]"
        NSLog("链表中元素个数:\(size)----元素内容:\(str)")
    }
    
    //MARK: 获取index位置的结点SingleListNode
    private func getNodeWithIndex(index: Int) -> SingleListNode<T>? {
        checkIndexValid(index: index)
        var node: SingleListNode<T>? = first
        for _ in 0..<index {
            node = node?.next
        }
        return node
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



//MARK: *********************************单向循环链表*********************************
public class SingleCycleList<T: Comparable> {
    /// 链表中元素个数
    var size: Int = 0
    /// 指向第一个结点
    var first: SingleListNode<T>?
    
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
        if index == 0 {
            
            //⚠️⚠️这句代码的位置一定要写在first改变前，因为getNodeWithIndex方法需要用到first
            let lastNode = size == 0 ? first : getNodeWithIndex(index: size - 1)
            
            let newNode = SingleListNode.init(val, first)
            first = newNode
            
            lastNode?.next = first
            
        }else {
            //先获取到index节点对象的上一个节点
            let prev = getNodeWithIndex(index: index-1)
            //新建节点
            let newNode = SingleListNode.init(val, prev?.next)
            // 让上一个节点的next指向新创建的节点
            prev?.next = newNode
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
    
    //⚠️循环链表和非循环链包差异地方 添加和删除
    /// 删除index位置的元素,并返回删除的元素
    func remove(index: Int) -> T? {
        checkIndexValid(index: index)
        //被删除元素的节点
        var oldNode = first
        if index == 0 {
            if size == 1 { //⚠️⚠️必须处理，否则只用else后的逻辑判断是无法删除的
                first = nil
            }else {
                
                //拿到最后一个节点,让最后一个节点的next指向最新的头节点
                let lastNode = getNodeWithIndex(index: size - 1)
                //⚠️⚠️这句代码一定要放在上面代码的下面，因为getNodeWithIndex方法需要用到first，如果写在它的上面first已经被改掉了，获取的结果就会出问题
                first = first?.next
                lastNode?.next = first
            }
        }else {
            //先获取到index节点对象的上一个节点
            let prev = getNodeWithIndex(index: index-1)
            //被删除元素的节点
            oldNode = prev?.next
            prev?.next = oldNode?.next
        }
        size -= 1
        return oldNode?.val
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
    }
    
    /// 打印链表中内容
    func printListElement() {
        var node = first
        var str = "["
        if (size > 0) {
            str = str + "\(String(describing: node!.val))"
            for _ in 0..<size {
                node = node?.next
                if let n = node {
                    str = str + "->\(String(describing: n.val))"
                }
            }
        }
        str += "]"
        NSLog("链表中元素个数:\(size)----元素内容:\(str)")
    }
    
    //MARK: 获取index位置的结点SingleListNode
    private func getNodeWithIndex(index: Int) -> SingleListNode<T>? {
        checkIndexValid(index: index)
        var node: SingleListNode<T>? = first
        for _ in 0..<index {
            node = node?.next
        }
        return node
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
