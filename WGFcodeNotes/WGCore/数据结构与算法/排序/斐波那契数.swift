//
//  1.斐波那契数.swift
//  WGFcodeNotes
//
//  Created by 武功 on 2021/10/7.
//  Copyright © 2021 WG. All rights reserved.
//
/*
 1. 求第n个斐波那契数
 0 1 1 2 3 5 8 13 21 34 55 ......
 
 */
import Foundation

public class WGDataTestVC : UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("开始了")
        DispatchQueue.global().async {
            NSLog("111111第64个斐波那契数是:\(self.fibonacciNumber1(35))")
        }
        DispatchQueue.global().async {
            NSLog("222222第64个斐波那契数是:\(self.fibonacciNumber2(35))")
        }
        NSLog("结束了")
    }
    
    
    //1. 递归算法计算第n个斐波那契数
    private func fibonacciNumber1(_ n: Int) -> Int {
        if n < 2 {
            return n
        }
        //下面代码和上面3行代码等价
//        if n <= 1 {
//            return n
//        }
        return fibonacciNumber1(n-2) + fibonacciNumber1(n-1)
    }
    
    //2. 非递归算法计算第n个斐波那契数【执行效率更高】
    private func fibonacciNumber2(_ n: Int) -> Int {
        if n <= 1 {
            return n
        }
        //0  1  1  2  3  5  8  13  21  34  55 ......
        //0  1  2  3  4  5  6  7   8   9   10
        var first = 0
        var second = 1
        var sum = 0
        for _ in 0..<n-1 {
            sum = first + second
            first = second
            second = sum
        }
        return sum
    }
}
