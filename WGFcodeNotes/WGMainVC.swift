//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit


public struct WGAnimalModel {
    private var name = ""  //KVC无法访问私有属性
    var age = 0
    var isSex = false
    var dic = [String: Any]()
    var arr = [String]()
}

//public class WGPerson : WGAnimalModel {
//    //可以继承父类所有的属性，但是私有的属性无法继承
//    var className = ""
//}


public class WGMainVC : UIViewController {
    private var lockObjc = NSLock()
    private var lock = NSRecursiveLock()
    private var appleTotalNum = 20
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        var entity = WGAnimalModel.init()
        //通过KVC赋值
        entity[keyPath: \WGAnimalModel.age] = 18
        //通过KVC获取值
        let age = entity[keyPath: \WGAnimalModel.age]
        NSLog("age:\(age)")
        
        let entity1 = WGAnimalModel.init()
        NSLog("新的结构体中的age:\(entity1.age)")
        KeyPath
    }

}



