### Thread与performSelector
#### Thread 常用属性和方法
    //类属性
    //获取当前线程信息(通过用于调试)
    class var current: Thread { get }      
    //是否是主线程(通过用于调试，判断当前线程是否是主线程)
    class var isMainThread: Bool { get }   
    //获取主线程，一般用于在子线程执行完任务后，回到主线程中执行任务
    class var main: Thread { get }         
    //获取当前线程的调用栈
    class var callStackSymbols: [String] { get }    
    //该线程调用函数的名字数字
    class var callStackReturnAddresses: [NSNumber] { get }  
    //属性
    var name: String?                 线程名称
    var stackSize: Int                线程使用栈区大小(默认是512K)
    var isMainThread: Bool { get }    是否是主线程
    var isExecuting: Bool { get }     是否正在被执行
    var isFinished: Bool { get }      是否已经完成
    var isCancelled: Bool { get }     是否取消
    var threadPriority: Double        设置线程优先级(0-1.0)
    var qualityOfService: QualityOfService  线程服务优先级
    //每个线程都有个字典，在线程中任何地方被访问
    var threadDictionary: NSMutableDictionary { get }    
    //类方法
    //线程终止(在执行任务过程中如果调用该方法，会使线程进入死亡状态)
    class func exit()                       
    class func isMultiThreaded() -> Bool    当前代码运行所在线程是否是子线程
    class func threadPriority() -> Double   线程优先级
    class func sleep(until date: Date)      让线程睡眠多长时间(单位是Date)
    class func setThreadPriority(_ p: Double) -> Bool          设置优先级
    //创建线程(iOS 10.0
    class func detachNewThread(_ block: @escaping () -> Void)  
    //让线程睡眠多长时间(单位是TimeInterval)
    class func sleep(forTimeInterval ti: TimeInterval)         
    class func detachNewThreadSelector(_ selector: Selector, toTarget   
    target: Any, with argument: Any?)
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
    
    let thread1 = Thread(target: self, selector: #selector(method1(dic:)),  
    object: ["key1": "value"])
    thread1.start()
    @objc func method1(dic: [String: String]) {
        NSLog("11111--\(Thread.current)--\(dic)")
    }
    
    打印结果：11111--<NSThread: 0x600001c5d680>{number = 6, name = (null)}--["key1": "value"]
        
#### 1.2 通过类方法创建，不需要手动启动，系统会自动开启线程的执行
    方式一:通过绑定事件来创建线程，这种方式可以为事件传递参数
    Thread.detachNewThreadSelector(#selector(textMethod(title:)),   
    toTarget: self, with: "传递给调用方法的参数")
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
    
    方式一：传递的参数:传递给调用方法的参数--11111--  
    <NSThread: 0x60000075c1c0>{number = 6, name = (null)}
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
    self.performSelector(onMainThread: Selector, with: Any?,   
    waitUntilDone: Bool, modes: [String]?)
    
    self.performSelector(onMainThread: Selector, with: Any?,  
    waitUntilDone: Bool)
    
    在指定的线程中执行指定的方法 
    self.perform(aSelector: Selector, on: Thread, with: Any?,  
    waitUntilDone: Bool, modes: [String]?)
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
    let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
    let thread2 = Thread(target: self, selector: #selector(method2), object: nil)
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
        //默认优先级，主线程和没有设置优先级的线程都默认为这个优先级
        case `default`          
        case utility            普通优先级，用于普通任务
        case background         最低优先级，用于不重要的任务
    }
    
    let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
    let thread2 = Thread(target: self, selector: #selector(method2), object: nil)
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
    let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
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
    2020-04-10 17:46:06 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
    2020-04-10 17:46:06 11111--<NSThread: 0x600002e5f380>{number = 5, name = (null)}
    2020-04-10 17:46:11 WGFcodeNotes[13188:379557] 11111--<NSThread:   
    0x600002e5f380>{number = 5, name = (null)}
    2020-04-10 17:46:11 WGFcodeNotes[13188:379557] 11111--<NSThread:   
    0x600002e5f380>{number = 5, name = (null)}
### 8.线程退出

    let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
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


### 9.performSelector相关的线程
#### 9.1 和线程无关的performSelector方法，这些方法都是在@protocol NSObject中，即NSObject中的协议
    -(id)performSelector:(SEL)aSelector;
    -(id)performSelector:(SEL)aSelector withObject:(id)object;
    -(id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
    -(BOOL)respondsToSelector:(SEL)aSelector;
    
    [self performSelector:@selector(clickChange)];
#### 若self没有实现方法clickChange，则运行项目会**crash**,所以使用该方法最好配合**respondsToSelector**方法一块使用，首先检查self是否实现了该方法，这样可以有效避免程序**crash**

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        if ([self respondsToSelector:@selector(clickChange:withOtherParame:)]) {
            [self performSelector:@selector(clickChange:withOtherParame:) 
            withObject:@"123" withObject:@[@"1",@"2"]];
        }
    }
    -(void)clickChange:(id)parame1 withOtherParame:(id)parame2 {
        NSLog(@"执行了---parame1:%@---parame2:%@",parame1,parame2);
    }
    
    打印结果：执行了---parame1:123---parame2:(
    1,
    2
    )
#### 分析，performSelector方法后面的**withObject:**其实就是传递参数用的

#### 9.2 与NSThread相关的方法
    
    -(void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait   
    modes:(nullable NSArray<NSString *> *)array;
    -(void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait;


    -(void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait
    modes:(nullable NSArray<NSString *> *)array;
    -(void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
    -(void)performSelectorInBackground:(SEL)aSelector withObject:(nullable id)arg;


    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelectorOnMainThread:@selector(clickChange:) withObject:@"1" waitUntilDone:YES];
        NSLog(@"结束了");
    }
    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---thread: %@",parame1,[NSThread currentThread]);
    }
    
    打印结果: 开始了
            执行了---parame1:1---thread: <NSThread: 0x280096f00>{number = 1, name = main}
            结束了

#### **performSelectorOnMainThread**方法就是回到主线程执行任务；**withObject**携带的参数；**waitUntilDone**是否阻塞当前线程；该方法是工作在主线程RunLoop运行循环中的NSRunLoopCommonModes模式下的，当从同一个线程中多次调用这个方法时，会导致selector方法选择器排队并以调用相同的顺序执行,如下
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelectorOnMainThread:@selector(clickChange:) withObject:@"1" waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(clickChange:) withObject:@"2" waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(clickChange:) withObject:@"3" waitUntilDone:NO];
        NSLog(@"结束了");
    }

    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---thread:%@",parame1,[NSThread currentThread]);
    }
    打印结果: 开始了
    20:43:47.467101+0800  结束了
    20:43:47.467331+0800 ---parame1:1---thread: <NSThread: 0x281606f00>{number = 1, name = main}
    20:43:47.467484+0800 ---parame1:2---thread: <NSThread: 0x281606f00>{number = 1, name = main}
    20:43:47.467562+0800 执行了---parame1:3---thread: <NSThread: 0x281606f00>{number = 1, name = main}

#### **performSelector:onThread**方法是在指定的线程中执行任务; **onThread**在指定的线程执行selector方法选择器；**waitUntilDone**是否阻塞当前线程; 该方法是工作在**target**线程的RunLoop运行循环中的NSRunLoopCommonModes模式下的
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelector:@selector(clickChange:) onThread:[NSThread currentThread] withObject:@"1" waitUntilDone:YES];
        NSLog(@"结束了");
    }

    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---thread: %@",parame1,[NSThread currentThread]);
    }

    打印结果: 开始了
            执行了---parame1:1---thread: <NSThread: 0x283ae24c0>{number = 1, name = main}
            结束了
#### **performSelectorInBackground**方法会开辟新的线程，将selector方法选择器放在新开辟的线程中执行任务;该方法不会阻塞当前线程；
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelectorInBackground:@selector(clickChange:) withObject:@"1"];
        NSLog(@"结束了");
    }

    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---thread: %@",parame1,[NSThread currentThread]);
    }
    
    打印结果: 开始了
            结束了
            执行了---parame1:1---thread: <NSThread: 0x2812f2a80>{number = 9, name = (null)}

#### 9.3 与NSRunloop相关的**performSelector**方法

    -(void)performInModes:(NSArray<NSRunLoopMode> *)modes block:(void (^)(void))block;  //ios(10.0)
    -(void)performBlock:(void (^)(void))block;        // ios(10.0)

    -(void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument afterDelay:(NSTimeInterval)delay
    inModes:(NSArray<NSRunLoopMode> *)modes;
    
    -(void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument afterDelay:(NSTimeInterval)delay;


    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelector:@selector(clickChange:) withObject:@"1" afterDelay:2.0];
        NSLog(@"结束了");
    }
    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@--thread: %@",parame1,[NSThread currentThread]);
    }
    
    打印结果: 21:12:18.995146+0800 开始了
     21:12:18.995267+0800 结束了
     21:12:20.996874+0800 执行了---parame1:1---crrent thread is <NSThread: 0x2833764c0>{number = 1, name = main}
     
#### 当前在主线程中执行，所以@selector也是在主线程中执行的; 然后我们把afterDelay设置为0秒看看效果
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        [self performSelector:@selector(clickChange:) withObject:@"1" afterDelay:0];
        for (int i = 0 ; i < 10 ; i++) {
            NSLog(@"结束了");
        }
    }
    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---crrent thread is %@",parame1,[NSThread currentThread]);
    }
    
    打印结果: 开始了
    结束了
    结束了
    ......
    结束了
    执行了---parame1:1---crrent thread is <NSThread: 0x282c1af40>{number = 1, name = main}
#### 当我们把**afterDelay**设置为0秒后，执行效果仍然是先执行**结束了**,然后再执行@selector方法选择器，为什么？因为即便延迟时间指定了0秒，不一定会使@selector方法选择器立即执行，选择器仍然在当前线程的运行循环中排队并尽快执行，接下来我们来看下在子线程是什么效果

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"开始了");
        NSThread *thread = [[NSThread alloc]initWithBlock:^{
            [self performSelector:@selector(clickChange:) withObject:@"1" afterDelay:0];
        }];
        [thread start];
        NSLog(@"结束了");
    }

    -(void)clickChange:(id)parame1 {
        NSLog(@"执行了---parame1:%@---crrent thread is %@",parame1,[NSThread currentThread]);
    }
    打印结果: 开始了
             结束了
#### 为什么该方法在子线程中执行时没有打印@selector方法选择器中的信息？因为该方法是依赖Runloop运行循环的，子线程中RunLoop默认是不开启的，所以该方法不会执行，要想执行，必须在该子线程中手动开启RunLoop运行循环

