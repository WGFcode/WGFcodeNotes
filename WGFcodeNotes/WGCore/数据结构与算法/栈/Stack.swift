//
//  Stack.swift
//  ZJKBank
//
//  Created by 白菜 on 2021/12/20.
//  Copyright © 2021 buybal. All rights reserved.
//

import Foundation

public class Stack<T: Comparable> {
    private var list: DoubleList = DoubleList<T>()
    private var arr: DynamicArray = DynamicArray<T>.init(capatity: nil)
    
    /// 获取栈中元素的个数
    func count() -> Int {
        //return list.count()
        return arr.count()
    }

    /// 判断栈是否为空
    func isEmpty() -> Bool {
        //return list.isEmpty()
        return arr.isEmpty()
    }

    /// 入栈
    func push(element: T) {
        arr.add(element: element)
        //list.add(val: element)
    }

    /// 出栈
    func pop() -> T? {
        return arr.remove(index: arr.size-1)
        //return list.remove(index: list.size-1)
    }

    /// 获取栈顶元素
    func top() -> T? {
        return arr.getElement(index: arr.size-1)
        //return list.get(index: list.size-1)
    }
}
