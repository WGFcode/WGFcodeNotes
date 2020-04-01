//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public class WGMainVC : UIViewController {
    private var lock = NSCondition()
    private var appleNum = 0 //苹果数量
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        let apple1 = Thread(target: self, selector: #selector(eatApple), object: nil)
        apple1.start()
        //为了能否演示效果，先吃-if(没有苹果)-wait(阻塞线程等待)-再去采摘-signal(唤醒阻塞的线程继续执行)
        Thread.sleep(forTimeInterval: 2.0)
        let apple2 = Thread(target: self, selector: #selector(pickApple), object: nil)
        apple2.start()
    }
    @objc func eatApple() {
        lock.lock()
        NSLog("开始判断是否有苹果")
        while appleNum == 0 {
            NSLog("1当前没有苹果,阻塞当前线程")
            lock.wait() //会阻塞当前线程，下面的代码不会执行，直到被唤醒
            NSLog("1wait已经被唤醒了")
        }
        NSLog("1已经有苹果可以吃了")
        appleNum -= 1
        NSLog("1开始解锁当前的线程")
        lock.unlock()
    }
    @objc func pickApple() {
        lock.lock()
        NSLog("2开始采摘苹果")
        appleNum += 1
        //当摘到一个苹果之后，通过signal方法唤醒wait
        NSLog("2开始唤醒被wait阻塞的线程")
        lock.signal()  //不会阻塞当前线程，会继续执行
        NSLog("2开始解锁当前的线程")
        lock.unlock()
    }
}
