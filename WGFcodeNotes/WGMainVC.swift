//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public class WGAnimalModel {
    var age = 0
    var isSex = false
    var dic = [String: Any]()
    var arr = [String]()
    var name: String?=nil
    //只读计算属性
    var cardId: String {
        return "sdfdsf"
    }
    var info: WGInfoModel?
}

public class WGInfoModel {
    var weight = 0
    var height = 0
    var name: String {
        return "张三"
    }
}


public class WGMainVC : UIViewController {
    private var lockObjc = NSLock()
    private var lock = NSRecursiveLock()
    private var appleTotalNum = 20
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
    

    }

}



