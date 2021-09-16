## 多线程总结
### 1.多线程通信
#### 在一个进程中，线程往往不是孤立存在的，多个线程之间需要进行通信，线程间通信主要体现在以下两个方面
* 1个线程传递数据给另1个线程，
* 在1个线程中执行完特定任务后，转到另1个线程继续执行任务
#### 1.1 Thread多线程通信

    常用的两个方法
    self performSelectorOnMainThread:(nonnull SEL) withObject:(nullable id)
    waitUntilDone:(BOOL)
    
    self performSelector:(nonnull SEL) onThread:(nonnull NSThread *) 
    withObject:(nullable id) waitUntilDone:(BOOL)
    

    //开启子线程去完成任务1
    self.performSelector(inBackground: #selector(method1), with: nil)

    @objc func method1() {
        NSLog("method1: current Thread is:\(Thread.current)")
        //waitUntilDone: 是否阻塞当前线程，直到method2中所有的任务都完成
        self.performSelector(onMainThread:#selector(method2),with:nil,waitUntilDone:true)
        NSLog("完成了")
    }

    @objc func method2() {
        NSLog("method2: current Thread is:\(Thread.current)")
    }
     
    打印结果: method1:current Thread is:<NSThread:0x600003613980>{number=7,name=(null)}
            method2:current Thread is:<NSThread:0x60000361e0c0>{number=1,name=main}
            完成了
### 1.2 GCD多线程通信
    DispatchQueue.global().async {
        for _ in 0...1 {
            NSLog("在子线程中执行任务--\(Thread.current)")
        }
        DispatchQueue.main.async {
            NSLog("回到主线程执行任务--\(Thread.current)")
        }
    }
    NSLog("结束了")
    
    打印结果: 结束了
            在子线程中执行任务--<NSThread: 0x600003243000>{number = 3, name = (null)}
            在子线程中执行任务--<NSThread: 0x600003243000>{number = 3, name = (null)}
            回到主线程执行任务--<NSThread: 0x60000322d640>{number = 1, name = main}
        
### 1.3 Operation多线程通信
    let queue = OperationQueue.init()
    queue.addOperation {
        for _ in 0...1 {
            NSLog("11111--\(Thread.current)")
        }
        OperationQueue.main.addOperation {
            NSLog("回到主线程中执行任务--\(Thread.current)")
        }
    }
    NSLog("完成了")
    
    打印结果: 完成了
            11111--<NSThread: 0x6000029cb5c0>{number = 3, name = (null)}
            11111--<NSThread: 0x6000029cb5c0>{number = 3, name = (null)}
            回到主线程中执行任务--<NSThread: 0x600002996d80>{number = 1, name = main}
### 2. GCD和Operation的区别
#### Operation可以设置操作的最大并发数来实现串行或者并发执行任务；可以设置操作间依赖方便控制操作间执行顺序；设定操作的优先级；可以取消单个或多个操作；可以暂停/恢复操作队列中的任务；可以使用KVO来观察操作的执行状态(isExecuteing/isFinished/isCancelled),一般用于复杂的业务，比如网络库Alamofire中就大量用到了Operation


