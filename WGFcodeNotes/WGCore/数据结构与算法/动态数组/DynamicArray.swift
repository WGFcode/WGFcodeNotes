//
//  DynamicArray.swift
//  appName
//
//  Created by 白菜 on 2021/12/17.
//  Copyright © 2021 baicai. All rights reserved.
//

import Foundation


public class DynamicArray<T: Comparable> {
    /// 数组元素个数
    var size: Int = 0
    /// 数组容量
    var length: Int = 0
    /// 默认容量 10
    private let DEFAULT_CAPACITY = 10
    /// 找不到元素提供默认值
    private let ELEMENT_NOT_FOUND = -1
    /// 内部数组
    private var array: [T]
    
    init(capatity: Int?) {
        //初始化若没有指定容量，则默认开辟10个空间
        let capa = capatity == nil ? DEFAULT_CAPACITY : capatity!
        self.array = Array.init(repeating: -1 as! T, count: capa)
        length = capa
    }
    
    /// 获取数组元素的个数
    func count() -> Int {
        return size
    }
    
    /// 判断数组是否为空
    func isEmpty() -> Bool {
        return size == 0
    }
    
    /// 判断是否包含某个元素
    func contains(element: T) -> Bool {
        return indexOf(element: element) != ELEMENT_NOT_FOUND
    }
    
    /// 添加元素到最后面
    func add(element: T) {
        addElement(element: element, index: size)
    }

    /// 向指定位置添加元素
    func addElement(element: T, index: Int) {
        checkIndexValid_add(index: index)
        //添加元素前 先确保容量够用，不够用需要扩容处理
        ensureCapacity(needCapacity: size+1)
        /* 0    1   2  3  4  5
           23  34  45  8  9  10
         */
        //【index～size-1] 的元素统一向右移动 必须倒序进行移动，否则会导致覆盖的问题
        for i in (index..<size).reversed() {
            array[i+1] = array[i]
        }
        //添加元素
        array[index] = element
        size += 1
    }
    
    /// 返回index位置的元素
    func getElement(index: Int) -> T {
        checkIndexValid(index: index)
        return array[index]
    }
    
    /// 设置index位置的元素,并返回被覆盖的值
    func setElement(element: T, index: Int) -> T {
        checkIndexValid(index: index)
        let oldElement = array[index]
        array[index] = element
        return oldElement
    }
    
    /// 删除index位置的元素,并返回删除的元素
    func remove(index: Int) -> T {
        checkIndexValid(index: index)
        let oldElement = array[index]
        /* 0    1   2  3  4  5
           23  34  45  8  9  10
         删除2号元素，那么就让3～5元素向左移动一位即可 【index+1,size-1】移动一位即可
         */
        for i in (index+1)..<size {
            array[i-1] = array[i]
        }
        size -= 1
        //数组元素是对象类型需要清空最后一个元素的内存
        //array[size] = NSNull() as! T
        
        return oldElement
    }
    
    /// 删除指定元素
    func removeElement(element: T) {
        let index = indexOf(element: element)
        _ = remove(index: index)
    }
    
    /// 获取元素的位置下标
    func indexOf(element: T) -> Int {
        for i in 0..<size {
            //⚠️如果数组元素是对象类型，那么这里如果仍然这么写就是判断两个对象的内存地址是否一样，
            //一般我们不用 == 来判断对象是否相等，而是在对象类内部重写isEqual方法来做判断，然后这里直接 array[i].isEqual(element)来判断
            //如果对象没有重写isEqual方法，而这里仍然用array[i].isEqual(element)来判断，默认就是比较两个对象的内存地址是否相等
            if array[i] == element {
                return i
            }
        }
        return ELEMENT_NOT_FOUND
    }
    
    /// 清除所有的元素
    func clear() {
        //如果是数组元素是对象类型，就需要清空处理
        for i in 0..<size {
            array[i] = NSNull() as! T
        }
        size = 0
    }
    
    /// 打印数组内容
    func printArrayElement() {
        var arrayInfo = "["
        for i in 0..<size {
            arrayInfo = arrayInfo + "\(array[i])_"
        }
        arrayInfo = arrayInfo + "]"
        NSLog("元素个数:\(size),数组:\(arrayInfo)")
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
            newArray[i] = array[i]
        }
        //用新的数组替代之前的数组
        array = newArray
        //新的容量替代之前的容量
        length = newCapacity
        NSLog("容量:\(oldCapacity) 扩容后容量:\(newCapacity)");
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
