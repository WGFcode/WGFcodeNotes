## RunLoop
### 面试题
1. 讲讲RunLoop,项目中有用到吗?
2. Runloop内部实现逻辑
3. RunLoop和线程的关系
4. timer和RunLoop关系
* 从结构上来说,RunLoop中包含多个模式mode,每个模式mode下会有一个timer; 运行逻辑中,timer的处理是在RunLoop中执行的
5. 程序中添加每3秒响应一次的NSTimer,当拖动tableview时,timer可能无法响应怎么解决?
6. runloop是怎么响应用户操作的,具体流程是什么样的?
* 用户点击屏幕后,首先是Sources1捕获到了该事件,Sources1会将该事件包装到EventQueue事件队列中,交给Sources0处理,即Sources1负责捕获,Sources0来处理
7. 说说RunLoop的几种状态
* 6种状态: 进入Loop、退出Loop、即将处理Timers、即将处理Sources、即将开始休眠、从休眠中唤醒
8. RunLoop的mode作用是什么
* mode模式可以将不同的Sources/Timers/Observers隔离开来,这样相互之间都不会影响,并且当我们切换mode模式时,其他mode不会被影响,操作起来更加流程,只会专注与处理当前的模式mode

### 1. 什么是RunLoop
#### RunLoop就是运行循环,在程序运行过程中循环做一些事情,做了哪些事情?应用范畴是?
1. 定时器(NSTimer)、performSelector
2. GCD Async Main Queue
3. 事件响应、手势识别、界面刷新
4. 网络请求
5. AutoreleasePool自定释放池

#### 如果没有RunLoop程序会立马退出; 如果有RunLoop,程序并不会马上退出,而是保持运行状态,RunLoop基本作用有
1. 保持程序的持续运行
2. 处理APP中的各种事件(比如触摸事件、定时器事件)
3. 节省CPU资源,提高程序性能: 该做事时做事,该休息时休息
4. RunLoop其实内部很像是个do-while循环

### 2. RunLoop对象
#### iOS中有2套API来访问和使用RunLoop,NSRunLoop和CFRunLoopRef都代表着RunLoop对象
1. Foundation: NSRunLoop(基于CFRunLoopRef的一层OC包装)
2. Core Foundation: CFRunLoopRef(是开源的:https://opensource.apple.com/tarballs/CF/)

### 3. RunLoop与线程的关系
* 每条线程都有唯一的一个与之对应的RunLoop对象
* RunLoop保存在一个全局的Dictionary字典里,线程作为Key,RunLoop作为value
* 线程刚创建时并没有RunLoop对象,RunLoop会在第一次获取它时创建
* RunLoop会在线程结束时销毁
* 主线程的RunLoop已经自动获取(创建),子线程默认没有开启RunLoop

### 4. RunLoop相关的类
#### Core Foundation关于RunLoop的5个类
1. CFRunLoopRef
2. CFRunLoopModeRef: 代表RunLoop的运行模式
3. CFRunLoopSourceRef
4. CFRunLoopTimerRef
5. CFRunLoopObserverRef

        typedef struct __CFRunLoop * CFRunLoopRef;
        struct __CFRunLoop {
            pthread_t _pthread;                 //线程
            CFMutableSetRef _commonModes;       //
            CFMutableSetRef _commonModeItems;   //
            CFRunLoopModeRef _currentMode;      //
            CFMutableSetRef _modes;             //(无序)集合,存放的是CFRunLoopModeRef类型
        };
        
        typedef struct __CFRunLoopMode *CFRunLoopModeRef;
        struct __CFRunLoopMode {
            CFStringRef _name;              //model名字
            CFMutableSetRef _sources0;      //装的CFRunLoopSourceRef对象
            CFMutableSetRef _sources1;      //装的CFRunLoopSourceRef对象
            CFMutableArrayRef _observers;   //装的CFRunLoopObserverRef对象
            CFMutableArrayRef _timers;      //装的CFRunLoopTimerRef对象
        }
        
        ----------------------RunLoop-------------------
        mode        mode         mode         mode      ...
        sources0    sources0     sources0     sources0
        sources1    sources1     sources1     sources1
        observers   observers    observers    observers
        timers      timers       timers       timers
* CFRunLoopModeRef代表RunLoop的运行模式
* 一个RunLoop包含若干个Mode,每个Mode又包含若干个Sources0/Sources1/Timer/Observer
* RunLoop启动时只能选择其中一个Mode,作为currentMode
* 如果需要切换Mode,只能退出当前Loop,再选择一个Mode进入(这里的退出并不是退出RunLoop循环,而是在RunLoop循环中退出,所以不会导致程序退出)
* 不同组的Sources0/Sources1/Timer/Observer能分割开来,互不影响(主要就是提高交互,当滚动时在一个Mode中,专心处理滚动的事情就行了)
* 如果Mode里没有任何Sources0/Sources1/Timer/Observer,RunLoop会立马退出
* 常见的两种运行Mode: 

        kCFRunLoopDefaultMode: App的默认Mode,通常主线程是在这个Mode下运行的
        UITrackingRunLoopMode: 界面跟踪Mode,用于scrollView追踪触摸滑动,保证界面滚动不受其他Mode影响

### 5. RunLoop运行逻辑
#### RunLoop就是在循环处理某个Mode下的Sources0/Sources1/Timer/Observer这些事件的
1. Sources0: 触摸事件处理、performSelector: onThread:
2. Sources1: 基于Port(端口)的线程间通信、系统事件捕捉(点击屏幕,先通过Sources1捕捉点击事件,然后交给Sources0去处理)
3. Timers:NSTimer、performSelector: withObject: afterDelay:
4. Observers: 用于监听RunLoop的状态、UI刷新(BeforeWaiting)、Autorelease pool(自动释放池)

        //UI刷新: 下面代码并不是说执行到这句代码就立马执行,而是先记住这件事,
        //等到RunLoop睡眠之前去处理这件事(将页面背景设置为红色),RunLoop没有事件处理就会去睡眠
        self.view.backgroundColor = [UIColor whiteColor];
        
        01: 通知Observers: 进入Loop
        02: 通知Observers: 即将处理Timers
        03: 通知Observers: 即将处理Sources
        04: 处理Blocks(RunLoop有CFRunLoopPerformBlock方法,可以将Block添加到RunLoop中)
        05: 处理Sources0(可能会再次处理Blocks)
        06: 如果存在Sources1,就跳转到第8步(执行的是第08步中的3)
        07: 如果没有Sources1,通知Observers: 开始休眠(等待消息唤醒)
        08: 通知Observers: 结束休眠(被某个消息唤醒,可能是下面的3种)
                1.处理Timers
                2.处理GCD Async To Main Queue(GCD是不依赖RunLoop的,但是这种情况下[从子线程回到主线程]会依赖)
                3.处理Sources1
        09: 处理Blocks
        10: 根据前面的执行结果,决定如何操作
                1.回到第02步
                2.退出Loop
        11: 通知Observers: 退出Loop(10步中的2)
        
#### RunLoop运行逻辑源码分析,可以通过项目中打断点,然后根据函数调用栈,在命令行中输入**bt**来查看,然后根据控制台日志内容去**Source/CFRunloopRef**中找到对应的入口

#### ⚠️: RunLoop开始休眠时,会阻塞当前线程,但这种阻塞并不是一直在等待(并不是while循环),不会消耗CPU资源,而是RunLoop从用户态切换到了内核态(mach_msg函数),内核态是系统层API控制的,实际上RunLoop的休眠和唤醒就是RunLoop在用户态和内核态之间的切换

### 6.RunLoop运行状态 6 种及监听

        /* Run Loop Observer Activities */
        typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
            kCFRunLoopEntry = (1UL << 0),          //即将进入Loop
            kCFRunLoopBeforeTimers = (1UL << 1),   //即将处理Timer
            kCFRunLoopBeforeSources = (1UL << 2),  //即将处理Sources
            kCFRunLoopBeforeWaiting = (1UL << 5),  //即将进入休眠
            kCFRunLoopAfterWaiting = (1UL << 6),   //刚从休眠中唤醒
            kCFRunLoopExit = (1UL << 7),           //即将退出Loop
            kCFRunLoopAllActivities = 0x0FFFFFFFU  //所有状态
        };
#### 监听RunLoop状态
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            /*
             kCFRunLoopCommonModes: 默认包含 kCFRunLoopDefaultMode + UITrackingRunLoopMode
             */
            //1.创建observer
            CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, CFRunLoopObserverCallBack1, NULL);
            //1.1 创建observer的第二种方法: 将监听方法放到Block中去
            CFRunLoopObserverRef observer1 = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            });
            
            //2.添加observer到RunLoop
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
            
            //3.释放observer
            CFRelease(observer);
        }
        
        // 监听到RunLoop状态改变
        void CFRunLoopObserverCallBack1(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
            switch (activity) {
                case kCFRunLoopEntry: {
                    CFRunLoopMode mode = CFRunLoopCopyCurrentMode(CFRunLoopGetCurrent());
                    NSLog(@"kCFRunLoopEntry-----运行模式:%@",mode);
                    CFRelease(mode); //mode是需要释放的
                    break;
                }
                case kCFRunLoopExit:
                    NSLog(@"kCFRunLoopExit");
                    break;
                case kCFRunLoopBeforeSources:
                    NSLog(@"kCFRunLoopBeforeSources");
                    break;
                case kCFRunLoopBeforeTimers:
                    NSLog(@"kCFRunLoopBeforeTimers");
                    break;
                case kCFRunLoopBeforeWaiting:
                    NSLog(@"kCFRunLoopBeforeWaiting");
                    break;
                case kCFRunLoopAfterWaiting:
                    NSLog(@"kCFRunLoopAfterWaiting");
                    break;
                default:
                    break;
            }
        }
### 7. RunLoop在实际开发中的应用
1. 解决NSTimer在滚动时停止工作的问题
2. 控制线程生命周期(线程保活)
3. 监控应用卡顿
4. 性能优化

#### 7.1 解决NSTimer在滚动时停止工作的问题
#### NSTimer默认运行在RunLoop的NSDefaultRunLoopMode模式下,而滚动时就切换到了UITrackingRunLoopMode模式下,所以导致了NSTimer定时器停止工作, 解决方法就是将NSTimer添加到RunLoop的NSRunLoopCommonModes通用模式下,NSRunLoopCommonModes其实并不是一种运行模式而是一个数组,里面存放的是[NSDefaultRunLoopMode、UITrackingRunLoopMode],它其实是一个标记,标记RunLoop可以运行在默认模式和滚动模式中

#### 7.2 控制线程生命周期(线程保活->AFNetworking)
#### 案例1
        @interface WGMainObjcVC()
        @property(nonatomic, strong) WGThread *thread;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            //这种创建线程的方式会导致循环引用: VC->Thread(属性)  Thread->VC(initWithTarget:self)
            self.thread = [[WGThread alloc]initWithTarget:self selector:@selector(task) object:nil];
            [self.thread start];
        }

        -(void)tesk{
            /* 保住线程:
               1.子线程中任务执行完成就会结束,线程就会销毁,所以要让子线程中一直有任务
               2.首先在子线程中添加任务到RunLoop,没有任务(Timers/Sources/Observers)RunLoop就会退出,线程就会销毁;
               3.运行RunLoop
             */
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] run];
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }
#### 这种方式会导致线程和VC之间的循环引用, 因为initWithTarget:self线程中强引用了VC
#### 案例2
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            //这种方式下创建线程,线程和VC之间就不会相互引用,VC能销毁了,但是线程不会销毁
            self.thread = [[WGThread alloc]initWithBlock:^{
                NSLog(@"-----start-----");
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                [[NSRunLoop currentRunLoop] run];
                //为什么VC销毁了,线程却不会被销毁?
                //因为启动线程后,RunLoop如果有任务就会执行,没有任务就会休眠,线程会一直卡在这个地方,
                //所以线程不会销毁,下面的代码也不会执行
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [self performSelector:@selector(task) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)task {
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }
#### 这种方式会导致线程不会被销毁, 因为RunLoop没有任务时,会处于休眠状态,会一直卡住当前的线程,导致线程无法释放, 那么我们接下来就要想办法在页面销毁时,停掉RunLoop
#### 案例3

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            //这种方式下创建线程,线程和VC之间就不会相互引用,VC能销毁了,但是线程不会销毁
            self.thread = [[WGThread alloc]initWithBlock:^{
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                [[NSRunLoop currentRunLoop] run];
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [self performSelector:@selector(task) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)task {
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }

        /// 停止RunLoop
        -(void)stop{
            //停止RunLoop,OC语法的NSRunLoop没有提供stop的API,所以只能用C语言的
            CFRunLoopStop(CFRunLoopGetCurrent());
        }

        -(void)dealloc {
            //必须是停掉子线程的RunLoop
            [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:NO];
            NSLog(@"-----%s",__func__);
        }
#### NSRunLoop中的run方法是无法停止的,它专门用于开启一个用不销毁的线程
#### CFRunLoopStop方法并没用停止掉RunLoop,因为[[NSRunLoop currentRunLoop] run];方法底层是无限循环调用了runMode: beforeDate:方法,而CFRunLoopStop方法只是停掉了当前循环中的Loop,并没用停掉整个循环,其实它也无法停掉这个无限循环. 所以我们就更换run而是用runMode: beforeDate:方法
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            //这种方式下创建线程,线程和VC之间就不会相互引用,VC能销毁了,但是线程不会销毁
            self.thread = [[WGThread alloc]initWithBlock:^{
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }
#### 调用runMode: beforeDate:方法后, 当任务执行完成后, 直接就打印了这个信息:-----end-----, 说明这种方式下,当任务执行完成后,RunLoop就直接退出了, 不能保活线程了

#### 案例4
        @interface WGMainObjcVC()
        @property(nonatomic, strong) WGThread *thread;
        @property(nonatomic, assign, getter=isStop) BOOL stop;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            self.stop = NO;
            __weak typeof(self) weakSelf = self;
            self.thread = [[WGThread alloc]initWithBlock:^{
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                //这里必须用弱引用,防止线程和VC相互引用
                while (!weakSelf.stop) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                }
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [self performSelector:@selector(task) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)task {
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }

        -(void)stop{
            //设置标记为YES
            self.stop = YES;
            CFRunLoopStop(CFRunLoopGetCurrent());
        }

        -(void)dealloc {
            //当控制器销毁时,停掉RunLoop,  
            [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
#### 通过设置属性,我们来控制线程什么时候停止, 但是上面还存在一个问题: 当我们进入页面直接返回时,程序会crash,为什么?  问题出在waitUntilDone:NO的参数设置上,waitUntilDone设置为NO表示主线程中的任务不需要等待子线程中的任务,在dealloc方法中,执行到performSelector的任务时,dealloc方法接下来就继续执行并且销毁了,不需要去等到stop任务完成后才销毁,所以就导致了self已经销毁了,但是仍然在用(stop方法中的self.stop); 所以要将dealloc方法中的performSelector方法的参数waitUntilDone设置为YES

#### 案例5

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            self.stop = NO;
            __weak typeof(self) weakSelf = self;
            self.thread = [[WGThread alloc]initWithBlock:^{
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                while (!weakSelf.stop) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                }
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [self performSelector:@selector(task) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)task {
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }

        -(void)stop{
            //设置标记为YES
            self.stop = YES;
            CFRunLoopStop(CFRunLoopGetCurrent());
        }

        -(void)dealloc {
            // waitUntilDone:YES代表子线程的代码执行完毕后,这个方法才会继续往下走
            [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:YES];
        }
#### 这种方式又会出现问题,当我们点击跳转到页面,然后什么都不操作,点击返回时, 发现RunLoop并没有停止掉,为什么? 我们在while (!weakSelf.stop) 处打断点,发现weakSelf为nil,当我们在VC销毁时调用Stop方法停止RunLoop后,程序会跳转到while (!weakSelf.stop),然后发现weakSelf为nil,那么条件就判断为true,就会继续调用runMode: beforeDate:方法,那么为什么weakSelf会为nil? 原因就是当调用stop后,程序执行到while循环,确实是停掉了当前的runMode: beforeDate:,但是停掉后,程序会继续判断while条件,此时self已经销毁了,所以weakSelf就也销毁了

#### 解决方法就是在while循环中首先判断weakSelf是否为nil,但是仍然在下列情况下会crash: 点击进入页面,然后执行任务,然后点击stop停掉线程, 然后再次点击返回页面时程序会crash,为什么? 原因很简单,就是当我们在页面内停掉RunLoop后,线程虽然没有销毁,但是这个线程已经不能再工作了,就是它的生命周期已经结束了,只是还没有销毁而已

#### 案例6 (正确做法)
        @interface WGMainObjcVC()
        @property(nonatomic, strong) WGThread *thread;
        @property(nonatomic, assign, getter=isStop) BOOL stop;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            self.stop = NO;
            __weak typeof(self) weakSelf = self;
            self.thread = [[WGThread alloc]initWithBlock:^{
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                while (weakSelf && !weakSelf.stop) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                }
                NSLog(@"-----end-----");
            }];
            [self.thread start];
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            if (!self.thread) {  //如果thread为nil就直接返回
                return;
            }
            [self performSelector:@selector(task) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)task {
            NSLog(@"-----%s-----%@",__func__,[NSThread currentThread]);
        }

        -(void)stop{
            self.stop = YES;
            CFRunLoopStop(CFRunLoopGetCurrent());
            // 清空Thread
            self.thread = nil;
        }

        -(void)dealloc {
            if (!self.thread) {  //如果thread为nil就直接返回
                return;
            }
            [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:YES];
        }
#### 完美解决

### 8. 封装线程保活的工具类
#### 有OC版本和C版本,详情参考WGCore/WGPermanentThreadOC|WGPermanentThreadC文件
#### 线程保活一般用在,例如在一个VC页面中, 一个按钮去执行一个异步任务,另一个按钮也要执行一个异步任务,那么可以使用线程保活在一个线程中去执行,只要这些任务不是需要并发执行的就行,线程保活可以节省CPU资源,避免了线程频繁的开启和销毁
