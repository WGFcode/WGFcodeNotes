#### Thread 创建方式
1. 通过初始化方式创建，需要手动启动线程

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
         @objc func testMethod() {
             NSLog("被调用")
         }

2. 通过类方法创建，不需要手动启动

        Thread.detachNewThreadSelector(#selector(textMethod(title:)), toTarget: self, with: "传递给调用方法的参数")
        if #available(iOS 10.0, *) {
            Thread.detachNewThread {
                NSLog("Block方式创建线程并启动")
            }
        } else {
            // Fallback on earlier versions
        }
        /*
         阻塞当前线程（线程休眠）
         Thread.sleep(until: <#T##Date#>)
         Thread.sleep(forTimeInterval: <#T##TimeInterval#>)
         Thread.exit()   退出当前线程
         Thread.isMainThread  是否是主线程
         */
         @objc func textMethod(title: String) {
             NSLog("\(title)")
         }
     
3. 通过NSObject扩展的方法隐式创建并自动启动线程

         self.performSelector(inBackground: #selector(testMethod), with: nil)
         @objc func testMethod() {
            NSLog("被调用")
         }
     
#### Thread 状态
   * 新建: 创建线程对象(仅针对初始化的创建方式，类方法和performSelector方法没有该状态)
   * 就绪: 向对象发送start消息，线程对象被加入到可调度线程池，供CPU调度
   * 运行: 线程执行完成之前,状态就在就绪和运行之间切换
   * 阻塞: 当满足一定条件时，可以使用sleep(until: <#T##Date#>)/sleep(forTimeInterval: <#T##TimeInterval#>)/@synchronized(self)线程锁阻塞当前线程，做一些其他操作，线程对象进入阻塞状态后，会被从“可调度线程池”中移出，CPU 不再调度
   * 死亡: 正常情况下线程执行完毕后就死亡，但如果在线程执行任务过程中调用Thread.exit()方法强行终止，那么后续代码都不会执行也会导致线程死亡(非正常死亡)
   * 注意: 如果线程对象调用cancel()方法，并不会销毁线程，该方法只是改变了线程的状态标识，需要在线程执行方法中判断isCancelled是否等于Yes，如果YES，则调用exit()方法销毁线程

#### Thread 线程间通信
##### 一般线程间通信主要指下面几种方法，子线程执行耗时操作，在主线程中进行UI更新
    //在主线程中执行指定方法
    self.performSelector(onMainThread: <#T##Selector#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>, modes: <#T##[String]?#>)
    self.performSelector(onMainThread: <#T##Selector#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>)
    //在指定的线程中执行指定的方法
    self.perform(<#T##aSelector: Selector##Selector#>, on: <#T##Thread#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>, modes: <#T##[String]?#>)
    self.perform(<#T##aSelector: Selector##Selector#>, on: <#T##Thread#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>)
    //在开启的子线程中执行指定的方法
    self.performSelector(inBackground: <#T##Selector#>, with: <#T##Any?#>)

#### Thread 线程间资源共享造成的抢夺&线程锁
##### 当多个线程访问同一资源时，会发生资源数据的抢夺和数据错误，所以需要线程锁来实现资源的同步使用，即同一时间，只能有一个线程进行资源的访问。
##### 通过下面例子体会一下：有20个苹果供3个人同时吃，
    let people1 = Thread(target: self, selector: #selector(eatApple), object: nil)
    people1.start()
    let people2 = Thread(target: self, selector: #selector(eatApple), object: nil)
    people2.start()
    let people3 = Thread(target: self, selector: #selector(eatApple), object: nil)
    people3.start()
    @objc func eatApple() {
        appleTotalNum -= 1
        NSLog("当前是否是主线程:\(Thread.isMainThread)-当前剩余的苹果数:\(appleTotalNum)")
    }
    
    打印的结果是：当前是否是主线程:false-当前剩余的苹果数:17
               当前是否是主线程:false-当前剩余的苹果数:17
               当前是否是主线程:false-当前剩余的苹果数:17
#### 通过打印结果发现数据错乱，我们期望的结果是，19-18-17，所以我们通过加线程锁进行资源的同步访问，在swift中使用objc_sync_enter()和objc_sync_exit()解决，OC中使用@synchronized()处理，一旦 调用objc_sync_enter以后，整个应用就会被锁定，直到遇到objc_sync_exit，所以一定要注意死锁的问题
     @objc func eatApple() {
        objc_sync_enter(self)
        appleTotalNum -= 1
        NSLog("当前是否是主线程:\(Thread.isMainThread)-当前剩余的苹果数:\(appleTotalNum)")
        objc_sync_exit(self)
    }

    打印结果如下: 当前是否是主线程:false-当前剩余的苹果数:19
                当前是否是主线程:false-当前剩余的苹果数:18
                当前是否是主线程:false-当前剩余的苹果数:17

