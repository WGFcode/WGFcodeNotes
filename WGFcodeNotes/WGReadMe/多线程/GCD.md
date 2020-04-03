#### GCD
##### GCD(Grand Central Dispatch)：伟大的中央调度器，是苹果公司为多核的并行运算提供的一种基于纯C语言的解决方案
##### GCD特点
     1.会自动利用更多的CPU内核
     2.自动管理线程的生命周期(创建线程/调度任务/销毁线程)
     3.我们只需要告诉GCD想要执行什么任务，并追加任务到队列中即可，不需要编写任何线程管理的代码

##### GCD中重要的概念: 任务、队列
#####  任务
#####  就是一段执行的代码，即GCD中的Block内执行的代码
##### 执行任务有两种形式:  同步执行(sync) 和 异步执行(async)
##### 同步执行: 只能在当前线程中执行，不具备开启新线程的能力，任务结束之前会阻塞当前线程，必须等任务执行完成后才能进行往下走，即同一时间只有一个任务被执行
##### 异步执行：具备开启新线程的能力(但是不一定开启新线程，需要根据任务所在的队列决定)，异步任务添加到队列后，不会阻塞当前线程，后续的操作不需要等待就可以继续执行，即同一时间可以有多个任务被执行


##### 队列
##### 就是用来存放任务的地方，队列是一种特殊的线性表(先用先出)
##### GCD中有两种队列: 串行队列 和 并发队列
##### 串行队列：每次只有一个任务被执行，一个任务执行完毕后，再执行下一个任务
    let serialQueue = DispatchQueue.init(label: "串行队列名称")
##### 并发队列：可以让多个任务并发（同时）执行
    let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
##### 主队列: 其实就是串行队列的一种,区别就是主队列中的任务只能在主线程中执行
    let mainQueue = DispatchQueue.main
##### 全局队列: 其实就是并发队列的一种，区别就是并发队列需要我们自己创建，而全局队列由系统提供 
    let globalQueue = DispatchQueue.global()

#####  队列+任务的组合方式如下
##### 1.串行队列+同步任务
    //1串行队列+单个同步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let serialQueue = DispatchQueue.init(label: "串行队列名称")
    serialQueue.sync {
        NSLog("开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("开始执行串行队列外的其它任务")
    输出结果:
    在当前线程(主线程)中处理完任务了:<NSThread: 0x60000009ed80>{number = 1, name = main}
    开始执行同步任务，当前的线程是:<NSThread: 0x600002906d80>{number = 1, name = main}
    开始执行串行队列外的其它任务
##### 分析：同步任务会阻塞当前线程(主线程),直到同步任务执行完成后，才执行后续的代码
##### 思考:如果不在主线程中执行上面的代码，会怎么样？会不会也阻塞当前线程(非主线程)
        let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        @objc func method1() {
            //1串行队列 + 单个同步任务
            NSLog("在当前线程中处理完任务了:\(Thread.current)")
            let serialQueue = DispatchQueue.init(label: "串行队列名称")
            serialQueue.sync {
                NSLog("开始执行同步任务，当前的线程是:\(Thread.current)")
            }
            NSLog("开始执行串行队列外的其它任务")
        }
        输出结果：
        在当前线程中处理完任务了:<NSThread: 0x600003d7d040>{number = 6, name = (null)}
        开始执行同步任务，当前的线程是:<NSThread: 0x600003d7d040>{number = 6, name = (null)}
        开始执行串行队列外的其它任务
##### 分析发现，同步任务确实阻塞了当前线程(不管当前线程是主线程还是非主线程)，必须等sync block中的任务执行完成后才能执行它后面的任务
##### 如果在串行队列中添加多个同步任务，同步任务之间的执行顺序会是什么样的？
    //1串行队列+多个同步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let serialQueue = DispatchQueue.init(label: "串行队列名称")
    serialQueue.sync {
        NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    serialQueue.sync {
        NSLog("22222开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    serialQueue.sync {
        NSLog("33333开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("开始执行串行队列外的其它任务")
    输出结果：
    在当前线程(主线程)中处理完任务了:<NSThread: 0x60000123ad80>{number = 1, name = main}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x60000123ad80>{number = 1, name = main}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x60000123ad80>{number = 1, name = main}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x60000123ad80>{number = 1, name = main}
    开始执行串行队列外的其它任务
##### 分析：串行队列中添加多个同步任务，同步任务之间是按照顺序执行的
##### 结论；同步任务+串行队列   不会开启新的线程，会阻塞当前线程(指的是串行队列里面的所有任务阻塞串行队列外的后续任务，直到队列中的所有任务全部执行完成后才开始执行队列外的后续任务)


##### 2.串行队列+异步任务
        //2串行队列+单个异步任务
        NSLog("在当前线程中处理完任务了:\(Thread.current)")
        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        serialQueue.async {
            NSLog("开始执行异步任务，当前的线程是:\(Thread.current)")
        }
        NSLog("开始执行串行队列外的其它任务")
        输出结果：
        在当前线程中处理完任务了:<NSThread: 0x600000f22140>{number = 1, name = main}
        开始执行串行队列外的其它任务
        开始执行异步任务，当前的线程是:<NSThread: 0x600000f42040>{number = 3, name = (null)}
##### 分析：发现异步任务开启了新的线程，但是并没有阻塞当前线程(主线程)，即async任务后的操作(打印“完成了”信息)不会去等待async block中的任务完成之后再执行，如果当前线程不是主线程，那么异步任务是否也不会阻塞当前线程(非主线程)，答案是肯定的，验证代码如下
    let thread1 = Thread.init(target: self, selector: #selector(method1), object: nil)
    thread1.start()
    @objc func method1() {
        //2.串行队列+单个异步任务
        NSLog("在当前线程中处理完任务了:\(Thread.current)")
        let serialQueue = DispatchQueue.init(label: "串行队列名称")
        serialQueue.async {
            NSLog("开始执行异步任务，当前的线程是:\(Thread.current)")
        }
        NSLog("开始执行串行队列外的其它任务")
    }
    输出结果：
    在当前线程中处理完任务了:<NSThread: 0x600000e0df40>{number = 6, name = (null)}
    开始执行串行队列外的其它任务
    开始执行异步任务，当前的线程是:<NSThread: 0x600000e68bc0>{number = 4, name = (null)}

##### 如果在串行队列中放多个异步任务，那么多个异步任务的在串行队列中执行顺序是什么?
    //2.串行队列+多个异步任务
    NSLog("在当前线程中处理完任务了:\(Thread.current)")
    let serialQueue = DispatchQueue.init(label: "串行队列名称")
    serialQueue.async {
        for _ in 0...2 {
            NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
        }
    }
    serialQueue.async {
        for _ in 0...2 {
            NSLog("22222开始执行同步任务，当前的线程是:\(Thread.current)")
        }
    }
    serialQueue.async {
        for _ in 0...2 {
            NSLog("33333开始执行同步任务，当前的线程是:\(Thread.current)")
        }
    }
    NSLog("开始执行串行队列外的其它任务")
    输出结果：
    在当前线程中处理完任务了:<NSThread: 0x6000013d2d80>{number = 1, name = main}
    开始执行串行队列外的其它任务
    11111开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x600001389700>{number = 5, name = (null)}
##### 可以发现在串行队列中放多个异步任务时，异步任务只开启了一条线程，并且这些异步任务之间是按照顺序执行的
##### 结论: 串行队列+异步任务   只会开启一条新的线程，不会阻塞当前的线程(串行队列外的代码执行不会被阻塞 )；异步任务之间是按照顺序执行的（因为串行队列中的所有任务都是一个一个的执行，无论它是同步还是异步）



##### 至此有一些心得体会了吧：同步任务会阻塞当前线程，异步不会阻塞当前线程，阻塞不阻塞针对的是队列中的所有任务是否对队列外的后续任务有阻塞，而队列中的任务之间的执行顺序要看所在的队列是串行的还是并发的

##### 3.并发队列+同步任务
    //3.并发队列+单个同步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
    concurrencyQueue.sync {
        NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("并发队列外的任务开始执行")
    输出结果:
    在当前线程(主线程)中处理完任务了:<NSThread: 0x600003ce6140>{number = 1, name = main}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x600003ce6140>{number = 1, name = main}
    并发队列外的任务开始执行
##### 分析：同步任务不会开启新的线程，会阻塞当前线程(队列外的后续任务会等待队列中的任务执行完成后才开始执行)
    //3.并发队列+对个同步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
    concurrencyQueue.sync {
        NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    concurrencyQueue.sync {
        NSLog("22222开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    concurrencyQueue.sync {
        NSLog("33333开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("并发队列外的任务开始执行")
    输出结果:
    在当前线程(主线程)中处理完任务了:<NSThread: 0x600000216140>{number = 1, name = main}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x600000216140>{number = 1, name = main}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x600000216140>{number = 1, name = main}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x600000216140>{number = 1, name = main}
    并发队列外的任务开始执行
##### 分析，多个同步任务之间也是按照顺序执行的，虽然是在并发队列中，但是并没有开启新的线程，所以也就无法达到并行的效
##### 结论：并发队列+同步任务，不会开启新的线程，所以队列中的同步任务 之间按照顺序执行；会阻塞当前线程(队列中的所有任务会阻塞队列外的后续任务的执行，直到队列中的所有任务执行完成后才执行)，

##### 心得：其实 并发队列+同步任务 和 串行队列+同步任务 的效果是一样的，阻塞当前线程，任务之间按照顺序依次执行


##### 4.并发队列+异步任务
    //4.并发队列+单个异步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
    concurrencyQueue.async {
        NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("并发队列外的任务开始执行")
    输出结果:
    在当前线程(主线程)中处理完任务了:<NSThread: 0x600003d8e6c0>{number = 1, name = main}
    并发队列外的任务开始执行
    11111开始执行异步任务，当前的线程是:<NSThread: 0x600003df3000>{number = 5, name = (null)}
##### 分析：开启了新的线程；没有阻塞当前的线程（并发队列外的后续代码执行并没有被并发队列中的任务阻塞）
    //4.并发队列+多个异步任务
    NSLog("在当前线程(主线程)中处理完任务了:\(Thread.current)")
    let concurrencyQueue = DispatchQueue.init(label: "并发队列名称", attributes: .concurrent)
    concurrencyQueue.async {
        NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
        for _ in 0...1{
            NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
        }
    }
    concurrencyQueue.async {
        NSLog("22222开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    concurrencyQueue.async {
        NSLog("33333开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("并发队列外的任务开始执行")
    输出结果:
    在当前线程(主线程)中处理完任务了:<NSThread: 0x600000c26cc0>{number = 1, name = main}
    并发队列外的任务开始执行
    11111开始执行异步任务，当前的线程是:<NSThread: 0x600000c58f80>{number = 5, name = (null)}
    22222开始执行异步任务，当前的线程是:<NSThread: 0x600000c1d340>{number = 4, name = (null)}
    33333开始执行异步任务，当前的线程是:<NSThread: 0x600000c7bdc0>{number = 6, name = (null)}
    11111开始执行异步任务，当前的线程是:<NSThread: 0x600000c58f80>{number = 5, name = (null)}
    11111开始执行异步任务，当前的线程是:<NSThread: 0x600000c58f80>{number = 5, name = (null)}
##### 分析：多个异步任务之间是并发执行的，即谁先开始执行和谁先完成执行的顺序是不确定的，同一时间可以执行多任务
##### 总结：并发队列+异步任务 会开启新的线程，不会阻塞当前线程（并发队列外的后续任务不会被并发队列中的任务阻塞，不用等待就可以执行），队列中的任务之间执行顺序是并行的，谁先执行谁先执行完是不确定的
    
##### 5.主队列+同步任务
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.testMethod()
    }
    func testMethod() {
        //5.主队列 + 同步任务
        NSLog("当前的线程是:\(Thread.current)")
        let mainQueue = DispatchQueue.main
        mainQueue.sync {
            NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
        }
        mainQueue.sync {
            NSLog("22222开始执行同步任务，当前的线程是:\(Thread.current)")
        }
        NSLog("主队列外的任务开始执行")
    }
    输入结果: 
    当前的线程是:<NSThread: 0x600003f08440>{number = 1, name = main}
    会发生crash
##### 分析：主队列其实是一种串行队列，同步任务会阻塞当前线程;首先testMethod()方法就是在主线程中执行的，在方法中遇到了第一个同步任务，第一个同步任务会阻塞testMethod方法的继续执行，但testMethod方法又会等待第一个同步任务，相互等待，就造成了死锁
##### 总结：主队列+同步任务 造成同步任务的相互等待，会造成死锁

##### 6.主队列+异步任务
    //6.主队列 + 异步任务
    NSLog("当前的线程是:\(Thread.current)")
    let mainQueue = DispatchQueue.main
    mainQueue.async {
        NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    mainQueue.async {
        NSLog("22222开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    mainQueue.async {
        NSLog("33333开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("主队列外的任务开始执行")
    输出结果:
    当前的线程是:<NSThread: 0x6000011ea140>{number = 1, name = main}
    主队列外的任务开始执行
    11111开始执行异步任务，当前的线程是:<NSThread: 0x6000011ea140>{number = 1, name = main}
    22222开始执行异步任务，当前的线程是:<NSThread: 0x6000011ea140>{number = 1, name = main}
    33333开始执行异步任务，当前的线程是:<NSThread: 0x6000011ea140>{number = 1, name = main}
##### 分析：并没有开启线程，任务都是在主线程中运行的，虽然是异步任务，但是都放在了主队列(串行队列)中，所以任务之间的执行顺序是按照顺序依次执行的
##### 总结：主队列+异步任务 没有开启新的线程，不会阻塞当前线程，任务之间是按照顺序执行的


##### 至此心得体会:同步不具备开启线程能力，异步具备开启线程的能力，但是不是所有的异步操作都能够开启新的线程，比如主队列中的异步任务就是在主线程中执行任务的，并没有开启线程



##### 7.全局队列+同步任务
    //7.全局队列(并发队列) + 同步任务
    NSLog("当前的线程是:\(Thread.current)")
    let globalQueue = DispatchQueue.global()
    globalQueue.sync {
        NSLog("11111开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    globalQueue.sync {
        NSLog("22222开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    globalQueue.sync {
        NSLog("33333开始执行同步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("全局队列外的任务开始执行")
    输出结果:
    当前的线程是:<NSThread: 0x6000033b4000>{number = 1, name = main}
    11111开始执行同步任务，当前的线程是:<NSThread: 0x6000033b4000>{number = 1, name = main}
    22222开始执行同步任务，当前的线程是:<NSThread: 0x6000033b4000>{number = 1, name = main}
    33333开始执行同步任务，当前的线程是:<NSThread: 0x6000033b4000>{number = 1, name = main}
    全局队列外的任务开始执行
    ##### 分析：没有开启新线程，阻塞了当前的线程，任务之间是按照顺序执行的
    ##### 总结: 全局队列+同步任务 没有开启新线程，同步任务阻塞了当前线程（全局队列所有任务外的后续任务会被全局队列中的所有任务阻塞，直到队列中的所有任务都执行完成后才执行），同步任务之间是按照顺序执行的，因为没有开启新的线程，所以即便是在全局队列中也只能按照顺序执行
##### 7.全局队列+异步任务
    //5.全局队列(并发队列) + 异步任务
    NSLog("当前的线程是:\(Thread.current)")
    let globalQueue = DispatchQueue.global()
    globalQueue.async {
        NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
        NSLog("11111开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    globalQueue.async {
        NSLog("22222开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    globalQueue.async {
        NSLog("33333开始执行异步任务，当前的线程是:\(Thread.current)")
    }
    NSLog("全局队列外的任务开始执行")
    输出结果:
    当前的线程是:<NSThread: 0x600002526d00>{number = 1, name = main}
    全局队列外的任务开始执行
    11111开始执行异步任务，当前的线程是:<NSThread: 0x60000257ebc0>{number = 5, name = (null)}
    22222开始执行异步任务，当前的线程是:<NSThread: 0x600002571900>{number = 3, name = (null)}
    33333开始执行异步任务，当前的线程是:<NSThread: 0x6000025ac180>{number = 6, name = (null)}
    11111开始执行异步任务，当前的线程是:<NSThread: 0x60000257ebc0>{number = 5, name = (null)}
##### 分析：开启了新的线程，异步任务没有阻塞当前线程，任务之间谁先执行谁先执行完成是不确定的，即并发执行
##### 总结: 全局队列+异步任务 开启新线程，不会阻塞当前线程，任务之间是并发执行的
    
##### 汇总
    *1. GCD多线程的实现就是分两步：首先创建队列  然后添加任务到队列
    *2. 同步不具备开启线程的能力；异步具备开启线程的能力，但并不是所有的异步任务都能开启线程，比如主线程+异步任务就是异步任务都是在主线程中执行的，虽然添加的是异步任务，但并没有开启新的线程
    *3.主队列和串行队列区别：主队列是系统创建的串行队列，串行队列是需要程序员自己创建的队列
    *4.全局队列和并发队列:全局队列是系统创建的并发队列，并发队列是需要程序员自己创建的队列
    *5.同步任务会阻塞当前线程(中断当前 任务，立即执行新任务)，异步任务不会阻塞当前线程(不会中断当前任务，而是等待执行新任务)，阻塞的含义其实是:（队列+任务）这一堆代码是否会阻塞它后续的操作(后续的任务)
    *6.任务(指的是放在队列中的任务)执行顺序,是根据队列的类型来判断的；串行队列中，任务一定是按照顺序执行的(除了主线程的同步任务会发生死锁crash外)，并发队列中，在(并发队列+异步任务/全局队列+异步任务)条件下任务是并发执行的，在(并发队列+同步任务/全局队列+同步任务)
    *7.         串行队列            并发队列           主队列           全局队列
    
              会阻塞当前线程      会阻塞当前线程       会阻塞当前线程      会阻塞当前线程
    同步任务    不开启线程          不开启线程        在当前主线程中执行     不开启线程
              任务顺序执行        任务顺序执行           死锁            任务顺序执行
              
              不会阻塞当前线程    不会阻塞当前线程      不会阻塞当前线程     不会阻塞当前线程
    异步任务    开启一条线程         开启多条线程       在当前主线程中执行    开启多条线程 
              顺序执行任务         并发执行任务        顺序执行任务        并发执行任务
