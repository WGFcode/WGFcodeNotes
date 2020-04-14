//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public final class WGTestEntity : NSObject {
    static let instance = WGTestEntity()
    override init() {
        super.init()
    }
}

public class WGMainVC : UIViewController {
    private var lockObjc = NSLock()
    private var lock = NSRecursiveLock()
    private var appleTotalNum = 20
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        NSLog("开始了")
        let thread1 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        let thread2 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        let thread3 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        thread1.start()
        thread2.start()
        thread3.start()
        NSLog("结束了")
    }
    
   
    @objc func eatApple() {
        lock.lock()
        lock.lock()
        lock.lock()
        appleTotalNum -= 1
        NSLog("11111--\(Thread.current)--剩余的苹果数:\(appleTotalNum)")
        lock.unlock()
        lock.unlock()
    }
}



