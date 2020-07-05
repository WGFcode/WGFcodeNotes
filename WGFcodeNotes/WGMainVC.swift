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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.lightGray
        //按钮里面放一个标签
        let btn = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        btn.backgroundColor = UIColor.white
        btn.layer.cornerRadius = 10
        
        let lab = UILabel(frame: CGRect(x: 10, y: 5, width: 80, height: 40))
        lab.text = "测试一下"
        btn.addSubview(lab)
        self.view.addSubview(btn)
        //设置按钮的透明度
        btn.alpha = 0.1
        //设置组透明
//        btn.layer.shouldRasterize = true
//        btn.layer.rasterizationScale = UIScreen.main.scale
    }
}



