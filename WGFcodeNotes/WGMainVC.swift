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
        
//        NSLog("开始了")
//        DispatchQueue.global().async {
//            for _ in 0...1 {
//                NSLog("11111--\(Thread.current)")
//            }
//        }
//        DispatchQueue.global().async {
//            for _ in 0...1 {
//                NSLog("22222--\(Thread.current)")
//            }
//        }
//        DispatchQueue.global().async {
//            for _ in 0...1 {
//                NSLog("33333--\(Thread.current)")
//            }
//        }
//        NSLog("结束了")
        
        
        
        
        NSLog("开始了")
        let group = DispatchGroup.init()
        let concurrentQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        group.enter()
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("11111--\(Thread.current)")
                }
                group.leave()
            }
        }))
        group.wait()
        group.enter()
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("22222--\(Thread.current)")
                }
                group.leave()
            }
        }))
        group.wait()
        group.enter()
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("33333--\(Thread.current)")
                }
                group.leave()
            }
        }))
        group.wait()
        NSLog("结束了")
    }
}



