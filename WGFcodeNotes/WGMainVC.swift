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
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        let thread1 = Thread(target: self, selector: #selector(testMethod), object: nil)
        //开启线程
        thread1.start()
        /*属性含义
         name: 设置线程名称
         threadDictionary: 每个线程都有个字典，在线程中任何地方被访问
         threadPriority:设置线程优先级(0-1.0)
         stackSize: 线程使用栈区大小(默认是512K)
         isExecuting: 线程是否正在执行
         isFinished: 线程是否执行完成
         isCancelled: 线程是否撤销
         isMainThread: 是否是主线程
         */
        //2.类方法创建线程并自动开启
        Thread.detachNewThreadSelector(#selector(textMethod1(title:)), toTarget: self, with: "传递给调用方法的参数")
        if #available(iOS 10.0, *) {
            Thread.detachNewThread {
                NSLog("Block方式创建线程并启动")
            }
        } else {
            // Fallback on earlier versions
        }
        /*
         调用类方法阻塞当前线程
         Thread.sleep(until: <#T##Date#>)
         Thread.sleep(forTimeInterval: <#T##TimeInterval#>)
         //推出当前线程
         Thread.exit()
         */
        
        
    }
    
    @objc func testMethod() {
    }
    
    @objc func textMethod1(title: String) {
        NSLog("\(title)")
    }
}
