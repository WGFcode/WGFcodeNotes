## GCD
##### GCD(Grand Central Dispatch)：伟大的中央调度器，是苹果公司为多核的并行运算提供的一种基于纯C语言的解决方案
## GCD特点
     1.会自动利用更多的CPU内核
     2.自动管理线程的生命周期(创建线程/调度任务/销毁线程)
     3.我们只需要告诉GCD想要执行什么任务，并追加任务到队列中即可，不需要编写任何线程管理的代码
     
## GCD 总结
* GCD处理多线程，首先就是创建队列，然后向队列中添加任务；
* GCD中队列有串行队列，并发队列，全局队列(系统创建的一种并发队列)，主队列(系统创建的一种串行队列)；
* 串行队列和并发队列是需要我们手动去创建的，而全局队列和主队列是系统提供的；
* 串行队列每次只有一个任务被执行，一个任务执行完成后才执行下一个任务；
* 并发队列中的任务，在开启多个线程的情况下可以并发执行，并发队列中只有在添加异步任务的情况下才会并发执行任务；
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
* GCD中实现多线程任务的同步执行，其实同步执行就是控制多个异步任务的执行顺序，有两种方式：第一种就是GCD组内可以利用wait方法阻塞当前线程达到同步，第二种就是利用信号量的signal和wait方法实现多个任务之间的同步执行，区别就是第一种只能用在group种，第三种可以用在group种也可以用在非group中
* GCD组中使用notify和wait方法时，需要注意，如果组内的任务中嵌套了异步任务，例如group中有任务A(异步任务A1)，任务B，任务C，如果遇到这种情况【组内所有任务完成后，才notify任务D开始执行】和【利用wait方法来使任务A执行完成后才开始执行任务B】时，其实是不能满足我们的要求的，因为任务A中嵌套了异步任务A1，而异步任务是直接返回的，所以notify或者wait就认为任务A完成了，其实并没有完成，这种情况下 ，我们需要使用group中的enter和leave方法，来分别告诉group（或者理解成告诉notify或者wait）存在一个未完成的任务和未完成的任务已经离开了，来实现任务A真正的执行完成了


## GCD中重要的概念: 任务、队列
###  任务
#####  就是一段执行的代码，即GCD中的Block内执行的代码
##### 执行任务有两种形式:  同步执行(sync) 和 异步执行(async)
##### 同步执行: 只能在当前线程中执行，不具备开启新线程的能力，任务结束之前会阻塞当前线程，必须等任务执行完成后才能进行往下走，即同一时间只有一个任务被执行
##### 异步执行：具备开启新线程的能力(但是不一定开启新线程，需要根据任务所在的队列决定)，异步任务添加到队列后，不会阻塞当前线程，后续的操作不需要等待就可以继续执行，即同一时间可以有多个任务被执行


### 队列
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
## 1.串行队列+同步任务
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


## 2.串行队列+异步任务
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

## 3.并发队列+同步任务
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


## 4.并发队列+异步任务
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
    
## 5.主队列+同步任务
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

## 6.主队列+异步任务
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

## 7.全局队列+同步任务
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
## 8.全局队列+异步任务
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

## GCD组
##### GCD组(DispatchGroup) 是什么？Apple文档这么说的A group of blocks submitted to queues for asynchronous invocation. 白话就是将【存放在队列中的多个Block】(多个任务)放在一个组里面，用于异步调用。

## 常用的方法分析
### 1.通知方法 notify 当group中所有的任务都执行完成时，通知去执行接下来的操作
        //创建组
        let group = DispatchGroup()
        //将全局队列(并发队列)+异步任务添加到group中
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            Thread.sleep(forTimeInterval: 2)
            NSLog("22222--\(Thread.current)")
        }))
        //group发送通知，告知后续的操作，我完成了，该你们执行了
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("添加到group内的所有任务都完成了，我开始执行了--\(Thread.current)")
        }))
        NSLog("---完成了---")
        输出结果: 

        ---完成了---
        11111--<NSThread: 0x60000185ca40>{number = 5, name = (null)}
        22222--<NSThread: 0x6000018357c0>{number = 4, name = (null)}
        添加到group内的所有任务都完成了，我开始执行了--<NSThread: 0x6000018357c0>{number = 4, name = (null)}
##### 分析：上来就打印了"---完成了---"说明group并不会阻塞当前的线程；组内添加的(并发队列+异步任务)任务是并发执行的，当组内任务全部完成后，才通知notify中Block中的方法执行

### 2. 等待方法wait 会阻塞当前线程，group中指定的任务完成后才开始执行后面的任务
        NSLog("开始了")
        //创建组
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
        //group发送通知，告知后续的操作，我完成了，该你们执行了
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("添加到group内的所有任务都完成了，我开始执行了--\(Thread.current)")
        }))
        NSLog("---完成了---")
        
        输出结果:
        
        开始了
        11111--<NSThread: 0x6000025c4500>{number = 4, name = (null)}
        ---完成了---
        22222--<NSThread: 0x6000025c4500>{number = 4, name = (null)}
        添加到group内的所有任务都完成了，我开始执行了--<NSThread: 0x6000025c4500>{number = 4, name = (null)}
##### 分析：wait阻塞了当前的线程，所以"---完成了---"的打印是在11111打印完成后才执行的，

### 3. enter方法和leave方法，成对出现的，用于标记队列中的未执行完毕和已执行完毕的任务数，enter使任务数+1，leave使任务数-1，当任务数为0的时候，才会使wait方法解除阻塞或者触发notify方法，通过例子来引出这两个方法

        NSLog("开始了")
        //创建组
        let group = DispatchGroup()
        //将全局队列(并发队列)+异步任务添加到group中
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            //并发队列中的异步任务中由嵌套了一个异步任务
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("模拟一下耗时操作:--\(Thread.current)")
            }
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("所有任务都完成了，我开始执行了--\(Thread.current)")
        }))
        NSLog("---完成了---")

        输出结果:

        2020-04-04 17:31:57.865336+0800 WGFcodeNotes[2353:94252] 开始了
        2020-04-04 17:31:57.865677+0800 WGFcodeNotes[2353:94252] ---完成了---
        2020-04-04 17:31:57.865779+0800 WGFcodeNotes[2353:94318] 22222--<NSThread: 0x6000031d0340>{number = 5, name = (null)}
        2020-04-04 17:31:57.865780+0800 WGFcodeNotes[2353:94307] 11111--<NSThread: 0x6000031c5cc0>{number = 4, name = (null)}
        2020-04-04 17:31:57.865965+0800 WGFcodeNotes[2353:94307] 所有任务都完成了，我开始执行了--<NSThread: 0x6000031c5cc0>{number = 4, name = (null)}
        2020-04-04 17:32:02.869768+0800 WGFcodeNotes[2353:94304] 模拟一下耗时操作:--<NSThread: 0x600003128980>{number = 6, name = (null)}
##### 分析：发现group并没有等待所有的异步任务都执行完成后才执行notify中的方法，为什么？因为 异步任务1中又开启了个线程去执行嵌套的异步任务，而异步线程(异步任务)是直接返回的,所以group就认为是执行完成了。如果解决这个问题？enter和leave方法要登场了
        NSLog("开始了")
        //创建组
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            //并发队列中的异步任务中由嵌套了一个异步任务
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("模拟一下耗时操作:--\(Thread.current)")
                group.leave()
            }
            NSLog("11111--\(Thread.current)")
        }))
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        group.notify(queue: DispatchQueue.global(), work: DispatchWorkItem.init(block: {
            NSLog("所有任务都完成了，我开始执行了--\(Thread.current)")
        }))
        NSLog("---完成了---")

        输出结果:
        
        2020-04-04 17:46:42.086209+0800 WGFcodeNotes[2583:104409] 开始了
        2020-04-04 17:46:42.086542+0800 WGFcodeNotes[2583:104409] ---完成了---
        2020-04-04 17:46:42.087041+0800 WGFcodeNotes[2583:104458] 22222--<NSThread: 0x6000004243c0>{number = 4, name = (null)}
        2020-04-04 17:46:42.087184+0800 WGFcodeNotes[2583:104462] 11111--<NSThread: 0x60000042cc00>{number = 5, name = (null)}
        2020-04-04 17:46:47.089302+0800 WGFcodeNotes[2583:104459] 模拟一下耗时操作:--<NSThread: 0x60000044e840>{number = 6, name = (null)}
        2020-04-04 17:46:47.089733+0800 WGFcodeNotes[2583:104459] 所有任务都完成了，我开始执行了--<NSThread: 0x60000044e840>{number = 6, name = (null)}
##### 分析：现在达到了group等待所有任务都完成了才开始去执行notify后的方法，在任务开始前调用group.enter()方法，其实就是告诉group，这里有一个未完成的任务，未完成的任务数会+1，等到任务完成后调用group.leave()方法，就是告诉group，这个任务已经完成了，未完成的任务数会-1，当任务数为0的时候，才会去执行notify方法,那么如何影响wait方法？接着来看

        NSLog("开始了")
        let group = DispatchGroup()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            //并发队列中的异步任务中由嵌套了一个异步任务
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("模拟一下耗时操作:--\(Thread.current)")
            }
            NSLog("11111--\(Thread.current)")
        }))
        group.wait()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        NSLog("---完成了---")

        输出结果：

        2020-04-04 17:55:25.912878+0800 WGFcodeNotes[2687:109524] 开始了
        2020-04-04 17:55:25.913724+0800 WGFcodeNotes[2687:109579] 11111--<NSThread: 0x600003500180>{number = 4, name = (null)}
        2020-04-04 17:55:25.914085+0800 WGFcodeNotes[2687:109524] ---完成了---
        2020-04-04 17:55:25.914298+0800 WGFcodeNotes[2687:109579] 22222--<NSThread: 0x600003500180>{number = 4, name = (null)}
        2020-04-04 17:55:30.914158+0800 WGFcodeNotes[2687:109578] 模拟一下耗时操作:--<NSThread: 0x60000351aa00>{number = 3, name = (null)}
##### 分析: 上面已经说过了，wait会阻塞当前的线程，那么为什么没有等到嵌套任务的任务执行完再执行后面的操作那？原因和上面一样，嵌套的异步任务直接返回了，所以wait认为方法执行完成了，所以就不再阻塞了，这时候用enter和leave就可以解决

        NSLog("开始了")
        let group = DispatchGroup()
        //告诉group,这里有个未完成的任务，group中未执行完成的任务数+1，直到遇到leave方法，才算告诉group该方法执行完成了
        group.enter()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            //并发队列中的异步任务中由嵌套了一个异步任务
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 5.0)
                NSLog("模拟一下耗时操作:--\(Thread.current)")
                group.leave() //告诉group该方法执行完成了，group中未执行完成的任务数-1
            }
            NSLog("11111--\(Thread.current)")
        }))
        group.wait()
        DispatchQueue.global().async(group: group, execute: DispatchWorkItem.init(block: {
            NSLog("22222--\(Thread.current)")
        }))
        NSLog("---完成了---")

        输出结果: 

        2020-04-04 18:01:36.980687+0800 WGFcodeNotes[2746:113701] 开始了
        2020-04-04 18:01:36.981235+0800 WGFcodeNotes[2746:113757] 11111--<NSThread: 0x600002f0eb40>{number = 3, name = (null)}
        2020-04-04 18:01:41.986551+0800 WGFcodeNotes[2746:113753] 模拟一下耗时操作:--<NSThread: 0x600002f56200>{number = 6, name = (null)}
        2020-04-04 18:01:41.987052+0800 WGFcodeNotes[2746:113701] ---完成了---
        2020-04-04 18:01:41.987295+0800 WGFcodeNotes[2746:113752] 22222--<NSThread: 0x600002f70540>{number = 7, name = (null)}
##### 分析： enter方法告诉group(这里其实就是告诉wait方法)这里有个未完成的任务，任务数+1，leval方法就是告诉group(这里其实就是告诉wait方法)这里有个未完成的任务已经完成了，任务数-1,等任务数为0的时候，告诉wait方法可以执行后续的任务了


## GCD 实现单例 
##### 使用dispatch_once方法实现，dispatch_once能够保证在程序运行过程中，指定的代码只会被执行一次
        OC单利实现方式
        //声明一个静态变量
        static WGTestModel *_instance;
        +(instancetype)shareInstance {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                _instance = [[WGTestModel alloc]init];
            });
            return _instance;
        }
        //swift中单例实现 final将WGTestEntity类终止被继承,其实static let的背后用的就是dispatch_once方法
        //设置初始化方法为私有，避免外部对象通过访问init方法创建单例类的实例。
        public final class WGTestEntity : NSObject {
            static let instance = WGTestEntity()
            private override init() {
                super.init()
            }
        }

## GCD 的asyncAfter方法
### asyncAfter Apple文档描述：Submits a work item to a dispatch queue for asynchronous execution after a specified time；即改方法并不是在指定时间后执行处理，而是在指定时间后将任务追加到队列中异步执行
        NSLog("开始")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            for i in 0...2 {
                NSLog("----\(i)----")
            }
        }
        NSLog("结束")
        输出结果:

        2020-04-04 22:26:50.811534+0800 WGFcodeNotes[4409:248519] 开始
        2020-04-04 22:26:50.812228+0800 WGFcodeNotes[4409:248519] 结束
        2020-04-04 22:26:50.918052+0800 WGFcodeNotes[4409:248519] ----0----
        2020-04-04 22:26:50.918392+0800 WGFcodeNotes[4409:248519] ----1----
        2020-04-04 22:26:50.918647+0800 WGFcodeNotes[4409:248519] ----2----
##### 分析，发现asyncAfter不会阻塞当前线程，在2秒时间过后，才开始执行里面的任务，同时发现了一个现象，如果NSLog("结束")后面还有其他任务（暂时用任务A代替）的话，asyncAfter会一直等到任务A结束后，再过2秒才开始执行asyncAfter内的任务，所以我们就能理解asyncAfter方法一般用在网络请求成功后，等到展示完提示后的信息后，才开始跳转，因为后续没有什么任务了

#### DispatchTime.now()+2指相对当前时间的2秒后，也可以使用DispatchTimeInterval.seconds(2)表示，或者DispatchTimeInterval的其他单位表示，毫秒(milliseconds),微秒(milliseconds),纳秒(nanoseconds),也可以使用DispatchWallTime 表示绝对时间（系统时间，设备休眠计时不暂停），精度是微秒。DispatchWallTime的用法和DispatchTime差不多。

## GCD中 barrier标志
### OC中应该说是barrier栅栏函数,在swift中是barrier标识，主要用于多个异步任务之间，控制指定的任务先执行，指定的任务后执行，其实类似GCD中的notify，但是区别就是，notify指的是添加到group内的所有任务都执行完才去通知notify block中的方法去执行，而barrier可以针对那些没有放在group组内的任务，可以是多个并发队列+异步任务，比如下面场景，任务4依赖任务1任务2任务3，任务5依赖任务4，而任务1任务2任务3都是可以分别独立执行，而任务5也可以独立执行，那么就可以使用栅栏将这些任务“分割”开来达到实际业务的需求
        //如果是系统创建的全局队列，barrier并没有起到效果，所以barrier不能用于全局队列
        //let concurrencyQueue = DispatchQueue.global()
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
        输出结果:

        2020-04-05 09:39:02.621259+0800 WGFcodeNotes[1370:43152] 22222--<NSThread: 0x6000016f18c0>{number = 6, name = (null)}
        2020-04-05 09:39:02.621259+0800 WGFcodeNotes[1370:43154] 33333--<NSThread: 0x6000016a80c0>{number = 4, name = (null)}
        2020-04-05 09:39:04.626118+0800 WGFcodeNotes[1370:43153] 11111--<NSThread: 0x6000016a0480>{number = 5, name = (null)}
        2020-04-05 09:39:07.631711+0800 WGFcodeNotes[1370:43153] 44444--<NSThread: 0x6000016a0480>{number = 5, name = (null)}
        2020-04-05 09:39:07.632105+0800 WGFcodeNotes[1370:43153] 5555--<NSThread: 0x6000016a0480>{number = 5, name = (null)}
##### 分析:任务1+任务2+任务3完成之前，barrier会阻塞当前线程，直到任务1+任务2+任务3全部完成后，才去执行任务4和任务5，同时注意到，任务4一定是比任务5优先执行的，同时也验证了将异步任务添加到系统创建的全局队列中，barrier是不会阻塞线程的，是达不到上面的执行顺序的，所以 barrier不能用于全局队列(全局并发队列)
### 结论:barrier用于任务块之间的执行顺序上的分割，这些任务必须放在同一个队列中，但是barrier不能用于全局队列



## GCD 信号量
### GCD中信号量DispatchSemaphore，用于控制线程并发数，初始化一个值创建信号量对象，wait()方法使信号量-1，signal()方法使信号量+1，当信号量为0的时候会阻塞当前线程，等待信号量大于0，恢复线程，主要用于多线程之间的同步，锁也可以实现多线程同步，但不同的是，锁是锁住某一资源，而信号量是逻辑上的“锁住”

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

        输出结果: 

        2020-04-05 13:50:11.471740+0800 WGFcodeNotes[2602:149807] 11111--<NSThread: 0x600003a74200>{number = 4, name = (null)}
        2020-04-05 13:50:11.472221+0800 WGFcodeNotes[2602:149807] 22222--<NSThread: 0x600003a74200>{number = 4, name = (null)}
        2020-04-05 13:50:11.472344+0800 WGFcodeNotes[2602:149807] 22222--<NSThread: 0x600003a74200>{number = 4, name = (null)}
        2020-04-05 13:50:11.472485+0800 WGFcodeNotes[2602:149807] 22222--<NSThread: 0x600003a74200>{number = 4, name = (null)}
        2020-04-05 13:50:11.472711+0800 WGFcodeNotes[2602:149807] 33333--<NSThread: 0x600003a74200>{number = 4, name = (null)}
##### 分析： 通过信号量的变化来控制多线程中的任务实现同步(即控制多个异步任务的执行顺序)，从中可以发现，信号量为0并不一定会阻塞线程，比如初始化信号量设置为0，并没有阻塞接下来的任务执行，通过信号量为0来决定是否阻塞当前线程是根据遇到wait方法的时候来判断的，如果执行到wait方法了，此时如果信号量为0，那么wait方法后的代码就会被阻塞，知道wait前的方法执行完成后并且调用了signal方法



## 使用场景：有多个异步任务完成后，才开始执行group.notify中Block中的操作
        //创建组
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
        输出结果:

        11111--<NSThread: 0x600003644c40>{number = 4, name = (null)}
        22222--<NSThread: 0x60000361fb40>{number = 6, name = (null)}
        33333--<NSThread: 0x600003645b00>{number = 7, name = (null)}
        00000--<NSThread: 0x60000361a140>{number = 1, name = main}
### 结论：DispatchGroup().notify其实通知的是队列，一般用于系统创建的队列(主队列)，如果你通知了我们自己手动创建的队列（串行队列/并发队列）或者系统创建的全局队列，都不会有问题的，但是无意义，因为这些队列中添加的任务，并不是因为group的notify触发的，而是按照自己该有的顺序去执行，也就是说notify对这些队列中添加的任务是没有任何影响的，因为notify真正通知的是跟随在notify后面block中的任务，文末有验证的demo和分析来证明这个结论


## 下面是验证结论的
##### 分析：可以发现，放在DispatchGroup组里面的任务的执行顺序是不确定的(不要让打印结果误导哦，打印多次就会发现是无序的)，并发执行的；只有组内的任务全部完成后，group才开始通知主线程去执行主线程要执行的任务，这里应该注意到，group通知的并不是主线程，而是通知的一个主队列，让主队列中的任务继续执行，因为主队列内的任务是在主线程中执行的，所以我们一般说是通知主线程做事情， group可以通知主队列，是否可以通知其他队列(串行队列，并发队列)？答案是可以的

        //创建组
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
        //这里我们创建一个串行队列,并添加同步任务
        let serialQueue = DispatchQueue(label: "串行队列名称")
        serialQueue.sync {
            NSLog("串行队列同步任务--\(Thread.current)")
        }
        group.notify(queue: serialQueue, work: DispatchWorkItem.init(block: {
            NSLog("开始去执行串行队列中的任务吧----\(Thread.current)")
        }))
        
        输出结果:
        
        串行队列同步任务--<NSThread: 0x600003add6c0>{number = 1, name = main}
        33333--<NSThread: 0x600003aa0840>{number = 6, name = (null)}
        11111--<NSThread: 0x600003aac040>{number = 4, name = (null)}
        22222--<NSThread: 0x600003a85a40>{number = 3, name = (null)}
        开始去执行串行队列中的任务吧----<NSThread: 0x600003aac040>{number = 4, name = (null)}
##### 分析：我们手动创建了串行队列，并添加了同步任务，然后group内任务全部完成后，去通知该串行队列去执行它里面的任务，但是结果却是，串行队列中的同步任务并没有收到通知(group.notify)后才去执行同步任务，串行队列中的同步任务并没有受到group的影响，而是按照自己该有的方式去执行了，通过线程打印信息还能发现，如果group通知到了创建的线程，那么group内的线程应该和创建的线程是一样的啊，为什么？开始介绍Group说的是：它是用来执行异步任务的，同步任务不能执行的，👌，我们继续创建异步任务验证
        //创建组
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
        输出结果:
        11111串行队列同步任务--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
        22222串行队列同步任务--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
        11111--<NSThread: 0x600000cf1880>{number = 5, name = (null)}
        22222--<NSThread: 0x600000cdc400>{number = 4, name = (null)}
        33333--<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
        开始去执行串行队列中的任务吧----<NSThread: 0x600000cda7c0>{number = 6, name = (null)}
##### 分析:通过结果打印，发现在串行队列中添加异步任务，group仍然没有通知到队列中的任务去执行，而是串行队列中的异步任务按照自己的方式去执行了，为什么？难道group不能通知串行队列(除了主队列)，只支持通知异步队列？我们继续验证

        //创建组
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

        输出结果:

        11111并发队列同步任务--<NSThread: 0x600000d76c40>{number = 1, name = main}
        22222并发队列同步任务--<NSThread: 0x600000d76c40>{number = 1, name = main}
        22222--<NSThread: 0x600000d3c900>{number = 5, name = (null)}
        11111--<NSThread: 0x600000d799c0>{number = 6, name = (null)}
        33333--<NSThread: 0x600000d02880>{number = 7, name = (null)}
        开始去执行并发队列中的任务吧----<NSThread: 0x600000d02880>{number = 7, name = (null)}
##### 分析：发现创建的异步队列，并添加了同步任务，group依然没有通知到，暴脾气上来了，为什么？难道group只支持通知并发队列中的异步任务，👌，我们继续验证并发队列下的异步任务
        
        //创建组
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
        
        输出结果：
        
        22222并发队列异步任务--<NSThread: 0x6000001e8480>{number = 6, name = (null)}
        11111并发队列异步任务--<NSThread: 0x6000001bd240>{number = 4, name = (null)}
        33333--<NSThread: 0x6000001eca80>{number = 8, name = (null)}
        22222--<NSThread: 0x6000001e8a00>{number = 7, name = (null)}
        11111--<NSThread: 0x6000001bd800>{number = 5, name = (null)}
        开始去执行并发队列中的任务吧----<NSThread: 0x6000001bd800>{number = 5, name = (null)}
##### 分析：答案依旧是😠😠group不能通知到并发队列中的异步任务，容我想思考一下，刚才group通知的都是需要我们程序员手动创建的队列，那么GCD自己创建的队列(主队列和全局队列)可以吗，目前我们知道group是可以通知到主队列的，那么系统创建的全局队列可以通知到吗？

        //创建组
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

        输出结果:

        全局队列异步任务--<NSThread: 0x600001e3c080>{number = 3, name = (null)}
        22222--<NSThread: 0x600001e2cc00>{number = 6, name = (null)}
        33333--<NSThread: 0x600001e344c0>{number = 7, name = (null)}
        11111--<NSThread: 0x600001e2a680>{number = 5, name = (null)}
        开始去执行并发队列中的任务吧----<NSThread: 0x600001e2a680>{number = 5, name = (null)}
##### 分析: 发现group通知了DispatchQueue.global()并发队列，但是并没有通知到(并发队列中的任务并不是group通知触发的)

