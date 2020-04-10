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
    private var thread1: Thread?=nil
    private var isSuccess2 = true
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        let thread2 = Thread.init(target: self, selector: #selector(method2), object: nil)
        thread1.qualityOfService = .userInteractive
        thread2.qualityOfService = .background
        thread1.start()
        thread2.start()
    }
    
    @objc func method1() {
        for _ in 0...1 {
            NSLog("11111--\(Thread.current)---")
        }
    }
    @objc func method2() {
        for _ in 0...1 {
            NSLog("22222--\(Thread.current)---")
        }
    }
}



