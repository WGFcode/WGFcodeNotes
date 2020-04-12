### Thread 常用属性和方法
        //类属性
        class var current: Thread { get }      获取当前线程信息(通过用于调试)
        class var isMainThread: Bool { get }   是否是主线程(通过用于调试，判断当前线程是否是主线程)
        class var main: Thread { get }         获取主线程，一般用于在子线程执行完任务后，回到主线程中执行任务
        class var callStackSymbols: [String] { get }    获取当前线程的调用栈
        class var callStackReturnAddresses: [NSNumber] { get }   该线程调用函数的名字数字
        //属性
        var name: String?                 线程名称
        var stackSize: Int                线程使用栈区大小(默认是512K)
        var isMainThread: Bool { get }    是否是主线程
        var isExecuting: Bool { get }     是否正在被执行
        var isFinished: Bool { get }      是否已经完成
        var isCancelled: Bool { get }     是否取消
        var threadPriority: Double        设置线程优先级(0-1.0)
        var qualityOfService: QualityOfService  线程服务优先级
        var threadDictionary: NSMutableDictionary { get }    每个线程都有个字典，在线程中任何地方被访问
        //类方法
        class func exit()                       线程终止(在执行任务过程中如果调用该方法，会使线程进入死亡状态)
        class func isMultiThreaded() -> Bool    当前代码运行所在线程是否是子线程
        class func threadPriority() -> Double   线程优先级
        class func sleep(until date: Date)      让线程睡眠多长时间(单位是Date)
        class func setThreadPriority(_ p: Double) -> Bool          设置优先级
        class func detachNewThread(_ block: @escaping () -> Void)  创建线程(iOS 10.0
        class func sleep(forTimeInterval ti: TimeInterval)         让线程睡眠多长时间(单位是TimeInterval)
        class func detachNewThreadSelector(_ selector: Selector, toTarget target: Any, with argument: Any?)
        //方法
        func cancel()  取消执行
        func start()   开始执行
        func main()    获取主线程
        init()         初始化方法
        convenience init(block: @escaping () -> Void) (iOS 10.0)
        convenience init(target: Any, selector: Selector, object argument: Any?)
        //convenience 便利构造函数特点
        1便利构造函数通常都是写在extension里面
        2便利函数init前面需要加载convenience
        3在便利构造函数中需要明确的调用self.init()

### 1.Thread 创建方式
#### 1.1 通过初始化方式创建，需要手动启动线程，调用start方法
        let thread1 = Thread(target: self, selector: #selector(testMethod), object: nil)
        thread1.start()
        @objc func testMethod() {
            NSLog("11111--\(Thread.current)")
        }
        
        打印结果：11111--<NSThread: 0x600000eecb40>{number = 6, name = (null)}
        
        注意:初始化方法中参数object其实就是传递给任务的参数
        
        let thread1 = Thread.init(target: self, selector: #selector(method1(dic:)), object: ["key1": "value"])
        thread1.start()
        @objc func method1(dic: [String: String]) {
            NSLog("11111--\(Thread.current)--\(dic)")
        }
        
        打印结果： 11111--<NSThread: 0x600001c5d680>{number = 6, name = (null)}--["key1": "value"]
        
#### 1.2 通过类方法创建，不需要手动启动，系统会自动开启线程的执行
        方式一:通过绑定事件来创建线程，这种方式可以为事件传递参数
        Thread.detachNewThreadSelector(#selector(textMethod(title:)), toTarget: self, with: "传递给调用方法的参数")
        方式二:通过将事件封装在block中来创建线程，这种方式无法传递参数
        if #available(iOS 10.0, *) {
            Thread.detachNewThread {
                NSLog("Block方式创建线程并启动")
            }
        } else { // Fallback on earlier versions }
        @objc func textMethod(title: String) {
            NSLog("传递的参数:\(title)--11111--\(Thread.current)")
        }
        
        打印结果：
        
        方式一：传递的参数:传递给调用方法的参数--11111--<NSThread: 0x60000075c1c0>{number = 6, name = (null)}
        方式二：11111--<NSThread: 0x6000007ba840>{number = 7, name = (null)}
#### 1.3 通过NSObject扩展的方法隐式创建并自动启动线程
        self.performSelector(inBackground: #selector(testMethod), with: nil)
        @objc func testMethod() {
            NSLog("11111--\(Thread.current)")
        }
        
        打印结果: 11111--<NSThread: 0x6000015f3480>{number = 6, name = (null)}
        
### 2. Thread 状态
   * 新建: 创建线程对象(仅针对初始化的创建方式，类方法和performSelector方法没有该状态)
   * 就绪: 向对象发送start消息，线程对象被加入到可调度线程池，供CPU调度
   * 运行: 线程执行完成之前,状态就在就绪和运行之间切换
   * 阻塞: 当满足一定条件时，可以使用sleep(until: <#T##Date#>)/sleep(forTimeInterval: <#T##TimeInterval#>)/@synchronized(self)线程锁阻塞当前线程，做一些其他操作，线程对象进入阻塞状态后，会被从“可调度线程池”中移出，CPU 不再调度
   * 死亡: 正常情况下线程执行完毕后就死亡，但如果在线程执行任务过程中调用Thread.exit()方法强行终止，那么后续代码都不会执行也会导致线程死亡(非正常死亡)
#### 如果调用cancel()方法，并不会销毁线程，该方法只是改变了线程的状态标识，需要在线程执行方法中判断isCancelled是否等于Yes，如果YES，则调用exit()方法销毁线程

### 3. Thread 线程间通信
#### 一般线程间通信主要指下面几种方法，子线程执行耗时操作，在主线程中进行UI更新
        在主线程中执行指定方法
        self.performSelector(onMainThread: Selector, with: Any?, waitUntilDone: Bool, modes: [String]?)
        self.performSelector(onMainThread: Selector, with: Any?, waitUntilDone: Bool)
        在指定的线程中执行指定的方法 
        self.perform(aSelector: Selector, on: Thread, with: Any?, waitUntilDone: Bool, modes: [String]?)
        self.perform(aSelector: Selector, on: Thread, with: Any?, waitUntilDone: Bool)
        在开启的子线程中执行指定的方法
        self.performSelector(inBackground: Selector, with: Any?)

### 4. Thread 线程间资源共享造成的抢夺&线程锁
#### 当多个线程访问同一资源时，会发生资源数据的抢夺和数据错误，所以需要线程锁来实现资源的同步使用，即同一时间，只能有一个线程进行资源的访问。
#### 通过下面例子体会一下：有20个苹果供3个人同时吃，
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

        打印结果：当前是否是主线程:false-当前剩余的苹果数:17
                当前是否是主线程:false-当前剩余的苹果数:17
                当前是否是主线程:false-当前剩余的苹果数:17
#### 我们期望的结果是:19-18-17，多个线程访问同一资源导致数据不符合实际业务 逻辑，为了保证同一时间只有一个线程访问资源，我们可以通过加线程锁来解决，在swift中使用objc_sync_enter()和objc_sync_exit()解决，OC中使用@synchronized()处理，一旦 调用objc_sync_enter以后，整个应用就会被锁定，直到遇到objc_sync_exit，所以这个方法是成对出现的，避免造成死锁
         @objc func eatApple() {
            objc_sync_enter(self)
            appleTotalNum -= 1
            NSLog("当前是否是主线程:\(Thread.isMainThread)-当前剩余的苹果数:\(appleTotalNum)")
            objc_sync_exit(self)
        }

        打印结果: 当前是否是主线程:false-当前剩余的苹果数:19
                当前是否是主线程:false-当前剩余的苹果数:18
                当前是否是主线程:false-当前剩余的苹果数:17

### 5. Thread threadPriority优先级设置
        NSLog("开始了")
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        let thread2 = Thread.init(target: self, selector: #selector(method2), object: nil)
        thread1.threadPriority = 0.3
        thread2.threadPriority = 0.8
        thread1.start()
        thread2.start()
        NSLog("完成了")

        @objc func method1() {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)--\(Thread.threadPriority())")
            }
        }
        @objc func method2() {
            for _ in 0...2 {
                NSLog("22222--\(Thread.current)--\(Thread.threadPriority())")
            }
        }

        打印结果: 开始了
                完成了
                22222--<NSThread: 0x60000064c540>{number = 7, name = (null)}--0.8064516129032258
                11111--<NSThread: 0x60000064c800>{number = 6, name = (null)}--0.3064516129032258
                22222--<NSThread: 0x60000064c540>{number = 7, name = (null)}--0.8064516129032258
                11111--<NSThread: 0x60000064c800>{number = 6, name = (null)}--0.3064516129032258
                22222--<NSThread: 0x60000064c540>{number = 7, name = (null)}--0.8064516129032258
                11111--<NSThread: 0x60000064c800>{number = 6, name = (null)}--0.3064516129032258
#### threadPriority(Double类型)默认的优先级是0.5，优先级取值范围是0-1.0,设置优先级只能去控制多个线程之间哪个线程先开始执行任务，而不能控制任务的真实顺序；优先级高的线程里面的任务最先执行.The priorities in this range are mapped to the operating system's priority values. A “typical” thread priority might be 0.5, but because the priority is determined by the kernel, there is no guarantee what this value actually will be.这是苹果给的说明，意思就是优先级的值是由内核决定的，它确切的值不能保证是多少
        
### 6. 服务优先级 qualityOfService
#### 苹果文档是这么解释的:Used to indicate the nature and importance of work to the system. Work with higher quality of service classes receive more resources than work with lower quality of service classes whenever there is resource contention.意思就是标识这个任务的重要性，每当存在资源竞争时，服务质量高的任务将获得更多的资源
        public enum QualityOfService : Int {
            case userInteractive    最高优先级，用于用户交互事件
            case userInitiated      次高优先级，用于用户需要马上执行的事件
            case `default`          默认优先级，主线程和没有设置优先级的线程都默认为这个优先级
            case utility            普通优先级，用于普通任务
            case background         最低优先级，用于不重要的任务
        }
        
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        let thread2 = Thread.init(target: self, selector: #selector(method2), object: nil)
        thread1.qualityOfService = .userInteractive
        thread2.qualityOfService = .background
        thread1.start()
        thread2.start()
        @objc func method1() {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        @objc func method2() {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        
        打印结果: 11111--<NSThread: 0x6000011287c0>{number = 5, name = (null)}
                 11111--<NSThread: 0x6000011287c0>{number = 5, name = (null)}
                 22222--<NSThread: 0x600001128a40>{number = 6, name = (null)}
                 22222--<NSThread: 0x600001128a40>{number = 6, name = (null)}
#### 服务优先级高的任务能优先获得更多的资源
### 7. 线程睡眠，使线程处于等待状态
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        @objc func method1() {
            for i in 0...3 {
                NSLog("11111--\(Thread.current)")
                if i == 1 {
                    Thread.sleep(forTimeInterval: 5.0)
                }
            }
        }

        打印结果:
        
        2020-04-10 17:46:06.244175+0800 WGFcodeNotes[13188:379557] 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
        2020-04-10 17:46:06.244476+0800 WGFcodeNotes[13188:379557] 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
        2020-04-10 17:46:11.248910+0800 WGFcodeNotes[13188:379557] 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
        2020-04-10 17:46:11.249298+0800 WGFcodeNotes[13188:379557] 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
### 8.线程退出

        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        @objc func method1() {
            for i in 0...3 {
                NSLog("11111--\(Thread.current)")
                if i == 1 {
                    Thread.exit()
                }
            }
            NSLog("方法1执行完成了")
        }
        
        打印结果: 11111--<NSThread: 0x600002436900>{number = 5, name = (null)}
                11111--<NSThread: 0x600002436900>{number = 5, name = (null)}
#### 正常情况下，线程中任务执行完成后，线程就销毁了，但是如果在执行任务过程中调用exit()方法，任务就会被终止，线程也提前进入死亡状态



