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
        self.view.backgroundColor = UIColor.white
        
        
        let queue = DispatchQueue.global()
        //将指定的队列挂起,对已经执行的处理任务或者正在执行的处理任务是无效的
        queue.suspend()
        //将指定的队列恢复,继续后面还没有执行的处理任务;对已经执行的处理任务或者正在执行的处理任务是无效的
        queue.resume()
       
    }
    
    
    
}



