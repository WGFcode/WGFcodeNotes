//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public class WGMainVC : UIViewController {
    
    private var appleTotalNum = 10
    //1.创建信号量，初始化为1，系统规定当信号量为0的时候必须等待
    private let semaphore = DispatchSemaphore(value: -2)
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        

    }
    @objc func eatApple() {

    }
}
