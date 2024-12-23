##  RunLoop
#### RunLoop就是通过内部维护的【事件循环】来对事件/消息进行管理的一个对象。没有消息处理时，处于休眠状态避免资源占用;有消息需要处理时立刻被唤醒；所谓的【事件循环】实质上就是runloop内部状态的转换而不是while死循环，分为两种状态
* 用户态:应用程序都是在用户态，平时开发用到的api等都是用户态的操作
* 内核态:系统调用，牵涉到操作系统，底层内核相关的指令
* 有消息时，从内核态 -> 用户态; 无消息休眠时，从用户态 -> 内核态

### 1. RunLoop作用
1. 保证RunLoop所在的线程不退出(保证程序不退出)；
2. 负责监听事件(触摸事件/时钟事件/网络事件等)；
3. 保持程序持续运行
4. 处理app各种事件(定时器Timer/方法调用PerformSelector/GCD Async Main Queue/事件响应、手势识别、界面刷新/网络请求/自动释放池 AutoreleasePool)      
5.节省CPU资源，提高程序性能


### 2. RunLoop类型
#### iOS系统为我们提供了两个RunLoop对象
1. CFRunLoopRef: Core Foundation框架下,它提供了纯 C 函数的API,是线程安全的
2. NSRunLoop: Foundation框架下，是基于CFRunLoopRef的封装，它提供了面向对象的API，但NSRunLoop不是线程安全的,苹果文档有警告:只能在当前线程中而不要在多个线程中操作RunLoop


### 3. RunLoop包含5种运行模式
#### 准确说应该包含四种运行模式,因其中一模式在iOS9时被废弃了,实际开发中会用到的就是前三种运行模式
1. NSDefaultRunLoopMode/kCFRunLoopDefaultMode: 默认的运行模式,一般用来处理Timer/网络等事件
2. UITrackingRunLoopMode: UI事件(触摸/滚动)下运行模式;专门处理UI事件
5. NSRunLoopCommonModes/kCFRunLoopCommonModes: 占位模式(默认模式&UI模式)
3. NSConnectionReplyMode: 该模式用来监控NSConnection对象,**很少用**(iOS9.0已经废弃NSConnection了，由NSURLSession替代,所以该模式也被苹果废弃了)  
4. NSModalPanelRunLoopMode: 等待诸如NSSavePanel或NSOpenPanel之类的模式面板的输入时，**很少用**

### 4. RunLoop运行模式包含内容
#### 通过RunLoop源码中CFRunLoop.c文件中发现RunLoop的每一种运行模式都包含如下内容,一个Runloop对象包含若干个mode，每个mode又包含若干个sources0/sources1/observers/timers；当启动一个Runloop时会先指定一个model作为currentMode，然后检查这个指定的mode是否存在以及mode中是否含有Source和Timer，如果mode不存在或者Mode中无Source和Timer，认为该Mode是个空的Mode,RunLoop就直接退出, RunLoop同一时间只能在一种运行模式下处理事件
    typedef struct __CFRunLoopMode *CFRunLoopModeRef;
    struct __CFRunLoopMode {
        pthread_mutex_t _lock;          互斥锁,来使多个线程保持同步
        CFStringRef _name;              运行在那个model下，例如 @"kCFRunLoopDefaultMode"
        CFMutableSetRef _sources0;      触摸事件，PerformSelectors，非基于Port的
        CFMutableSetRef _sources1;      基于Port的线程间通信，基于Port的
        CFMutableArrayRef _observers;   添加监听的方法:
        CFMutableArrayRef _timers;      定时执行的定时器
        CFMutableDictionaryRef _portToV1SourceMap;
        __CFPortSet _portSet;
        ...
    }
### 5. RunLoop状态
#### 我们知道RunLoop中的每个mode里面都包含Sources/Timers/Observers, Sources是输入事件,Timers不是一个输入事件而是一个定时事件,那么Observers是什么?其实Observers主要就是用来监听RunLoop在当前运行模式mode下的运行状态
        CFRunLoopObserverRef这是一个观察者，主要用途就是监听RunLoop的状态变化
        /* Run Loop Observer Activities */
        typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
            kCFRunLoopEntry = (1UL << 0),                即将进入RunLoop
            kCFRunLoopBeforeTimers = (1UL << 1),         即将处理Timers
            kCFRunLoopBeforeSources = (1UL << 2),        即将处理Sources
            kCFRunLoopBeforeWaiting = (1UL << 5),        即将进入休眠
            kCFRunLoopAfterWaiting = (1UL << 6),         刚从休眠中唤醒
            kCFRunLoopExit = (1UL << 7),                 即将退出RunLoop
            kCFRunLoopAllActivities = 0x0FFFFFFFU
        };
        
### 6. Runloop与线程的关系
* 每条线程都有唯一的一个与之对应的RunLoop对象
* Runloop保存在一个全局的Dictionary字典中，线程为key，RunLoop为value
* 主线程的RunLoop已经自动创建并开启，子线程的Runloop并没有创建,我们也无法创建,需要的时候直接去获取(获取的过程中系统才会创建),如果我们不主动获取,那么子线程的RunLoop一直都不会有,子线程中RunLoop的创建是发生在第一次获取时
* RunLoop 的销毁是发生在子线程结束时，你只能在一个线程的内部获取其RunLoop; 而主线程的RunLoop是不会销毁的,默认创建并开启了

### 7. NSRunLoop 源码
    @class NSTimer, NSPort, NSArray<ObjectType>, NSString;
    FOUNDATION_EXPORT NSRunLoopMode const NSDefaultRunLoopMode;
    FOUNDATION_EXPORT NSRunLoopMode const NSRunLoopCommonModes;
     
    @interface NSRunLoop : NSObject {
        //获取当前RunLoop对象
        @property (class, readonly, strong) NSRunLoop *currentRunLoop;  
        //获取主线程的RunLoop对象
        @property (class, readonly, strong) NSRunLoop *mainRunLoop;     
        //获取当前RunLoop的运行模式
        @property (nullable, readonly, copy) NSRunLoopMode currentMode; 
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
        - (void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument   
        afterDelay:(NSTimeInterval)delay inModes:(NSArray<NSRunLoopMode> *)modes;
        
        - (void)performSelector:(SEL)aSelector withObject:(nullable id)anArgument  
        afterDelay:(NSTimeInterval)delay;
        
        + (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector  
        object:(nullable id)anArgument;
        
        + (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget;
    @end

    @interface NSRunLoop (NSOrderedPerform)
        - (void)performSelector:(SEL)aSelector target:(id)target argument:(nullable id)arg  
        order:(NSUInteger)order modes:(NSArray<NSRunLoopMode> *)modes;
        
        - (void)cancelPerformSelector:(SEL)aSelector target:(id)target argument:(nullable id)arg;
        - (void)cancelPerformSelectorsWithTarget:(id)target;
    @end
    
   
### 8. NSTimer
#### 8.1 NSTimer基本使用
#### NSTimer是完成依赖RunLoop的,如果没有RunLoop,NSTimer是无法工作的,基本工作流程:创建NSTimer->将其添加到RunLoop中
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建timer
        NSTimer *timer=[NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(timerChange)  
        userInfo:nil repeats:YES];
        //2. 将timer添加到当前RunLoop(主线程)中, 如果不添加到NSRunLoop中,NSTimer是无法工作的
        [[NSRunLoop currentRunLoop] addTimer:timer forMode: NSDefaultRunLoopMode];
        
        // 3.添加到UITrackingRunLoopMode运行模式下  NSTimer无效
        //[[NSRunLoop currentRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];
        // 4. 添加到NSRunLoopCommonModes运行模式下  NSTimer有效
        //[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }

    -(void)timerChange {
        NSLog(@"timer来了");
    }
#### 上面NSTimer方法中userInfo参数表示可以给NSTimer传递参数,但是这个参数需要通过NSTimer对象来获取,算个小小的知识点. 
#### 从上面可以发现NSTimer只能运行在NSDefaultRunLoopMode默认模式和NSRunLoopCommonModes占位(UI&默认)模式这两种模式下,这里就解释了我们在项目中经常遇到的问题: 滚动视图时我们的NSTimer会无效,原因就是当滚动视图时触发的是RunLoop下的UITrackingRunLoopMode(UI模式),也就是说滚动视图时,RunLoop从默认模式NSDefaultRunLoopMode跳到UI模式UITrackingRunLoopMode下去执行了,而RunLoop同一时间只能在一个模式下运行,所以就导致了NSTimer的实效,解决办法就是在创建完NSTimer后将其添加到NSRunLoopCommonModes占位模式下

#### 我们知道UITrackingRunLoopMode(UI模式)下不仅会处理滚动视图事件也会处理触摸事件,所以点击事件同样也是在该模式下被处理的,所以我们应该可以发现一点有UI事件,RunLoop的运行模式就会马上从默认模式下切换到UI模式下进行处理,所以我们得到结论: UITrackingRunLoopMode(UI模式)处理事件的优先级比NSDefaultRunLoopMode(默认模式)要高


#### 8.2 GCD下的NSTimer
#### GCD多线程操作中是存在RunLoop的,只是我们平时操作GCD很少涉及到RunLoop,只是GCD将RunLoop进行了封装

    @interface WGRunLoopVC ()
    @property(nonatomic, strong) dispatch_source_t timer;
    @end

    @implementation WGRunLoopVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, 
        dispatch_get_global_queue(0, 0));
        //设置定时器各种属性  参数: 定时器 开始时间 时间间隔
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC , 0);
        // 设置Timer的回调
        dispatch_source_set_event_handler(self.timer, ^{
            NSLog(@"当前的线程:%@",[NSThread currentThread]);
        });
        //启动Timer
        dispatch_resume(self.timer);
        
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
    
    打印结果:  当前的线程:<NSThread: 0x60000180fe00>{number = 4, name = (null)}
             当前的线程:<NSThread: 0x60000180fe00>{number = 4, name = (null)}
             当前的线程:<NSThread: 0x60000180fe00>{number = 4, name = (null)}
             ...
#### 在GCD的子线程中添加Timer是不需要去触碰RunLoop的,因为GCD中已经封装了RunLoop了,所以不需要我们去将Timer再添加到RunLoop中了. 扩展问题: 如果有人说iOS下Timer必须手动添加到RunLoop中才能有效,这句话是不准确的,因为在GCD中添加Timer是不需要添加的,GCD内部已经封装好了RunLoop

#### 8.3 NSTimer导致的循环引用问题
    //WGRunLoopVC.m文件
    @interface WGRunLoopVC ()
    @property(nonatomic, strong) NSTimer *timer;
    @property(nonatomic, strong) NSString *name;
    @end

    @implementation WGRunLoopVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.name = @"zhang san";
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建NSTimer 2.自动添加到RunLoop中 3.会导致循环引用问题
        //scheduledTimerWithTimeInterval方式默认已经添加到RunLoop中了
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self  
        selector:@selector(timerChange) userInfo:nil repeats:YES];
    }

    -(void)timerChange{
        NSLog(@"timer来了,名字是: %@", self.name);
    }

    -(void)dealloc {
        NSLog(@"WGRunLoopVC页面销毁了");
    }
#### 当我们进入WGRunLoopVC这个页面时, 定时器任务开始执行,但是当我们返回这个页面时, dealloc方法并没有执行并且定时器任务也在一直执行并没有停止, 为什么? 因为NSTimer循环引用问题(NSTimer & self之间的循环引用),接下来我们来解决NSTimer导致的循环引用问题, 关键就在于打破这个循环引用

#### NSTimer循环引用解决方式一:  
#### 前提条件: 在合适的时机先关闭NSTimer并置为nil, 然后再返回页面, **不完美的解决方案**
    // 这里我们以touchesBegan/viewWillDisappear为例来 模拟合适时机
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    -(void)viewWillDisappear:(BOOL)animated {
        [super viewWillDisappear:animated];
        [self.timer invalidate];
        self.timer = nil;
    }
#### 需要注意的就是 NSTImer的invalidate方法和置nil,写在页面的dealloc方法中也是无用的, 必须写在dealloc方法前才有效果
    
#### NSTimer循环引用解决方式二:  
#### 前提条件: 利用NSTimer初始化的Block方法来解决循环引用, 在Block中通过__weak+__strong来打破循环引用,  这种方式和方式一基本一致, **不完美的解决方案**
    __weak typeof(self) weakSelf = self;
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer){
        NSLog(@"timer来了,名字是: %@", weakSelf.name);
    }];
    
    // 这里我们以touchesBegan/viewWillDisappear为例来 模拟合适时机
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    -(void)viewWillDisappear:(BOOL)animated {
        [super viewWillDisappear:animated];
        [self.timer invalidate];
        self.timer = nil;
    }


#### NSTimer循环引用解决方式三:  
#### 前提条件: 利用RunTime进行方法交换来打破循环引用, 就是利用中间者来进行方法交换处理, 从而不让NSTimer来引用self
    //利用RunTimer添加方法需要导入头文件
    #import <objc/message.h>

    @interface WGRunLoopVC ()
    @property(nonatomic, strong) NSTimer *timer;
    @property(nonatomic, strong) id target;
    @property(nonatomic, strong) NSString *name;
    @end

    @implementation WGRunLoopVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.name = @"zhang san";
        //1. 初始化中间者
        _target = [[NSObject alloc]init];
        //此时的_target并不具备处理消息(timerChange)的能力,所以我们需要通过RunTime为_target添加处理消息的能力
        /*
         给当前的类[NSObject class]添加方法
         添加方法编号: 其实就是方法名称
         添加方法的IMP地址: 因为_target对象内部没有timerChange方法,所以这里的方法地址用的就是当前对象  
         self中的方法timerChange地址,然后把这个地址交给_target对象
         */
        class_addMethod([NSObject class], 
                        @selector(timerChange),   
                        class_getMethodImplementation([self class], 
                        @selector(timerChange)), 
                        "v@:");
        // 如果只添加方法是不行的,因为定时器任务中有打印self.name,但是_target对象底层是结构体,它的内部并  
        没有name这个属性,所以程序运行会crash,那么我们就需要再动态添加_target对象的name属性
        //class_addIvar([NSObject class], [@"name" UTF8String], sizeof(id), log2(sizeof(id)), "@");
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:_target  
        selector:@selector(timerChange) userInfo:nil repeats:YES];
    }

    -(void)timerChange{
        NSLog(@"timer来了,名字是:");
    }

    -(void)dealloc {
        NSLog(@"WGRunLoopVC页面销毁了");
        [self.timer invalidate];
        self.timer = nil;
    }
#### 进入页面,定时器任务开始执行, 返回页面dealloc方法也被调用了, 这种方式是提供了一种打破循环引用的思考方式,但是在真实项目中,我们不会去写太多类似class_addMethod/class_addIvar这些C语言的方法,太麻烦了

#### NSTimer循环引用解决方式四: **终极方案**
#### 利用NSProxy类来进行消息的转发,这个类的作用就是消息转发,
        // 自定义WGProxy类继承自NSProxy 
        //WGProxy.h文件
        /// NSProxy消息转发的基类
        @interface WGProxy : NSProxy
        @property(nonatomic, weak) id target;
        @end
        
        //WGProxy.h文件
        @implementation WGProxy
        //作用就是 消息转发
        -(void)forwardInvocation:(NSInvocation *)invocation {
            [invocation invokeWithTarget:self.target];
        }
        -(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
            return [self.target methodSignatureForSelector:sel];
        }
        @end

        // 在WGRunLoopVC文件中引入WGProxy头文件
        #import "WGProxy.h"
        //WGRunLoopVC.m文件
        @interface WGRunLoopVC ()
        @property(nonatomic, strong) NSTimer *timer;
        @property(nonatomic, strong) WGProxy *proxy;
        @property(nonatomic, strong) NSString *name;
        @end

        @implementation WGRunLoopVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            self.name = @"zhang san";
            // 1. 实例化WGProxy,注意它只有alloc方法没有init方法
            self.proxy = [WGProxy alloc];
            // 2. 将self设置为proxy对象的target(类似代理)
            self.proxy.target = self;
            // 3. 将NSTimer的target设置为proxy对象
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.proxy  
            selector:@selector(timerChange) userInfo:nil repeats:YES];
        }

        -(void)timerChange{
            NSLog(@"timer来了,名字是: %@", self.name);
        }

        -(void)dealloc {
            NSLog(@"WGRunLoopVC页面销毁了");
            [self.timer invalidate];
            self.timer = nil;
        }
#### 当进入页面时,定时器任务开始执行,当页面返回时,dealloc方法会被调用,完美解决了NSTimer的循环引用的问题, 对于资深开发者强烈建议使用该方式来解决NSTimer的循环引用问题


### 9. Source: 事件源
#### 从GCD中的Timer案例中,我们知道Timer可以包装成一个Source, 按照函数调用栈可以分为两类
1. Source0: 触摸事件处理;非Source1就是Source0
2. Source1: 系统内核事件/基于NSPort端口的事件



### 10. 线程中的RunLoop
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建子线程
        NSThread *thread = [[NSThread alloc]initWithBlock:^{
            //2. 在子线程中添加NSTimer并将其添加到NSRunLoop中
            NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self  
            selector:@selector(timerChange) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            //3. 打印当前线程
            NSLog(@"当前线程是:%@",[NSThread currentThread]);
        }];
        [thread start];
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
        
    打印结果: 当前线程是:<NSThread: 0x600001f6a180>{number = 6, name = (null)}
#### 从打印结果可以看出, NSTimer中的事件(timerChange)并没有被执行,为什么? 因为在执行完子线程的任务后,子线程thread已经被销毁了, 接下来我们来验证这个
    // 1. 自定义继承自NSThread的类
    @interface WGThread : NSThread

    @end

    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程WGThread已经销毁了");
    }
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建子线程
        WGThread *thread = [[WGThread alloc]initWithBlock:^{
            //2. 在子线程中添加NSTimer并将其添加到NSRunLoop中
            NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self   
            selector:@selector(timerChange) userInfo:nil repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            NSLog(@"当前线程是:%@",[NSThread currentThread]);
        }];
        [thread start];
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
    
    打印结果: 当前线程是:<WGThread: 0x600002dda3c0>{number = 5, name = (null)}
            线程WGThread已经销毁了
#### 从打印结果看可以验证我们上面的结论: 在子线程中添加NSTimer并添加到NSRunloop中, NSTimer事件是无效的,原因就是子线程销毁了, 那么随着子线程的销毁子线程中的RunLoop也销毁了,所以NSTimer事件无效

#### 那么我们如何保证子线程不会被销毁? 首先想到的就是将子线程作为属性来强引用它,接下来我们来验证
    @interface WGRunLoopVC ()
    @property(nonatomic, strong) WGThread *thread;
    @end

    @implementation WGRunLoopVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建子线程
        self.thread = [[WGThread alloc]initWithBlock:^{
            //2. 在子线程中添加NSTimer并将其添加到NSRunLoop中
            NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self  
            selector:@selector(timerChange) userInfo:nil repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            NSLog(@"当前线程是:%@",[NSThread currentThread]);
        }];
        [self.thread start];
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
    
    打印结果: 当前线程是:<WGThread: 0x600002d8ea80>{number = 7, name = (null)}
#### 从打印结果上看出, “线程WGThread已经销毁了”这个消息并没有打印,说明我们的子线程并没有销毁,但是,但是,但是,子线程没有销毁为什么NSTimer事件还是无效哪? 接下来借用上面的demo,我们继续验证,既然线程没有销毁,那么我们可以继续用这个子线程
    // 在点击屏幕时,我们继续去启动这个子线程去执行任务
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"子线程地址:%@",self.thread);
        [self.thread start];
    }
    
    打印结果: 子线程地址:<WGThread: 0x6000038aef80>{number = 5, name = main}
    接着程序crash了,  报错信息:Terminating app due to uncaught exception 'NSInvalidArgumentException',   
    reason: '*** -[WGThread start]: attempt to start the thread again'
#### 通过上面分析得出: 我们强引用子线程作为属性, 只能保证这个子线程对象在内存当中(我们打印出WGThread对象的内存地址了), 但是对线程来说, 线程是通过CPU调度的, 实际上这个线程已经无效不能再为我们服务了, 所以我们得出结论: 通过强引用子线程作为属性, 也不能保证子线程有效工作(虽然子线程没有被销毁,但是子线程已经无效不能再工作了), 所以强引用子线程属性来保住子线程的命是毫无意义的

### 究竟怎么才能保证线程不销毁并且有效工作哪? 
#### 即保证线程的命, 只有唯一的一个方法: 即子线程中的任务没有执行完成

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建子线程
        WGThread *thread = [[WGThread alloc]initWithBlock:^{
            //2. 在子线程中添加NSTimer并将其添加到NSRunLoop中
            NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self   
            selector:@selector(timerChange) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            //3. 保住线程的命: 开启RunLoop循环,让它一直跑起来
            [[NSRunLoop currentRunLoop] run];
            //4 注意注意注意:下面的打印是不会被执行的,为什么? 因为RunLoop开启后是死循环,一直在处理循环里面的事件
            NSLog(@"当前线程是: %@", [NSThread currentThread]);
        }];
        [thread start];
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
        
    打印结果: timer来了
            timer来了
             ...
#### 结论: 想保住子线程的命,唯一的方法就是开启RunLoop进入死循环,这样子线程中就一直有任务,  所以线程也不会销毁并可以正常工作, 同时验证了即使这个页面被push/pop/presend/dismiss,这个子线程都不会销毁, 即子线程中的NSTimer事件会一直在执行

### 上面我们通过开启RunLoop来让子线程中一直有任务,这样子线程就不会被销毁了,但是如果我们想释放掉这个子线程该怎么做哪?
    //.m文件
    @interface WGRunLoopVC ()
    @property(nonatomic, assign) Boolean finish;  //声明个变量来控制进出死循环
    @end

    @implementation WGRunLoopVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.finish = NO;
        self.view.backgroundColor = [UIColor redColor];
        //1. 创建子线程
        WGThread *thread = [[WGThread alloc]initWithBlock:^{
            //2. 在子线程中添加NSTimer并将其添加到NSRunLoop中
            NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self   
            selector:@selector(timerChange) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            //3. 如果while里面是Yes就开始开启RunLoop, 直到遇到NO才退出RunLoop循环
            while (!self.finish) { 
                //每隔极短的时间就开启一次RunLoop
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
            }
            //4. 当跳出循环后,下面的代码才会被执行
            NSLog(@"当前线程是: %@", [NSThread currentThread]);
        }];
        [thread start];
    }

    -(void)timerChange{
        NSLog(@"timer来了");
    }
    
    //点击屏幕时,我们让循环跳出
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        NSLog(@"点击屏幕了");
        self.finish = YES;
    }

    打印结果:  timer来了
              timer来了
              timer来了
              timer来了
              点击屏幕了
              当前线程是: <WGThread: 0x600003c216c0>{number = 6, name = (null)}
              线程WGThread已经销毁了

#### 从上面打印结果得出结论: 想让子线程销毁, 可以通过设置变量来控制死循环的进入和退出,这样当子线程中的没有任务时,子线程就销毁了

#### 结论: 线程和RunLoop是一一对应的, 在子线程中,想保住子线程的命, 就是让子线程中一直有任务在处理,可以通过开启RunLoop来进入死循环来保证子线程中一直存在任务; 如果想销毁子线程,那么就要设置变量来控制while死循环的进入和进出条件, 然后在while循环中每隔极端的时间开启一次RunLoop, 在需要销毁子线程时,设置变量来控制while循环退出, 当while退出循环时, RunLoop也不再开启了, 子线程中没有任务了,子线程也就销毁了




### 11 RunLoop的面试题
#### 11.1 子线程中performSelector方法的调用原理分析

    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [super touchesBegan:touches withEvent:event];
        //创建全局队列并添加异步任务
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"11111");
            /*
            1. 打印结果 11111  22222  33333
            分析: 该方法定义在NSObject.h文件中,就是正常的方法调用, 代码执行到这里就会去执行testPerform方法
            */
            //[self performSelector:@selector(testPerform) withObject:nil];
            
            /*
             2. 打印结果 11111 33333
            分析: 该方法定义在NSRunLoop.h文件中,该方法底层是设置一个Timer(定时器)事件源,但是当前子线程的RunLoop  
            默认是没有开启的所以,testPerform方法是不会被执行的, 无论afterDelay设置的时间是多少都不会被执行
            */
            //[self performSelector:@selector(testPerform) withObject:nil afterDelay:0];
            /*
             2.1 如果我们开启当前线程的RunLoop,那么打印结果就是 11111  22222  33333
             我们知道 [[NSRunLoop currentRunLoop] run]; 是个循环,为什么还会打印33333?  
             因为testPerform一旦执行完成,RunLoop中没有任务就会死掉,所以testPerform执行完成后跳出  
             RunLoop循环就接着打印了33333
             */
            //[[NSRunLoop currentRunLoop] run];
            
            /*
             3. 打印结果
             waitUntilDone: YES: 11111 22222 33333
                             NO: 11111 33333
             分析: 该方法定义在NSThread.h头文件中如果是YES,并且onThread和当前所在的线程是同一个线程,那么  
             就立马先执行testPerform后返回然后再接着往下执行; 如果是NO,那么该方法就依赖当前线程的RunLoop,  
             由于当前线程的RunLoop没有开启,所以testPerform不会执行
            */
            [self performSelector:@selector(testPerform) onThread:[NSThread currentThread]  
            withObject:nil waitUntilDone:NO];
            /*
             3.1 如果我们开启当前线程的RunLoop,那么waitUntilDone在设置为NO的情况下,打印结果如下: 11111 22222  
             [[NSRunLoop currentRunLoop] run]是循环, testPerform执行完成后RunLoop不应该销毁吗? (因为任务完成了)  
             为什么?⚠️: 这里有疑问, 暂时猜测此处的RunLoop开启会陷入一个死循环, 所以后续的信息33333就不会打印了
             */
            //[[NSRunLoop currentRunLoop] run];
            
            
            /* 3.2 开启RunLoop方法二
            如果没有输入源或者Timer事件添加到运行循环中,此方法将立即退出, 否则会重复调用该方法直到指定的时间到来
            因为我们设置了到指定的未来时间截止,所以该RunLoop开启后会一直运行
            我们也可以理解成死循环了 所以下面打印的结果就是: 11111 22222
            */
            //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
            
            /* 3.3 开启RunLoop方法三
            如果没有输入源或者Timer事件添加到运行循环中,则此方法立即退出并返回NO,否则,将在处理完第一个输入源后或事件  
            到达后返回,所以下面打印的结果就是: 11111 22222 33333
            */
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            NSLog(@"33333");
        });
    }

    -(void)testPerform{
        NSLog(@"22222");
    }
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/runloop_performSelect.png)


### 4.RunLoop在项目中应用场景
* 控制线程的声明周期（线程保活）；常驻线程
* NSTimer定时器使用/解决NSTimer在滚动的时候停止的问题/
* 监控应用卡顿
* 性能优化
* AutoreleasePool

#### 4.1 线程保活
#### 为什么要线程保活? 我们知道线程中任务一旦执行完成，线程随之就会销毁，如果我们需要在子线程中频繁的执行任务，那么就要频繁的创建子线程和销毁子线程，这样很消耗性能，所以我们要使用线程保活，让这个线程一旦创建了就不会销毁。最典型的就是网络请求库AFNetworking，每个网络请求都是异步执行的，那么就需要创建多个子线程来执行这些异步任务，为了提高性能，AFNetworking使用线程保活，让每一个网络请求都在同一个子线程中执行，这个子线程不会被销毁
    //.h文件
    @interface WGThread : NSThread
    @end

    @interface WGMainObjcVC : UIViewController
    @end

    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程销毁了");
    }
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        WGThread *thread = [[WGThread alloc]initWithTarget:self   
        selector:@selector(change) object:nil];
        [thread start];
    }
    -(void)change {
        NSLog(@"线程中任务执行完成");
    }
    @end

    打印结果: 线程中任务执行完成
            线程销毁了  
####  分析: 线程中任务执行完成后，线程就会被销毁，并且线程对应的RunLoop也会随之销毁
    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGThread *thread;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        self.thread=[[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
        [self.thread start];
    }

    -(void)change {
        NSLog(@"开始执行线程中的任务");
        //没有添加任何事件处理，直接run的话，RunLoop因为没有事件处理会立马退出 
        [[NSRunLoop currentRunLoop] run];
        NSLog(@"线程中任务执行完成");
    }

    //点击屏幕，继续向线程(self.thread)中添加任务
    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self performSelector:@selector(newChange) onThread:self.thread   
        withObject:nil waitUntilDone:NO];
    }
    -(void)newChange {
        for (int i = 0; i < 3; i ++) {
            NSLog(@"----%d----",i);
        }
    }
    @end
    
    打印结果: 开始执行线程中的任务
            线程中任务执行完成
    点击屏幕的时候，并没有任何信息的打印
#### 分析: 我们通过方法[[NSRunLoop currentRunLoop] run]来启动RunLoop循环，但是因为没有添加任何事件处理，所以RunLoop会立马退出，所以会打印“线程中任务执行完成”的信息；当我们点击屏幕向线程中添加任何的时候，并没有打印任何信息，再次说明了RunLoop退出了，所以不会处理任何消息
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        self.thread=[[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
        [self.thread start];
    }
    -(void)change {
        NSLog(@"开始执行线程中的任务");
        //为RunLoop添加个Port(虽然什么都不处理),这样RunLoop就不会退出了
        [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
        //添加Port后，执行这句代码，由于没有事件处理，RunLoop会立即进入睡眠状态，等待有事件需要处理的时候会被再次唤醒
        //由于RunLoop处于休眠状态了，所以它下面的信息"线程中任务执行完成"就不会被打印了
        [[NSRunLoop currentRunLoop] run];
        NSLog(@"线程中任务执行完成");
    }
    //点击屏幕，继续向线程(self.thread)中添加任务
    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self performSelector:@selector(newChange) onThread:self.thread  
        withObject:nil waitUntilDone:NO];
    }
    -(void)newChange {
        for (int i = 0; i < 3; i ++) {
            NSLog(@"----%d----",i);
        }
    }
    
    打印结果:开始执行线程中的任务
            ----0----
            ----1----
            ----2----
#### 分析:必须向RunLoop中添加事件源，才能保证RunLoop不会退出，这样当有新的任务时，RunLoop就会被唤醒来执行相应的事件，但是上面有两个问题: 
* self和thread会造成循环引用；
* thread一直不会死

#### 4.1.1 解决循环引用的问题
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        
        //创建线程方式一
        //self.thread = [[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
        //[self.thread start];
        
        //创建线程方式二: 这种方式就不会造成self和thread的循环引用了，但是这种创建方式必须在iOS10以上才适合
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc] initWithBlock:^{
                NSLog(@"开始执行线程中的任务");
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                [[NSRunLoop currentRunLoop] run];
                NSLog(@"线程中任务执行完成");
            }];
        } else {
            // Fallback on earlier versions
        }
        [self.thread start];
    }

#### 4.1.2 如何解决线程不会死的问题
#### 即使是页面销毁了(WGMainObjcVC)，thread仍然是存在的，因为RunLoop在 [[NSRunLoop currentRunLoop] run]这一行一直阻塞，一直不会打印"线程中任务执行完成”的信息，这时候任务一直在进行，任务还没有完成，线程就不会死，即便在界面销毁的时候手动将thread=nil,thread也不会死；如果想让线程死掉，就得想办法让RunLoop停掉，当把RunLoop停掉后，代码就会从[[NSRunLoop currentRunLoop] run]往下走，当线程执行完任务后，就会销毁，如何停止RunLoop？
    [[NSRunLoop currentRunLoop] run];
#### 官方文档对**run** 方法的描述:(Puts the receiver into a permanent loop, during which time it processes data from all attached input sources)将接收器放入一个永久循环的loop中，在此期间，它处理来自所有附加输入源的数据。从这里可以看出通过**run**方法是无法停止RunLoop的。(it runs the receiver in the NSDefaultRunLoopMode by repeatedly invoking runMode:beforeDate:)这句话的意思就是它通过反复调用runMode:beforeDate:在NSDefaultRunLoopMode中运行接收器来实现的无限循环，那么我们可以模仿**run**方法的实现，来写一个white循环，内部也调用runMode:beforeDate:方法
    //.h文件
    @interface WGThread : NSThread
    @end

    @interface WGMainObjcVC : UIViewController
    @end

    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"WGThread线程销毁了");
    }
    @end

    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGThread *thread;
    @property(nonatomic, assign, getter=isStop)BOOL isStop; 添加一个Runloop退出的条件
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.isStop = NO;
        __weak typeof(self) weakSelf = self;
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc] initWithBlock:^{
            
            NSLog(@"开始执行线程中的任务");
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //self强引用thread,thread强引用Block，Block内又引用self,weakSelf来避免循环引用
            while (!weakSelf.isStop) {
                //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
                //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:  
                [NSDate distantFuture]];
            }
            NSLog(@"线程中任务执行完成");
            }];
        } else { // Fallback on earlier versions }
        [self.thread start];
        UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
        stopBtn.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:stopBtn];
        [stopBtn addTarget:self action:@selector(clickStopBtn)  
        forControlEvents:UIControlEventTouchUpInside];
    }

    -(void)clickStopBtn {
        /*
         🤔思考:为什么要放到self.thread执行停止Runloop的任务？
         因为一个线程对应一个Runloop对象，而我们要停止的是self.thread这个线程对应的Runloop对象 
         如果直接在这个方法中写停止Runloop，停止的是主线程中对应的Runloop对象
         */
        NSLog(@"点击了停止Runloop的按钮");
        [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil  
        waitUntilDone:NO];
    }

    -(void)stopRunLoop {
        self.isStop = YES;
        //系统提供的停止RunLoop的方法
        CFRunLoopStop(CFRunLoopGetCurrent());
    }

    //向self.thread线程中添加任务
    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self performSelector:@selector(newChange) onThread:self.thread withObject:nil  
        waitUntilDone:NO];
    }

    -(void)newChange {
        NSLog(@"开始执行添加到thread线程中的任务");
        for (int i = 0; i < 3; i ++) {
            NSLog(@"----%d----",i);
        }
    }

    -(void)dealloc {
        NSLog(@"WGMainObjcVC销毁了");
    }
    @end
        
    打印结果: 开始执行线程中的任务                  (刚进入页面)
            开始执行添加到thread线程中的任务        (点击屏幕)
            ----0----
            ----1----
            ----2----
            点击了停止Runloop的按钮               (点击stopBtn按钮）
            线程中任务执行完成
            没有任何打印信息(说明Runloop已经被停止)  (点击屏幕)
            WGMainObjcVC销毁了                  (点击页面返回按钮)
            线程销毁了
#### 分析: 可以发现RunLoop确实停止了，并且销毁也销毁了；不过有个不方便的地方，就是每次退出页面前，必须先点击stopBtn按钮停止RunLoop，然后再返回页面，能不能退出页面的时候就调用stopRunLoop方法,下面是改进的方法
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/runLoop1.png)

    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程销毁了");
    }
    @end
    
    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGThread *thread;
    @property(nonatomic, assign, getter=isStop)BOOL isStop; 添加一个Runloop退出的条件
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.isStop = NO;
        __weak typeof(self) weakSelf = self;
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc] initWithBlock:^{
            NSLog(@"开始执行线程中的任务");
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //self强引用thread,thread强引用Block，Block内又引用self,weakSelf来避免循环引用
            while (!weakSelf.isStop) {
                //[NSDate distantFuture]表示未来某一不可达到的时间点，说白了等同与正无穷大的事件
                //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:  
                [NSDate distantFuture]];
            }
            NSLog(@"线程中任务执行完成");
            }];
        } else { /*Fallback on earlier versions*/ }
        [self.thread start];
    }
    -(void)dealloc {
        [self performSelector:@selector(stopRunLoop) onThread:self.thread   
        withObject:nil waitUntilDone:NO];
        NSLog(@"WGMainObjcVC销毁了");
    }
    -(void)stopRunLoop {
        NSLog(@"开始执行RunRunLoop停止的方法");
        self.isStop = YES;
        //系统提供的停止RunLoop的方法
        CFRunLoopStop(CFRunLoopGetCurrent());
        NSLog(@"执行RunRunLoop停止的方法已经结束了");
    }
    @end
        
    打印结果: 开始执行线程中的任务              (进入页面)
            WGMainObjcVC销毁了              (返回页面)
            开始执行RunRunLoop停止的方法
            执行RunRunLoop停止的方法已经结束了
            程序crash -[WGMainObjcVC release]: message sent to deallocated instance 0x7fb2f6f06bb0
        
#### 分析:这种方式在页面消失的时候会导致程序crash,因为我们在dealloc方法中，为子线程添加方法去停止Runloop的时候，performSelector方法中的参数waitUntilDone被设置为了NO，意思是不需要等待子线程中任务(stopRunLoop)完成就可以继续执行,所以WGMainObjcVC页面先销毁了，但是在子线程任务中(stopRunLoop)调用停止Runloop方法后，会再次调用Runloop的white循环方法去判断，而此时while (!weakSelf.isStop) {...}中weakSelf已经销毁了，所以导致了carsh.那么我们把waitUntilDone参数设置为YES，等待子线程任务完成后，再执行dealloc方法剩下的任务来销毁页面
        -(void)dealloc {
            [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:YES];
            NSLog(@"WGMainObjcVC销毁了");
        }
        -(void)stopRunLoop {
            NSLog(@"开始执行RunRunLoop停止的方法");
            self.isStop = YES;
            //系统提供的停止RunLoop的方法
            CFRunLoopStop(CFRunLoopGetCurrent());
            NSLog(@"执行RunRunLoop停止的方法已经结束了");
        }
        打印结果: 开始执行线程中的任务                (进入页面)
                开始执行RunRunLoop停止的方法。      (退出页面)
                执行RunRunLoop停止的方法已经结束了
                WGMainObjcVC销毁了
#### 分析：此刻确实是子线程任务先执行了(也就是停止了RunLoop),然后dealloc方法才执行完成(WGMainObjcVC销毁了)。但是我们发现线程thread并没有打印"线程销毁了"的消息，所以thread还没有被销毁？为什么？
* 因为当调用CFRunLoopStop(CFRunLoopGetCurrent());方法来停掉RunLoop，确实停掉了，但是停掉之后，会再次来到while循环判断条件while (!weakSelf.isStop) {...}此时weakSelf已经销毁了，所以while (!weakSelf.isStop) 等价于while(YES),所以会再次进入循环体启动RunLoop，RunLoop又跑起来了，线程又有事情干了，所以线程不会销毁。解决方法就是在循环条件中加上判断weakSelf是否为nil的条件，如果为nil就不要再进入循环体去启动RunLoop了,如下，

        while (weakSelf && !weakSelf.isStop) {
            //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
            //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode  
            beforeDate:[NSDate distantFuture]];
        }
        
        打印结果: 开始执行线程中的任务                (进入页面)
                开始执行RunRunLoop停止的方法        (返回页面)
                执行RunRunLoop停止的方法已经结束了
                线程中任务执行完成
                WGMainObjcVC销毁了
                线程销毁了
#### 分析: 这样我们就可以保证页面销毁，暂停了RunLoop，并且线程也销毁了。那么如果我们在页面里面去暂停RunLoop而不是通过页面销毁。会不会也能保证暂停RunLoop，并且线程也销毁了.

#### 但是这里有个BUG，当我们手动去停止Runloop，然后再返回页面的时候，程序crash
    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程销毁了");
    }
    @end

    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGThread *thread;
    @property(nonatomic, assign, getter=isStop)BOOL isStop; 添加一个Runloop退出的条件
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.isStop = NO;
        __weak typeof(self) weakSelf = self;
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc] initWithBlock:^{
            
            NSLog(@"开始执行线程中的任务");
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //self强引用thread,thread强引用Block，Block内又引用self,weakSelf来避免循环引用
            while (weakSelf && !weakSelf.isStop) {
                //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
                //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode   
                beforeDate:[NSDate distantFuture]];
            }
            NSLog(@"线程中任务执行完成");
            
            }];
        } else { /*Fallback on earlier versions*/ }
        [self.thread start];
        
        UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
        stopBtn.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:stopBtn];
        [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    }

    -(void)stop{
        [self performSelector:@selector(stopRunLoop) onThread:self.thread  
        withObject:nil waitUntilDone:YES];
    }

    -(void)stopRunLoop {
        NSLog(@"开始执行RunRunLoop停止的方法");
        self.isStop = YES;
        //系统提供的停止RunLoop的方法
        CFRunLoopStop(CFRunLoopGetCurrent());
        NSLog(@"执行RunRunLoop停止的方法已经结束了");
    }

    -(void)dealloc {
        [self stop];
        NSLog(@"WGMainObjcVC销毁了");
    }
    @end

    打印结果: 开始执行线程中的任务                 (进入页面)
            开始执行RunRunLoop停止的方法         (点击stopBtn按钮)
            执行RunRunLoop停止的方法已经结束了
            线程中任务执行完成
            程序crash                          （退出页面）
#### 分析: 为什么在退出页面的时候，程序会crash?当我们点击stopBtn按钮后，Runloop确实停掉了，那么这个时候Runloop对应的线程就不能用了，但这个时候线程thread还没有销毁，因为还没有调用dealloc方法，当我们返回的页面的时候，是调用的dealloc方法，但是在dealloc方法执行完成前先调用了stop方法，在stop方法中，我们使用了方法performSelector来将任务添加到thread线程上，但是此时thread是不能用的，把一个任务添加到不能用的线程thread上，所以程序会crash。那么如何解决那？我们可以在暂停RunLoop后，可以将thread线程置为nil，这时候如果发现子线程thread为nil，就不要在这个子线程上添加任务了 
#### 最终线程保活的方案

    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程销毁了");
    }
    @end

    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGThread *thread;
    @property(nonatomic, assign, getter=isStop)BOOL isStop;  //添加一个Runloop退出的条件
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.isStop = NO;
        __weak typeof(self) weakSelf = self;
        if (@available(iOS 10.0, *)) {
            self.thread = [[WGThread alloc] initWithBlock:^{
            
            NSLog(@"开始执行线程中的任务");
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //self强引用thread,thread强引用Block，Block内又引用self,weakSelf来避免循环引用
            while (weakSelf && !weakSelf.isStop) {
                //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
                //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
                beforeDate:[NSDate distantFuture]];
            }
            NSLog(@"线程中任务执行完成");
                
            }];
        } else { /*Fallback on earlier versions*/ }
        [self.thread start];
        
        UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
        stopBtn.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:stopBtn];
        [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    }
    -(void)stop{
        if (self.thread != nil) {
            [self performSelector:@selector(stopRunLoop) onThread:self.thread  
            withObject:nil waitUntilDone:YES];
        }
    }
    -(void)stopRunLoop {
        NSLog(@"开始执行RunRunLoop停止的方法");
        self.isStop = YES;
        //系统提供的停止RunLoop的方法
        CFRunLoopStop(CFRunLoopGetCurrent());
        NSLog(@"执行RunRunLoop停止的方法已经结束了");
        self.thread = nil;
    }
    -(void)dealloc {
        [self stop];
        NSLog(@"WGMainObjcVC销毁了");
    }
    @end

    打印结果: 开始执行线程中的任务               (进入页面)
            开始执行RunRunLoop停止的方法       (点击stopBtn按钮)
            执行RunRunLoop停止的方法已经结束了   
            线程中任务执行完成
            线程销毁了                   
            WGMainObjcVC销毁了               (退出页面)
            
    如果是进入页面后直接退出页面则打印结果如下
            开始执行线程中的任务                (进入页面)
            开始执行RunRunLoop停止的方法        (退出页面)
            执行RunRunLoop停止的方法已经结束了
            线程中任务执行完成
            WGMainObjcVC销毁了
            线程销毁了
#### 分析:上面的方式已经完美解决了问题，并实现了线程保活

#### 4.1.3 封装线程保活类
    //.h文件
    @interface WGThread : NSThread
    @end

    typedef void (^WGHandle)(void);
    //线程保活类
    @interface WGKeepThreadAlive : NSObject

    -(instancetype)init;
    //在当前子线程下处理一个事件
    -(void)handleEvent:(WGHandle)handle;
    //停止当前线程对应的RunLoop循环并销毁线程
    -(void)stopRunLoop;

    @end

    //.m文件
    @implementation WGThread
    -(void)dealloc {
        NSLog(@"线程销毁了");
    }
    @end

    @interface WGKeepThreadAlive()
    //这里可直接使用NSThread，使用WGThread只是为了验证线程是否销毁
    //@property(nonatomic, strong) NSThread *thread;   
    @property(nonatomic, strong) WGThread *thread;
    @property(nonatomic, assign, getter=isStop) BOOL stop;
    @end

    //线程保活类
    @implementation WGKeepThreadAlive

    -(instancetype)init {
        if (self = [super init]) {
            self.stop = NO;
            __weak typeof(self)weakSelf = self;
            if (@available(iOS 10.0, *)) {
                self.thread = [[WGThread alloc]initWithBlock:^{
                
                //给当前线程对应的RunLoop对象添加基于端口的事件源
                [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
                //先判断，如果条件满足再执行循环体内的语句。
                //如果当前weakSelf不为nil，并且变量stop没有声明停止，就进入循环体
                while (weakSelf && !weakSelf.stop) {
                    //如果当前线程下有在NSDefaultRunLoopMode运行模式下的事件，那么RunLoop就会启动并去处理；  
                    如果没有事件，那么RunLoop就会处于休眠状态并在每过(多长时间)去启动一次该线程下的RunLoop
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:  
                    [NSDate distantFuture]];
                }
                    
                }];
                [self.thread start];
            } else { /*Fallback on earlier versions */ };
        }
        return self;
    }

    //在当前子线程下处理一个事件
    -(void)handleEvent:(WGHandle)handle {
        if (self.thread != nil && handle != nil) {
            //此方法可以传递参数，将参数放在withObject中;waitUntilDone:NO处理任务的时候，这里不需要等待  
            子线程中的任务执行完成，即仍然异步执行
            [self performSelector:@selector(privateHandleEventInThread:)   
            onThread:self.thread withObject:handle waitUntilDone:NO];
        }
    }
    -(void)privateHandleEventInThread:(WGHandle)handle{
        handle();
    }

    //停止当前线程对应的RunLoop循环并销毁线程
    -(void)stopRunLoop {
        if (self.thread != nil) {
            [self performSelector:@selector(privateStop) onThread:self.thread  
            withObject:nil waitUntilDone:YES];
        }
    }
    -(void)privateStop {
        self.stop = YES;
        CFRunLoopStop(CFRunLoopGetCurrent());
        self.thread = nil;
    }

    //对象销毁的时候停止RunLoop并销毁线程
    -(void)dealloc {
        [self stopRunLoop];
        NSLog(@"对象销毁了");
    }
    @end

    调用验证
    
    //.h文件
    @interface WGMainObjcVC()
    @property(nonatomic, strong) WGKeepThreadAlive *alive;
    @end
    
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.alive =[[WGKeepThreadAlive alloc]init];
        [self.alive handleEvent:^{
            NSLog(@"当前线程是:%@---我的名字叫张三",[NSThread currentThread]);
        }];
    }

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [self.alive stopRunLoop];
    }
    
    //进入页面->点击屏幕->退出页面
    打印结果: 当前线程是:<WGThread: 0x600001a80a00>{number = 6, name = (null)}---我的名字叫张三
            线程销毁了
            对象销毁了

    //进入页面->退出页面
    打印结果: 当前线程是:<WGThread: 0x600001a94cc0>{number = 8, name = (null)}---我的名字叫张三
            对象销毁了
            线程销毁了
        
#### 4.1.4 思考线程保活，为什么选择RunLoop,用强指针不行吗？
#### 强指针确实可以保住线程的命，置其不会被销毁，但是线程中的任务执行完成后，这个线程的生命周期就结束了，即便强指针保住了该线程的名，但是该线程已经是个“无用者”了，当有新的任务添加到这个“无用者”线程时，程序会crash。而选择RunLoop不仅能保住线程的命，也能让线程保持激活的状态，有任务就唤醒执行，没有任务就休眠

### 4.2 解决NSTimer在滚动的时候停止的问题
    //.m文件
    @interface WGMainObjcVC() <UIScrollViewDelegate>
    @property(nonatomic, strong) UIScrollView *scrollView;
    @property(nonatomic, strong) NSTimer *timer;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 80,   
        UIScreen.mainScreen.bounds.size.width, 300)];
        
        self.scrollView.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width,  
        UIScreen.mainScreen.bounds.size.height * 2);
        
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor redColor];
        [self.view addSubview:self.scrollView];
        
        //定时器启动方式一：需要手动将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下
        self.timer = [NSTimer timerWithTimeInterval:2.0 target:self   
        selector:@selector(timeChange) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        [self.timer fire];
        /*定时器启动方式二：默认将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下了
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self  
        selector:@selector(timeChange) userInfo:nil repeats:YES];
        [self.timer fire];
        */
    }
    -(void)timeChange {
        NSLog(@"定时器执行任务---当前的Runloop运行的模式是:%@",[NSRunLoop currentRunLoop].currentMode);
    }
    -(void)scrollViewDidScroll:(UIScrollView *)scrollView {
        NSLog(@"开始滚动---当前的Runloop运行的模式是:%@",[NSRunLoop currentRunLoop].currentMode);
    }
    @end

    打印结果: 10:03:14.051210+0800 定时器执行任务---当前的Runloop运行的模式是:kCFRunLoopDefaultMode
            10:03:16.052367+0800  定时器执行任务---当前的Runloop运行的模式是:kCFRunLoopDefaultMode
            10:03:18.052332+0800  定时器执行任务---当前的Runloop运行的模式是:kCFRunLoopDefaultMode
            10:03:18.219758+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
            10:03:19.475690+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
            10:03:20.860416+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
            10:03:21.054855+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
            10:03:22.723441+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
#### 分析，当进入页面的时候，定时器开始循环执行任务，此时的RunLoop对应的运行模式是kCFRunLoopDefaultMode，但是当用户去滑动滚动视图的时候，定时器任务停止了，因为此时RunLoop对应的运行模式是UITrackingRunLoopMode,所以我们需要将定时器的任务放到RunLoop的kCFRunLoopCommonModes运行模式下，kCFRunLoopCommonModes不是真正的运行模式，而是占位模式，使用此值作为模式添加到运行循环中的对象将受到所有运行循环模式的监视，

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 80, 
        UIScreen.mainScreen.bounds.size.width, 300)];
        
        self.scrollView.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width,
        UIScreen.mainScreen.bounds.size.height * 2);
        
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor redColor];
        [self.view addSubview:self.scrollView];
        
        //定时器启动方式一：需要手动将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下
        self.timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(timeChange)  
        userInfo:nil repeats:YES];
        //[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        //将定时器添加到RunLoop运行循环中的NSRunLoopCommonModes运行模式下
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.timer fire];

        /*定时器启动方式二：默认将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下了
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self   
        selector:@selector(timeChange) userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.timer fire];
        */
    }

    -(void)timeChange {
        NSLog(@"定时器执行任务---当前的Runloop运行的模式是:%@",[NSRunLoop currentRunLoop].currentMode);
    }

    -(void)scrollViewDidScroll:(UIScrollView *)scrollView {
        NSLog(@"开始滚动---当前的Runloop运行的模式是:%@",[NSRunLoop currentRunLoop].currentMode);
    }
    
    打印结果: 10:36:42.809265+0800  定时器执行任务---当前的Runloop运行的模式是:kCFRunLoopDefaultMode
        10:36:44.809261+0800  定时器执行任务---当前的Runloop运行的模式是:kCFRunLoopDefaultMode
        10:36:46.523926+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:46.580310+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:46.637176+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:46.717130+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:46.808626+0800  定时器执行任务---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:46.830735+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
        10:36:47.285391+0800  开始滚动---当前的Runloop运行的模式是:UITrackingRunLoopMode
#### 分析: 可以发现，在滚动的过程中，定时器任务仍然可以执行；同时发现在滚动视图的的时候，定时器任务的运行模式是UITrackingRunLoopMode模式，当不滚动视图的时候，定时器任务的运行模式是kCFRunLoopDefaultMode，这里再次证明了我们设置的NSRunLoopCommonModes并不是真正的运行模式，而是一个占位模式，用于监听RunLoop所有模式下的事件；为什么我们不能直接添加UITrackingRunLoopMode到定时器任务中？因为系统没有提供给我们获取这个模式的接口，只提供了两种运行模式NSDefaultRunLoopMode和NSRunLoopCommonModes

### 4.3 监控应用卡顿 TODO

#### 引起页面卡顿的原因分析：
* 复杂 UI 、图文混排的绘制量过大
* 在主线程上做网络同步请求或者大量的 IO 操作
* 运算量过大，CPU 持续高占用
* 死锁和主子线程抢锁

#### FPS(Frames Per Second)指画面每秒传输的帧数，每秒传输的帧数越多，所显示的动作或画面就会越流畅，通俗理解成画面“刷新率”(单位是Hz)。FPS值越低就越卡顿，iOS中正常的屏幕刷新率是60Hz,即每秒60次，一般保持在50～60Hz就可以保证有流畅的体验了。**CADisplayLink**可以用来检测FPS的，但是这个只能用来检测app的FPS值，并不能准确定位到哪个方法/页面出现了卡顿，所以我们要利用RunLoop的原理来进行检测

#### RunLoop检测卡顿主要是监控RunLoop的状态来判断是否会出现卡顿；我们需要监测的状态有两个：RunLoop在进入睡眠之前和唤醒后的两个loop状态定义的值，分别是kCFRunLoopBeforeWaiting 和 kCFRunLoopAfterWaiting
    CFRunLoopObserverRef这是一个观察者，主要用途就是监听RunLoop的状态变化
    /* Run Loop Observer Activities */
    typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
        kCFRunLoopEntry = (1UL << 0),            进入RunLoop
        kCFRunLoopBeforeTimers = (1UL << 1),     (即将处理Timers)触发 Timer 回调
        kCFRunLoopBeforeSources = (1UL << 2),    (即将处理Sources)触发 Source0 回调
        kCFRunLoopBeforeWaiting = (1UL << 5),    (即将进入休眠)等待 mach_port 消息
        kCFRunLoopAfterWaiting = (1UL << 6),     (刚从休眠中唤醒)接收 mach_port 消息
        kCFRunLoopExit = (1UL << 7),             退出RunLoop
        kCFRunLoopAllActivities = 0x0FFFFFFFU    loop 所有状态改变
    };
#### 检测卡顿步骤 (https://www.cnblogs.com/qiyiyifan/p/11089735.html)
* 创建一个RunLoop的观察者(CFRunLoopObserverContext)
* 把观察者加入主线程的kCFRunLoopCommonModes模式中，以监测主线程
*  创建一个持续的子线程来维护观察者进而用来监控主线程的RunLoop状态；
* 根据主线程RunLoop的状态来判断是否卡顿。一旦发现进入睡眠前的 kCFRunLoopBeforeWaiting 状态，或者唤醒后的状态 kCFRunLoopAfterWaiting，在设置的时间阈值内一直没有变化，即可判定为卡顿；
* dump 出堆栈的信息，从而进一步分析出具体是哪个方法的执行时间过长；


### 4.4 性能优化
#### 4.4.1 RunLoop如何保证不影响UI卡顿？例如UITableView/UICollectionView的ItemCell都包含了UIImageView用来显示网络图片：第一就是异步获取网络图片，第二将图片渲染到UIImageView上；第一步我们都知道图片数据是通过子线程异步获取到的，但是第二步我们一般都是在主线程中直接设置图片，这样滚动页面的时候Runloop对应的运行模式是UITrackingRunLoopMode，如果直接通过self.imageView.image = XXX,那么这种设置图片方式的仍然在UITrackingRunLoopMode中，如果图片比较大，解压缩和渲染肯定会很耗时，进而导致页面卡顿。我们可以使用方法[imageView performSelectorOnMainThread:@selector(setImg:) withObject:image waitUntilDone:NO modes:@[NSDefaultRunLoopMode]]来将图片设置的方法放在NSDefaultRunLoopMode的运行模式下，为了流畅性，把图片加载延迟。


## RunLoop
### 面试题
1. 讲讲RunLoop,项目中有用到吗?
2. Runloop内部实现逻辑
3. RunLoop和线程的关系
4. timer和RunLoop关系
* 从结构上来说,RunLoop中包含多个模式mode,每个模式mode下会有一个timer; 运行逻辑来说,timer的处理是在RunLoop中执行的
5. 程序中添加每3秒响应一次的NSTimer,当拖动tableview时,timer可能无法响应怎么解决?
6. runloop是怎么响应用户操作的,具体流程是什么样的?
* 用户点击屏幕后,首先是Sources1捕获到了该事件,Sources1会将该事件包装到EventQueue事件队列中,交给Sources0处理,即Sources1负责捕获,Sources0来处理
7. 说说RunLoop的几种状态
* 6种状态: 进入Loop、退出Loop、即将处理Timers、即将处理Sources、即将开始休眠、从休眠中唤醒
8. RunLoop的mode作用是什么
* mode模式可以将不同的Sources/Timers/Observers隔离开来,这样相互之间都不会影响,并且当我们切换mode模式时,其他mode不会被影响,操作起来更加流程,只会专注于处理当前的模式mode

### 1. 什么是RunLoop
#### RunLoop就是运行循环,在程序运行过程中循环做一些事情,做了哪些事情?应用范畴是? 可以通过断点，控制台输入bt来查看调用栈
1. 定时器(NSTimer)、performSelector:withObject:afterDelay:
        
        NSLog(@"------start");
        [self performSelector:@selector(test) withObject:nil afterDelay:0];
        NSLog(@"------end");
        打印顺序：1.start--2.end--3.test任务 原因是：需要等到RunLoop在当次Loop到来时才会去处理

2. GCD Async Main Queue

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        });
3. 事件响应、手势识别、界面刷新
4. 网络请求
5. AutoreleasePool自动释放池

#### 如果没有RunLoop程序会立马退出; 如果有RunLoop,程序并不会马上退出,而是保持运行状态,RunLoop基本作用有
1. 保持程序的持续运行
2. 处理APP中的各种事件(比如触摸事件、定时器事件)
3. 节省CPU资源,提高程序性能: 该做事时做事,该休息时休息
4. RunLoop其实内部类似个do-while循环

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
1. CFRunLoopRef: 是一个CFRunLoop结构体的指针，负责运行循环，处理事件，保持运行
2. CFRunLoopModeRef: 代表RunLoop的运行模式，模式下对应多个处理源
3. CFRunLoopSourceRef: [Source0触摸事件处理/ Source1基于Port的线程间通信]
4. CFRunLoopTimerRef: NSTimer的运用
5. CFRunLoopObserverRef: 用于监听RunLoop的状态，UI刷新，自动释放池

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
* 如果需要切换Mode,只能退出当前Loop,再选择一个Mode进入(这里的退出并不是退出RunLoop循环,而是在RunLoop循环中退出当前的这次循环,所以不会导致程序退出)
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

#### ⚠️: RunLoop开始休眠时,会阻塞当前线程,但这种阻塞并不是一直在等待(并不是while循环),不会消耗CPU资源,而是RunLoop从用户态切换到了内核态(通过mach_msg函数),内核态是系统层API控制的,实际上RunLoop的休眠和唤醒就是RunLoop在用户态和内核态之间的切换

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
        //kCFRunLoopCommonModes: 默认包含 kCFRunLoopDefaultMode + UITrackingRunLoopMode
        //1.创建observer
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault,  
        kCFRunLoopAllActivities, YES, 0, CFRunLoopObserverCallBack1, NULL);
        //1.1 创建observer的第二种方法: 将监听方法放到Block中去
        CFRunLoopObserverRef observer1 = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,  
        kCFRunLoopAllActivities,YES,0,^(CFRunLoopObserverRef observer, CFRunLoopActivity activity){
        });
        
        //2.添加observer到RunLoop
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
        
        //3.释放observer
        CFRelease(observer);
    }
        
    // 监听到RunLoop状态改变
    void CFRunLoopObserverCallBack1(CFRunLoopObserverRef observer,CFRunLoopActivity activity,void *info){
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
        /*这种创建线程的方式+ NSRunLoop的run方法 会导致循环引用: 
        VC->Thread(属性)  Thread->VC(initWithTarget:self)
        */
        self.thread=[[WGThread alloc]initWithTarget:self selector:@selector(task) object:nil];
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
#### 这种方式虽然会保住线程不死，但是会导致线程和VC之间的循环引用, [[NSRunLoop currentRunLoop] run]方法没有任务时会一直让线程处于休眠状态，导致线程无法释放  而initWithTarget:self中线程又强引用了VC，导致VC也无法释放
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
        [self performSelector:@selector(task) onThread:self.thread  
        withObject:nil waitUntilDone:NO];
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
#### NSRunLoop中的run方法是无法停止的,它专门用于开启一个永不销毁的线程
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
#### 调用runMode: beforeDate:方法后, 当任务执行完成后, 直接就打印了这个信息:-----end-----, 说明这种方式下,当任务执行完成后,RunLoop就直接退出了, 不能保活线程了,即CFRunLoopStop方法会停止runMode这一次的循环

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

#### 口述线程保活的过程：创建一个继承自NSObject的类，在初始化时通过block的方式创建线程，并在block中通过向RunLoop中添加NSPort端口并通过runMode: beforeDate:方法来保活线程，然后声明一个属性来控制线程何时销毁，注意的是销毁线程的方法要在当前即将销毁的子线程中去销毁，并且在销毁时将线程置为nil,主要就是为了防止在停掉RunLoop后，线程已经不能再用了，可能会再次调用一个不能用的线程去做事情，CFRunLoopStop()方法是不能停掉run方法开启的循环的，但是可以关闭runMode: beforeDate:方法开启的当次线程；其实如果我们通过C语言的CFRunLoopRunInMode方法开启RunLoop的话，就不需要额外声明一个属性和while循环来控制线程的销毁了，因为这个方法的第三个参数设置为false就可以保证Loop不会退出，并且CFRunLoopStop()方法也可以停止掉这个方法
