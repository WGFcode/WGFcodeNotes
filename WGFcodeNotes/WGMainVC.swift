//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit


struct MyStruct {
    var name = ""
    var age = 0
    mutating func testFunc() {
        age = 18
    }
}


typealias Location = CGPoint
public class WGMainVC : UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        var my = MyStruct()
        my.name = "zhangsan"
        my.name = "lisi"
        my.testFunc()
    }
}



