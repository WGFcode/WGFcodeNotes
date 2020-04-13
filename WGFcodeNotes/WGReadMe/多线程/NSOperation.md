## NSOperation 这是OC的命名方式，在swift中叫做Operation

### 总结:
* Operation实现需要Operation+OperationQueue结合才能实现多线程操作,即创建操作(任务),然后将操作(任务)添加到操作队列中,操作队列会自动执行队列中的任务,不需要我们手动再开启操作(任务);
* 操作(任务)的创建在OC中主要通过(NSInvocationOperation/NSBlockOperation/自定义继承自NSOperation的子类)这三种方式创建,而在swift中通过(BlockOperation/自定义继承自Operation的子类)来创建;

* 单独创建操作而没有涉及到操作队列的情况下: 如果都是通过初始化创建的操作(BlockOperation.init(block: () -> Void)),那么不管创建多少个,这些操作的执行都是在当前线程中同步执行的,会阻塞当前的线程(操作外的任务会处于等待状态),操作之间的顺序是按照顺序一个一个执行的;如果通过初始化创建了第一个操作,然后调用操作的addExecutionBlock(block: () -> Void)方法添加多个操作(任务),那么第一个通过初始化创建的操作会在当前线程中执行,其他通过addExecutionBlock添加的操作系统会开启多条子线程进行执行,具体开启多少条线程,由系统决定,但这种方式下操作的执行仍然是同步的,即会阻塞当前的线程,而多个操作(任务)之间的执行顺序是无序的并发执行的;单独创建的操作都需要手动调用操作的start方法来开启操作

* 实际业务场景中,单独创建操作而没有操作队列的话,操作的执行都是同步的,即操作会阻塞当前的线程,所以想利用Operation实现多线程必须结合操作队列OperatioQueue来实现

* 在swift中一般通过BlockOperation创建操作,遇到复杂的业务可以自定义继承自Operation的子类来创建操作,然后将操作添加到OperationQueue队列中实现多线程,操作是异步的,即不会阻塞当前线程,并且队列中的任务是并发的,就是队列中的任务之间执行顺序是无序的

* 操作队列中的操作(任务)是并发执行的,那么如果想控制队列中的操作的执行顺序怎么办? 一般情况下我们都是通过设置操作之间的依赖来控制操作的执行顺序,但是有个特殊情况,就是如果操作中嵌套了异步任务,那么就不能通过添加操作之间的依赖来控制操作的执行顺序,因为操作中嵌套了异步任务,而异步任务是直接返回的,所以添加的依赖会以为嵌套异步任务的操作已经完成了,这时候我们可以使用依赖+信号量(通过添加信号量来判断嵌套的异步任务是否真正的执行完成)的方式来控制队列中操作的真正执行顺序

* 使用BlockOperation初始化创建多个操作,然后将操作添加到队列中;和使用BlockOperation初始化一个操作,然后调用addExecutionBlock方法添加多个操作,然后将这一个操作添加到队列中的区别是什么?首先无论哪种方式,执行效果是一样的,唯一的区别就是第一种方式可以添加操作之间的依赖关系/设置操作间优先级,而第一种方式因为就一个操作变量,所以不能设置

### Operation(操作)+OperationQueue(操作队列)：创建操作，将操作添加到操作队列中来实现多线程编程。Operation是对GCD的进一步封装，完全的面相对象，首先我们先看下操作和操作队列常用的属性和方法（提醒：所有验证都是基于swift的）
        //操作
        var name: String?                           设置操作名称
        var isCancelled: Bool { get }               判断操作是否已经标记为取消
        var queuePriority: Operation.QueuePriority  设置操作优先级
        var qualityOfService: QualityOfService      设置服务优先级
        var isExecuting: Bool { get }               判断操作是否正在在运行
        var isFinished: Bool { get }                判断操作是否已经结束
        var isConcurrent: Bool { get }
        var isAsynchronous: Bool { get }
        var isReady: Bool { get }
        var completionBlock: (() -> Void)?
        var dependencies: [Operation] { get }       在当前操作开始执行之前完成执行的所有操作对象数组。
        func main()
        func start()                                执行操作
        func cancel()                               可取消操作，实质是标记 isCancelled 状态
        func addDependency(_ op: Operation)         添加依赖，使当前操作依赖于操作 op 的完成
        func removeDependency(_ op: Operation)      移除依赖，取消当前操作对操作 op 的依赖
        func waitUntilFinished()                    阻塞当前线程，直到该操作结束。可用于线程执行顺序的同步
        
        //操作队列
        var maxConcurrentOperationCount: Int        设置操作队列最大的并发数，注意并不是线程数
        var isSuspended: Bool                       是否暂停
        var name: String?                           名称
        var qualityOfService: QualityOfService      服务质量
        func cancelAllOperations()                  取消操作队列中所有的操作
        func waitUntilAllOperationsAreFinished()    等待所有的操作都完成
        func addOperation(_ op: Operation)          添加操作到队列中
        添加操作数组到队列中，waitUntilFinished：是否阻塞当前线程
        func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool)
        func addOperation(_ block: @escaping () -> Void)  将封装到Block的操作添加到队列中
        unowned(unsafe) var underlyingQueue: DispatchQueue?
        class var current: OperationQueue? { get }
        class var main: OperationQueue { get }
        @available(iOS 13.0, *)
        var progress: Progress { get }              操作队列执行的进度
        //This acts similarly to the `dispatch_barrier_async` function.
        func addBarrierBlock(_ barrier: @escaping () -> Void) 添加栅栏

## 1.Operation(操作) 
### Operation就是代码执行或者说是任务，类似GCD中block的任务，Operation在OC中主要是通过它的子类(NSInvocationOperation/NSBlockOperation/创建自定义继承自NSOperation的子类)来创建操作；在swift中则是通过(BlockOperation/创建自定义继承自Operation的子类)来创建的，NSInvocationOperation这个OC中的子类在swift中已经被废弃了
### 1.1 BlockOperation创建操作
        NSLog("开始了")
        let blockOperation = BlockOperation.init {
            Thread.sleep(forTimeInterval: 2.0)
            NSLog("11111--\(Thread.current)")
        }
        blockOperation.start()
        NSLog("结束了")

        输出结果：

        2020-04-05 16:02:27.259123+0800 WGFcodeNotes[3217:205216] 开始了
        2020-04-05 16:02:29.260643+0800 WGFcodeNotes[3217:205216] 11111--<NSThread: 0x6000015de880>{number = 1, name = main}
        2020-04-05 16:02:29.261014+0800 WGFcodeNotes[3217:205216] 结束了
##### 分析：如果不涉及到操作队列，通过BlockOperation的初始化方法创建的操作，默认是在当前线程中执行，不会开启新线程，可以认为这就是一个同步任务，按照顺序依次执行,强调一下，代码是在主线程中调用的，所以打印的就是主线程，如果是在其他线程中，那么打印的就是其他线程，可以理解成start()方法会阻塞当前的线程，直到start前的操作完成了，才能执行start()方法后的操作

        NSLog("开始了")
        let blockOperation = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        blockOperation.addExecutionBlock {
            Thread.sleep(forTimeInterval: 2.0)
            NSLog("22222--\(Thread.current)")
        }
        blockOperation.addExecutionBlock {
            NSLog("33333--\(Thread.current)")
        }
        blockOperation.start()
        NSLog("结束了")
        输出结果:

        2020-04-07 09:31:35.373480+0800 WGFcodeNotes[4292:289535] 开始了
        2020-04-07 09:31:35.374009+0800 WGFcodeNotes[4292:289593] 33333--<NSThread: 0x600003af1280>{number = 5, name = (null)}
        2020-04-07 09:31:35.374010+0800 WGFcodeNotes[4292:289535] 11111--<NSThread: 0x600003aeddc0>{number = 1, name = main}
        2020-04-07 09:31:37.374123+0800 WGFcodeNotes[4292:289589] 22222--<NSThread: 0x600003af5c80>{number = 3, name = (null)}
        2020-04-07 09:31:37.374408+0800 WGFcodeNotes[4292:289535] 结束了
##### 分析：如果调用BlockOperation的addExecutionBlock方法添加操作，那么系统就会为每个操作开辟新的线程去执行这些操作，具体开辟多少条线程，是由系统决定的，而BlockOperation中的所有操作的执行顺序是异步的。但不管开启多少个线程，BlockOperation还是同步的，因为所有的操作都执行完成了，才开始去执行start()后的操作(打印"结束了"的信息)
        
### 结论: 如果BlockOperation只是通过初始化封装了一个操作，那么默认情况下，这一个操作就是在当前线程中执行的(当前线程可以是主线程也可以是非主线程，具体要看BlockOperation的初始化是在哪个线程中执行)，如果通过addExecutionBlock方法添加(封装)了多个操作，那么除了第一个操作在当前线程中执行，其它操作都是在新开辟的子线程中执行，另外BlockOperation操作是需要手动调用start()方法才可以执行的。可以说BlockOperation是同步的，因为只有所有的操作都完成了，才能执行后续的操作，实际业务一般不需要这样的线程，而是需要配置OperationQueue来实现多线程操作。


### 1.2 自定义继承自Operation的子类来创建操作

##### 自定义继承自Operation的子类创建操作分为两种 一种是非并发的操作 一种是并发操作
### 1.2.1 实现非并发的自定义子类：继承Operation，重新main方法即可
        public class CustomOperation1 : Operation {
            public override func main() {
                //打印的是当前线程(如果当前线程是主线程，那么就打印主线程，如果不是主线程，则打印指定的线程)
                NSLog("----\(Thread.current)----")
            }
        }

        let op1 = CustomOperation1()
        op1.main()
        //调用main()或者start()方法都能执行操作，如果两个方法都写，则执行两次
        //op1.start()

        打印结果:

        ----<NSThread: 0x600000abd240>{number = 1, name = main}----

        self.performSelector(inBackground: #selector(method1), with: nil)
        @objc func method1() {
            let op1 = CustomOperation1()
            op1.start()
        }

        打印结果: ----<NSThread: 0x600000590dc0>{number = 6, name = (null)}----
##### 分析： 继承自Operation并重写main方法创建的操作，是按照顺序执行的，不能并发执行的

### 1.2.2 实现并发的自定义子类：继承Operation，
##### TODO 

### 2.操作队列OperationQueue
##### OperationQueue操作队列，即将操作添加到队列中，如果只创建了操作，需要手动调用start()方法才能出发操作的执行，并且这些操作是同步的，即所有的操作都完成后，才能执行后续的操作；但是如果将操作添加到队列中，队列就会自动调用start()方法，并且是异步的，即后续的执行不需要等待队列中的任务执行完成后才执行

##### OperationQueue操作队列并没有像GCD那样可以明确的创建串行队列和并发队列，通过初始化创建的操作队列，默认是并发的，但是可以通过设置maxConcurrentOperationCount(最大的并发操作数)来达到串行的效果，如果该属性设置为1，则为串行效果。系统也提供了获取主队列的类属性(main)

        //初始化队列
        //let queue = OperationQueue.init()
        //操作队列中添加任务方式
        //方式一:添加操作到队列，操作是以block的形式传入的
        //queue.addOperation(block: ()->Void)
        //方式二: 通过添加指定的操作到队列
        //queue.addOperation(op: Operation)  
        //方式三: 通过添加指定的操作数组到队列中 waitUntilFinished: true,等待
        //queue.addOperations(ops: [Operation], waitUntilFinished: Bool)
        //设置操作队列的最大并发操作数，控制的不是并发线程的数量，而是一个队列中同时能并发执行的最大操作数 
        //queue.maxConcurrentOperationCount
        //设置队列中的操作是暂停还是恢复，true:暂停 false:不暂停（恢复）只能暂停后续的操作，正在执行的操作不会被暂停
        //queue.isSuspended
        //取消队列中的所有操作，只能取消后续的操作，正在执行的操作不会被取消
        //queue.cancelAllOperations()
        //获取主队列(类属性)
        //OperationQueue.main
        //获取当前的操作队列(类属性)
        //OperationQueue.current
        //iOS13之后新添加了下面的方法，添加栅栏，其效果类似dispatch_barrier_async
        //queue.addBarrierBlock(barrier: () -> Void)
        //These two functions are inherently a race condition and should be avoided if possible
        //操作队列中的操作数，只读的
        //queue.operationCount
        //获取操作队列中所有的操作,返回的是个数组[Operation]类型
        //queue.operations

##### 下面是OperationQueue+Operation常用的操作

### 2.1 创建队列 并添加操作 实现多线程操作
        NSLog("开始了")
        //创建队列
        let queue = OperationQueue.init()
        //创建操作
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        //将操作添加到队列中 
        方式一: 异步执行(队列中的操作不会阻塞当前线程，队列外的任务不需要等待队列中任务的完成就可以执行)
        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        //方式二 可以设置同步执行 waitUntilFinished:是否阻塞队列外的任务，知道队列中的所有操作都完成
        //true:同步执行，即阻塞当前线程，直到队列中操作都完成后才执行队列外的任务  false:不阻塞
        //queue.addOperations([op1,op2,op3], waitUntilFinished: true)
        NSLog("结束了")

        方式一的打印结果:

        开始了
        结束了
        11111--<NSThread: 0x60000248a340>{number = 6, name = (null)}
        33333--<NSThread: 0x600002408d00>{number = 5, name = (null)}
        22222--<NSThread: 0x600002403bc0>{number = 3, name = (null)}
        
        方式二的打印结果:
        
        开始了
        11111--<NSThread: 0x60000248a340>{number = 6, name = (null)}
        33333--<NSThread: 0x600002408d00>{number = 5, name = (null)}
        22222--<NSThread: 0x600002403bc0>{number = 3, name = (null)}
        结束了
        
##### 分析 首先创建队列,默认创建的队列是并发的，即maxConcurrentOperationCount不为1，然后创建操作，将操作添加到队列中，在添加的过程中，可以根据需要设置队列中的任务是否需要阻塞当前线程，即队列外的任务是否要等待队列内的操作全部完成才去执行；而队列内的多个操作(任务)之间是并发的，即执行是无序的，如果想控制队列内多个操作(任务)的执行顺序，则可以通过添加操作之间的约束来实现，如下
### 2.2 添加依赖，控制队列中操作之间的执行顺序
        NSLog("开始了")
        let queue = OperationQueue.init()
        let op1 = BlockOperation.init {
            Thread.sleep(forTimeInterval: 2.0)
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            Thread.sleep(forTimeInterval: 1.0)
            NSLog("33333--\(Thread.current)")
        }
        //想让操作按照任务1->任务2->任务3的顺序执行，则可以如下设置依赖
        //任务2的执行依赖任务1
        op2.addDependency(op1)
        //任务3的执行依赖任务2的执行
        op3.addDependency(op2)
        //将操作添加到队列中
        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        NSLog("结束了")
        
        输出结果：
        2020-04-07 15:18:51.530460+0800 WGFcodeNotes[7952:535967] 开始了
        2020-04-07 15:18:51.530809+0800 WGFcodeNotes[7952:535967] 结束了
        2020-04-07 15:18:53.535261+0800 WGFcodeNotes[7952:536019] 11111--<NSThread: 0x6000021c9840>{number = 3, name = (null)}
        2020-04-07 15:18:53.535609+0800 WGFcodeNotes[7952:536016] 22222--<NSThread: 0x6000021c8480>{number = 5, name = (null)}
        2020-04-07 15:18:54.537197+0800 WGFcodeNotes[7952:536016] 33333--<NSThread: 0x6000021c8480>{number = 5, name = (null)}
##### 分析 想控制队列中的多个操作的执行顺序，可以通过添加操作之间的相互约束来达到执行顺序的控制

### 2.3 取消操作 任务一旦被取消，就不会再恢复了
        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        op1.cancel()
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:
        开始了
        结束了
        33333--<NSThread: 0x60000140ee80>{number = 3, name = (null)}
        22222--<NSThread: 0x600001464880>{number = 4, name = (null)}
##### 分析 在特定业务场景下，我们需要取消某一个操作，那么就可以在适当的时机调用Operation的cancel()方法来取消该操作，除了 Operation操作提供了取消单个操作的方法外，队列OperationQueue也提供了cancelAllOperations()方法来取消队列中所有的操作。

### 2.4 暂停操作和恢复操作 
        //在外面声明一个队列属性
        private var queue = OperationQueue()

        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        //暂定队列中的操作
        queue.isSuspended = true
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        //点击屏幕 恢复队列中的操作
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            queue.isSuspended = false
        }

        输出结果: 
        开始了
        结束了
        点击屏幕后恢复操作: 
        22222--<NSThread: 0x6000001d4140>{number = 4, name = (null)}
        11111--<NSThread: 0x600000125800>{number = 7, name = (null)}
        33333--<NSThread: 0x6000001b1ac0>{number = 8, name = (null)}
##### 分析，只能暂停队列中的操作，而操作Operation没有提供暂停单一操作的方法。需要注意的是，暂停的不是队列中所有的操作，也不能暂停当前正在执行的操作，暂停的是队列中还没有被执行的操作；恢复队列中的任务，恢复的是上次队列中暂停的还没有被执行的操作

### 2.5 设置最大的并发操作数 (并不是开启线程的数量，而是同一时间可以并发处理的操作(任务)数)
        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            for _ in 0...2{
            NSLog("11111--\(Thread.current)")
            }
        }
        let op2 = BlockOperation.init {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        let op3 = BlockOperation.init {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:

        开始了
        结束了
        22222--<NSThread: 0x6000014c2980>{number = 5, name = (null)}
        11111--<NSThread: 0x6000014f5480>{number = 4, name = (null)}
        33333--<NSThread: 0x6000014f5c00>{number = 6, name = (null)}
        22222--<NSThread: 0x6000014c2980>{number = 5, name = (null)}
        33333--<NSThread: 0x6000014f5c00>{number = 6, name = (null)}
        11111--<NSThread: 0x6000014f5480>{number = 4, name = (null)}
        11111--<NSThread: 0x6000014f5480>{number = 4, name = (null)}
##### 分析 通过初始化创建的队列OperationQueue默认是并发处理队列中的任务的，可以发现队列中的多个操作(任务)之间是并发执行的，maxConcurrentOperationCount最大的并发操作数默认值是由系统动态设置的，但默认值肯定不会是1，如果我们手动设置该值为1会有什么结果

        NSLog("开始了")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let op1 = BlockOperation.init {
            for _ in 0...2{
            NSLog("11111--\(Thread.current)")
            }
        }
        let op2 = BlockOperation.init {
            Thread.sleep(forTimeInterval: 2.0)
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        let op3 = BlockOperation.init {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:

        开始了
        结束了
        11111--<NSThread: 0x600000d66cc0>{number = 5, name = (null)}
        11111--<NSThread: 0x600000d66cc0>{number = 5, name = (null)}
        11111--<NSThread: 0x600000d66cc0>{number = 5, name = (null)}
        22222--<NSThread: 0x600000d806c0>{number = 6, name = (null)}
        22222--<NSThread: 0x600000d806c0>{number = 6, name = (null)}
        33333--<NSThread: 0x600000d806c0>{number = 6, name = (null)}
        33333--<NSThread: 0x600000d806c0>{number = 6, name = (null)}
        ##### 分析 如果设置maxConcurrentOperationCount值为1，那么此时的队列就是串行队列了，队列中的任务之间是同步执行的，即每次只能执行一个任务并按照顺序执行，同时发现了打印的线程有2个子线程，所以也验证了maxConcurrentOperationCount并不是控制线程的个数，而是同一时间可以处理的最大操作(任务)数，而开启多少个线程数是由系统决定的

##### 如果将并发的最大操作数设置为2
        NSLog("开始了")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        let op1 = BlockOperation.init {
            for _ in 0...2{
            NSLog("11111--\(Thread.current)")
            }
        }
        let op2 = BlockOperation.init {
            for _ in 0...1 {
                NSLog("22222--\(Thread.current)")
            }
        }
        let op3 = BlockOperation.init {
            for _ in 0...1 {
                NSLog("33333--\(Thread.current)")
            }
        }
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:

        开始了
        结束了
        22222--<NSThread: 0x600000640a40>{number = 6, name = (null)}
        11111--<NSThread: 0x600000676600>{number = 5, name = (null)}
        22222--<NSThread: 0x600000640a40>{number = 6, name = (null)}
        11111--<NSThread: 0x600000676600>{number = 5, name = (null)}
        33333--<NSThread: 0x60000061dd40>{number = 4, name = (null)}
        11111--<NSThread: 0x600000676600>{number = 5, name = (null)}
        33333--<NSThread: 0x60000061dd40>{number = 4, name = (null)}

##### 分析 可以发现当并发的最大操作数设置为2是，队列内的操作(任务)是并发执行的

### 2.6 设置操作的优先级 
##### 设置优先级并不能控制队列中操作的执行顺序，只是去控制同一队列中进入就绪状态的操作(任务)的开始执行顺序，什么是就绪状态？就绪状态取决于操作时间的依赖关系。添加到队列中的操作基本都是处于准备就绪状态，而如果操作之间又添加了依赖关系，就要根据依赖关系来确定操作是否是就绪状态
##### 例如 有任务1，任务2，任务3，任务4，任务2依赖任务1，任务3依赖任务2，由于任务1和任务4没有依赖关系，所以任务1和任务4处于就绪状态，此时设置任务1和任务4的优先级，谁优先级高先最先被执行；由于任务2和任务3有依赖，所以任务2和任务3就不是处于就绪状态的操作；如果队列中同时包含了就绪状态(任务1和任务4)和未就绪状态(任务2和任务3)的操作，并且未就绪状态((任务2和任务3))的优先级高于就绪状态(任务1和任务4)的优先级，也是优先执行就绪状态的操作(任务1和任务4)，因为优先级不能取代依赖关系。

        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        //设置操作的优先级来实现
        op1.queuePriority = .veryHigh
        op2.queuePriority = .high
        op3.queuePriority = .low
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:
        开始了
        结束了
        33333--<NSThread: 0x60000297da80>{number = 5, name = (null)}
        11111--<NSThread: 0x6000029085c0>{number = 4, name = (null)}
        22222--<NSThread: 0x6000029156c0>{number = 3, name = (null)}
##### 分析 操作的queuePriority主要分为5中 按照优先级由低到高的顺序依次是veryLow->low->normal->high->veryHigh，添加到队列中的操作，首先进入的是准备就绪状态，而进入准备就绪状态的操作(任务)的开始执行顺序(非结束执行顺序)是由操作之间相对的优先级决定的 

##### 除了设置各个操作的优先级,也可以设置操作的服务优先级QualityOfService,为了让这个操作能更高更多更快的获取到系统资源，但是系统如何调度资源是我们控制不了的,设置服务有限级如下


    ##### 除了设置队列优先级，也可以设置服务优先级
        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        /*可以通过设置操作的服务优先级QualityOfService来实现系统资源的优先使用,
         QualityOfService是个枚举值 优先级由高到低
         userInteractive: 33 用于直接参与提供交互式UI的工作。 例如，处理控制事件或绘制到屏幕上。
         userInitiated: 25 由用户发起的并且需要立即得到结果的任务，比如滑动scroll view时去加载数据用于后续cell的显示，这些任务通常跟后续的用户交互相关，在几秒或者更短的时间内完成
         utility: 17 一些可能需要花点时间的任务，这些任务不需要马上返回结果，比如下载的任务，这些任务可能花费几秒或者几分钟的时间
         background: 9 这些任务对用户不可见，比如后台进行备份的操作，这些任务可能需要较长的时间，几分钟甚至几个小时
         `default`: -1 优先级介于userInteractive和utility之间，当没有 QoS信息时默认使用，开发者不应该使用这个值来设置自己的任务
         */
        op1.qualityOfService = .userInteractive
        op2.qualityOfService = .utility
        op3.qualityOfService = .background
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        NSLog("结束了")

        输出结果:

        开始了
        结束了
        11111--<NSThread: 0x60000127ac40>{number = 6, name = (null)}
        33333--<NSThread: 0x6000012490c0>{number = 5, name = (null)}
        22222--<NSThread: 0x600001291b40>{number = 7, name = (null)}
### 2.7 OperationQueue队列中其他的方法解读
#### 2.7.1 iOS13新添加的方法 addBarrierBlock,添加栅栏,
        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            NSLog("33333--\(Thread.current)")
        }
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        if #available(iOS 13.0, *) {
            queue.addBarrierBlock {
                Thread.sleep(forTimeInterval: 2)
                NSLog("44444--\(Thread.current)")
            }
        } else {
        }
        NSLog("结束了")

        输出结果:

        2020-04-07 22:05:28.317716+0800 WGFcodeNotes[3593:41730] 开始了
        2020-04-07 22:05:28.318498+0800 WGFcodeNotes[3593:41730] 结束了
        2020-04-07 22:05:28.318642+0800 WGFcodeNotes[3593:41808] 33333--<NSThread: 0x600000f23480>{number = 3, name = (null)}
        2020-04-07 22:05:28.318642+0800 WGFcodeNotes[3593:41807] 11111--<NSThread: 0x600000f01cc0>{number = 6, name = (null)}
        2020-04-07 22:05:28.318683+0800 WGFcodeNotes[3593:41804] 22222--<NSThread: 0x600000f36ac0>{number = 5, name = (null)}
        2020-04-07 22:05:30.323685+0800 WGFcodeNotes[3593:41804] 44444--<NSThread: 0x600000f36ac0>{number = 5, name = (null)}
##### 分析 addBarrierBlock方法指的是当操作队列中的所有操作(任务)都执行完成后,才开始去执行addBarrierBlock方法中的代码
#### 2.7.2 waitUntilAllOperationsAreFinished方法,实现操作同步,一般OperaionQueue都是异步的,这里的同步指的是队列外的任务要等队列中所有的任务完成后,才能执行队列外后续的操作,异步就是队列外的任务不需要等队列中的全部任务都完成才执行
        NSLog("开始了")
        let queue = OperationQueue()
        let op1 = BlockOperation.init {
            NSLog("11111--\(Thread.current)")
        }
        let op2 = BlockOperation.init {
            NSLog("22222--\(Thread.current)")
        }
        let op3 = BlockOperation.init {
            Thread.sleep(forTimeInterval: 2.0)
            NSLog("33333--\(Thread.current)")
        }
        queue.addOperations([op1,op2,op3], waitUntilFinished: false)
        queue.waitUntilAllOperationsAreFinished()
        NSLog("结束了")

        输出结果:

        2020-04-07 22:22:03.391152+0800 WGFcodeNotes[4158:51385] 开始了
        2020-04-07 22:22:03.392460+0800 WGFcodeNotes[4158:51476] 22222--<NSThread: 0x600000b45100>{number = 6, name = (null)}
        2020-04-07 22:22:03.392475+0800 WGFcodeNotes[4158:51487] 11111--<NSThread: 0x600000b70080>{number = 3, name = (null)}
        2020-04-07 22:22:05.395055+0800 WGFcodeNotes[4158:51477] 33333--<NSThread: 0x600000b70040>{number = 4, name = (null)}
        2020-04-07 22:22:05.395430+0800 WGFcodeNotes[4158:51385] 结束了
##### 分析 waitUntilAllOperationsAreFinished方法会阻塞当前的线程,知道队列中所有的操作(任务)都完成后,才开始执行后续的任务(这里指的就是打印"结束了"的信息)

### 2.8 线程间通信

        NSLog("开始了")
        let queue = OperationQueue()
        queue.addOperation {
            //模拟耗时操作
            for _ in 0...2 {
                Thread.sleep(forTimeInterval: 2)
                NSLog("11111--\(Thread.current)")
            }
            //执行完成后回到主线程进行刷新UI界面等操作
            OperationQueue.main.addOperation {
                NSLog("22222开始在主线程中做事情--\(Thread.current)")
            }
        }
        NSLog("结束了")
        
        输出结果:
        2020-04-07 22:12:44.711590+0800 WGFcodeNotes[3802:46098] 开始了
        2020-04-07 22:12:44.712124+0800 WGFcodeNotes[3802:46098] 结束了
        2020-04-07 22:12:46.727603+0800 WGFcodeNotes[3802:46229] 11111--<NSThread: 0x6000002ceb40>{number = 4, name = (null)}
        2020-04-07 22:12:48.730814+0800 WGFcodeNotes[3802:46229] 11111--<NSThread: 0x6000002ceb40>{number = 4, name = (null)}
        2020-04-07 22:12:50.731442+0800 WGFcodeNotes[3802:46229] 11111--<NSThread: 0x6000002ceb40>{number = 4, name = (null)}
        2020-04-07 22:12:50.732214+0800 WGFcodeNotes[3802:46098] 22222开始在主线程中做事情--<NSThread: 0x60000029e100>{number = 1, name = main}
##### 分析 一般线程间通信指的就是在子线程中做完事情后,再回到主线程中执行其他任务
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
