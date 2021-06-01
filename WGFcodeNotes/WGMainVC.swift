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


public class WGMainVC : UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        //这里必须是var修饰，否则编译器会报错
        var a = MyStruct()
        a.testFunc()
        NSLog("age:\(a.age)")
        age:18
    }
    

}





