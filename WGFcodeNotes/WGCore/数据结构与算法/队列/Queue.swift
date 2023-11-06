//
//  Queue.swift
//  appName
//
//  Created by 白菜 on 2021/12/20.
//  Copyright © 2021 baicai. All rights reserved.
//

import Foundation

//MARK: *********************************队列*********************************
public class Queue<T: Comparable> {
    
    private var list = DoubleList<T>.init()
    
    
    /// 获取队列中元素的个数
    func count() -> Int {
        return list.count()
    }

    /// 判断队列是否为空
    func isEmpty() -> Bool {
        return list.isEmpty()
    }

    /// 入队
    func enQueue(element: T) {
        list.add(val: element)
    }

    /// 出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueue() -> T? {
        return list.remove(index: 0)
    }

    /// 获取队列的头元素
    func front() -> T? {
        return list.get(index: 0)
    }
}


//MARK: *********************************循环队列*********************************
/* 循环队列：底层用数组实现
    循环双端队列：可以进行两端添加、删除操作的循环队列
 */
public class CircleQueue<T: Comparable> {
    private var front = 0   //队头的下标
    private var size = 0
    private var array: [T]
    private let DEFAULT_CAPACITY = 10   // 默认容量 10
    private var length = 0   //数组的容量
    
    init() {
        self.array = Array.init(repeating: -1 as! T, count: DEFAULT_CAPACITY)
        self.length = DEFAULT_CAPACITY
    }
    
    /// 获取队列中元素的个数
    func count() -> Int {
        return size
    }

    /// 判断队列是否为空
    func isEmpty() -> Bool {
        return size == 0
    }

    /*     front
     0   1   2   3   4   5   6   7
             34  45  67  1  90   66
     */
    /// 入队
    func enQueue(element: T) {
        //确保容量
        ensureCapacity(needCapacity: size + 1)
        array[index(size)] = element
        size += 1
    }
    
    /*                         front
     0   1   2   3   4   5   6   7
     23                          66
     */
    /// 出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueue() -> T? {
        let element = array[front]
        array[front] = -1 as! T
        front = index(1)
        size -= 1
        return element
    }

    /// 获取队列的头元素
    func getFront() -> T? {
        return array[front]
    }
    
    /// 清空数据
    func clear() {
        for i in 0..<size {
            array[index(i)] = -1 as! T
        }
        size = 0
        front = 0
    }
    
    /// 索引映射
    private func index(_ index: Int) -> Int {
        //return (front + index) % length
        let baseIndex = front + index
        return baseIndex - (baseIndex >= length ? length : 0)
    }
    
    /// 扩容处理
    private func ensureCapacity(needCapacity: Int) {
        let oldCapacity = length
        guard oldCapacity < needCapacity else { //现有容量比需要的容量大，就不需要扩容，直接返回即可
            return
        }
        //新的容量 扩容为现有容量的1.5倍  >> 运算符效率高
        let newCapacity = oldCapacity + (oldCapacity >> 1)
        // 创建新容量的数组
        var newArray:[T] = Array.init(repeating: -1 as! T, count: newCapacity)
    
        //将之前的元素重新写到新的数组中
        for i in 0..<size {
            newArray[i] = array[index(i)]
        }
        //用新的数组替代之前的数组
        array = newArray
        //新的容量替代之前的容量
        length = newCapacity
        //重置front
        front = 0
        NSLog("容量:\(oldCapacity) 扩容后容量:\(newCapacity)");
    }
    
    /// 打印链表中内容
    func printQueueElement() {
        var str = "["
        for i in 0..<length {
            if i != 0 {
                str += ","
            }
            str += "\(array[i])"
        }
        str += "]"
        NSLog("队列容量:\(length)-队列中元素个数:\(size)-元素内容:\(str)")
    }
}



//MARK: *********************************双端队列*********************************
public class DoubleQueue<T: Comparable> {
    
    private var list = DoubleList<T>.init()
    
    /// 获取队列中元素的个数
    func count() -> Int {
        return list.count()
    }

    /// 判断队列是否为空
    func isEmpty() -> Bool {
        return list.isEmpty()
    }

    /// 入队-从队尾入队
    func enQueueRear(element: T) {
        list.add(val: element)
    }
    
    /// 出队-从队头出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueueFront() -> T? {
        return list.remove(index: 0)
    }
    
    /// 入队-从队头入队
    func enQueueFront(element: T) {
        list.add(val: element, index: 0)
    }

    /// 出队-从队尾出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueueRear() -> T? {
        return list.remove(index: list.size - 1)
    }

    /// 获取队列的头元素
    func front() -> T? {
        return list.get(index: 0)
    }
    
    /// 获取队列的尾元素
    func rear() -> T? {
        return list.get(index: list.size - 1)
    }

    /// 清空
    func clear() {
        list.clear()
    }
}


//MARK: *********************************双端循环队列*********************************
//循环双端队列：可以进行两端添加、删除操作的循环队列
public class CircleDoubleQueue<T: Comparable> {
    private var front = 0   //队头的下标
    private var size = 0
    private var array: [T]
    /// 默认容量 10
    private let DEFAULT_CAPACITY = 10
    private var length = 0   //数组的容量
    
    init() {
        self.array = Array.init(repeating: -1 as! T, count: DEFAULT_CAPACITY)
        self.length = DEFAULT_CAPACITY
    }
    
    /// 获取队列中元素的个数
    func count() -> Int {
        return size
    }

    /// 判断队列是否为空
    func isEmpty() -> Bool {
        return size == 0
    }

    /// 入队-从尾部入队
    func enQueueRear(element: T) {
        //确保容量
        ensureCapacity(needCapacity: size + 1)
        array[index(size)] = element
        size += 1
    }
    
    
    /// 出队-从头部出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueueFront() -> T? {
        let element = array[front]
        array[front] = -1 as! T
        front = index(1)
        size -= 1
        return element
    }
    // 0 1 2 3 4 5
    //           1
    /// 入队-从头部入队
    func enQueueFront(element: T) {
        //确保容量
        ensureCapacity(needCapacity: size + 1)
        front = index(-1)
        array[front] = element
        size += 1
    }

    /// 出队-从尾部出队
    @discardableResult  //可废弃的结果：如果该方法被调用，但是没有使用到返回值，就会有警告，但是编辑是没问题的，为了剔除警告，可以使用discardableResult关键词
    func deQueueRear() -> T? {
        let rearIndex = index(size - 1)
        let rear = array[rearIndex]
        array[rearIndex] = -1 as! T
        size -= 1
        return rear
    }

    /// 获取队列的头元素
    func getFront() -> T? {
        return array[front]
    }
    
    /// 获取队列的尾元素
    func rear() -> T? {
        return array[index(size-1)]
    }
    
    /// 清空数据
    func clear() {
        for i in 0..<size {
            array[index(i)] = -1 as! T
        }
        size = 0
        front = 0
    }
    
    /// 索引映射
    private func index(_ index: Int) -> Int {
        var baseIndex = index
        baseIndex = baseIndex + front
        if baseIndex < 0 {
            // index = -1
            // front
            //  0   1   2   3   4   5   6  7   8   9
            //  12  3   54  8
            return baseIndex + length
        }
        //return baseIndex % length
        return baseIndex - (baseIndex >= length ? length : 0)
    }
    /// 运算符 % 效率太低下，可以进一步优化
    private func test() {
        let n = 6
        let m = 10
        let result1 = n % m
        if n >= m {
            NSLog("----\(n - m)")
        }else {
            NSLog("----\(n)")
        }
        // m > 0, n >= 0, n < 2m  则 n % m 等价于下面的代码
        let result2 = n - (n >= m ? m : 0)
        NSLog("result1: \(result1)----result2:\(result2)")
    }
    
    /// 扩容处理
    private func ensureCapacity(needCapacity: Int) {
        let oldCapacity = length
        guard oldCapacity < needCapacity else { //现有容量比需要的容量大，就不需要扩容，直接返回即可
            return
        }
        //新的容量 扩容为现有容量的1.5倍  >> 运算符效率高
        let newCapacity = oldCapacity + (oldCapacity >> 1)
        // 创建新容量的数组
        var newArray:[T] = Array.init(repeating: -1 as! T, count: newCapacity)
    
        //将之前的元素重新写到新的数组中
        for i in 0..<size {
            newArray[i] = array[index(i)]
        }
        //用新的数组替代之前的数组
        array = newArray
        //新的容量替代之前的容量
        length = newCapacity
        //重置front
        front = 0
        NSLog("容量:\(oldCapacity) 扩容后容量:\(newCapacity)");
    }
    
    /// 打印链表中内容
    func printQueueElement() {
        var str = "["
        for i in 0..<length {
            if i != 0 {
                str += ","
            }
            str += "\(array[i])"
        }
        str += "]"
        NSLog("队列容量:\(length)-队列中元素个数:\(size)-元素内容:\(str)")
    }
}
