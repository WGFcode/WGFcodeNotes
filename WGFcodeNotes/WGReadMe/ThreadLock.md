
## MJ多线程总结
### 面试题
1. 你理解的多线程?
2. iOS的多线程方案有哪几种?你更倾向于哪一种?
3. 你在项目中用到过GCD吗? GCD的队列类型
4. 说一下OperationQueue和GCD的区别, 以及各自的优势
5. 线程安全的处理手段有哪些?
6. OC你了解的锁有哪些? 在你回答的基础上进行二次提问
* 自旋和互斥的对比
* 使用以上锁需要注意哪些?
* 用C/OC/C++,任选其一,实现自旋和互斥? 口述即可

### 1. iOS中常见的多线程方案

    技术方案                     简介                  语言     线程生命周期  使用频率
    pthread   一套通用的多线程API,适用于Unix/Linux        C       程序员管理   几乎不用
              /Windows等系统跨平台/可移植、适用难度大
                
    NSThread  使用更加面向对象                           OC      程序员管理   偶尔使用
              简单易用、可直接操作线程对象
    
    GCD       旨在替换NSThread等线程技术                  C       自动管理    经常使用
              充分利用设备的多核        
    
    NSOperation   基于GCD(底层是GCD),更加面向对象         OC       自动管理    经常使用
                  比GCD多了一些更简单实用的功能    

#### NSThread、GCD、NSOperation底层都是pthread,项目中使用更多的是GCD

### 2. GCD的常用函数
1. 用同步(sync)的方式执行任务

        queue: 队列 block: 任务
        dispatch_sync(dispatch_queue_t queue, dispatch_block_t block)
        
2. 用异步(async)的方式执行任务

        dispatch_async(dispatch_queue_t queue, dispatch_block_t block)
3. GCD源码: https://github.com/apple/swift-corelibs-libdispatch

#### 2.1 GCD的队列
1. 并发队列(Concurrent Dispatch Queue)

        可以让多个任务并发(同时)执行(自动开启多个线程同时执行任务)
        并发功能只有在异步(dispatch_async)函数下才有效
2. 串行队列(Serial Dispatch Queue)

        让任务一个接着一个地执行(一个任务执行完毕后,再执行下一个任务)

#### 2.2 GCD中容易混淆的概念
1. 同步和异步主要影响: 能不能开启新的线程

        同步: 在当前线程中执行任务,不具备开启线程的能力
        异步: 在新的线程中执行任务,具备开启新线程的能力(但不一定会开新线程,如主队列异步任务还是在主线程中执行)
2. 并发和串行主要影响: 任务的执行方式

        并发: 多个任务并发(同时)执行
        串行: 一个任务执行完毕后,再执行下一个任务

#### 2.3 队列和任务的组合执行效果
                          并发队列         手动创建的串行队列(非主队列)          主队列
      同步(sync)     没有开线程/串行执行任务    没有开线程/串行执行任务     没有开线程/串行执行任务(产生死锁)
      异步(async)    开启新线程/并发执行任务    开启新线程/串行执行任务     没有开线程/串行执行任务
      
#### 主队列也是特殊的串行队列, 实际开发中我们用的最多的组合就是异步并发队列的组合, 只要是同步(sync)任务都是没有开线程并且是串行执行的, 只要在主队列里面无论是同步还是异步都是没有开线程并且是串行执行的

### 3. 死锁
#### 死锁: 线程卡住了,不能继续往下执行了, 那么什么情况下会产生死锁?
#### 案例1 
    - (void)viewDidLoad {
        [super viewDidLoad];
        NSLog(@"执行任务1");
        //队列特点是: 排队、先进先出
        dispatch_queue_t queue = dispatch_get_main_queue();
        //dispatch_sync: 立马在当前线程执行任务,执行完毕后才能继续往下走
        dispatch_sync(queue, ^{
            NSLog(@"执行任务2");
        });
        NSLog(@"执行任务3");
    }
    
    打印结果:  执行任务1
             程序crash,产生死锁
             
    主线程          主队列
    任务1           ViewDidLoad
    sync           任务2
    任务3
#### 会产生死锁, 执行完任务1后,遇到同步任务sync需要立马执行,所以就去主队列中取出任务2来执行,但是在主队列中任务2前面的任务还没有完成,需要等待,等待ViewDidLoad执行完成后才能执行任务2,而执行完任务3后ViewDidLoad才能算执行完,而任务3又在等待任务2的执行完成,导致任务2和任务3相互等待,产生死锁

#### 案例2
    - (void)viewDidLoad {
        [super viewDidLoad];
        NSLog(@"执行任务1");
        //串行队列(非主队列)
        dispatch_queue_t queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
        //dispatch_sync: 立马在当前线程执行任务,执行完毕后才能继续往下走
        dispatch_sync(queue, ^{
            NSLog(@"执行任务2");
        });
        NSLog(@"执行任务3");
    }

    打印结果: 执行任务1
            执行任务2
            执行任务3
                    
    主线程    主队列           串行队列
    任务1    viewDidLoad       任务2
    sync          
    任务3
#### 不会产生死锁, 因为viewDidLoad是在默认的主队列中完成的,而任务2是在串行队列中,两个不在同一个队列中,所以不存在相互等待的问题
#### ⚠️ 主队列同步任务会产生死锁,但是串行队列(非主队列)同步任务不会产生死锁


#### 案例3
    - (void)viewDidLoad {
        [super viewDidLoad];

        NSLog(@"执行任务1");
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_async(queue, ^{
            NSLog(@"执行任务2");
        });
        NSLog(@"执行任务3");
        NSLog(@"执行任务4");
        NSLog(@"执行任务5");
        NSLog(@"执行任务6");
    }
    打印结果: 执行任务1
            执行任务3
            执行任务4
            执行任务5
            执行任务6
            执行任务2
            
    主线程    主队列           
    任务1    viewDidLoad       
    async     任务2      
    任务3    
    任务4
    任务5
    任务6
#### 不会产生死锁, 因为dispatch_sync同步任务要求立马在当前线程同步执行, 而dispatch_async异步任务不要求立马在当前线程同步执行任务, 该案例中虽然是异步任务但是是在主线程中,所以不会开启新的线程,仍然在主线程中执行;dispatch_async异步任务可以等待上一个任务的完成后再执行,即等待ViewDidLoad执行完成后再执行,说白了就是等任务3/4/5/6执行完成了再执行任务2


#### 案例4
    - (void)viewDidLoad {
        [super viewDidLoad];

        NSLog(@"执行任务1");
        //串行队列
        dispatch_queue_t queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{  //block1
            NSLog(@"执行任务2");
            dispatch_sync(queue, ^{ //block2
                NSLog(@"执行任务3");
            });
            NSLog(@"执行任务4");
        });
        NSLog(@"执行任务5");
    }
    
    打印结果: 执行任务1
            执行任务5
            执行任务2
            程序crash,产生死锁
            
    子线程     串行队列
    任务2      block1(任务4完成了block1才算执行完成)
    sync      block2(任务3)
    任务4          
#### 产生死锁,首先我们分析最外层的dispatch_async异步任务,不会阻塞当前线程,说白了就是不要求立马执行,所以可以等待,即执行任务1然后执行了任务5,接着执行任务2,这个很好理解; block1和block2都添加到了串行队列,按照先进先出的原则,block1在最上面,block2在下面, 执行dispatch_sync同步任务时,需要在当前线程中立马执行, 所以需要从串行队列中取出block2去执行任务3,然而block1在串行队列最上面,所以想执行block2中的任务,需要先将block1中的任务执行完成, 而block1任务的完成是根据任务4是否完成来决定的,而任务4完成需要根据任务3的完成后才能执行, 所以就存在了任务3和任务4相互等待,导致死锁

#### 案例5
    - (void)viewDidLoad {
        [super viewDidLoad];

        NSLog(@"执行任务1");
        //串行队列
        dispatch_queue_t queue=dispatch_queue_create("myqueue",DISPATCH_QUEUE_SERIAL);
        //并发队列
        dispatch_queue_t queue2=dispatch_queue_create("myqueue2",DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{  //block1
            NSLog(@"执行任务2");
            dispatch_sync(queue2, ^{ //block2
                NSLog(@"执行任务3");
            });
            NSLog(@"执行任务4");
        });
        NSLog(@"执行任务5");
    }

    打印结果: 执行任务1
            执行任务5
            执行任务2
            执行任务3
            执行任务4
            
    子线程    串行队列   并发队列
             block1    block2
#### 不会产生死锁,  因为block1和block2在不同的队列中, 不会产生相互等待的情况,任务2执行完成后,遇到dispatch_sync同步任务要求立马执行,那么就从并发队列中取出block2执行即可,而block1是在串行队列中,所以不存在相互等待

#### 案例6
    - (void)viewDidLoad {
        [super viewDidLoad];

        NSLog(@"执行任务1");
        //串行队列
        dispatch_queue_t queue=dispatch_queue_create("myqueue",DISPATCH_QUEUE_SERIAL);
        //串行队列
        dispatch_queue_t queue2=dispatch_queue_create("myqueue2",DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{  //block1
            NSLog(@"执行任务2");
            dispatch_sync(queue2, ^{ //block2
                NSLog(@"执行任务3");
            });
            NSLog(@"执行任务4");
        });
        NSLog(@"执行任务5");
    }
    打印结果: 执行任务1
            执行任务5
            执行任务2
            执行任务3
            执行任务4
    
    子线程    串行队列   串行队列
             block1    block2
#### 不会产生死锁,道理是一样的,block1和block2在不同的队列中,所以不会存在相互等待的情况

#### 案例7
    - (void)viewDidLoad {
        [super viewDidLoad];

        NSLog(@"执行任务1");
        //并发队列
        dispatch_queue_t queue=dispatch_queue_create("myqueue",DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{  //block1
            NSLog(@"执行任务2");
            dispatch_sync(queue, ^{ //block2
                NSLog(@"执行任务3");
            });
            NSLog(@"执行任务4");
        });
        NSLog(@"执行任务5");
    }

    打印结果: 执行任务1
            执行任务5
            执行任务2
            执行任务3
            执行任务4
            
    子线程    并发队列 
             block1    
             block2

#### 不会产生死锁, 虽然block1和block2都在同一个队列中,遇到dispatch_sync同步任务需要立刻执行,但是是在并发队列中,可以同时执行多个任务, 不需要等待上一个任务的完成,所以不存在相互等待


#### 总结: 产生死锁情况: 使用sync函数往当前串行队列中添加任务(案例1中主队列中添加任务会发生死锁,但是手动创建的串行队列不会发生死锁,这个要特别注意),会卡住当前的串行队列,产生死锁


#### 3.1 疑问🤔️: 全局队列和创建的队列有什么区别
    - (void)viewDidLoad {
        [super viewDidLoad];
        //全局队列
        dispatch_queue_t queue1 = dispatch_get_global_queue(0, 0);
        dispatch_queue_t queue2 = dispatch_get_global_queue(0, 0);
        //手动创建并发队列
        dispatch_queue_t queue3=dispatch_queue_create("queue3",DISPATCH_QUEUE_CONCURRENT);
        dispatch_queue_t queue4=dispatch_queue_create("queue4",DISPATCH_QUEUE_CONCURRENT);
        // 名称一样的并发队列
        dispatch_queue_t queue5=dispatch_queue_create("queue4",DISPATCH_QUEUE_CONCURRENT);
        NSLog(@"%p %p %p %p %p", queue1, queue2, queue3, queue4,queue5);
    }

    打印结果:  0x104fc4f00 0x104fc4f00 0x600000fcee00 0x600000fcee80 0x600000fcef00
#### 全局队列是全局的,只有这一个队列,所以queue1和queue2的地址是相同的; 而手动创建的并发队列地址是不一样的,即便拥有相同的线程名也是不一样的, 但项目中不建议使用相同的线程名,因为线程名也是会用到的,为了便于区分所以不建议使用相同的线程名
#### 在GCD中栅栏函数不能作用在全局队列中，只能作用在手动创建的并发队列中，栅栏函数会阻断任务执行，因为全局队列系统也在使用，添加栅栏函数容易引起系统级的线程阻拦

### 4. GNUstep: Foundation框架下原理源码参考
* 是GUN计划的项目之一,它将Cocoa的OC库重新开源实现了一遍
* 源码地址: http://gnustep.org/resources/downloads.php
* 虽然GNUstep不是苹果官方源码,但还是具有一定的参考价值的
* 我们可以通过这个源码来窥探OC中的底层实现原理

### 5. 面试题
#### 案例1
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"执行任务1");
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_async(queue, ^{
            //本质是向RunLoop中添加定时器
            [self performSelector:@selector(test) withObject:nil afterDelay:.0];
        });
        NSLog(@"执行任务3");
    }
    -(void)test{
        NSLog(@"执行任务2");
    }
    
    打印结果: 执行任务1
            执行任务3
#### 任务2不会被执行,因为dispatch_async异步任务会开启新的线程(子线程), 但是performSelector:withObject:afterDelay:方法底层是依靠Runloop来执行的, 而子线程中默认没有启动RunLoop,所以performSelector方法不会被执行,也就是任务2不会被执, 通过RunTime源码我们可以知道performSelector:withObject是通过objc_msgSend来发送消息的,而performSelector:withObject:afterDelay:方法是在RunLoop下定义的,它的底层用到的是定时器NSTimer,本质就是向RunLoop中添加定时器

#### 解决方法
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"执行任务1");
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_async(queue, ^{
            [self performSelector:@selector(test) withObject:nil afterDelay:.0];
            //这句代码可以去掉的,因为performSelector本质是个定时器,所以可以唤醒Runloop(observer/Timer/source)
            //不需要再添加额外的端口来唤醒RunLoop了
            //[[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //启动RunLoop
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        });
        NSLog(@"执行任务3");
    }
    -(void)test{
        NSLog(@"执行任务2");
    }

    打印结果: 执行任务1
            执行任务3
            执行任务2

#### 案例2 
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSThread *thread = [[NSThread alloc]initWithBlock:^{
            NSLog(@"执行任务1");
        }];
        [thread start];
        [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:YES];
    }
    -(void)test{
        NSLog(@"执行任务2");
    }

    打印结果: 执行任务1
#### 任务2不会执行,因为执行完[thread start]后,线程已经销毁了,所以程序会crash

#### 解决方案
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSThread *thread = [[NSThread alloc]initWithBlock:^{
            NSLog(@"执行任务1");
            //向子线程中的RunLoop添加NSPort端口来保证Runloop一直存在,并且启动Runloop
            [[NSRunLoop  currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }];
        [thread start];
        [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:YES];
    }
    -(void)test{
        NSLog(@"执行任务2");
    }
    打印结果: 执行任务1
            执行任务2
        
#### 向子线程中的RunLoop添加NSPort端口来保证Runloop一直存在,并且启动Runloop,这样执行完 [thread start]后,线程也不会销毁,就能保证任务2的执行

#### 案例3
#### 如果用GCD实现如下功能
* 异步并发执行任务1、任务2
* 等任务1、任务2都执行完毕后,再回到主线程执行任务3

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            dispatch_group_t group = dispatch_group_create();
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_group_async(group, queue, ^{
                for (int i = 0; i < 5; i++) {
                    NSLog(@"执行任务1-%@",[NSThread currentThread]);
                }
            });
            dispatch_group_async(group, queue, ^{
                for (int i = 0; i < 5; i++) {
                    NSLog(@"执行任务2-%@",[NSThread currentThread]);
                }
            });
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                for (int i = 0; i < 5; i++) {
                    NSLog(@"执行任务3-%@",[NSThread currentThread]);
                }
            });
        }
        
        打印结果: 执行任务2-<NSThread: 0x600001a03940>{number = 6, name = (null)}
                执行任务1-<NSThread: 0x600001ad6fc0>{number = 4, name = (null)}
                执行任务2-<NSThread: 0x600001a03940>{number = 6, name = (null)}
                执行任务1-<NSThread: 0x600001ad6fc0>{number = 4, name = (null)}
                执行任务2-<NSThread: 0x600001a03940>{number = 6, name = (null)}
                执行任务1-<NSThread: 0x600001ad6fc0>{number = 4, name = (null)}
                执行任务2-<NSThread: 0x600001a03940>{number = 6, name = (null)}
                执行任务1-<NSThread: 0x600001ad6fc0>{number = 4, name = (null)}
                执行任务2-<NSThread: 0x600001a03940>{number = 6, name = (null)}
                执行任务1-<NSThread: 0x600001ad6fc0>{number = 4, name = (null)}
                执行任务3-<NSThread: 0x600001a8b900>{number = 1, name = main}
                执行任务3-<NSThread: 0x600001a8b900>{number = 1, name = main}
                执行任务3-<NSThread: 0x600001a8b900>{number = 1, name = main}
                执行任务3-<NSThread: 0x600001a8b900>{number = 1, name = main}
                执行任务3-<NSThread: 0x600001a8b900>{number = 1, name = main}
#### 任务1和任务2交替执行(异步执行), 执行完成后,再执行任务3

### 6. 多线程安全隐患解决方案
#### 6.1 1块资源可能会被多个线程共享,也就是多个线程可能会访问同一块资源;多个线程访问同一个对象、同一个变量、同一个文件;就会导致数据错乱,比如存钱取钱、火车票售卖等
#### 解决方案: 使用**线程同步技术**(同步就是协同步调,按预定的先后次序进行), 常见的线程同步技术就是**加锁**

#### 6.2 iOS中的线程同步方案
1. OSSpinLock
2. os_unfair_lock
3. pthread_mutex
4. dispatch_semaphore
5. dispatch_queue(DISPATCH_QUEUE_SERIAL)
6. NSLock
7. NSRecursiveLock
8. NSCondition
9. NSConditionLock
10. @synchronized 

#### 6.2.1 OSSpinLock
#### OSSpinLock叫做“自旋锁”,等待锁的线程会处于忙等(busy-wait)状态,一直占用CPU资源
* 目前已经不再安全,可能会出现优先级反转问题
* 如果等待锁的线程优先级较高, 它会一直占用着CPU资源,优先级较低的线程无法释放锁
* 需要导入头文件 #import <libkern/OSAtomic.h>
* iOS10+后因为OSSpinLock不安全就被苹果舍弃了,所以项目中不再建议使用
* 自旋锁就是当遇到已经有加锁时, 就会一直等待,并且是忙时等待,类似while循环,一直询问是否解锁了,比较耗费CPU资源

        #import <libkern/OSAtomic.h>
        
        @interface WGMainObjcVC()
        @property(nonatomic, assign) int ticketCount;
        @property(nonatomic, assign) OSSpinLock lock;
        @end
        
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            _ticketCount = 15;
            //1. 初始化锁
            _lock = OS_SPINLOCK_INIT;
            [self testTicket];
        }

        -(void)testTicket {
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
        }
        -(void)saleTicket{
            //2. 加锁
            OSSpinLockLock(&_lock);
            _ticketCount -= 1;
            NSLog(@"还剩%d张票",_ticketCount);
            //3. 解锁
            OSSpinLockUnlock(&_lock);
        }
#### 6.2.2 os_unfair_lock
#### os_unfair_lock用于取代不安全的OSSpinLock,从iOS10开始才支持, 从底层调用情况(汇编)看,等待os_unfair_lock锁的线程会处于休眠状态,并非忙等,即当遇到已经有加锁时, 就会处于休眠状态,而不是一直忙等去占用CPU资源
        需要导入头文件
        #import <os/lock.h>
        
        //1. 初始化锁
        _lock = OS_UNFAIR_LOCK_INIT;

        -(void)saleTicket{
            //2. 加锁
            os_unfair_lock_lock(&_lock);
            _ticketCount -= 1;
            NSLog(@"还剩%d张票",_ticketCount);
            //3. 解锁
            os_unfair_lock_unlock(&_lock);
        }
#### 如果忘记解锁(忘记调用os_unfair_lock_unlock),那么就会产生死锁,死锁就是永远也拿不到锁

#### 6.2.3 pthread_mutex
#### 1.mutex叫做“互斥锁”,等待锁的线程会处于休眠状态
        #import <pthread.h>

        @interface WGMainObjcVC()
        @property(nonatomic, assign) int ticketCount;
        @property(nonatomic, assign) pthread_mutex_t mutex;
        @end


        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            _ticketCount = 15;
            
            //1. 静态初始化
            //pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
            //初始化属性
            pthread_mutexattr_t attr;
            pthread_mutexattr_init(&attr);
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);
            //2.初始化锁
            pthread_mutex_init(&_mutex, &attr);
            /*
             #define PTHREAD_MUTEX_NORMAL        0          普通锁
             #define PTHREAD_MUTEX_ERRORCHECK    1          检测错误锁(一般用不上)
             #define PTHREAD_MUTEX_RECURSIVE     2       递归锁
             #define PTHREAD_MUTEX_DEFAULT        PTHREAD_MUTEX_NORMAL  普通锁
             */
            //3.销毁属性
            pthread_mutexattr_destroy(&attr);
            
            [self testTicket];
        }

        -(void)testTicket {
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
        }
        -(void)saleTicket{
            //2. 加锁
            pthread_mutex_lock(&_mutex);
            _ticketCount -= 1;
            NSLog(@"还剩%d张票",_ticketCount);
            //3. 解锁
            pthread_mutex_unlock(&_mutex);
        }

        -(void)dealloc {
            //4. 销毁锁
            pthread_mutex_destroy(&_mutex);
        }
        
#### 2.pthread_mutex中的递归锁
#### pthread_mutex_init(&_mutex, NULL),如果属性设置为NULL,则是默认的普通锁,如果属性中设置了PTHREAD_MUTEX_RECURSIVE,则为递归锁, 
        pthread_mutex_t的属性设置为PTHREAD_MUTEX_RECURSIVE则为递归锁
        -(void)test{  //1
            pthread_mutex_lock(&_mutex);
            NSLog(@"%s",__func__);
            [self test];  //2
            pthread_mutex_unlock(&_mutex);
        }
#### 递归锁: 允许同一个线程对一把锁重复加锁, 如上代码中,如果线程1调用test,则加锁,此时继续执行,当执行到test2的位置时, 又开始调用test方法,此时线程1仍然可以对已经加锁的锁在此进行加锁; 如果线程1已经加锁了,线程2也来了,那么线程2是无法加锁的,需要等待线程1解锁后才能执行

#### 3.pthread_mutex中的条件
    #import <pthread.h>

    @interface WGMainObjcVC()
    @property(nonatomic, assign) pthread_mutex_t mutex;
    @property(nonatomic, strong) NSMutableArray *data;
    @property(nonatomic, assign) pthread_cond_t cond;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        _ticketCount = 15;
        _data = [NSMutableArray array];
        //1. 静态初始化
        //pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
        //初始化属性
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);
        //2.初始化锁
        pthread_mutex_init(&_mutex, &attr);
        //3.销毁属性
        pthread_mutexattr_destroy(&attr);
        // 初始化条件
        pthread_cond_init(&_cond, NULL);
    }

    -(void)dealloc {
        //4.销毁锁
        pthread_mutex_destroy(&_mutex);
        //5.销毁条件
        pthread_cond_destroy(&_cond);
    }

    -(void)test {
        //在不同的子线程中执行增、删操作
        [[[NSThread alloc] initWithTarget:self selector:@selector(add) object:nil] start];
        [[[NSThread alloc] initWithTarget:self selector:@selector(remove) object:nil] start];
    }

    -(void)add{
        pthread_mutex_lock(&_mutex);
        [_data addObject:@"123"];
        NSLog(@"添加了元素");
        //唤醒刚刚因为pthread_cond_wait而睡眠的线程
        pthread_cond_signal(&_cond);
        pthread_mutex_unlock(&_mutex);
    }
    -(void)remove{
        pthread_mutex_lock(&_mutex);
        if (_data.count == 0) {
            //等待,一旦睡觉_mutex就会解锁, 锁就会放开; 一旦被再次唤醒,那么就会继续对_mutex进行加锁
            pthread_cond_wait(&_cond, &_mutex);
            //pthread_cond_broadcast(&_cond)  激活所有等待该条件的线程
        }
        [_data removeLastObject];
        NSLog(@"删除了元素");
        pthread_mutex_unlock(&_mutex);
    }
#### 通过pthread_cond条件就可以保证不同线程中执行数组增删操作,就能保证在没有元素情况下,一定会先调用添加元素的操作


#### 6.2.4 NSLock
#### NSLock是对mutex普通锁的封装
    @interface NSLock : NSObject <NSLocking> {
        - (BOOL)tryLock;
        //到这个时间如果还等不到锁,就加锁失败会睡觉,如果等到锁了,那么就加锁成功
        - (BOOL)lockBeforeDate:(NSDate *)limit; 
    }
    @protocol NSLocking
    - (void)lock;
    - (void)unlock;
    @end
    
    @property(nonatomic, strong) NSLock *lock;
    //1. 初始化
    _lock = [[NSLock alloc]init];

    -(void)saleTicket{
        //2. 加锁
        [_lock lock];
        _ticketCount -= 1;
        NSLog(@"还剩%d张票",_ticketCount);
        //3. 解锁
        [_lock unlock];
    }
#### 6.2.5 NSRecursiveLock
#### NSRecursiveLock递归锁是对mutex递归锁的封装,API和NSLock基本一致
        @interface NSRecursiveLock : NSObject <NSLocking> {
        - (BOOL)tryLock;
        - (BOOL)lockBeforeDate:(NSDate *)limit;
        }
#### 6.2.6 NSCondition
#### NSCondition是对mutex和cond的封装, 更加面向对象
        @interface NSCondition : NSObject <NSLocking> {
        - (void)wait;
        - (BOOL)waitUntilDate:(NSDate *)limit;
        - (void)signal;
        - (void)broadcast;
        }
        
        _lock = [[NSConditionLock alloc]init];
        
        -(void)add{
            [_lock lock];
            [_data addObject:@"123"];
            NSLog(@"添加了元素");
            //唤醒刚刚因为wait而睡眠的线程
            [_lock signal];
            [_lock unlock];
        }
        -(void)remove{
            [_lock lock];
            if (_data.count == 0) {
                [_lock wait];
            }
            [_data removeLastObject];
            NSLog(@"删除了元素");
            [_lock unlock];
        }
#### 6.2.7 NSConditionLock
#### NSConditionLock是对NSCondition的进一步封装,可以设置具体的条件值
    @interface NSConditionLock : NSObject <NSLocking> {
        - (instancetype)initWithCondition:(NSInteger)condition NS_DESIGNATED_INITIALIZER;
        
        @property (readonly) NSInteger condition;
        - (void)lockWhenCondition:(NSInteger)condition;
        - (BOOL)tryLock;
        - (BOOL)tryLockWhenCondition:(NSInteger)condition;
        - (void)unlockWithCondition:(NSInteger)condition;
        - (BOOL)lockBeforeDate:(NSDate *)limit;
        - (BOOL)lockWhenCondition:(NSInteger)condition beforeDate:(NSDate *)limit;
    }
        
#### 6.2.8 dispatch_queue
#### 直接使用GCD的串行队列也可以实现线程同步的
        @interface WGMainObjcVC()
        @property(nonatomic, assign) int ticketCount;
        @property(nonatomic, strong) dispatch_queue_t serialQueue; //串行队列
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            _ticketCount = 15;
            _serialQueue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
            [self testTicket];
        }

        -(void)testTicket {
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
            dispatch_async(queue, ^{
                for (int i = 0; i < 5; i++) {
                    [self saleTicket];
                }
            });
        }
        -(void)saleTicket{
            dispatch_sync(_serialQueue, ^{
                _ticketCount -= 1;
                NSLog(@"还剩%d张票",_ticketCount);
            });
        }
#### saleTicket方法本身就是在子线程中执行的,那么这里使用dispatch_sync同步并且放在串行队列中就可以保证该条线程下任务完成后才能执行下一个任务,就能保证线程同步了

#### 6.2.9 dispatch_semaphore_t信号量
* 信号量的初始值,可以用来控制线程并发访问的最大数量
* 信号量的初始化为1时,代表同时只允许1条线程访问资源,保证线程同步
* dispatch_semaphore_create(value); value值代表并发执行的最大线程数量,即同时可以多少条线程执行任务
* dispatch_semaphore_wait(dispatch_semaphore_t, dispatch_time_t); 

        当信号量value值 > 0时,将value值减1,继续往下执行
        当信号量value值 <= 0时,就休眠等待,知道信号量的值变成 > 0, 然后将value值减1,继续往下执行代码
* dispatch_semaphore_signal(dispatch_semaphore_t); 使信号量value值加1
* 通过将信号量初始值设置为1, 可以达到线程同步,即每次只有一个线程在执行任务
#### 案例1:创建了20个子线程,想让每次执行task的线程只有5个线程在执行,即控制最大线程执行数是5
        
    @interface WGMainObjcVC()
    @property(nonatomic, strong) dispatch_semaphore_t semaphore;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //设置信号量的初始值为5,代表线程执行的最大并发数为5,即每次只能有5个线程在执行任务
        _semaphore = dispatch_semaphore_create(5);
        [self test];
    }

    -(void)test {
        for (int i = 0; i < 20; i++) {
            [[[NSThread alloc]initWithTarget:self selector:@selector(task) object:nil] start];
        }
    }

    -(void)task {
        //如果信号量的值 > 0,就让信号量的值减1,然后继续往下执行代码
        //如果信号量的值 <= 0,就会休眠等待,知道信号量的值变成 >0,然后就让信号量的值减1,然后继续往下执行代码
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        sleep(2);
        NSLog(@"task----%@",[NSThread currentThread]);
        //让信号量的值+1
        dispatch_semaphore_signal(_semaphore);
    }
#### 案例2: 使用信号量实现线程同步

    @interface WGMainObjcVC()
    @property(nonatomic, assign) int ticketCount;
    @property(nonatomic, strong) dispatch_semaphore_t semaphore;
    @end


    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        _ticketCount = 15;
        //1. 初始值设置为1, 代表每次只能有一个线程在执行任务
        _semaphore = dispatch_semaphore_create(1);
        [self testTicket];
    }

    -(void)testTicket {
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_async(queue, ^{
            for (int i = 0; i < 5; i++) {
                [self saleTicket];
            }
        });
        dispatch_async(queue, ^{
            for (int i = 0; i < 5; i++) {
                [self saleTicket];
            }
        });
        dispatch_async(queue, ^{
            for (int i = 0; i < 5; i++) {
                [self saleTicket];
            }
        });
    }
    -(void)saleTicket{
        //2. 初始化为1, 判断为信号量>0,然后将信号量的值减1变成0,继续往下执行任务
        //此时如果有第二个线程到来,发现信号量=0,就会处于等待状态,等待信号量的值 > 0
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        _ticketCount -= 1;
        NSLog(@"还剩%d张票",_ticketCount);
        //3. 将信号量的值+1
        dispatch_semaphore_signal(_semaphore);
    }

#### 6.2.10 @synchronized
#### @synchronized是对mutex递归锁的封装,所以@synchronized就是个递归锁,源码查看: objc4中的objc-sync.mm文件, 底层就是根据@synchronized(对象)传进来的对象找到对应的锁, 每个对象对应一个锁,底层是个Map结构,拿到对应对应的锁后进行加锁解锁操作
    -(void)saleTicket{
        @synchronized (self) {
            _ticketCount -= 1;
            NSLog(@"还剩%d张票",_ticketCount);
        }
    }

#### 这里传进的时self对象,根据业务需要,如果想保证所有对象(项目中可能会创建多个对象情况下)使用的是同一把锁,也可以传进去[self class]对象,因为所有对象的类对象只有一个,这样就能保证使用的是同一把锁,或者也可以这么操作
    -(void)saleTicket{
        //保证testObj对象只会被创建一次,每个对象都对应一把锁,只要对象是唯一的,那么使用的就是同一把锁
        static NSObject *testObj;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            testObj = [[NSObject alloc]init];
        });
        @synchronized (testObj) {
            _ticketCount -= 1;
            NSLog(@"还剩%d张票",_ticketCount);
        }
    }

#### 6.3 iOS线程同步方案性能比较
#### 性能从高到低: 
1. os_unfair_lock(iOS10+)
2. OSSpinLock(iOS10+以后已经被舍弃了,替换成os_unfair_lock了)
3. dispatch_semaphore(可以支持iOS8)  **推荐使用**
4. pthread_mutex(可以支持iOS8、扩平台) **推荐使用**
5. dispatch_queue(DISPATCH_QUEUE_SERIAL)
6. NSLock(对pthread_mutex的封装)
7. NSCondition
8. pthread_mutex(recursive):递归锁
9. NSRecursiveLock(对pthread_mutex(recursive)的封装)
10. NSConditionLock
11. @synchronized 


### 7. 自旋锁和互斥锁比较
#### OSSpinLock就是自旋锁,自旋锁的特点就是当发生多个线程资源抢夺时,会处于忙等的状态,即等待锁的线程会处于忙等(busy-wait)状态,一直占用CPU资源, 而互斥锁就是mutex,即等待锁的线程会处于休眠状态,不会一直占用CPU资源. iOS中其实自旋锁已经没法用了,OSSpinLock在iOS10+上已经不能用了,虽然用os_unfair_lock这个来替代,但是os_unfair_lock底层调用并没有看出来是自旋锁, 它仍然属于低级锁(遇到锁要等待时,直接进入休眠去等待),即互斥锁, 虽然我们现在不用了,但是面试过程中仍然会有自旋锁的问题,所以我们可以了解一下

#### 7.1 什么情况使用自旋锁
1. 预计线程等待锁的时间很短(锁内的代码或者任务花费很少的时间,就可以用自旋锁,因为时间短,所以就不需要用互斥锁先进入睡眠,再唤醒,这样也比较消耗性能)
2. 加锁的代码(临界区)经常被调用,但竞争情况不激烈(很少的线程来抢夺资源)
3. CPU资源不紧张
4. 多核处理器
#### 7.2 什么情况使用互斥锁
1. 预计线程等待锁的时间很长
2. 单核处理器
3. 临界区有IO(文件读写)操作
4. 临界区代码复杂或者循环最大
5. 临界区竞争非常激烈

### 8. automic关键词
1. automic关键词用于保证属性getter/setter方法的原子操作,相当于在getter/setter方法内部加了线程同步的锁
2. 可以参考RunTime源码中的objc-accessors.mm
3. 它并不能保证使用属性的过程是线程安全的

        /*
        nonatomic: 非原子属性
        atomic: 原子属性
        原子在物理学中就是不可再分割的,代码层面就是 int a = 10, int b = 20 int c = a+b,正常情况  
        三行代码会按照顺序逐条执行,如果有多个线程访问,那么同一时间可能线程1访问int a = 10, 线程2访问  
        int b = 20, 线程3访问int c = a+b,而如果是原子属性,那么就是不可分割的,线程会把这  
        三行代码看成是一个整体,即同一时间多个线程访问时,某一个线程只能访问的是这三行代码的整体
        */
        @property(atomic, strong) NSString *name;
        -(void)setName:(NSString *)name {
            //加锁
            self.name = name;
            //解锁
        }
        -(NSString *)name {
            //加锁
            return self.name;
            //解锁
        }
#### 既然atomic是原子属性,可以保证线程安全,为什么iOS项目中声明属性时,很少用atomic?
1. 首先atomic内部是自旋锁, 会很消耗性能和内存的
2. 实际业务中很少遇到多个线程访问同一个属性的,除非是多个线程访问多个对象的同一个属性,如果真是这种情况再考虑加锁解锁问题即可

#### 为什么atomic并不能保证使用属性的过程是线程安全的? 
    @interface WGMainObjcVC()
    @property(atomic, strong) NSMutableArray *data;
    @end
    
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];

        //1. 下面的代码相当于调用了属性data的setter方法,所以它是线程安全的
        //[self setData:[NSMutableArray array]];
        self.data = [NSMutableArray array];

        //2. 添加元素相当于先通过getter方法获取到data对象,这一步是线程安全的,但是再调用  
        addObject方法这一步就不是线程安全的了
        //[[self data] addObject:@"1"];
        [self.data addObject:@"1"];
        [self.data addObject:@"2"];
        [self.data addObject:@"3"];
    }

#### atomic属性只有在使用它的getter/setter方法时是线程安全的,但是在使用过程中并不能保证线程安全

### 9. iOS中的读写安全方案
#### iOS中的IO操作(文件操作), 如何保证读写安全? 从文件中读取内容、往文件中写入内容,读写是不能同时进行的
    @interface WGMainObjcVC()
    @property(nonatomic, strong) dispatch_semaphore_t semaphore;
    @end
    
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        
        //1.初始化信号量,value设置为1,即只能有一条线程在执行任务
        self.semaphore = dispatch_semaphore_create(1);
        for (int i = 0; i < 5; i++) {
            [[[NSThread alloc]initWithTarget:self selector:@selector(read) object:nil] start];
            [[[NSThread alloc]initWithTarget:self selector:@selector(write) object:nil] start];
        }
    }

    //从文件中读取内容
    -(void)read {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"%s",__func__);
        dispatch_semaphore_signal(self.semaphore);
    }
    //往文件中写入内容
    -(void)write {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"%s",__func__);
        dispatch_semaphore_signal(self.semaphore);
    }

#### 通过信号量的方式,虽然我们能够保证同一时间只能有读操作,或者同一时间只能有写操作,但是实际情况中,我们需要的是允许在同一时间有多个线程可以读操作,但是同一时间只能有一个线程在写操作,这样才会更加提高项目,即多读单写操作

#### 9.1项目中需求(多读单写)
1. 同一时间,只能有1条线程进行写的操作
2. 同一时间,允许有多个线程进行读的操作
3. 同一时间, 不允许既有写的操作,又有读的操作,即读写不能同步进行

#### 9.2 iOS中读写安全的方案有2中
1. pthread_rwlock: 读写锁
2. dispatch_barrier_async: 异步栅栏调用

#### 方案1: 读写锁pthread_rwlock, 等待锁的线程会进入休眠,类似互斥锁
    #import <pthread.h>

    @interface WGMainObjcVC()
    @property(nonatomic, assign) pthread_rwlock_t lock;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 初始化读写锁
        pthread_rwlock_init(&_lock, NULL);

        //全局并发队列异步任务,这样就能让读写同时进行,主要为了能更好的观察打印结果中read   
        可以同时进行,但是write只能1秒进行一次
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        for (int i = 0; i < 10; i++) {
            dispatch_async(queue, ^{
                [self read];
            });
            dispatch_async(queue, ^{
                [self write];
            });
        }
    }

    //从文件中读取内容
    -(void)read {
        pthread_rwlock_rdlock(&_lock); //读-加锁
        sleep(1);
        NSLog(@"%s",__func__);
        pthread_rwlock_unlock(&_lock); //解锁
    }

    //往文件中写入内容
    -(void)write {
        pthread_rwlock_wrlock(&_lock);  //写-加锁
        sleep(1);
        NSLog(@"%s",__func__);
        pthread_rwlock_unlock(&_lock);  //解锁
    }

    //销毁锁
    -(void)dealloc {
        pthread_rwlock_destroy(&_lock);
    }
#### 这样就能保证可以同时进行多次读操作,但是每次只能进行一次写操作, 读写操作不会同时进行

#### 方案2: 异步栅栏调用dispatch_barrier_async
1. 这个函数传入的并发队列必须是自己通过dispatch_queue_create创建的,而不能是系统创建的全局队列
2. 读写操作中,必须传入的是同一个并发队列
3. 如果传入的是一个串行队列或者一个全局的并发队列,那这个函数便等同于dispatch_async函数的效果

        @interface WGMainObjcVC()
        @property(nonatomic, strong) dispatch_queue_t queue;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //1. 手动创建的并发队列
            self.queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_CONCURRENT);
            for (int i = 0; i < 10; i++) {
                [self read];
                [self write];
            }
        }

        //从文件中读取内容
        -(void)read {
            dispatch_async(self.queue, ^{   //2.读时
                sleep(1);
                NSLog(@"read");
            });
        }

        //往文件中写入内容
        -(void)write {
            //3.写时: 调用dispatch_barrier_async函数
            dispatch_barrier_async(self.queue, ^{  
                sleep(1);
                NSLog(@"write");
            });
        }



### 下面是之前的总结
## 线程锁
### 常用的线程锁一般有
1. NSLock-普通锁
2. NSCondition-状态锁
3. synchronized-同步代码块
4. NSRecursiveLock-递归锁
5. NSConditionLock-条件锁
6. NSDistributedLock-分布锁(MAC开发下用到的，一般少用)
7. GCD中信号量-可实现多线程同步(并不属于线程锁)


### 1.NSLock
#### 创建NSLock对象，然后调用实例方法lock()和unlock()方法实现加锁和解锁，NSLock也提供了try()方法，来判断是否加锁成功。接下来通过案例来说明
    //初始化苹果数量为20个
    private var appleTotalNum = 20

    NSLog("开始了")
    let thread1=Thread(target:self, selector: #selector(eatApple), object:nil)
    let thread2=Thread(target:self, selector: #selector(eatApple), object:nil)
    let thread3=Thread(target:self, selector: #selector(eatApple), object:nil)
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
#### 需要注意的就是lock加锁和unlock解锁是成对出现的。如果没有加锁(lock),直接解锁(unlock),程序执行和没有加锁解锁效果是一样的；如果多次加锁(获取锁)，会导致死锁
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
    let thread1 = Thread(target:self, selector: #selector(method1), object:nil)
    thread1.start()
    let thread2 = Thread(target:self, selector: #selector(method1), object:nil)
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
    NSThread *thread1=[[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
    [thread1 start];
    NSThread *thread2=[[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
    [thread2 start];
    NSThread *thread3=[[NSThread alloc]initWithTarget:self selector:@selector(method1) object:nil];
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
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock3.png)

#### 总结：@synchronized(objc)工作时，Runtime会为objc分配一个递归锁，并保存在哈希表中，通过Objc内存地址的哈希值在哈希表中查找到SyncData，并将其加锁；如果在synchronized内部objc被释放或者值为nil，会调用objc_sync_nil()方法；如果@synchronized(nil)传进入了nil，那么synchronized内部的代码就不是线程安全的;如果objc_sync_enter(objc1)和objc_sync_exit(objc2)两个参数不一致时，objc1对象被锁定但并未被解锁，会导致其他线程无法访问，这种情况下如果再开辟线程去访问会发生crash
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/lock4.png)


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


### 6. NSDistributedLock(分布锁)
#### 是MAC开发中的跨进程的分布式锁，底层是用文件系统实现的互斥锁。


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

