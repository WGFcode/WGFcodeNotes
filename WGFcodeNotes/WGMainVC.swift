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
    
//    private var queue = OperationQueue()
    private var isSuccess2 = true
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
        // 270000 + 60000
//        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
//        let mainQueue = DispatchQueue.main
//        let globalQueue = DispatchQueue.global()
//        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
//        thread1.start()
        NSLog("开始了")
        //let queue = OperationQueue()
        let op1 = BlockOperation.init {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        op1.addExecutionBlock {
            for _ in 0...2 {
                NSLog("22222--\(Thread.current)")
            }
        }
        op1.addExecutionBlock {
            for _ in 0...2 {
                NSLog("33333--\(Thread.current)")
            }
        }
        op1.start()
//        op1.waitUntilFinished()
//        op2.waitUntilFinished()
        //控制队列中的操作执行顺序方式一:通过设置操作之间的依赖关系
//        op2.addDependency(op1)
//        op3.addDependency(op2)
        
//        queue.addOperations([op1,op2,op3], waitUntilFinished: false)

        NSLog("结束了")
        //执行操作
//        op.start()
//        op.main()
        //只读 判断操作是否已经标记为取消
        //op.isCancelled
        //可取消操作，实质是标记 isCancelled 状态
//        op.cancel()
//        //只读 判断操作是否正在在运行
//        op.isExecuting
//        //只读 判断操作是否已经结束
//        op.isFinished
//        //添加依赖，使当前操作依赖于操作 op 的完成
//        op.addDependency(op: Operation)
//        //移除依赖，取消当前操作对操作 op 的依赖
//        op.removeDependency(op: Operation)
//        //只读 在当前操作开始执行之前完成执行的所有操作对象数组。
//        op.dependencies
//        //设置操作优先级
//        op.queuePriority
//        //设置服务优先级
//        op.qualityOfService
//        //设置操作名称
//        op.name
//        //阻塞当前线程，直到该操作结束。可用于线程执行顺序的同步。
//        op.waitUntilFinished()
        //        @available(iOS 4.0, *)
        //        open var completionBlock: (() -> Void)?
        //        open var isConcurrent: Bool { get }
        //        @available(iOS 7.0, *)
        //        open var isAsynchronous: Bool { get }
        //        open var isReady: Bool { get }

    }
}



