//
//  ViewController.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import UIKit


//协议可选方式一
@objc protocol WGCustom {
    func eat()
    func sleep()
    @objc optional func playBackketbool()
}
// 协议可选方式二
protocol WGCustom1 {
    func eat()
    func sleep()
    func playBackketbool()
}
//通过扩展
extension WGCustom1 {
    func playBackketbool() {
    }
}




class ViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        let total = testSum(num: 100000)
        NSLog("-----%ld", total)
    }
    
    func testSum(num: Int) -> Int {
        func sumInternal(n: Int, current: Int) -> Int {
            if n == 0 {
                return current
            }else {
                return sumInternal(n: n, current: current+n)
            }
        }
        return sumInternal(n: num, current: 0)
    }
}

