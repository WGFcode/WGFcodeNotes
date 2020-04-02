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
    private var pageNum = 10
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        let thread2 = Thread(target: self, selector: #selector(method1), object: nil)
        thread2.start()
    }
    @objc func method1() {
        objc_sync_enter(self)
        pageNum -= 1
        NSLog("当前的pageNum为:\(pageNum)")
        //如果objc和objc_sync_enter中的objc不一致，该对象会被锁定但并未解锁，当点击屏幕另一个线程访问时，会crash
        objc_sync_exit("")
        NSLog("----------")
    }
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let thread3 = Thread(target: self, selector: #selector(method1), object: nil)
        thread3.start()
    }
}
