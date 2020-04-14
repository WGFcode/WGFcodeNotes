## 线程锁
### 常用的线程锁一般有
1. NSLock-普通锁
2. NSCondition-状态锁
3. synchronized-同步代码块
4. NSRecursiveLock-递归锁
5. NSConditionLock-条件锁
6. NSDistributedLock-分布锁(MAC开发下用到的，一般少用)
7. GCD中信号量-可实现多线程同步(并不属于线程锁)



### 1.NSLock：创建NSLock对象，然后调用实例方法lock()和unlock()方法实现加锁和解锁，NSLock也提供了try()方法，来判断是否加锁成功。接下来通过案例来说明
        //初始化苹果数量为20个
        private var appleTotalNum = 20

        NSLog("开始了")
        let thread1 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        let thread2 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        let thread3 = Thread.init(target: self, selector: #selector(eatApple), object: nil)
        thread1.start()
        thread2.start()
        thread3.start()
        NSLog("结束了")
        
        打印结果: 开始了
                结束了
                11111--<NSThread: 0x600002a63080>{number = 6, name = (null)}--剩余的苹果数:17
                11111--<NSThread: 0x600002a62a40>{number = 8, name = (null)}--剩余的苹果数:17
                11111--<NSThread: 0x600002a62a00>{number = 7, name = (null)}--剩余的苹果数:17
#### 分析:有3个线程任务同时去访问appleTotalNum变量，通过打印信息发现不符合我们的业务逻辑(每次只能吃掉一个苹果，正常的打印信息应该是剩余的苹果数19->18->17),接下来我们通过加锁来控制同一时间只有一个线程任务被执行
        //声明一个锁对象
        private var lockObjc = NSLock()

        @objc func eatApple() {
            lockObjc.lock()            
            appleTotalNum -= 1
            NSLog("11111--\(Thread.current)--剩余的苹果数:\(appleTotalNum)")
            lockObjc.unlock()
        }

        打印结果:开始了
                结束了
                11111--<NSThread: 0x60000359e380>{number = 7, name = (null)}--剩余的苹果数:19
                11111--<NSThread: 0x60000359e080>{number = 8, name = (null)}--剩余的苹果数:18
                11111--<NSThread: 0x60000359e2c0>{number = 9, name = (null)}--剩余的苹果数:17
#### 分析：打印的结果和我们的预期一样。当一个线程开始进来执行任务的时候，调用NSLock的lock方法锁住这个资源(任务)，其他线程不能访问，直到这个线程的任务完成，然后调用unlock方法来解锁，告诉其他线程可以继续去访问了，从而达到同一时间只能有一个线程来执行该任务，避免了多线程间的资源抢夺
### 需要注意的就是lock加锁和unlock解锁是成对出现的。如果没有加锁(lock),直接解锁(unlock),程序执行和没有加锁解锁效果是一样的；如果多次加锁(获取锁)，会导致死锁
        //只解锁而没有加锁
        @objc func eatApple() {
            appleTotalNum -= 1
            NSLog("11111--\(Thread.current)--剩余的苹果数:\(appleTotalNum)")
            lockObjc.unlock()
        }
        打印结果: 开始了
                结束了
                11111--<NSThread: 0x6000011a9900>{number = 6, name = (null)}--剩余的苹果数:17
                11111--<NSThread: 0x6000011a9b00>{number = 7, name = (null)}--剩余的苹果数:18
                11111--<NSThread: 0x6000011a9bc0>{number = 5, name = (null)}--剩余的苹果数:17
                
        //多次加锁，不管解锁次数是不是和加锁次数一样，都会造成死锁
        @objc func eatApple() {
            NSLog("进来了")
            lockObjc.lock()
            lockObjc.lock()
            appleTotalNum -= 1
            NSLog("11111--\(Thread.current)--剩余的苹果数:\(appleTotalNum)")
            lockObjc.unlock()
            lockObjc.unlock()
        }
        打印结果: 开始了
                结束了
                进来了
                进来了
                进来了
#### 当NSLock类收到一个解锁的消息，必须确保发送源也是来自那个发送上锁的线程，即lock和unlock必须同时出现在被同一个线程访问的任务中，否则会毁掉线程安全，出现非预期的效果

### 2.NSCondition(状态锁)
#### 状态锁只要由两部分组成：锁：保证在多个线程中资源的同步访问  线程检查器：检查线程是否需要处在阻塞/唤醒状态

![](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock2.png)

        打印结果：开始判断是否有苹果
                1当前没有苹果,阻塞当前线程
                2开始采摘苹果
                2开始唤醒被wait阻塞的线程
                2开始解锁当前的线程
                1wait已经被唤醒了
                1已经有苹果可以吃了
                1开始解锁当前的线程
### 3. 同步代码块 synchronized(OC)   objc_sync_enter/objc_sync_exit(swfit)  
#### swift例子,定义一个属性pageNum，初始值为10
        let thread1 = Thread(target: self, selector: #selector(method1), object: nil)
        thread1.start()
        let thread2 = Thread(target: self, selector: #selector(method1), object: nil)
        thread2.start()
        @objc func method1() {
            //objc_sync_enter(self)
            pageNum -= 1
            NSLog("当前的pageNum为:\(pageNum)")
            //objc_sync_exit(self)
        }

        打印结果: 当前的pageNum为:8
                当前的pageNum为:8
                
        如果将objc_sync_enter objc_sync_exit添加上去
        打印结果: 当前的pageNum为:9  
                当前的pageNum为:8
#### OC例子
        _pageNum = 10;
        NSThread *thread1 = [[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
        [thread1 start];
        NSThread *thread2 = [[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
        [thread2 start];
        NSThread *thread3 = [[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
        [thread3 start];
        -(void)method1 {
            @synchronized (self) {
                _pageNum -= 1;
                NSLog(@"当前的pageNum为:%d",_pageNum);
            }
        }
        打印结果: 当前的pageNum为:9
                 当前的pageNum为:8
                 当前的pageNum为:7
#### 实际上 @synchronized (objc)同步锁会被编辑器转化为在swift中使用的objc_sync_enter(objc)和objc_sync_exit(objc)两个方法，这两个方法在Runtime的源码可以查看到
![](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock3.png)
#### 总结：@synchronized(objc)工作时，Runtime会为objc分配一个递归锁，并保存在哈希表中，通过Objc内存地址的哈希值在哈希表中查找到SyncData，并将其加锁；如果在synchronized内部objc被释放或者值为nil，会调用objc_sync_nil()方法；如果@synchronized(nil)传进入了nil，那么synchronized内部的代码就不是线程安全的;如果objc_sync_enter(objc1)和objc_sync_exit(objc2)两个参数不一致时，objc1对象被锁定但并未被解锁，会导致其他线程无法访问，这种情况下如果再开辟线程去访问会发生crash
![](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock4.png)


### 4. NSRecursiveLock(递归锁)
#### 递归锁与普通锁(NSLock)区别：递归锁允许同一个线程多次加锁而不会造成死锁，普通锁多次lock的时候，会造成死锁
        private var lock = NSRecursiveLock()
        @objc func eatApple() {
            lock.lock()
            lock.lock()
            appleTotalNum -= 1
            NSLog("剩余苹果数:\(appleTotalNum)")
            lock.unlock()
            lock.unlock()
        }
        
        打印结果: 开始了
                结束了
                11111--<NSThread: 0x600000091440>{number = 6, name = (null)}--剩余的苹果数:19
                11111--<NSThread: 0x600000091880>{number = 7, name = (null)}--剩余的苹果数:18
                11111--<NSThread: 0x6000000915c0>{number = 8, name = (null)}--剩余的苹果数:17
#### 需要注意的是lock和unlock要成对出现，否则会出现不确定的结果
        @objc func eatApple() {
            lock.lock()
            lock.lock()
            lock.lock()
            appleTotalNum -= 1
            NSLog("11111--\(Thread.current)--剩余的苹果数:\(appleTotalNum)")
            lock.unlock()
            lock.unlock()
        }

        打印结果: 开始了
                结束了
                11111--<NSThread: 0x60000106bec0>{number = 7, name = (null)}--剩余的苹果数:19

### 5.条件锁 NSConditionLock
#### 首先需要通过设置条件初始化NSConditionLock对象，具体事例如下
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock1.png)
#### 可以发现当condition条件一致的时候，lock(whenCondition:)和unlock(withCondition:)这两个方法会相互通知


### 6. NSDistributedLock(分布锁):是MAC开发中的跨进程的分布式锁，底层是用文件系统实现的互斥锁。


### 7. GCD中的信号量
#### GCD中的信号量可用于实现多线程同步,信号量实现多线程同步和锁的区别：信号量不一定是锁定某一个资源，而是流程上的概念；线程锁是锁住的资源无法被其它线程访问，从而阻塞线程而实现线程同步。需要注意的就是信号量的初始值不能小于0，否则会发生crash
####
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock5.png)

### 8.总结
* NSLock-普通锁：据说性能低，所以好多人不推荐使用
* NSCondition-状态锁：使用其做多线程之间的通信调用不是线程安全的
* synchronized-同步代码块：适用线程不多，任务量不大的多线程加锁
* NSRecursiveLock-递归锁：性能出奇的高，但是只能作为递归使用,所以限制了使用场景
* NSConditionLock-条件锁：单纯加锁性能非常低，比NSLock低很多，但是可以用来做多线程处理不同任务的通信调用
* NSDistributedLock-分布锁(MAC开发下用到的，一般少用)
* GCD中信号量-可实现多线程同步(并不属于线程锁)：使用信号来做“加锁”实现多线程同步，性能提升显著

