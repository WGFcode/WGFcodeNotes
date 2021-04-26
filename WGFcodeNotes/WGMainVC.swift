//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit


class WGMyClass {
    func testFunc(){
        NSLog("WGMyClass->testFunc")
    }
}

struct WGMyStruct {
    func testFunc() {
        NSLog("WGMyStruct->testFunc")
    }
}


typealias Location = CGPoint
public class WGMainVC : UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let cls = WGMyClass()
        cls.testFunc()
        
        let str = WGMyStruct()
        str.testFunc()
        
    }
}



