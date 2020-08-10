## GCD
### GCD(Grand Central Dispatch)：伟大的中央调度器，是苹果公司为多核的并行运算提供的一种基于纯C语言的解决方案
### GCD特点
     1.会自动利用更多的CPU内核
     2.自动管理线程的生命周期(创建线程/调度任务/销毁线程)
     3.我们只需要告诉GCD想要执行什么任务，并追加任务到队列中即可，不需要编写任何线程管理的代码(GCD提供的是系统级线程管理提高执行效率)
### GCD易发问题:
     1.多个线程访问/更新相同的资源导致数据不一致(数据竞争);
     2.停止等待事件的线程会导致多个线程互相持续等待(死锁); 
     3.使用太多线程会消耗大量的内存,主要就是引起大量的上下文切换,大幅度降低系统的响应性能
#### 尽管会出现易发的问题,但仍应当使用多线程编程的原因: 因为多线程编程可保证应用程序的响应性能
     
     
## GCD 总结
* GCD处理多线程，首先就是创建队列，然后向队列中添加任务；
* GCD中队列有串行队列，并发队列，全局队列(系统创建的一种并发队列)，主队列(系统创建的一种串行队列)；
* 串行队列和并发队列是需要我们手动去创建的，而全局队列和主队列是系统提供的；
* 串行队列每次只有一个任务被执行，一个任务执行完成后才执行下一个任务(等待现在执行中处理结果)；
* 并发队列中的任务，在开启多个线程的情况下可以并发执行，并发队列中只有在添加异步任务的情况下才会  
并发执行任务(不等待现在执行中处理结果)；
* 串行队列和主队列最大区别就是，主队列中的任务必须在主线程中执行；
* GCD中任务分为 同步任务和异步任务；
* 同步任务会阻塞当前线程，不具备开启线程的能力；
* 异步任务不会阻塞当前线程，具备开启线程的能力；
* 异步任务不一定会开启新的线程，比如在串行队列+异步任务中，多个任务却只开启了一条线程；在主线程+异步任务中，没有开启线程，因为所有的异步任务都是在主线程中执行的
* 主队列+同步任务会造成死锁
* 一般项目中用到的最多的就是 并发队列+异步任务 来实现并发执行(多条线程同一时间执行多个任务)，提高执行效率
* GCD中DispatchGroup组其实就是用来将多个任务存放在group中，然后实现异步调用
* GCD组中notify方法，当添加到group中所有的任务都执行完成后，才开始执行 notify 中Block内的任务，一般可以用于任务C依赖任务A任务B的完成这样的业务逻辑中，notify不会阻塞当前线程
* 在GCD组中，如果我想控制组内的任务执行顺序，比如组内有任务A，任务B，任务C都是异步执行的，执行顺序是无序的，如果想让组内的任务按照任务A->任务B->任务C顺序执行，怎么办？这时候就可以用group中的wait方法来控制，任务A->group.wait()->任务B->group.wait()-任务C， wait方法会阻塞当前线程
* 除了wait方法控制group组内的任务执行顺序(实现多线程中的同步，还可以使用信号量DispatchSemaphore来控制)，创建信号量并设置初始信号量值为0->任务A(A执行完成后调用signal方法使信号量+1)->wait(信号量为0时，阻塞wait后的任务执行，直到信号量值大于0)->任务B(signal)-wait()->任务C
* GCD中实现多线程任务的同步执行，其实同步执行就是控制多个异步任务的执行顺序，有两种方式：第一种就是GCD组内可以利用wait方法阻塞当前线程达到同步，第二种就是利用信号量的signal和wait方法实现多个任务之间的同步执行，区别就是第一种只能用在group种，第二种可以用在group中也可以用在非group中使用
* GCD组中使用notify和wait方法时，需要注意，如果组内的任务中嵌套了异步任务，例如group中有任务A(异步任务A1)，任务B，任务C，如果遇到这种情况【组内所有任务完成后，才notify任务D开始执行】和【利用wait方法来使任务A执行完成后才开始执行任务B】时，其实是不能满足我们的要求的，因为任务A中嵌套了异步任务A1，而异步任务是直接返回的，所以notify或者wait就认为任务A完成了，其实并没有完成，这种情况下 ，我们需要使用group中的enter和leave方法，来分别告诉group（或者理解成告诉notify或者wait）存在一个未完成的任务和未完成的任务已经离开了，来实现任务A真正的执行完成了


## 1.GCD中重要的概念: 任务、队列

###  任务：
#### 任务就是一段执行的代码，即GCD中的Block内执行的代码；分为同步(sync)和异步(async)
* 同步(sync): 任务只能在当前线程中执行，不具备开启新线程的能力，会阻塞当前线程，即必须等待任务完成后才能执行后续的操作，同一时间只有一个任务被执行；
* 异步(async)：任务可以在多个线程中执行，具备开启新线程的能力，不会阻塞当前线程，即不需要等待任务完成就可以执行后续的操作，同一时间可以有多个任务被执行；
##### 注意： 异步只是具备开启新线程的能力，但不是一定会开启新线程，需要根据任务所在的队列来判断，比如串行队列+多个异步任务中只开启了一条新线程；主队列+多个异步任务中并没有开启新的线程，所有异步任务都是在主线程中执行的；


### 队列
#### 队列就是用来存放任务的地方，队列是一种特殊的线性表(先用先出)，GCD中主要分串行队列和并发队列，根据是不是系统创建的又扩展了全局队列和主队列
* 串行队列：每次只有一个任务被执行，一个任务执行完毕后，再执行下一个任务(等待现在执行中的处理结果),  
例如任务ABC,任务B要等任务A完成后执行,任务C要等任务B完成后才能执行; 只使用一个线程

        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        第一个参数是队列名称: 该名称也会出现在应用程序crash所生成的CrashLog中,所以名称尽量易懂方便寻找问题
    * 并发队列：可以让多个任务并发（同时）执行,并发执行的处理数量取决于当前系统的状态;  
    例如任务ABC,任务B不用等待任务A完成后执行,任务C也不需要等待任务B的完成后执行; 可以使用多个线程

          let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
    
* 主队列: 其实就是串行队列的一种,区别就是主队列中的任务只能在主线程中执行
    let mainQueue = DispatchQueue.main
* 全局队列: 其实就是并发队列的一种，区别就是并发队列需要我们自己创建，而全局队列由系统提供 
    let globalQueue = DispatchQueue.global()
    
    
### 任务的创建方式
#### 任务的创建是依托队列的，无论是串行队列，并发队列，主队列，还是全局队列，创建方式都有下列几种
        串行队列
        let queue = DispatchQueue.init(label: "串行队列名称")
        并发队列
        let queue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        主队列
        let queue = DispatchQueue.main
        全局队列
        let queue = DispatchQueue.global()
        
        创建异步任务
        方式一:将异步任务封装到Block中
        queue.async {
            code
        }
        方式二: 将异步任务封装在DispatchWorkItem对象中
        queue.async(execute: DispatchWorkItem)
        方式三: 将异步任务封装在DispatchWorkItem对象中，并将其放到指定的group组中
        queue.async(group: DispatchGroup, execute: DispatchWorkItem)
        方式四: 将任务封装在Block中，设置所在的group组，设置任务的服务质量或者说是优先级，对DispatchWorkItem对象的相关设置
        queue.async(group: DispatchGroup?, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute: () -> Void)
        方式五: 和方式四一样，只是去掉了相对应的设置项或者是采用了默认的设置
        queue.async(execute: () -> Void)
        
        创建同步任务
        方式一: 将同步任务封装在block中
        queue.sync {
            code
        }
        和方式一是一样的
        queue.sync(execute: () -> Void)
        方式二: 将任务封装在DispatchWorkItem对象中
        queue.sync(execute: DispatchWorkItem)
## DispatchWorkItem/DispatchQoS/DispatchWorkItemFlags解析
### 1.DispatchWorkItem对象，在创建任务的时候可以将任务封装成DispatchWorkItem对象。苹果给出文档说明:The work you want to perform, encapsulated in a way that lets you attach a completion handle or execution dependencies. A DispatchWorkItem encapsulates work to be performed on a dispatch queue or within a dispatch group(想要执行的工作以某种方式封装，可以附加完成句柄或执行依赖项。 DispatchWorkItem封装要在调度队列上或在调度组内执行的工作)

        func perform()                      开始执行
        func wait()                         等待
        func cancel()                       取消执行
        var isCancelled: Bool { get }       是否取消执行了
        func wait(timeout: DispatchTime) -> DispatchTimeoutResult           设置等待的时间
        func wait(wallTimeout: DispatchWallTime) -> DispatchTimeoutResult   设置等待的时间
        func notify(queue: DispatchQueue, execute: DispatchWorkItem)        通知指定队列完成
        func notify(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], queue: DispatchQueue, execute: @escaping @convention(block) () -> Void)
        init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], block: @escaping @convention(block) () -> Void)
#### DispatchWorkItem核心就是封装一个可以执行的闭包。可以通过perform()方法直接执行内部的闭包，执行顺序是按照代码顺序执行的；如果是添加到队列中，则封装的闭包由队列来调度，也就不需要执行perform方法，执行顺序是根据队列中的任务来决定的；也可以设置闭包任务的延时/等待/取消/通知等

        NSLog("开始了")
        let workItem = DispatchWorkItem.init {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        workItem.perform()
        NSLog("完成了")
        
        打印结果: 开始了
                11111--<NSThread: 0x600003bed040>{number = 1, name = main}
                11111--<NSThread: 0x600003bed040>{number = 1, name = main}
                11111--<NSThread: 0x600003bed040>{number = 1, name = main}
                完成了
                
        NSLog("开始了")
        let workItem = DispatchWorkItem.init {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        DispatchQueue.global().async(execute: workItem)
        NSLog("完成了")

        打印结果: 开始了
                完成了
                11111--<NSThread: 0x6000012a5d00>{number = 6, name = (null)}
                11111--<NSThread: 0x6000012a5d00>{number = 6, name = (null)}
                11111--<NSThread: 0x6000012a5d00>{number = 6, name = (null)}
### 2. DispatchQoS 服务质量等级
#### 苹果文档说明:The quality of service, or the execution priority, to apply to tasks.(用于设置任务的服务质量或者执行优先级)。通过设置服务等级来指定任务的重要性，系统会对其进行优先级排序并相应地对其进行调度，优先级高的任务可以获得更多系统资源，更快的被执行。DispatchQoS是个结构体类型，有如下项
        优先级从高到低
        public static let userInteractive: DispatchQoS
        public static let userInitiated: DispatchQoS
        public static let `default`: DispatchQoS
        public static let utility: DispatchQoS
        public static let background: DispatchQoS
        public static let unspecified: DispatchQoS

### 3. DispatchWorkItemFlags
#### 苹果文档说明:A set of behaviors for a work item, such as its quality-of-service class and whether to create a barrier or spawn a new detached thread.(工作项的一组行为，例如其服务质量类以及是否创建屏障或生成新的分离线程。)详细的应该查看[_block _flags _t](https://developer.apple.com/documentation/dispatch/dispatch_block_flags_t),项目中最常用到的就是设置barrier栅栏，等到栅栏前的任务都完成后才执行栅栏后的任务

        static let barrier: DispatchWorkItemFlags               使工作项在提交到并发队列时充当障碍块。
        static let detached: DispatchWorkItemFlags              取消工作项的属性与当前执行上下文的关联。
        static let assignCurrentContext: DispatchWorkItemFlags  设置工作项的属性以匹配当前执行上下文的属性。
        static let noQoS: DispatchWorkItemFlags                 执行工作项，而不分配服务质量等级。
        static let inheritQoS: DispatchWorkItemFlags            首选与当前执行上下文关联的服务质量类。
        static let enforceQoS: DispatchWorkItemFlags            首选与该块关联的服务质量类。

        NSLog("开始了")
        let queue = DispatchQueue.init(label: "并发队列", attributes: .concurrent)
        queue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        queue.async(flags: .barrier) {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        queue.async {
            for _ in 0...1 {
                NSLog("44444--\(Thread.current)")
            }
        }
        NSLog("完成了")
         
        打印结果: 开始了
                完成了
                11111--<NSThread: 0x6000010ea640>{number = 3, name = (null)}
                11111--<NSThread: 0x6000010ea640>{number = 3, name = (null)}
                22222--<NSThread: 0x6000010ea640>{number = 3, name = (null)}
                22222--<NSThread: 0x6000010ea640>{number = 3, name = (null)}
                44444--<NSThread: 0x6000010ea640>{number = 3, name = (null)}
                44444--<NSThread: 0x6000010ea640>{number = 3, name = (null)}

#### 设置队列中任务的栅栏barrier属性，可以使队列中设置栅栏任务(任务2)前的任务(任务1)先执行，等任务1执行完成后才执行队列中栅栏任务后的任务(任务4)，这个过程并不会阻塞当前线程。


##  队列+任务组合
### 1.1 串行队列+同步任务
        //1串行队列+单个同步任务
        NSLog("开始了，当前线程--\(Thread.current)")
        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        serialQueue.sync {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        NSLog("结束了")
        打印结果: 开始了，当前线程--<NSThread: 0x60000060ed80>{number = 1, name = main}
                11111--<NSThread: 0x60000060ed80>{number = 1, name = main}
                11111--<NSThread: 0x60000060ed80>{number = 1, name = main}
                11111--<NSThread: 0x60000060ed80>{number = 1, name = main}
                结束了
        
#### 分析：将同步任务添加到串行队列中，同步任务会阻塞当前的线程(主线程)，直到串行队列中的同步任务完成后才执行后续的任务(打印了"结束了"信息)；思考->如果当前线程不是主线程，会不会阻塞当前线程？
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        @objc func method1() {
            NSLog("开始了，当前线程--\(Thread.current)")
            let serialQueue = DispatchQueue.init(label: "串行队列名称")
            serialQueue.sync {
                for _ in 0...2 {
                    NSLog("11111--\(Thread.current)")
                }
            }
            NSLog("结束了")
        }
        
        打印结果: 开始了，当前线程--<NSThread: 0x600001b26ac0>{number = 6, name = (null)}
                11111--<NSThread: 0x600001b26ac0>{number = 6, name = (null)}
                11111--<NSThread: 0x600001b26ac0>{number = 6, name = (null)}
                11111--<NSThread: 0x600001b26ac0>{number = 6, name = (null)}
                结束了

#### 分析:如果当前线程不是主线程，同步任务仍然会阻塞当前的线程，直到队列中的同步任务完成后才执行后续的操作；思考->如果串行队列中放多个同步任务，那么这些同步任务之间的执行顺序是什么样的?
        NSLog("开始了")
        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        serialQueue.sync {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        serialQueue.sync {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        serialQueue.sync {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果：开始了
                11111--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                11111--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                22222--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                22222--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                33333--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                33333--<NSThread: 0x6000027f56c0>{number = 1, name = main}
                结束了

#### 分析：串行队列中添加多个同步任务，首先就是同步任务会阻塞当前线程，直到队列中所有任务都完成后才执行后续的操作；其次队列中任务之间执行顺序是串行的，即按照顺序一个一个的执行，同一时间只有一个任务被执行
#### 结论；同步任务+串行队列   不会开启新的线程，会阻塞当前线程(可以是主线程也可以是非主线程),队列中任务之间的执行顺序是串行的，会按照顺序一个一个的执行，同一时间只能有一个任务被执行。


### 1.2 串行队列+异步任务
        NSLog("开始了")
        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        serialQueue.async {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        serialQueue.async {
            for _ in 0...2 {
                NSLog("22222--\(Thread.current)")
            }
        }
        serialQueue.async {
            for _ in 0...2 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果：开始了
                结束了
                11111--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                11111--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                11111--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                22222--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                22222--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                22222--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                33333--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                33333--<NSThread: 0x600000e02000>{number = 5, name = (null)}
                33333--<NSThread: 0x600000e02000>{number = 5, name = (null)}
#### 分析: 串行队列中添加异步任务，不会阻塞当前的线程，虽然添加了多个任务，但只开启了一条新的子线程，多个异步任务之间的执行顺序也是按照串行顺序执行的，即一个任务完成后才能执行下一个任务，同一时间只有一个任务被执行。
#### 结论: 串行队列+异步任务   只会开启一条新的线程，不会阻塞当前的线程；异步任务之间的执行顺序是串行的，任务按照顺序在新开的线程中一个一个的执行，同一时间只有一个任务被执行。

##### 心得体会: 同步任务会阻塞当前线程，异步任务不会阻塞当前线程，阻塞不阻塞针对的是队列中的所有任务是否对队列外的后续任务有阻塞；而队列中的任务之间的执行顺序要看所在的队列是串行的还是并发的

### 1.3 并发队列+同步任务
        //3.并发队列+多个同步任务
        NSLog("开始了")
        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrencyQueue.sync {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        concurrencyQueue.sync {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        concurrencyQueue.sync {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果: 开始了
                11111--<NSThread: 0x600003aaad80>{number = 1, name = main}
                11111--<NSThread: 0x600003aaad80>{number = 1, name = main}
                22222--<NSThread: 0x600003aaad80>{number = 1, name = main}
                22222--<NSThread: 0x600003aaad80>{number = 1, name = main}
                33333--<NSThread: 0x600003aaad80>{number = 1, name = main}
                33333--<NSThread: 0x600003aaad80>{number = 1, name = main}
                结束了

#### 分析：因为是同步任务，所以不会开启新的线程，而且会阻塞当前的线程；虽然是在并发队列中，但是由于没有开启新的线程，只能在当前线程中执行，并不具备并发执行的条件，所以任务之间的执行顺序只能是串行的，即一个任务完成后才能执行下一个任务，同一时间只能有一个任务被执行

#### 结论：并发队列+同步任务 不会开启新的线程，会阻塞当前线程，队列中所有的任务只能在当前线程中执行；队列中的任务之间的执行顺序是串行的，即同一时间只能有一个任务被执行 

##### 心得体会：其实 并发队列+同步任务 和 串行队列+同步任务 的效果是一样的，都是阻塞当前线程，都没有开启新的线程，任务之间执行顺序都是串行的，即一个任务完成后才能执行下一个任务

### 1.4并发队列+异步任务
        //4.并发队列+异步任务
        NSLog("开始了")
        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrencyQueue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        concurrencyQueue.async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        concurrencyQueue.async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果: 开始了
                结束了
                22222--<NSThread: 0x600003c540c0>{number = 6, name = (null)}
                33333--<NSThread: 0x600003c81d00>{number = 3, name = (null)}
                11111--<NSThread: 0x600003ca5380>{number = 4, name = (null)}
                22222--<NSThread: 0x600003c540c0>{number = 6, name = (null)}
                33333--<NSThread: 0x600003c81d00>{number = 3, name = (null)}
                11111--<NSThread: 0x600003ca5380>{number = 4, name = (null)}
                
#### 分析：因为添加的是异步任务，所以没有阻塞当前的线程，并且开启了新的线程；由于是并发队列，并且开启了新的线程，所以队列中的任务是并发执行的，即同一时间有多个任务在多个子线程中并发执行，但是这些任务之间谁先执行谁先完成都是不确定的

#### 总结：并发队列+异步任务 会开启新的线程，不会阻塞当前线程；队列中的任务之间执行顺序是并行的，谁先执行谁先执行完成是不确定的，同一时间有多个任务被执行。这是项目中用到最多的组合来实现多线程编程
    
### 1.5 主队列+同步任务
        public override func viewDidLoad() {
            super.viewDidLoad()
            self.test()
        }
        private func test() {
            //5.主队列+同步任务
            NSLog("开始了")
            let mainQueue = DispatchQueue.main
            mainQueue.sync {
                for _ in 0...1 {
                    NSLog("11111--\(Thread.current)")
                }
            }
            mainQueue.sync {
                for _ in 0...1 {
                    NSLog("22222--\(Thread.current)")
                }
            }
            NSLog("结束了")
        }
        
        打印结果: 开始了
        (lldb) 会发生crash
#### 分析：主队列其实是一种串行队列，同步任务会阻塞当前线程;首先test()方法就是在主线程中执行的，在方法中遇到了第一个同步任务，第一个同步任务会阻塞test方法的继续执行，但testMethod方法又会等待第一个同步任务，相互等待，就造成了死锁
#### 总结：主队列+同步任务 主队列即串行队列，所有任务必须在主线程中完成；造成同步任务的相互等待，会造成死锁

### 1.6 主队列+异步任务
        //6.主队列 + 异步任务
        NSLog("开始了")
        let mainQueue = DispatchQueue.main
        mainQueue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        mainQueue.async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        mainQueue.async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果:开始了
                结束了
                11111--<NSThread: 0x600003822d80>{number = 1, name = main}
                11111--<NSThread: 0x600003822d80>{number = 1, name = main}
                22222--<NSThread: 0x600003822d80>{number = 1, name = main}
                22222--<NSThread: 0x600003822d80>{number = 1, name = main}
                33333--<NSThread: 0x600003822d80>{number = 1, name = main}
                33333--<NSThread: 0x600003822d80>{number = 1, name = main}
#### 分析：主队列中所有的任务都是在主线程中执行的，所以即便是异步任务具备开启线程的能力，在主队列中也不会开启新的线程；因为添加的是异步任务,所以不会阻塞当前的线程；主队列中的任务之间的执行顺序是串行的，即一个任务完成后才会执行下一个任务，同一时间只能有一个任务被执行

#### 总结：主队列+异步任务 所有任务都在主线程中执行，不会开启新的线程，不会阻塞当前线程，任务之间是按照顺序串行之行的

##### 心得体会:同步不具备开启线程能力，异步具备开启线程的能力，但是不是所有的异步操作都能够开启新的线程，比如主队列中的异步任务就是在主线程中执行任务的，并没有开启线程

### 1.7 全局队列+同步任务
        //7.全局队列(并发队列) + 同步任务
        NSLog("开始了")
        let globalQueue = DispatchQueue.global()
        globalQueue.sync {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        globalQueue.sync {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        globalQueue.sync {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果:开始了
                11111--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                11111--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                22222--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                22222--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                33333--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                33333--<NSThread: 0x600001ba2d80>{number = 1, name = main}
                结束了
#### 分析：因为是同步任务，所以阻塞了当前的线程并且没有开启新线程，任务之间是按照顺序执行的
#### 总结: 全局队列+同步任务 没有开启新线程，同步任务阻塞了当前线程，同步任务之间是按照顺序执行的，因为没有开启新的线程，所以即便是在全局队列中也只能按照顺序执行，即同一时间只能有一个任务被执行
### 1.8 全局队列+异步任务
        //8.全局队列(并发队列) + 异步任务
        NSLog("开始了")
        let globalQueue = DispatchQueue.global()
        globalQueue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        globalQueue.async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        globalQueue.async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果: 开始了
                结束了
                22222--<NSThread: 0x600001cc2c00>{number = 6, name = (null)}
                11111--<NSThread: 0x600001cec740>{number = 4, name = (null)}
                33333--<NSThread: 0x600001cc2ac0>{number = 5, name = (null)}
                11111--<NSThread: 0x600001cec740>{number = 4, name = (null)}
                22222--<NSThread: 0x600001cc2c00>{number = 6, name = (null)}
                33333--<NSThread: 0x600001cc2ac0>{number = 5, name = (null)}

#### 分析：因为是异步任务，所以不会阻塞当前的线程；开启了新的线程；队列重任务之间的执行顺序是并发的(谁先执行谁先执行完成是不确定的),即同一时间可以有多个任务被执行
##### 总结: 全局队列+异步任务 开启新线程；不会阻塞当前线程；队列中任务之间是并发执行的；这个也是项目中实现多线程最常用的组合

    
## 汇总
    1. GCD多线程的实现就是分两步：首先创建队列  然后添加任务到队列
    2. 同步不具备开启线程的能力；异步具备开启线程的能力，但并不是所有的异步任务都能开启线程，比如主线程+异步任务就是异步任务都是在主线程中执行的，虽然添加的是异步任务，但并没有开启新的线程
    3.主队列和串行队列区别：主队列是系统创建的串行队列，串行队列是需要程序员自己创建的队列
    4.全局队列和并发队列:全局队列是系统创建的并发队列，并发队列是需要程序员自己创建的队列
    5.同步任务会阻塞当前线程(中断当前 任务，立即执行新任务)，异步任务不会阻塞当前线程(不会中断当前任务，而是等待执行新任务)，阻塞的含义其实是:（队列+任务）这一堆代码是否会阻塞它后续的操作(后续的任务)
    6.任务(指的是放在队列中的任务)执行顺序,是根据队列的类型来判断的；串行队列中，任务一定是按照顺序执行的(除了主线程的同步任务会发生死锁crash外)，并发队列中，在(并发队列+异步任务/全局队列+异步任务)条件下任务是并发执行的，在(并发队列+同步任务/全局队列+同步任务)
    7.          串行队列           并发队列            主队列             全局队列

              会阻塞当前线程      会阻塞当前线程       会阻塞当前线程      会阻塞当前线程
    同步任务    不开启线程          不开启线程        在当前主线程中执行     不开启线程
              任务顺序执行        任务顺序执行           死锁            任务顺序执行
              
              不会阻塞当前线程    不会阻塞当前线程      不会阻塞当前线程     不会阻塞当前线程
    异步任务    开启一条线程         开启多条线程       在当前主线程中执行    开启多条线程 
              顺序执行任务         并发执行任务        顺序执行任务        并发执行任务
    8.项目中实现多线程编程用到最多的组合就是:[并发队列+异步任务],[全局队列+异步任务]
    
## 2. GCD组
### GCD组(DispatchGroup) 是什么？Apple文档这么说的A group of blocks submitted to queues for asynchronous invocation. 白话就是将【存放在队列中的多个Block(多个任务)】放在一个组里面，用于异步调用。  
当我们想在追加多个任务完层后执行结果处理任务,虽然串行队列和并发队列都可以实现,但是它们实现起来代码量会比较  
大,所以GCD组出现了;GCD组常用的方法分析如下

### 2.1 通知方法notify  
#### 当group中所有的任务都执行完成时，通知去执行接下来的操作,GCD组会监视组内任务执行的结果,一旦检测到  
所有任务都执行结束,就会将结果的处理任务(notify中Block代码块)添加到队列中去执行

        NSLog("开始了")
        创建组
        let group = DispatchGroup()
        将全局队列(并发队列)+异步任务添加到group中
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("组的任务都已经完成了--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        NSLog("完成了")
        
        打印结果: 开始了
                完成了
                33333--<NSThread: 0x600002ff8540>{number = 7, name = (null)}
                11111--<NSThread: 0x600002fd4e80>{number = 6, name = (null)}
                22222--<NSThread: 0x600002fdc080>{number = 3, name = (null)}
                组的任务都已经完成了--<NSThread: 0x600002fdc080>{number = 3, name = (null)}

#### 分析：从打印结果说明->GCD组Group中的notify方法不会阻塞当前的线程；无论组内任务的添加顺序是在notify方法前还是notify后，只要是在同一个组group中，notify内的代码执行都会等待组内的任务完成后才去执行；group组内添加的是全局队列+异步任务，所以组内的任务是并发执行的，即谁先执行谁先执行完成都是不确定的，同一时间有多个任务被执行。

### 2.2 等待方法wait 
#### 会阻塞当前线程，group中指定的任务完成后才开始执行后面的任务
        NSLog("开始了")
        let group = DispatchGroup()
        //将全局队列(并发队列)+异步任务添加到group中
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            //给任务1添加个耗时的任务，来验证wait阻塞线程
            Thread.sleep(forTimeInterval: 5.0)
            NSLog("11111--\(Thread.current)")
        }))
        group.wait()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("组的任务都已经完成了--\(Thread.current)")
        }))
        NSLog("完成了")
        
        打印结果: 18:08:16.547034+0800 开始了
                18:08:21.547895+0800 11111--<NSThread: 0x6000028c8e40>{number = 7, name = (null)}
                18:08:21.548411+0800 完成了
                18:08:21.548498+0800 22222--<NSThread: 0x600002892240>{number = 8, name = (null)}
                18:08:21.549064+0800 组的任务都已经完成了--<NSThread: 0x600002892240>{number = 8, name = (null)}
        
#### 分析：从打印结果说明->GCD组Group的wait方法会阻塞当前的线程，当wait()方法前的任务执行完成后，才能执行wait方法后的任务

### 🤔思考：上面对notify和wait两个方法的使用说明中，我们使用的是全局队列+异步任务的组合，如果在异步任务中嵌套了异步任务，我们知道异步任务是直接返回的，那么我们的notify和wait方法就会认为这些任务执行完成了，但实际上嵌套的异步任务可能并没有执行完成，如何保证嵌套的异步任务真的完成了，然后才去触发notify和wait方法？接下来我们使用enter和leave来解决这个问题

### 2.3 enter方法和leave方法
#### 这两个方法都是成对出现的，enter方法用于标记队列中未执行完的任务数，enter使任务数+1；leave方法用于标记队列中未完成的任务中已经执行完的任务数，enter使任务数-1；当任务数为0的时候，才会触发notify和wait方法(其实就是告诉他们任务执行完成了)，我们通过demo来说明
        NSLog("开始了")
        let group = DispatchGroup()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("嵌套的异步任务执行完成了--\(Thread.current)")
            }
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("组的任务都已经完成了--\(Thread.current)")
        }))
        NSLog("完成了")

        打印结果: 18:35:14.844661+0800 开始了
                18:35:14.844966+0800  完成了
                18:35:14.845055+0800  11111--<NSThread: 0x60000102f1c0>{number = 5, name = (null)}
                18:35:14.845069+0800  22222--<NSThread: 0x60000107d840>{number = 4, name = (null)}
                18:35:14.845236+0800  组的任务都已经完成了--<NSThread: 0x60000107d840>{number = 4, name = (null)}
                18:35:19.848907+0800  嵌套的异步任务执行完成了--<NSThread: 0x60000101fd80>{number = 6, name = (null)}
                
#### 分析: notify方法认为组内的任务(包括任务中嵌套的异步任务)都已经完成了，所以才去执行notify方法内的任务，而实际上嵌套的异步任务并没有真正的完成；为了保证任务真正的完成了，接下来我们使用enter和leave方法来保证任务的真正完成
        NSLog("开始了")
        let group = DispatchGroup()
        group.enter()           //告诉notify方法这里有个未完成的任务
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("嵌套的异步任务执行完成了--\(Thread.current)")
                group.leave()   //告诉notify方法这里的未完成的任务已经完成了
            }
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("组的任务都已经完成了--\(Thread.current)")
        }))
        NSLog("完成了")
        
        打印结果: 开始了
                18:45:04.108444+0800 完成了
                18:45:04.108539+0800 11111--<NSThread: 0x600003b9ad80>{number = 3, name = (null)}
                18:45:04.108541+0800 22222--<NSThread: 0x600003ba1c80>{number = 5, name = (null)}
                18:45:09.108973+0800 嵌套的异步任务执行完成了--<NSThread: 0x600003ba16c0>{number = 4, name = (null)}
                18:45:09.109376+0800 组的任务都已经完成了--<NSThread: 0x600003ba16c0>{number = 4, name = (null)}
#### 分析：通过在嵌套任务的任务外添加enter方法和在嵌套的异步任务完成的时候添加leave方法来保证嵌套了异步任务的任务真正的完成了，才去触发notify方法(告诉notify方法组内所有的任务都已经完成了)

### 接下来来验证enter+leave方法对对wait方法的作用
        NSLog("开始了")
        let group = DispatchGroup()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("嵌套的异步任务执行完成了--\(Thread.current)")
            }
            NSLog("11111--\(Thread.current)")
        }))
        group.wait()  //阻塞当前线程，直到任务1完成后才去执行后续的任务(任务2)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            for _ in 0...1{
                NSLog("22222--\(Thread.current)")
            }
        }))
        NSLog("完成了")
        
        打印结果: 18:55:34.128208+0800 开始了
                18:55:34.128896+0800 11111--<NSThread: 0x6000000daf40>{number = 5, name = (null)}
                18:55:34.129387+0800 完成了
                18:55:34.131582+0800 22222--<NSThread: 0x6000000daf40>{number = 5, name = (null)}
                18:55:34.132303+0800 22222--<NSThread: 0x6000000daf40>{number = 5, name = (null)}
                18:55:39.134459+0800 嵌套的异步任务执行完成了--<NSThread: 0x6000000fad80>{number = 6, name = (null)}
#### 分析：wait会阻塞当前线程这个我们已经知道了；wait作用是等待wait方法前的任务(任务1)完成后才去执行后续的任何或操作，但是由于任务1中嵌套了异步任务，异步任务是直接返回的，所以wait方法任务任务1已经完成了，但事实上任务1并没有真正的执行完成，为了解决这个问题，我们使用enter+leave方法来保证任务的完成
        NSLog("开始了")
        let group = DispatchGroup()
        group.enter()           //告诉wait方法这里有个未完成的任务
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("嵌套的异步任务执行完成了--\(Thread.current)")
                group.leave()   //告诉wait方法这里的未完成的任务已经完成了
            }
            NSLog("11111--\(Thread.current)")
        }))
        group.wait()  //阻塞当前线程，直到任务1完成后才去执行后续的任务(任务2)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            for _ in 0...1{
                NSLog("22222--\(Thread.current)")
            }
        }))
        NSLog("完成了")
        
        打印结果: 19:02:43.951194+0800 开始了
                 19:02:43.951938+0800  11111--<NSThread: 0x60000276a9c0>{number = 5, name = (null)}
                 19:02:48.953570+0800  嵌套的异步任务执行完成了--<NSThread: 0x600002778400>{number = 7, name = (null)}
                 19:02:48.954122+0800  完成了
                 19:02:48.954913+0800  22222--<NSThread: 0x60000276edc0>{number = 8, name = (null)}
                 19:02:48.955123+0800  22222--<NSThread: 0x60000276edc0>{number = 8, name = (null)}

#### 分析：通过GCD组Group的enter+leave方法来保证异步任务(嵌套异步任务的任务)真正的完成了，才去通知到wait方法该任务已经完成了

### 2.4 dispatch_apply 函数
#### dispatch_apply 函数是按指定的次数将指定的Block追加到指定的队列中,并等待全部处理执行结束,即阻塞当前线程
        NSLog(@"开始了");
        //OC创建全局队列
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //将Block任务添加到全局队列中,并连续添加5次
        dispatch_apply(5, queue, ^(size_t index) {
            NSLog(@"11111------%zu-----", index);
        });
        NSLog(@"完成了");
        
        NSLog("开始了")
        //swift中concurrentPerform是个类方法
        DispatchQueue.concurrentPerform(iterations: 5) { (index) in
            NSLog("11111-------\(index)---")
        }
        NSLog("结束了")
        
        结果: 开始了
            11111------1-----
            11111------0-----
            11111------2-----
            11111------3-----
            11111------4-----
            完成了
##### 各个任务的处理执行顺序是不确定的,但是最后输入结果中“完成了”必定是在最后的位置,所以dispatch_apply函数会等待全部处理执行结束,即会阻塞当前线程

### 2.4 suspend/resume函数
#### 当追加大量处理任务到queue时,在追加过程中,有时希望不执行已追加的处理任务,那么就可以使用队列挂起或恢复的功能
        let queue = DispatchQueue.global()
        //将指定的队列挂起,对已经执行的处理任务或者正在执行的处理任务是无效的
        queue.suspend()
        //将指定的队列恢复,继续后面还没有执行的处理任务;对已经执行的处理任务或者正在执行的处理任务是无效的
        queue.resume()

## 3. GCD 实现单例 
### 使用dispatch_once方法实现，dispatch_once能够保证在程序运行过程中，指定的代码只会被执行一次
        OC单利实现方式
        声明一个静态变量
        static WGTestModel *_instance;
        +(instancetype)shareInstance {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                _instance = [[WGTestModel alloc]init];
            });
            return _instance;
        }
        
        swift中单例实现 final将WGTestEntity类终止被继承,其实static let的背后用的就是dispatch_once方法
        设置初始化方法为私有，避免外部对象通过访问init方法创建单例类的实例。
        public final class WGTestEntity : NSObject {
            static let instance = WGTestEntity()
            private override init() {
                super.init()
            }
        }

## 4. GCD 的asyncAfter方法
### asyncAfter Apple文档描述：Submits a work item to a dispatch queue for asynchronous execution after a specified time；即该方法并不是在指定时间后执行处理，而是在指定时间后将任务追加到队列中异步执行;该方法是通过队列调用的，并且必须是异步调用
        //常用方法：延迟指定的时间后，将异步任务添加到队列queue(串行队列/主队列/并发队列/全局队列)中
        queue.asyncAfter(deadline: DispatchTime, execute: () -> Void)
        queue.asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem)
        queue.asyncAfter(deadline: DispatchTime, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute: () -> Void)
        queue.asyncAfter(wallDeadline: DispatchWallTime, execute: () -> Void)
        queue.asyncAfter(wallDeadline: DispatchWallTime, execute: DispatchWorkItem)
        queue.asyncAfter(wallDeadline: DispatchWallTime, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute: () -> Void)
        
        DispatchTime和DispatchWallTime的区别
        DispatchTime: 定义的是相对的时间；会受到系统休眠等因素的影响，比如设备睡眠时，DispatchTime也跟着睡眠
        DispatchWallTime: 定义的是绝对的时间；不会受到系统休眠等因素的影响
        比如: 有任务A和任务B，任务A用DispatchTime定义了10分钟后执行，任务B用DispatchWallTime也定义了10分钟
        当等待了5分钟后，APP处于休眠状态了，那么任务A也会进入休眠状态，当再起启动APP的时候，任务A仍然是需要等待10分钟后才执行的，
        而任务B不会受到系统休眠的影响，当APP重新启动的时候(等待了5分钟，APP休眠+重新启动用了1分钟)，任务B只需要再等待4分钟就可以执行了
        

        NSLog("开始了")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
            for _ in 0...2 {
                NSLog("11111--\(Thread.current)")
            }
        }
        NSLog("完成了")
        输出结果: 22:24:42.135427+0800 开始了
                 22:24:42.141666+0800 完成了
                 22:24:44.146355+0800 11111--<NSThread: 0x600003e8cb40>{number = 1, name = main}
                 22:24:44.146625+0800 11111--<NSThread: 0x600003e8cb40>{number = 1, name = main}
                 22:24:44.146794+0800 11111--<NSThread: 0x600003e8cb40>{number = 1, name = main}
#### 分析:asyncAfter方法不会阻塞当前线程，DispatchTime.now() + 2.0:指在当前时间的基础上再加2秒后，将异步任务添加到主线程中执行； 

### DispatchTime和DispatchWallTime的区别

* DispatchTime：定义的是相对的时间；会受到系统休眠等因素的影响，比如设备睡眠时，DispatchTime也跟着睡眠;
* DispatchWallTime：定义的是绝对的时间；不会受到系统休眠等因素的影响
* 比如: 有任务A和任务B，任务A用DispatchTime定义了10分钟后执行，任务B用DispatchWallTime也定义了10分钟  当等待了5分钟后，APP处于休眠状态了，那么任务A也会进入休眠状态，当再起启动APP的时候，任务A仍然是  需要等待10分钟后才执行的，而任务B不会受到系统休眠的影响，当APP重新启动的时候。(等待了5分钟，APP休眠+重新启动用了1分钟)，任务B只需要再等待4分钟就可以执行了
* DispatchTimeInterval 可以用来表示DispatchTime和DispatchWallTime偏移量的时间间隔;是一个枚举类型
        
        苹果文档:Represents a time interval that can be used as an offset from a `DispatchTime` or `DispatchWallTime`
        case seconds(Int)            单位是秒
        case milliseconds(Int)       单位是毫秒
        case microseconds(Int)       单位是微秒
        case nanoseconds(Int)        单位是纳秒
        case never                   没有时间间隔 


## 5. GCD中 barrier标志
#### OC中应该说是barrier栅栏函数,在swift中是barrier标识，主要用于多个异步任务之间，控制指定的任务先执行，  
指定的任务后执行，其实类似GCD中的notify，但是区别就是，notify指的是添加到group内的所有任务都执行完才去  
通知notify block中的方法去执行，而barrier可以针对那些没有放在group组内的任务，可以是多个并发队列+异步任务，比如  
下面场景，任务4依赖任务1任务2任务3，任务5依赖任务4，而任务1任务2任务3都是可以分别独立执行，而任务5也可以  
独立执行，那么就可以使用栅栏将这些任务“分割”开来达到实际业务的需求; barrier栅栏函数可实现高效率的  
数据库访问和文件访问

        如果是系统创建的全局队列，barrier并没有起到效果，所以barrier不能用于全局队列
        //let concurrencyQueue = DispatchQueue.global()
        NSLog("开始了")
        let concurrencyQueue = DispatchQueue.init(label: "并发队列", attributes: .concurrent)
        concurrencyQueue.async {
            Thread.sleep(forTimeInterval: 2)
            NSLog("11111--\(Thread.current)")
        }
        concurrencyQueue.async {
            NSLog("22222--\(Thread.current)")
        }
        concurrencyQueue.async {
            NSLog("33333--\(Thread.current)")
        }
        //添加barrier栅栏，阻塞当前线程，直到任务1任务2任务3完成之后，才去执行下面任务4任务5
        concurrencyQueue.async(group: nil, qos: .default, flags: .barrier) {
            Thread.sleep(forTimeInterval: 3.0)
            NSLog("44444--\(Thread.current)")
        }
        concurrencyQueue.async {
            NSLog("5555--\(Thread.current)")
        }
        NSLog("完成了")
        
        输出结果: 23:01:32.581077+0800 开始了
                23:01:32.582589+0800 完成了
                23:01:32.582658+0800 33333--<NSThread: 0x600000471380>{number = 5, name = (null)}
                23:01:32.582662+0800 22222--<NSThread: 0x60000042a6c0>{number = 3, name = (null)}
                23:01:34.585967+0800 11111--<NSThread: 0x6000004101c0>{number = 4, name = (null)}
                23:01:37.588499+0800 44444--<NSThread: 0x6000004101c0>{number = 4, name = (null)}
                23:01:37.588967+0800 5555--<NSThread: 0x6000004101c0>{number = 4, name = (null)}
#### 分析: 添加的barrier栅栏标识不会阻塞当前的线程；阻塞的是队列中栅栏barrier后的任务(任务4和任务5)，直到任务1任务2任务3完成后，才开始执行被标识为barrier栅栏的任务4及其后的任务(任务5)，这里任务4的执行顺序一定是优先于任务5的；  结论:barrier用于任务块之间的执行顺序上的分割，这些任务必须放在同一个队列中，但是barrier不能用于全局队列



## 6. GCD 信号量
### GCD中信号量DispatchSemaphore，用于控制线程并发数，初始化一个值创建信号量对象，wait()方法使信号量-1，signal()方法使信号量+1，当信号量为0的时候会阻塞当前线程，等待信号量大于0，恢复线程，主要用于多线程之间的同步，锁也可以实现多线程同步，但不同的是，锁是锁住某一资源，而信号量是逻辑上的“锁住”

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

        打印结果: 开始了
                11111--<NSThread: 0x600002926b80>{number = 3, name = (null)}
                22222--<NSThread: 0x600002926b80>{number = 3, name = (null)}
                22222--<NSThread: 0x600002926b80>{number = 3, name = (null)}
                22222--<NSThread: 0x600002926b80>{number = 3, name = (null)}
                完成了
                33333--<NSThread: 0x600002926b80>{number = 3, name = (null)}
#### 分析: 信号量中的wait方法会阻塞当前的线程(通过“完成了”的打印信息顺序)；wait方法主要是根据当前的信号量是否大于0来决定是否阻塞当前线程，如果信号量>0则不阻塞当前线程，wait方法后的任务可以继续执行；如果信号量=0，则阻塞当前线程，wait方法后的任务需要等待wait方法前的任务，直到wait方法前的任务中调用了信号量的signal方法，使信号量+1；在多线程开发中我们通常使用信号量来控制队列中多个异步任务之间的执行顺序，来实现异步任务的同步执行。

## 7.项目中使用总结
### 7.1 项目中为了实现多线程(同一时间开启多个子线程来执行多个任务)，使用最多的就是【并发队列+异步任务】和【全局队列+异步任务】组合；
        【并发队列+异步任务】
        NSLog("开始了")
        let concurrentQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果: 开始了
                结束了
                33333--<NSThread: 0x600001c06000>{number = 3, name = (null)}
                11111--<NSThread: 0x600001c5a040>{number = 5, name = (null)}
                22222--<NSThread: 0x600001c59200>{number = 4, name = (null)}
                33333--<NSThread: 0x600001c06000>{number = 3, name = (null)}
                11111--<NSThread: 0x600001c5a040>{number = 5, name = (null)}
                22222--<NSThread: 0x600001c59200>{number = 4, name = (null)}
        
        【全局队列+异步任务】
        NSLog("开始了")
        DispatchQueue.global().async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }
        DispatchQueue.global().async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        DispatchQueue.global().async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        打印结果: 开始了
        结束了
        33333--<NSThread: 0x600003b7f000>{number = 6, name = (null)}
        11111--<NSThread: 0x600003b21080>{number = 5, name = (null)}
        22222--<NSThread: 0x600003b2c2c0>{number = 4, name = (null)}
        33333--<NSThread: 0x600003b7f000>{number = 6, name = (null)}
        11111--<NSThread: 0x600003b21080>{number = 5, name = (null)}
        22222--<NSThread: 0x600003b2c2c0>{number = 4, name = (null)}

### 7.2 实现线程同步(控制多个异步任务之间的执行顺序)，可以使用信号量来控制，信号量是会阻塞当前线程的
        NSLog("开始了")
        let semp = DispatchSemaphore.init(value: 0)
        let concurrentQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
            semp.signal()
        }
        semp.wait()

        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
            semp.signal()
        }
        semp.wait()

        concurrentQueue.async {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
            semp.signal()
        }
        semp.wait()
        NSLog("结束了")

        打印结果:开始了
                11111--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                11111--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                22222--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                22222--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                33333--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                33333--<NSThread: 0x6000027a5680>{number = 6, name = (null)}
                结束了
#### 【全局队列+异步任务】使用信号量控制队列中任务的执行顺序的实现方法和上面是一样的；这里有个特殊情况，如果异步任务中嵌套了异步任务，如果保证任务完成了？依然使用信号量来解决，改变wait方法和signal方法的位置即可
        NSLog("开始了")
        let semp = DispatchSemaphore.init(value: 0)
        let concurrentQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrentQueue.async {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("11111--\(Thread.current)")
                }
                semp.signal()
            }
        }
        semp.wait()
        concurrentQueue.async {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("22222--\(Thread.current)")
                }
                semp.signal()
            }
        }
        semp.wait()
        concurrentQueue.async {
            concurrentQueue.async {
                for _ in 0...1 {
                    NSLog("33333--\(Thread.current)")
                }
                semp.signal()
            }
        }
        semp.wait()
        NSLog("结束了")
        
        打印结果: 开始了
                11111--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                11111--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                22222--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                22222--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                33333--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                33333--<NSThread: 0x600003e151c0>{number = 5, name = (null)}
                结束了
### 7.3 除了使用信号量，我们也可以使用GCD中组的wait方法来控制，wait方法会阻塞当前线程

        NSLog("开始了")
        let group = DispatchGroup.init()
        let concurrentQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            for _ in 0...1 {
                NSLog("11111--\(Thread.current)")
            }
        }))
        group.wait()
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }))
        group.wait()
        concurrentQueue.async(group: group, execute: DispatchWorkItem.init(block: {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }))
        group.wait()
        NSLog("结束了")

        打印结果：开始了
        11111--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        11111--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        22222--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        22222--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        33333--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        33333--<NSThread: 0x600000016f00>{number = 4, name = (null)}
        结束了
#### 【全局队列+异步任务】用GCD的组来实现同步的方式和上面是一样，那么如果任务中也嵌套了异步任务，那么在GCD组中如何保证任务真的完成了?依然通过wait方法，另外再加上enter和leval的组合方法来实现
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

        打印结果:开始了
        11111--<NSThread: 0x600002289800>{number = 5, name = (null)}
        11111--<NSThread: 0x600002289800>{number = 5, name = (null)}
        22222--<NSThread: 0x600002289800>{number = 5, name = (null)}
        22222--<NSThread: 0x600002289800>{number = 5, name = (null)}
        33333--<NSThread: 0x600002289800>{number = 5, name = (null)}
        33333--<NSThread: 0x600002289800>{number = 5, name = (null)}
        结束了


### GCD组中的group.notify(queue: DispatchQueue, work: DispatchWorkItem)方法，通过验证我们得出结论:notify方法只能通知到的队列有主队列和全局队列，都是由系统创建的，而手动创建的串行队列/并发队列并不能通知到
### 下面是验证结论的

        NSLog("开始了")
        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        //组内的所有任务执行完成后，才通知主线程去执行主线程要执行的任务
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem.init(block: {
            NSLog("00000--\(Thread.current)")
        }))
        NSLog("结束了")
        
        打印结果: 开始了
                结束了
                11111--<NSThread: 0x6000020e4e80>{number = 5, name = (null)}
                33333--<NSThread: 0x600002083840>{number = 6, name = (null)}
                22222--<NSThread: 0x6000020f4ac0>{number = 3, name = (null)}
                00000--<NSThread: 0x600002082140>{number = 1, name = main}

#### 分析：放在DispatchGroup组里面的任务的执行顺序是不确定的,并发执行的；只有组内的任务全部完成后，group才开始通知主线程去执行主线程要执行的任务，这里应该注意到，group通知的并不是主线程，而是通知的一个主队列，让主队列中的任务继续执行，因为主队列内的任务是在主线程中执行的，所以我们一般说是通知主线程做事情， group可以通知主队列，是否可以通知其他队列(串行队列，并发队列)？答案是可以的

        NSLog("开始了")
        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        //串行队列+同步任务
        let serialQueue = DispatchQueue(label: "串行队列名称")
        serialQueue.sync {
            NSLog("串行队列同步任务--\(Thread.current)")
        }
        group.notify(queue: serialQueue, work: DispatchWorkItem.init(block: {
            NSLog("00000----\(Thread.current)")
        }))
        NSLog("结束了")
        
        打印结果: 开始了
                串行队列同步任务--<NSThread: 0x600002d1a140>{number = 1, name = main}
                结束了
                11111--<NSThread: 0x600002d13b00>{number = 5, name = (null)}
                22222--<NSThread: 0x600002d11540>{number = 3, name = (null)}
                33333--<NSThread: 0x600002d13b00>{number = 5, name = (null)}
                00000----<NSThread: 0x600002d13b00>{number = 5, name = (null)}
##### 分析：我们手动创建了串行队列，并添加了同步任务，然后group内任务全部完成后，去通知该串行队列去执行它里面的任务，但是结果却是，串行队列中的同步任务并没有收到通知(group.notify)后才去执行同步任务，串行队列中的同步任务并没有受到group的影响，而是按照自己该有的方式去执行了，通过线程打印信息还能发现，如果group通知到了创建的线程，那么group内的线程应该和创建的线程是一样的啊，为什么？开始介绍Group说的是：它是用来执行异步任务的，同步任务不能执行的，👌，我们继续创建异步任务验证
        
        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        //这里我们创建一个串行队列,并添加异步任务
        let serialQueue = DispatchQueue(label: "串行队列名称")
        serialQueue.async {
            NSLog("11111串行队列同步任务--\(Thread.current)")
        }
        serialQueue.async {
            NSLog("22222串行队列同步任务--\(Thread.current)")
        }
        group.notify(queue: serialQueue, work: DispatchWorkItem.init(block: {
            NSLog("开始去执行串行队列中的任务吧----\(Thread.current)")
        }))
        
        打印结果: 11111串行队列同步任务--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
                22222串行队列同步任务--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
                11111--<NSThread: 0x600000cf1880>{number = 5, name = (null)}
                22222--<NSThread: 0x600000cdc400>{number = 4, name = (null)}
                33333--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
                开始去执行串行队列中的任务吧----<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
##### 分析:通过结果打印，发现在串行队列中添加异步任务，group仍然没有通知到队列中的任务去执行，而是串行队列中的异步任务按照自己的方式去执行了，为什么？难道group不能通知串行队列(除了主队列)，只支持通知异步队列？我们继续验证

        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        //这里我们创建一个并发队列,并添加同步任务
        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrencyQueue.sync {
            NSLog("11111并发队列同步任务--\(Thread.current)")
        }
        concurrencyQueue.sync {
            NSLog("22222并发队列同步任务--\(Thread.current)")
        }
        group.notify(queue: concurrencyQueue, work: DispatchWorkItem.init(block: {
            NSLog("开始去执行并发队列中的任务吧----\(Thread.current)")
        }))

        打印结果: 11111并发队列同步任务--<NSThread: 0x600000d76c40>{number = 1, name = main}
                22222并发队列同步任务--<NSThread: 0x600000d76c40>{number = 1, name = main}
                22222--<NSThread: 0x600000d3c900>{number = 5, name = (null)}
                11111--<NSThread: 0x600000d799c0>{number = 6, name = (null)}
                33333--<NSThread: 0x600000d02880>{number = 7, name = (null)}
                开始去执行并发队列中的任务吧----<NSThread: 0x600000d02880>{number = 7, name = (null)}
##### 分析：发现创建的异步队列，并添加了同步任务，group依然没有通知到，暴脾气上来了，为什么？难道group只支持通知并发队列中的异步任务，👌，我们继续验证并发队列下的异步任务
        
        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        //这里我们创建一个并发队列,并添加异步任务
        let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
        concurrencyQueue.async {
            NSLog("11111并发队列异步任务--\(Thread.current)")
        }
        concurrencyQueue.async {
            NSLog("22222并发队列异步任务--\(Thread.current)")
        }
        group.notify(queue: concurrencyQueue, work: DispatchWorkItem.init(block: {
            NSLog("开始去执行并发队列中的任务吧----\(Thread.current)")
        }))
        
        打印结果：22222并发队列异步任务--<NSThread: 0x6000001e8480>{number = 6, name = (null)}
                11111并发队列异步任务--<NSThread: 0x6000001bd240>{number = 4, name = (null)}
                33333--<NSThread: 0x6000001eca80>{number = 8, name = (null)}
                22222--<NSThread: 0x6000001e8a00>{number = 7, name = (null)}
                11111--<NSThread: 0x6000001bd800>{number = 5, name = (null)}
                开始去执行并发队列中的任务吧----<NSThread: 0x6000001bd800>{number = 5, name = (null)}
##### 分析：答案依旧是😠😠group不能通知到并发队列中的异步任务，容我想思考一下，刚才group通知的都是需要我们程序员手动创建的队列，那么GCD自己创建的队列(主队列和全局队列)可以吗，目前我们知道group是可以通知到主队列的，那么系统创建的全局队列可以通知到吗？

        let group = DispatchGroup()
        //将全局队列+异步任务添加到组中(DispatchQueue.global()全局队列其实就是个并发队列)
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("33333--\(Thread.current)")
        }))
        DispatchQueue.global().async {
            NSLog("全局队列异步任务--\(Thread.current)")
        }
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("开始去执行并发队列中的任务吧----\(Thread.current)")
        }))

        打印结果: 全局队列异步任务--<NSThread: 0x600001e3c080>{number = 3, name = (null)}
                22222--<NSThread: 0x600001e2cc00>{number = 6, name = (null)}
                33333--<NSThread: 0x600001e344c0>{number = 7, name = (null)}
                11111--<NSThread: 0x600001e2a680>{number = 5, name = (null)}
                开始去执行并发队列中的任务吧----<NSThread: 0x600001e2a680>{number = 5, name = (null)}
##### 分析: 发现group通知了DispatchQueue.global()并发队列，但是并没有通知到(并发队列中的任务并不是group通知触发的)


## 思考
### DispatchGroup() :初始化dispatch_group_t
###  enter() : add操作的原子性,count+1
###  leave
### notify: 1.更新链表数据结果 2.将任务添加到链表尾部,然后遍历链表执行任务
