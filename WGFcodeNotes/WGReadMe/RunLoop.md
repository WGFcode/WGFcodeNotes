##  RunLoop
### RunLoop就是通过内部维护的【事件循环】来对事件/消息进行管理的一个对象。没有消息处理时，处于休眠状态避免资源占用;有消息需要处理时立刻被唤醒；所谓的【事件循环】实质上就是runloop内部状态的转换而不是while死循环，分为两种状态
* 用户态:应用程序都是在用户态，平时开发用到的api等都是用户态的操作
* 内核态:系统调用，牵涉到操作系统，底层内核相关的指令
* 有消息时，从内核态 -> 用户态; 无消息休眠时，从用户态 -> 内核态

### 1 Runloop与线程的关系
* 每条线程都有唯一的一个与之对应的RunLoop对象
* runloop保存在一个全局的Dictionary字典中，线程为key，RunLoop为value
* 主线程的RunLoop已经自动获取(创建)，子线程的runloop需要主动创建
* 线程刚创建时并没有RunLoop，如果你不主动获取，那它一直都不会有。RunLoop的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时，你只能在一个线程的内部获取其RunLoop(主线程除外)

### 2.Runloop源码
#### OSX/iOS系统中提供了两个对象:
* NSRunLoop: 存在于Foundation框架下，是基于CFRunLoopRef的封装，提供了面向对象的API，但是这些API不是线程安全的
* CFRunLoopRef: 存在于CoreFoundation框架下，它提供了纯 C 函数的API，所有这些API都是线程安全的。
#### 这里只引出NSRunLoop相关的API，CFRunLoopRef是C函数的API，有兴趣的可以研究
        @class NSTimer, NSPort, NSArray<ObjectType>, NSString;
        FOUNDATION_EXPORT NSRunLoopMode const NSDefaultRunLoopMode;
        FOUNDATION_EXPORT NSRunLoopMode const NSRunLoopCommonModes;
         
        @interface NSRunLoop : NSObject {
         
        @property (class, readonly, strong) NSRunLoop *currentRunLoop;  获取当前RunLoop对象
        @property (class, readonly, strong) NSRunLoop *mainRunLoop;     获取主线程的RunLoop对象
        @property (nullable, readonly, copy) NSRunLoopMode currentMode; 获取当前RunLoop的运行模式
        添加一个定时器到runloop循环中，并指定运行模式
        - (void)addTimer:(NSTimer *)timer forMode:(NSRunLoopMode)mode;
        添加一个端口到runloop循环中，并指定运行模式
        - (void)addPort:(NSPort *)aPort forMode:(NSRunLoopMode)mode;
        从runloop循环中移除一个端口到，并指定运行模式
        - (void)removePort:(NSPort *)aPort forMode:(NSRunLoopMode)mode;

        - (nullable NSDate *)limitDateForMode:(NSRunLoopMode)mode;
        - (void)acceptInputForMode:(NSRunLoopMode)mode beforeDate:(NSDate *)limitDate;
         
        @end

        @interface NSRunLoop (NSRunLoopConveniences)
         
        进入处理runloop的事件循环
        - (void)run;
        等待多长时间进入处理runloop的事件循环
        - (void)runUntilDate:(NSDate *)limitDate;
        - (BOOL)runMode:(NSRunLoopMode)mode beforeDate:(NSDate *)limitDate;
        ios(10.0)
        - (void)performInModes:(NSArray<NSRunLoopMode> *)modes block:(void (^)(void))block;
        ios(10.0)
        - (void)performBlock:(void (^)(void))block;
         
        @end

        Delayed perform
        @interface NSObject (NSDelayedPerforming)
         
        - (void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray<NSRunLoopMode> *)modes;
        - (void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument afterDelay:(NSTimeInterval)delay;
        + (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(nullable id)anArgument;
        + (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget;
         
        @end

        @interface NSRunLoop (NSOrderedPerform)
         
        - (void)performSelector:(SEL)aSelector target:(id)target argument:(nullable id)arg order:(NSUInteger)order modes:(NSArray<NSRunLoopMode> *)modes;
        - (void)cancelPerformSelector:(SEL)aSelector target:(id)target argument:(nullable id)arg;
        - (void)cancelPerformSelectorsWithTarget:(id)target;

        @end
### 2.1 线程下的Runloop
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            NSLog(@"\n当前的线程是:%@\n当前的Runloop对象:%p\n主线程的Runloop对象:%p\n",[NSThread currentThread],[NSRunLoop currentRunLoop],[NSRunLoop mainRunLoop]);
            
            NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(change) object:nil];
            [thread start];
        }
        -(void)change {
            NSLog(@"\n当前的线程是:%@\n当前的Runloop对象:%p\n主线程的Runloop对象:%p\n",[NSThread currentThread],[NSRunLoop currentRunLoop],[NSRunLoop mainRunLoop]);
        }
        @end
        打印结果: 当前的线程是:<NSThread: 0x60000376e140>{number = 1, name = main}
                当前的Runloop对象:0x6000006702a0
                主线程的Runloop对象:0x6000006702a0
                
                当前的线程是:<NSThread: 0x6000037273c0>{number = 7, name = (null)}
                当前的Runloop对象:0x600000674660
                主线程的Runloop对象:0x6000006702a0
#### 分析，在当前线程即主线程中，currentRunLoop和mainRunLoop获取到的都是主线程下的RunLoop对象；开启子线程后，系统会创建一个和这个子线程相对应的RunLoop对象，当然这里需注意的就是我们必须主动去获取，即调用currentRunLoop方法时系统才开始创建，如果不去主动获取，只创建子线程是不会创建对应的RunLoop对象的，而在这个子线程中我们仍然可以通过mainRunLoop来获取主线程下对应的RunLoop对象

### 3. RunLoop的运行模式分类
#### RunLoop的运行有自己的运行模式(model),苹果为我们公开提供了两种运行模式
* NSDefaultRunLoopMode（kCFRunLoopDefaultMode）
* NSRunLoopCommonModes（kCFRunLoopCommonModes）

        //.m文件
        @interface WGMainObjcVC()<UIScrollViewDelegate>
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            
            NSLog(@"WGMainObjcVC-viewDidLoad当前的model:---%@",[NSRunLoop currentRunLoop].currentMode);
            
            UIScrollView *scrol = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 100)];
            scrol.backgroundColor = [UIColor redColor];
            scrol.delegate = self;
            scrol.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height *2);
            [self.view addSubview:scrol];
        }
        -(void)scrollViewDidScroll:(UIScrollView *)scrollView {
            NSLog(@"scrollViewDidScroll当前的model:---%@",[NSRunLoop currentRunLoop].currentMode);
        }
        @end
        
        打印结果: WGMainObjcVC-viewDidLoad当前的model:---kCFRunLoopDefaultMode
                scrollViewDidScroll当前的model:---kCFRunLoopDefaultMode
                scrollViewDidScroll当前的model:---UITrackingRunLoopMode
                scrollViewDidScroll当前的model:---UITrackingRunLoopMode
                ...
#### 可以发现在主线程中正常情况下，RunLoop的运行模式是kCFRunLoopDefaultMode，当有UIScrollView滚动的时候，运行模式是UITrackingRunLoopMode,所以除了苹果公开提供的两种运行模式外，我们能证明存在的还有UITrackingRunLoopMode运行模式。
    
#### 其实Runloop实际的运行模式有下列五种

* kCFRunLoopDefaultMode：App的默认Mode，通常主线程是在这个Mode下运行
* UITrackingRunLoopMode：界面跟踪Mode，用于ScrollView追踪触摸滑动，保证界面滑动时不受其他Mode影响
* UIInitializationRunLoopMode：在刚启动App时第进入的第一个Mode，启动完成后就不再使用
* GSEventReceiveRunLoopMode：接受系统事件的内部Mode，通常用不到
* kCFRunLoopCommonModes：这是一个占位用的Mode，不是一种真正的Mode

##### 注意 NSDefaultRunLoopMode是NSRunLoop中的叫法，对应的是CFRunLoopRef中的kCFRunLoopDefaultMode，NSRunLoopCommonModes是NSRunLoop中的叫法，对应的是CFRunLoopRef中的kCFRunLoopCommonModes
### 3.1 运行模式RunLoopMode源码
#### 通过CFRunLoopRef的源码我们发现每个运行模式model都包含下列内容
        struct __CFRunLoopMode {
        CFStringRef _name;              运行在那个model下，例如 @"kCFRunLoopDefaultMode"
        CFMutableSetRef _sources0;      触摸事件，PerformSelectors，非基于Port的
        CFMutableSetRef _sources1;      基于Port的线程间通信，基于Port的
        CFMutableArrayRef _observers;   添加监听的方法:
        CFMutableArrayRef _timers;      定时执行的定时器
        ...
        }
#### 分析：一个Runloop对象包含若干个mode，每个mode又包含若干个sources0/sources1/observers/timers；Runloop启动时只能选择其中的一个model作为currentMode;如果mode中没有任何sources0/sources1/observers/timers，Runloop会立马退出
    
    
