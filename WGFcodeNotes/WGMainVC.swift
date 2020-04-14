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
}


public class WGMainVC : UIViewController {
    private var lockObjc = NSLock()
    private var lock = NSRecursiveLock()
    private var appleTotalNum = 20
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        let entity = WGAnimalModel.init()
        //通过KVC赋值
        entity[keyPath: \WGAnimalModel.age] = 18
        //通过KVC获取值
        let age = entity[keyPath: \WGAnimalModel.age]
        NSLog("age:\(age)")
        
        let entity1 = WGAnimalModel.init()
        NSLog("新的结构体中的age:\(entity1.age)")
        
        
        let agePath: WritableKeyPath<WGAnimalModel,Int> = \WGAnimalModel.age
        let sexPath: WritableKeyPath<WGAnimalModel,Bool> = \WGAnimalModel.isSex
        let arrPath: WritableKeyPath<WGAnimalModel,[String]> = \WGAnimalModel.arr
        let dicPath: WritableKeyPath<WGAnimalModel,[String: Any]> = \WGAnimalModel.dic
        let namePath: WritableKeyPath<WGAnimalModel,String?> = \WGAnimalModel.name
        let cardIdPath: KeyPath<WGAnimalModel,String> = \WGAnimalModel.cardId
        let infoPath: ReferenceWritableKeyPath<WGAnimalModel, WGInfoModel?> = \WGAnimalModel.info
        let infoWeight: KeyPath<WGAnimalModel, Int?> = \WGAnimalModel.info?.weight
        
        
        

    }

}



