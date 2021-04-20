//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit


struct DirectionStruct {
    var height: Float = 1
    var name = "a"
    var sex = true  
    //实际占用内存大小:25 系统分配内存大小:32 内存对齐大小:8
}


public class WGMainVC : UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        var stru = DirectionStruct()
        NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: stru))\n 系统分配内存大小:\(MemoryLayout.stride(ofValue: stru))\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: stru))")
        
        
    }
}



