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
    var appleTotalNum = 20
    private var lockObjc = NSLock()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        let people1 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people1.start()
        let people2 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people2.start()
        let people3 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people3.start()
    }
    
    @objc func eatApple() {
        lockObjc.lock()
        appleTotalNum -= 1
        NSLog("当前是否是主线程:\(Thread.isMainThread)-当前剩余的苹果数:\(appleTotalNum)")
        lockObjc.unlock()
    }
    
    
//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        NSLog("剩余的苹果数是:\(appleTotalNum)")
//        objc_sync_enter(self)
//        objc_sync_exit(self)
//    }
}
