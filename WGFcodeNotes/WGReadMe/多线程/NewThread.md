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
        异步: 在新的线程中执行任务,具备开启新线程的能力(但不一定一定会开新线程,如主队列异步任务还是在主线程中执行)
2. 并发和串行主要影响: 任务的执行方式

        并发: 多个任务并发(同时)执行
        串行: 一个任务执行完毕后,再执行下一个任务

#### 2.3 队列和任务的组合执行效果
                          并发队列         手动创建的串行队列(非主队列)          主队列
      同步(sync)     没有开线程/串行执行任务    没有开线程/串行执行任务     没有开线程/串行执行任务
      异步(async)    开启新线程/并发执行任务    开启新线程/串行执行任务     没有开线程/串行执行任务
      
      ⚠️: 使用sync函数往当前串行队列中添加任务,会卡住当前的串行队列,产生死锁
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
            dispatch_queue_t queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
            //并发队列
            dispatch_queue_t queue2 = dispatch_queue_create("myqueue2", DISPATCH_QUEUE_CONCURRENT);
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
            dispatch_queue_t queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
            //串行队列
            dispatch_queue_t queue2 = dispatch_queue_create("myqueue2", DISPATCH_QUEUE_SERIAL);
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
            dispatch_queue_t queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_CONCURRENT);
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
                执行任务2
                执行任务3
                执行任务4
                执行任务5
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
            dispatch_queue_t queue3 = dispatch_queue_create("queue3", DISPATCH_QUEUE_CONCURRENT);
            dispatch_queue_t queue4 = dispatch_queue_create("queue4", DISPATCH_QUEUE_CONCURRENT);
            // 名称一样的并发队列
            dispatch_queue_t queue5 = dispatch_queue_create("queue4", DISPATCH_QUEUE_CONCURRENT);
            NSLog(@"%p %p %p %p %p", queue1, queue2, queue3, queue4,queue5);
        }

        打印结果:  0x104fc4f00 0x104fc4f00 0x600000fcee00 0x600000fcee80 0x600000fcef00
#### 全局队列是全局的,只有这一个队列,所以queue1和queue2的地址是相同的; 而手动创建的并发队列地址是不一样的,即便拥有相同的线程名也是不一样的, 但项目中不建议使用相同的线程名,因为线程名也是会用到的,为了便于区分所以不建议使用相同的线程名

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
             #define PTHREAD_MUTEX_RECURSIVE        2       递归锁
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
#### NSConditionLock是对NSConditionCon的进一步封装,可以设置具体的条件值
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


### 7. 自选锁和互斥锁比较

