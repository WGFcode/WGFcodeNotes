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

### 2.2 验证：线程中任务执行完成后，线程销毁
        //.h文件
        @interface WGThread : NSThread
        @end

        @interface WGMainObjcVC : UIViewController
        @end

        //.m文件
        @implementation WGThread
        -(void)dealloc {
            NSLog(@"线程消失了");
            NSRunLoop *loop = [NSRunLoop currentRunLoop];
            NSRunLoop *mainLoop = [NSRunLoop mainRunLoop];
            NSLog(@"当前的RunLoop对象:%p,主线程的RunLoop:%p",[NSRunLoop currentRunLoop],[NSRunLoop mainRunLoop]);
        }
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            WGThread *thread = [[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
            [thread start];
        }
        -(void)change {
            NSLog(@"---------10---------");
            NSLog(@"当前的RunLoop对象:%p,主线程的RunLoop:%p",[NSRunLoop currentRunLoop],[NSRunLoop mainRunLoop]);
        }
        @end

        打印结果：---------10---------
                当前的RunLoop对象:0x6000012c9fe0,主线程的RunLoop:0x6000012d4960
                线程消失了
                当前的RunLoop对象:0x8c8c8c8c8c8c8c8c,主线程的RunLoop:0x6000012d4960
#### 分析: 从打印结果可以看出，当线程中的任务执行完成后，线程就会销毁，同时线程对应的RunLoop对象也会随之销毁(虽然打印的地址是0x8c8c8c8c8c8c8c8c，但如果打印它的对象信息会发现里面什么内容都没有)


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
        
        CFRunLoopObserverRef这是一个观察者，主要用途就是监听RunLoop的状态变化
        /* Run Loop Observer Activities */
        typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
            kCFRunLoopEntry = (1UL << 0),                即将进入RunLoop
            kCFRunLoopBeforeTimers = (1UL << 1),         即将处理Timers
            kCFRunLoopBeforeSources = (1UL << 2),        即将处理Sources
            kCFRunLoopBeforeWaiting = (1UL << 5),        即将进入休眠
            kCFRunLoopAfterWaiting = (1UL << 6),         刚从休眠中唤醒
            kCFRunLoopExit = (1UL << 7),                 即将推出RunLoop
            kCFRunLoopAllActivities = 0x0FFFFFFFU
        };
#### 分析：一个Runloop对象包含若干个mode，每个mode又包含若干个sources0/sources1/observers/timers；当启动一个Runloop时会先指定一个model作为currentMode，然后检查这个指定的mode是否存在以及mode中是否含有Source和Timer，如果mode不存在或者Mode中无Source和Timer，认为该Mode是个空的Mode,RunLoop就直接退出
    
    
### 4.RunLoop在项目中应用场景
* 控制线程的声明周期（线程保活）
* 解决NSTimer在滚动的时候停止的问题
* 监控应用卡顿
* 性能优化

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
            WGThread *thread = [[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
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
            self.thread = [[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
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
            [self performSelector:@selector(newChange) onThread:self.thread withObject:nil waitUntilDone:NO];
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
            self.thread = [[WGThread alloc]initWithTarget:self selector:@selector(change) object:nil];
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
            [self performSelector:@selector(newChange) onThread:self.thread withObject:nil waitUntilDone:NO];
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
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    }
                    NSLog(@"线程中任务执行完成");
                }];
            } else { // Fallback on earlier versions }
            [self.thread start];
            UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
            stopBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:stopBtn];
            [stopBtn addTarget:self action:@selector(clickStopBtn) forControlEvents:UIControlEventTouchUpInside];
        }

        -(void)clickStopBtn {
            /*
             🤔思考:为什么要放到self.thread执行停止Runloop的任务？
             因为一个线程对应一个Runloop对象，而我们要停止的是self.thread这个线程对应的Runloop对象
             如果直接在这个方法中写停止Runloop，停止的是主线程中对应的Runloop对象
             */
            NSLog(@"点击了停止Runloop的按钮");
            [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }

        -(void)stopRunLoop {
            self.isStop = YES;
            //系统提供的停止RunLoop的方法
            CFRunLoopStop(CFRunLoopGetCurrent());
        }

        //向self.thread线程中添加任务
        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [self performSelector:@selector(newChange) onThread:self.thread withObject:nil waitUntilDone:NO];
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
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/runloop1.png)

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
                        //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
                        //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    }
                    NSLog(@"线程中任务执行完成");
                }];
            } else { /*Fallback on earlier versions*/ }
            [self.thread start];
        }
        -(void)dealloc {
            [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:NO];
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
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
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
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
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
            [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:YES];
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
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
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
                [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:YES];
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
        //@property(nonatomic, strong) NSThread *thread;   这里可直接使用NSThread，使用WGThread只是为了验证线程是否销毁
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
                            //如果当前线程下有在NSDefaultRunLoopMode运行模式下的事件，那么RunLoop就会启动并去处理；如果没有事件，那么RunLoop就会处于休眠状态并在每过(多长时间)去启动一次该线程下的RunLoop
                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
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
                //此方法可以传递参数，将参数放在withObject中;waitUntilDone:NO处理任务的时候，这里不需要等待子线程中的任务执行完成，即仍然异步执行
                [self performSelector:@selector(privateHandleEventInThread:) onThread:self.thread withObject:handle waitUntilDone:NO];
            }
        }
        -(void)privateHandleEventInThread:(WGHandle)handle{
            handle();
        }

        //停止当前线程对应的RunLoop循环并销毁线程
        -(void)stopRunLoop {
            if (self.thread != nil) {
                [self performSelector:@selector(privateStop) onThread:self.thread withObject:nil waitUntilDone:YES];
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
            self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 80, UIScreen.mainScreen.bounds.size.width, 300)];
            self.scrollView.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height * 2);
            self.scrollView.delegate = self;
            self.scrollView.backgroundColor = [UIColor redColor];
            [self.view addSubview:self.scrollView];
            
            //定时器启动方式一：需要手动将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下
            self.timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
            [self.timer fire];
            /*定时器启动方式二：默认将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下了
            self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
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
            self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 80, UIScreen.mainScreen.bounds.size.width, 300)];
            self.scrollView.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height * 2);
            self.scrollView.delegate = self;
            self.scrollView.backgroundColor = [UIColor redColor];
            [self.view addSubview:self.scrollView];
            
            //定时器启动方式一：需要手动将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下
            self.timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
            //[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
            //将定时器添加到RunLoop运行循环中的NSRunLoopCommonModes运行模式下
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
            [self.timer fire];
    
            /*定时器启动方式二：默认将定时器添加到RunLoop中的NSDefaultRunLoopMode运行模式下了
            self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
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

### 4.3 监控应用卡顿

#### 引起页面卡顿的原因分析：
* 复杂 UI 、图文混排的绘制量过大
* 在主线程上做网络同步请求或者大量的 IO 操作
* 运算量过大，CPU 持续高占用
* 死锁和主子线程抢锁

#### FPS(Frames Per Second)指画面每秒传输的帧数，每秒传输的帧数越多，所显示的动作或画面就会越流畅，通俗理解成画面“刷新率”(单位是Hz)。FPS值越低就越卡顿，iOS中正常的屏幕刷新率是60Hz,即每秒60次，一般保持在50～60Hz就可以保证有流畅的体验了。**CADisplayLink**可以用来检测FPS的，但是这个只能用来检测app的FPS值，并不能准确定位到哪个方法/页面出现了卡顿，所以我们要利用RunLoop的原理来进行检测

#### RunLoop检测卡顿主要是监控RunLoop的状态来判断是否会出现卡顿；我们需要监测的状态有两个：RunLoop在进入睡眠之前和唤醒后的两个loop状态定义的值，分别是kCFRunLoopBeforeSources 和 kCFRunLoopAfterWaiting
        CFRunLoopObserverRef这是一个观察者，主要用途就是监听RunLoop的状态变化
        /* Run Loop Observer Activities */
        typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
            kCFRunLoopEntry = (1UL << 0),                进入RunLoop
            kCFRunLoopBeforeTimers = (1UL << 1),         (即将处理Timers)触发 Timer 回调
            kCFRunLoopBeforeSources = (1UL << 2),        (即将处理Sources)触发 Source0 回调
            kCFRunLoopBeforeWaiting = (1UL << 5),        (即将进入休眠)等待 mach_port 消息
            kCFRunLoopAfterWaiting = (1UL << 6),         (刚从休眠中唤醒)接收 mach_port 消息
            kCFRunLoopExit = (1UL << 7),                 退出RunLoop
            kCFRunLoopAllActivities = 0x0FFFFFFFU        loop 所有状态改变
        };
#### 检测卡顿步骤 (https://www.cnblogs.com/qiyiyifan/p/11089735.html)
* 创建一个RunLoop的观察者(CFRunLoopObserverContext)
* 把观察者加入主线程的kCFRunLoopCommonModes模式中，以监测主线程
*  创建一个持续的子线程来维护观察者进而用来监控主线程的RunLoop状态；
* 根据主线程RunLoop的状态来判断是否卡顿。一旦发现进入睡眠前的 kCFRunLoopBeforeSources 状态，或者唤醒后的状态 kCFRunLoopAfterWaiting，在设置的时间阈值内一直没有变化，即可判定为卡顿；
* dump 出堆栈的信息，从而进一步分析出具体是哪个方法的执行时间过长；

























































### 4.4 性能优化
