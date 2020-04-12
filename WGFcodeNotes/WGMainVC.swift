//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public final class WGTestEntity : NSObject {
    static let instance = WGTestEntity()
    override init() {
        super.init()
    }
}

public class WGMainVC : UIViewController {
    private var thread1: Thread?=nil
    private var isSuccess2 = true
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        NSLog("开始了")
        let semp = DispatchSemaphore.init(value: 0)
        DispatchQueue.global().async {
            NSLog("11111--\(Thread.current)")
            semp.signal()
        }
        //因为信号量初始值为0，所以wait方法阻塞当前线程，直到信号量变为1(调用了signal方法)，才执行wait后的任务,
        semp.wait()
        //需要注意的是此时信号量是0，但是是不会阻塞下面代码执行的，因为信号量为0阻塞线程是根据wait方法来判断的
        //如果遇到wait方法，此时判断信号量是否为0，如果是0，那么会阻塞wait方法后的代码执行，而wait前的代码仍然可以执行
        DispatchQueue.global().async {
            for _ in 0...2 {
                NSLog("22222--\(Thread.current)")
            }
            semp.signal()
        }
        //此时信号量是0，所以wait方法后的代码会被阻塞，知道任务2中调用signal方法，使信号量+1
        semp.wait()
        DispatchQueue.global().async {
            NSLog("33333--\(Thread.current)")
        }
        NSLog("完成了")
        
    }
    

}



