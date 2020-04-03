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
        
        /*创建串行队列
         label:队列名称，方便调试用
         qos:队列的优先级，优先级越高获得更多的计算资源
         attributes: 标示队列类型,
            默认是串行队列
            concurrent：并发队列
            initiallyInactive:标识运行队列中的任务需要手动触发,由队列的activate 方法进行触发。如果未添加此标识，向队列中添加的任务会自动运行
         autoreleaseFrequency:设置负责管理任务内对象生命周期的autorelease pool的自动释放频率
            inherit：继承目标队列的该属性，
            workItem：跟随每个任务的执行周期进行自动创建和释放
            never：不会自动创建 autorelease pool，需要手动管理。
        */
//        let serialQueue = DispatchQueue.init(label: "串行队列名称")
//        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
//        let mainQueue = DispatchQueue.main
//        let globalQueue = DispatchQueue.global()
//        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
//        thread1.start()
        
        

        //创建组
        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        group.enter()
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem.init(block: {
            NSLog("00000--\(Thread.current)")
        }))
        
    }
    
    func testMethod() {

    }
}
