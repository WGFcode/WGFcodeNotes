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
        
        let people1 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people1.start()
        let people2 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people2.start()
        let people3 = Thread(target: self, selector: #selector(eatApple), object: nil)
        people3.start()
    }
    @objc func eatApple() {
        //如果信号量>0,使信号量-1，否则阻塞线程直到该信号量的值大于0或者达到等待时间。
        semaphore.wait() //使信号量-1(告诉其他线程，现在里面资源已经减1了，没有资源了，需要等待资源释放后才能访问)
        appleTotalNum -= 1
        NSLog("剩余苹果数:\(appleTotalNum)")
        semaphore.signal()  //使信号量+1(告诉其他线程，现在里面有资源了，可以访问了)
    }
}
