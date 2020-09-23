//
//  ViewController.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import UIKit

enum WGSexType {
//    case Man(Bool,Bool,Bool)
//    case Woman(Bool,Bool)
//    case RenYao(Bool)
    /*
      枚举实际占用的内存大小：----3个字节,
      枚举被系统分配的内存大小：----3个字节,
      枚举内存对齐的字节数长度：----1个字节,
    */
//    case Man(Bool,Bool,Bool)
//    case Woman(Float,Bool)
//    case RenYao(Bool)
    /*
      枚举实际占用的内存大小：----5个字节,
      枚举被系统分配的内存大小：----8个字节,
      枚举内存对齐的字节数长度：----4个字节,
     */
//    case Man(String,Bool,Bool)
//    case Woman(Float,Bool)
//    case RenYao(Bool)
    /*
      枚举实际占用的内存大小：----18个字节,
      枚举被系统分配的内存大小：----24个字节,
      枚举内存对齐的字节数长度：----8个字节,
     */
    case Man(String,String,Bool)
    case Woman(Float,Float)
    case RenYao(String)
    /*
      枚举实际占用的内存大小：----33个字节,
      枚举被系统分配的内存大小：----40个字节,
      枚举内存对齐的字节数长度：----8个字节,
     */
}


class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        
        let sexEnum = WGSexType.Man("1","1",true)
        // 实际占用的内存大小
        let sexEnumSize0 = MemoryLayout.size(ofValue: sexEnum)
        // 系统分配的内存大小
        let sexEnumSize1 = MemoryLayout.stride(ofValue: sexEnum)
        // 内存对齐的字节数长度
        let sexEnumSize2 = MemoryLayout.alignment(ofValue: sexEnum)
        NSLog("\n枚举实际占用的内存大小：----\(sexEnumSize0)个字节, \n枚举被系统分配的内存大小：----\(sexEnumSize1)个字节, \n 枚举内存对齐的字节数长度：----\(sexEnumSize2)个字节, \n")
    }
}

