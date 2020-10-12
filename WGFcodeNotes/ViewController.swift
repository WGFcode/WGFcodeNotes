//
//  ViewController.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import UIKit


//enum WGSexType {
//    case Man(String,String,String) //内存对齐8字节 实际占用48 系统分配：48
//    case Woman(Bool,Bool)
////    case RenYao(String)
//}

struct WGSexType {
    var sex: Bool = false    //1
    var age: Int = 0         //8
    var name: String = ""    //16
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        
        
        let sexEnum = WGSexType()
        // 实际占用的内存大小
        let sexEnumSize0 = MemoryLayout.size(ofValue: sexEnum)
        // 系统分配的内存大小
        let sexEnumSize1 = MemoryLayout.stride(ofValue: sexEnum)
        // 内存对齐的字节数长度
        let sexEnumSize2 = MemoryLayout.alignment(ofValue: sexEnum)
        NSLog("\n结构体实际占用的内存大小：----\(sexEnumSize0)个字节, \n结构体被系统分配的内存大小：----\(sexEnumSize1)个字节, \n 结构体内存对齐的字节数长度：----\(sexEnumSize2)个字节, \n")
    }
    
    private func printAddress(value: Any) {
        print("\(value)地址是:\(Unmanaged.passUnretained(value as AnyObject).toOpaque())")
    }
}

