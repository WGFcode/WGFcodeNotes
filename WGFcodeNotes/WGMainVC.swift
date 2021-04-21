//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit


enum Kind {
    case wolf
    case fox
    case dog
    case sheep
}

struct Animal {
    private var a: Int = 1       //8
    var b: String = "animal"     //16
    var c: Kind = .wolf          //8
    var d: String?      //16
    var e: Int8 = 8 //8
}



public class WGMainVC : UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let animal = Animal()
        
        NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: animal))\n 系统分配内存大小:\(MemoryLayout.stride(ofValue: animal))\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: animal))")
        
        NSLog("实际占用内存大小:\(MemoryLayout<Int8>.size)\n 系统分配内存大小:\(MemoryLayout.<Int8>.stride)\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: animal))")
    }
}



