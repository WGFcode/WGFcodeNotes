### 内存管理
### 1.面试题
#### 1.1. 使用CADisplayLink、NSTimer有什么注意点
    #### CADisplayLink、NSTimer会对targe产生强引用，如果target又对它们产生强引用，那么就会发生循环引用
    @interface WGMainObjcVC()
    @property(nonatomic, strong) CADisplayLink *link;
    @property(nonatomic, strong) NSTimer *timer;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        
        //CADisplayLink其实也是个定时器，区别就是不需要设置时间，保证调用频率和屏幕的刷帧频率一致，60FPS
        //self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkTest)];
        //[self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        //开启定时器方式一
        //self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(test) userInfo:nil repeats:YES];
        //[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        //开启定时器方式二
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(test) userInfo:nil repeats:YES];
    }

    -(void)test {
        NSLog(@"%s",__func__);
    }

    -(void)dealloc {
        //[self.link invalidate];
        [self.timer invalidate];
    }
    
    打印结果： -[WGMainObjcVC test]
             -[WGMainObjcVC test]
             ......
#### 即使页面销毁了，定时器中的任务仍然会调用，因为self强引用了CADisplayLink/NSTimer,而CADisplayLink/NSTimer又强引用了target:self,导致了循环引用。
#### 解决方案一： 利用Block的方式创建定时器，然后通过__weak弱引用来解决循环引用问题
        //这种创建定时器的方式利用__weak不能解决循环引用问题
        //因为无论target:的参数传递self还是weakSelf，都是传递个指针给target,
        //而NStimer/CADisplayLink内部都会对传递进来的target参数进行强引用的，__weak是用来解决Block循环引用的。
        __weak typeof(self) weakSelf = self;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(test) userInfo:nil repeats:YES];
        
        //利用Block方式创建定时器，利用__weak是可以解决循环引用问题的
        __weak typeof(self) weakSelf = self;
        //NSTimer强引用者Block，而Block对self是弱引用的，所以可以解决循环引用问题
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [weakSelf test];
        }];
#### 解决方案二：新建一个对象(让对象来弱引用self)，作为NSTimer/CADisplayLink的target参数，那么这个对象就要实现定时器的任务，为了让self实现定时器任务，在这个对象内部进行消息转发，将消息转发给self来解决循环引用问题
        //WGTargetProxy.h文件
        @interface WGTargetProxy : NSObject
        @property(nonatomic, weak) id target;
        +(instancetype)proxyWithTarget:(id)target;
        @end
        
        //WGTargetProxy.m文件
        @implementation WGTargetProxy
        +(instancetype)proxyWithTarget:(id)target {
            WGTargetProxy *proxy = [[WGTargetProxy alloc]init];
            proxy.target = target;
            return proxy;
        }
        //转发消息给target
        - (id)forwardingTargetForSelector:(SEL)aSelector {
            return self.target;
        }
        @end
        
        //利用添加的对象来作为target,target对self进行弱引用，然后在添加的对象中，对方法进行消息转发，转发给self
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[WGTargetProxy proxyWithTarget:self] selector:@selector(test) userInfo:nil repeats:YES];
    
#### 解决方案三: 创建一个继承自NSProxy的类，然后直接进行消息转发.NSProxy类似于NSObject，是基类，主要用来做消息转发。效率高，因为它不是继承自NSObject的，所以当调用一个不存在的方法时，避免了去父类中查找的过程，而是直接进行消息转发
        //WGTargetProxy.h文件
        @interface WGTargetProxy : NSProxy
        @property(nonatomic, weak) id target;
        +(instancetype)proxyWithTarget:(id)target;
        @end
    
        //WGTargetProxy.m文件
        @implementation WGTargetProxy
        +(instancetype)proxyWithTarget:(id)target {
            //继承自NSProxy类的对象没有init方法
            WGTargetProxy *proxy = [WGTargetProxy alloc];
            proxy.target = target;
            return proxy;
        }
        - (void)forwardInvocation:(NSInvocation *)invocation {
            [invocation invokeWithTarget:self.target];
        }
        -(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
             return [self.target methodSignatureForSelector:sel];
        }
        @end
    
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[WGTargetProxy proxyWithTarget:self] selector:@selector(test) userInfo:nil repeats:YES];
#### ⚠️知识点：如果是继承自NSProxy的对象，如果调用这个对象的isKindOfClass,那么就是会进入消息转发，会让这个对象的target去执行。例如：
        //继承自NSProxy
        WGTargetProxy *proxy1 = [WGTargetProxy1 proxyWithTarget:self];
        //继承自NSObject
        WGTargetProxy *proxy2 = [WGTargetProxy2 proxyWithTarget:self];
        NSLog(@"继承自NSProxy---%d\n 继承自NSObject---%d\n",[proxy1 isKindOfClass:[self class]],[proxy2 isKindOfClass:[self class]]);
    
        打印结果：继承自NSProxy---1
                继承自NSObject---0
    
#### 1.2 NSTimer为什么不准时？有什么方法来保证定时器的准时哪？
#### 因为NSTimer是依赖于RunLoop的，如果RunLoop的任务过重，即NSTimer事件需要等待RunLoop处理其他的事情，处理完了才会来处理NSTimer事件，所以才会导致NSTimer不准时。想保证定时器任务的准时，可以使用GCD定时器，因为GCD定时器是不依赖Runloop的，它是直接和系统内核挂钩的
#### 1.3 GCD定时器
    
    @interface WGMainObjcVC()
    //必须强引用这个定时器，否则定时器是不会工作的
    @property(nonatomic, strong) dispatch_source_t timer;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        NSLog(@"-------begin-------");
        //创建队列:主队列就是在主线程下，非主队列都是在子线程中
        dispatch_queue_t queue = dispatch_get_main_queue();
        //1. 创建定时器
            参数1：源的类型 参数2/参数3: 直接传递0即可 参数4:设置定时器运行的队列
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        //2. 设置时间
            参数1: 设置哪个定时器  参数2: 开始时间，必须是dispatch_time(参数1,开始的时间) NSEC_PER_SEC：纳秒
            参数3: 间隔多长时间执行一次定时器任务  参数4: 误差，设置为0即可
        NSTimeInterval start = 3.0;
        NSTimeInterval interval = 1.0;
        dispatch_source_set_timer(self.timer,
                                  dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC),
                                  interval * NSEC_PER_SEC,
                                  0);
        //3. 设置定时器回调方法
        dispatch_source_set_event_handler(self.timer, ^{
            NSLog(@"1111--current Threaad:%@",[NSThread currentThread]);
        });
        //设置定时器回调方法二：通过Block方式
        //dispatch_source_set_event_handler_f(self.timer, timerTest);
        //4. 启动定时器
        dispatch_resume(self.timer);
    }
    
    //typedef void (*dispatch_function_t)(void *_Nullable);
    void timerTest(void* paramer) {
        NSLog(@"1111--current Threaad:%@",[NSThread currentThread]);
    }

    @end
    
    打印结果: 16:00:23.706883+0800 -------begin-------
            16:00:26.708723+0800  1111--current Threaad:<NSThread: 0x2825a20c0>{number = 1, name = main}
            16:00:27.708869+0800  1111--current Threaad:<NSThread: 0x2825a20c0>{number = 1, name = main}
            16:00:28.708798+0800  1111--current Threaad:<NSThread: 0x2825a20c0>{number = 1, name = main}
            16:00:29.708184+0800  1111--current Threaad:<NSThread: 0x2825a20c0>{number = 1, name = main}
    当页面返回时，定时器打印任务结束
#### 分析：我们通过GCD创建的定时器，是不依赖于RunLoop的，所以它的定时时间是准确的，那么如果我们在页面中添加个滚动视图去触摸滚动时，定时器任务是不会停止的，因为GCD创建的定时器和RunLoop没有任何关系，不会存在像NSTimer运行在RunLoopMode导致的实效问题；GCD创建的定时器不存在循环引用的问题，因为GCD内部已经做了处理了。GCD创建的定时器既可以同步执行也可以异步执行

#### 1.4 项目中利用GCD封装定时器
#### 详情见工程项目中的**WGGCDTimer**
    
### 2.介绍下内存的几大区域
#### 2.1 iOS内存布局,后续自己验证
     低地址   
       |   [保留地址]
       |   [代码段(_TEXT)]: 编译之后的代码
       |   [数据段(_DATA)]: 
       |           字符串常量: 比如 NSString *str = @"123"
       |           已初始化数据:已初始化的全局变量、静态变量
       |           未初始化数据:未初始化的全局变量、静态变量
       |   [堆(heap)] : 通过alloc、malloc、calloc等动态分配的空间,分配的内存地址越来越大
       |               堆分配地址是由低到高
       |   [栈(stack)]: 函数调用开销,函数中的局部变量(不管是否初始化)都是放在栈上的,分配的内存地址越来越小
       |               栈分配地址是由高到低
       |   [内核区]
       |
     高地址
#### 2.2   Tagged Pointer技术
#### 从64bit开始,iOS引入了Tagged Pointer技术,用来优化NSNumber、NSDate、NSString等小对象的存储.
1.  在没有使用Tagged Pointer技术前,NSNumber等对象就是普通的OC对象,需要动态分配内存,维护饮用计数等,NSNumber的指针存储的是堆中NSNumber对象的地址值; 
2. 使用Tagged Pointer技术后, NSNumber指针里面存储的数据变成了: Tag(类型标记)+Data(值),也就是直接将数据存储到了指针中

        // 这两行代码完全一样
        NSNumber *number = [NSNumber numberWithInt:10];
        NSNumber *number = @10; 

        //没有使用 Tagged Pointer技术前
        0x10010101                       内存地址: 0x10010101
        number       ------------->    NSNumber对象
                                       存储值10
        //使用 Tagged Pointer技术后
        number = 0xb0000a1   (a代表10 1代表类型)
3. 当指针(Tagged Pointer)不够存储数据时,才会使用动态分配内存的方式来存储数据
4. objc_msgSend能识别Tagged Pointer,比如NSNumber的intValue方法,直接从指针提取数据,节省了以前的调用开销
5. 如何判断一个指针是否是Tagged Pointer? iOS平台,最高有效位是1(第64位); Mac平台,最低有效位是1

        
#### 2.2.1 有关Tagged Pointer面试题
        // 下面两种方式会出现什么问题
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        for (int i = 0; i < 1000; i++) {
            dispatch_async(queue, ^{
                self.name = [NSString stringWithFormat:@"abcdefghijk"];
            });
        }

        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        for (int i = 0; i < 1000; i++) {
            dispatch_async(queue, ^{
                self.name = [NSString stringWithFormat:@"abc"];
            });
        }


        @interface WGMainObjcVC()
        @property(nonatomic, copy) NSString *name;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];

            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            for (int i = 0; i < 1000; i++) {
                dispatch_async(queue, ^{
                    self.name = [NSString stringWithFormat:@"abcdefghijk"];
                });
            }
        }
        运行直接报错: Thread 4: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
#### 分析, 我们知道self.name实际上调用的是name属性的setter方法,ARC环境下,是系统帮我们添加了release/retain操作,实际在MRC环境下setter方法的伪代码如下, 案例中是多个线程中调用name属性的setter方法,那么就存在同一时间多个线程调用[_name release]方法,即_name可能会被释放多次,所以就会到导致错误(坏内存访问),而无论修饰符是strong还是copy,都会执行[_name release]这句代码,
        -(void)setName:(NSString *)name {
            if (_name != name) {  //如果传进来的属性值和之前不一样,就先将旧值release,然后在赋值
                [_name release];
                _name = [name retain];   //name属性修饰符是strong
                //_name = [name copy];   //name属性修饰符是copy
            }
        }
#### 解决方案: 
* 方案一: 将修饰name属性的nonatomic非原子属性改为atomic原子属性,这样在setter方法时就会有加锁解锁,就可以保证线程访问安全,即同一时间只有一个线程访问. (不推荐)如果其他地方也调用了self.name,而加锁解锁会消耗性能,所以不推荐使用
* 方案二: 直接在对name属性赋值的前后进行加锁/解锁操作即可

        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        for (int i = 0; i < 1000; i++) {
            dispatch_async(queue, ^{
                self.name = [NSString stringWithFormat:@"abc"];
            });
        }
        NSString *str1 = [NSString stringWithFormat:@"abcdefghijk"];
        NSString *str2 = [NSString stringWithFormat:@"abc"];
        NSLog(@"str1: ----%@ str2:---- %@",[str1 class],[str2 class]);
        
        正常运行并打印
        str1: ----__NSCFString str2:---- NSTaggedPointerString
        
#### 分析: 因为字符串值是abc, 直接是用Tagged Pointer技术存储的,所以它不是OC对象,不会去调用属性name的setter方法
        
#### 2.3 Tagged Pointer源码分析

        objc_release(id obj){
            if (!obj) return;
            //在realse销毁对象时,如果对象是TaggedPointer直接返回,不做销毁操作,因为它并不是一个OC对象
            if (obj->isTaggedPointer()) return;  
            return obj->release();
        }
        
        objc_object::isTaggedPointer() {
            return _objc_isTaggedPointer(this);
        }
        
        #if OBJC_MSB_TAGGED_POINTERS   //iOS开发,将1向左移63位(指针的最高有效位是1,就是TaggedPointer)
        #define _OBJC_TAG_MASK (1UL<<63)  
        #else  //Mac开发(指针的最低有效位是1,就是TaggedPointer)
        #define _OBJC_TAG_MASK 1UL
        
        //如果 指针&_OBJC_TAG_MASK = _OBJC_TAG_MASK 就是TaggedPointer
        _objc_isTaggedPointer(const void * _Nullable ptr) {
            return ((uintptr_t)ptr & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
        }
        
### 3. OC对象内存管理
#### 3.1 在iOS中,利用**引用计数**来管理OC对象中的内存;
* 一个新创建的OC对象,引用计数默认是1,当引用计数减为0时,OC对象就会销毁,释放其占用的内存空间;
* 调用retain会让OC对象的引用计数+1,调用release会使对象的引用计数-1;
* 当调用alloc、new、copy、mutableCopy方法返回了一个对象,在不需要这个对象时,需要调用release或autorelease来释放
* 想拥有某个对象,就让它的引用计数+1; 不想再拥有某个对象,就让它的引用计数-1


#### 接下来我们关闭ARC(Build Settings -> Objective-C Automatic Reference Counting ->NO(默认是YES,即ARC)),在MRC下验证

        //WGPerson.m文件
        @implementation WGPerson
        -(void)dealloc {
            [super dealloc];
            NSLog(@"----%s",__func__);
        }
        @end

        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                //内存泄漏: 该释放的对象没有释放
                //WGPerson *p = [WGPerson new];
                WGPerson *p = [[WGPerson alloc]init];
                NSLog(@"%ld", [p retainCount]);
                [p release];
            }
            return 0;
        }

        打印结果: 1
                -----[WGPerson dealloc]
#### 每次创建一个OC对象,都需要在不使用时,调用release进行释放; 另外还有一个释放对象的方法autorelease,该方法好处就是开发者不需要去担心调用对象的方法/属性是在release方法前还是后的问题, 如果使用release进行释放,在release方法后是不能对对象进行操作的,因为对象已经销毁了,再调用对象的属性/方法会报错, 而

        WGPerson *p = [[[WGPerson alloc]init] autorelease];
        NSLog(@"%ld", [p retainCount]);
        
        打印结果: 1
                -----[WGPerson dealloc]
#### 3.2 在OC中各个对象之间是有联系的(WGPerson对象拥有WGDog狗对象),所以涉及到MRC下内存管理方法总结,一般在MRC下我们写setter方法和销毁对象方法是这样的

        @interface WGPerson : NSObject
        {
            WGDog *_dog;
        }
        -(void)setDog:(WGDog *)dog;
        -(WGDog *)dog;
        @end

        @implementation WGPerson
        //MRC下,判断不是同一个对象,先对原来的对象进行release,然后再对传进来的对象进行retain
        -(void)setDog:(WGDog *)dog {
            if (_dog != dog) {
                [_dog release];
                _dog = [dog retain];
            }
        }
        -(WGDog *)dog {
            return _dog;
        }

        -(void)dealloc {
            [_dog release];
            _dog = nil;
            //上面两行代码也可以换成下面的,调用的是setDog方法
            self.dog = nil
            //父类的dealloc放到最后
            [super dealloc];
            NSLog(@"----%s",__func__);
        }
        @end

#### 3.3 在MRC环境下,   @synthesize 属性 = _属性名称; 会自动生成成员变量和属性的setter/getter实现
    @interface WGPerson : NSObject
    //MRC下声明属性,之前仅仅是声明了属性的setter/getter方法,后面编译器做了优化,也对属性的setter/getter方法做了实现
    @property(nonatomic, assign) int age;
    @end

    @implementation WGPerson
    //自动生成成员变量和属性的setter/getter实现,后面编译器做了优化,也对属性的setter/getter方法做了实现,所以后面也可以不用写了
    @synthesize age = _age;
    @end
    
    
    @property(nonatomic, assign) int age;
    @property(nonatomic, retain) WGDog *dog;
    
    在MRC下系统帮我们生成了对应的setter方法如下,但是不会生成dealloc方法,dealloc方法还是需要我们手动去写的
    -(void)setAge:(int)age {
        _age = age;
    }

    -(void)setDog:(WGDog *)dog {
        if (_dog != dog) {
            [_dog release];
            _dog = [dog retain];
        }
    }
#### 可以看出assign/retain的区别,assign针对的是基本数据类型,它的setter方法是直接赋值;而retain修饰是针对对象的,它的setter方法会先对旧的对象进行release,然后再对新的对象进行retain,会使引用计数+1

#### 在MRC下只要不是alloc、new、malloc开头的创建对象,都不需要手动去调用release,例如下面的,因为它们在调用对用的创建方法时,系统已经帮我们做了autorelease操作 
        NSMutableArray *arr = [NSMutableArray array];
        NSDictionary *dic = [NSDictionary dictionary];

#### 3.4 copy 和 mutableCopy
#### 拷贝的目的: 就是产生一个副本.跟源对象互不影响.修改了源对象,不影响副本对象; 修改了副本对象,不影响源对象. iOS提供了两种拷贝方法: 
1. copy: 不可变拷贝,产生不可变副本; 
2. mutableCopy: 可变拷贝, 产生可变副本;

#### 3.4.1 在MRC环境下,当我们通过alloc、new、copy、mutableCopy等方法产生的对象,我们需要负责释放的,如下
        //通过这种方式创建的字符串,在MRC下,系统已经帮我们自动插入了autorelease,所以不需要我们再手动调用releas方法了
        //注意:这里如果写的字符串值比较小,就会用到TaggedPointer计数,那么它的引用计数值会是-1,不利于我们观察对象的引用计数
        //NSString *str0 = [NSString stringWithFormat:@"123sdfasdfsfsf"];
        NSString *str1 = [[NSString alloc]initWithFormat:@"123sdfasdfsfsf"];
        NSString *str2 = [str1 copy];
        NSMutableString *str3 = [str1 mutableCopy];

        NSLog(@"\nstr1:%p\nstr2:%p\n:str3:%p\n",str1,str2,str3);
        [str3 release];
        [str2 release];
        [str1 release];

        打印结果: str1:0x102045a90
                str2:0x102045a90
                :str3:0x102046150
#### 分析,为什么str1和str2的地址值是一样的? copy不是产生了副本对象吗? 原因就是源对象str1是不可变的,而通过copy后产生的副本对象也是不可变的,根据拷贝的准则: 修改源对象/副本对象不影响副本对象/源对象, 因为源对象本身就是不可变的,所以根本无法修改,为了节省空间,所以系统将str2的指针也指向了str1指针所指向的内容, 如果此时对str1或者str2赋新的值,那么它们的地址就会变成不一样的,因为拷贝的准则,所以系统会为str1和str2分配不同的地址空间


#### 3.4.2 深拷贝和浅拷贝
* 深拷贝: 内容拷贝,产生新的对象
* 浅拷贝: 指针拷贝,没有产生新的对象

        //源对象不可变
        NSString *str1 = [[NSString alloc]initWithFormat:@"123"]; 
        NSString *str2 = [str1 copy];                    //浅拷贝,没有产生新的对象
        NSMutableString *str3 = [str1 mutableCopy];      //深拷贝,产生新的对象

        //str1引用计数1   str2和str1指向同一个对象,所以此时的[str1 copy]就相当于[str1 retain],使引用计数+1  str3引用计数1

        //源对象可变
        NSMutableString *str1 = [[NSMutableString alloc]initWithFormat:@"123"];
        NSString *str2 = [str1 copy];                    //深拷贝,产生了新的对象
        NSMutableString *str3 = [str1 mutableCopy];      //深拷贝,产生了新的对象

#### 3.4.3 总结: 数组、字典与字符串仍然适用上面的方法
                             copy                         mutablecopy
       NSString              NSString-浅拷贝               NSMutableString-深拷贝 
       NSMutableString       NSString-深拷贝               NSMutableString-深拷贝
       NSArray               NSArray-浅拷贝                NSMutableArray-深拷贝
       NSMutableArray        NSArray-深拷贝                NSMutableArray-深拷贝
       NSDictionary          NSDictionary-浅拷贝           NSMutableDictionary-深拷贝
       NSMutableDictionary   NSDictionary-深拷贝           NSMutableDictionary-深拷贝


#### 3.4.4 案例分析
#### 在MRC环境下,下面声明的属性会自动生成对应的setter方法
        @interface WGPerson : NSObject
        @property(nonatomic, assign) int age;
        @property(nonatomic, retain) WGDog *dog;
        @property(nonatomic, copy) NSArray *arr;
        @end

        -(void)setAge:(int)age {
            _age = age;
        }
        -(void)setDog:(WGDog *)dog {
            if (_dog != dog) {
                [_dog release];
                _dog = [dog retain];
            }
        }
        -(void)setArr:(NSArray *)arr {
            if (_arr != arr) {
                [_arr release];
                _arr = [arr copy];
            }
        }
#### 下面代码是否有问题
        @interface WGPerson : NSObject
        @property(nonatomic, copy) NSMutableArray *arr;
        @end
        
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                WGPerson *p = [[WGPerson alloc]init];
                p.arr = [[NSMutableArray alloc]init];
                [p.arr addObject:@"123"];
                [p.arr addObject:@"456"];
                [p release];
            }
            return 0;
        }
        
        //MRC下系统为arr生成的setter方法实现
        -(void)setArr:(NSArray *)arr {
            if (_arr != arr) {
                [_arr release];
                _arr = [arr copy];
            }
        }
#### 分析: 上面代码会报错,因为声明的可变数组arr用的是copy修饰,它底层的setter方法调用的是copy方法,那么返回的数组对象就是不可变的,所以在进行[p.arr addObject:]方法调用时会报错:-[__NSArray0 addObject:]: unrecognized selector sent to instance 0x101801070, 那么可不可以用mutableCopy来修饰arr哪? 答案是肯定不可以,因为mutableCopy压根都不能用来作为属性修饰符. 所以总结一句话: 开发过程中不要用copy来修饰一个可变的数组,而是要修饰一个不可变的数组,这样开发过程中一旦调用了addObject方法,编译器就会直接检查然后报错

#### 3.4.5 OC对象的copy操作
#### OC对象如果想实现copy操作,那么需要实现NSCopying协议中的copyWithZone方法
        @interface WGPerson : NSObject<NSCopying>
        @property(nonatomic, copy) NSMutableArray *arr;
        @end

        -(id)copyWithZone:(NSZone *)zone {
            WGPerson *p = [[WGPerson allocWithZone:zone] init];
            p.arr = self.arr;
            return p;
        }

        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                WGPerson *p = [[WGPerson alloc]init];
                WGPerson *p1 = [p copy];
            }
            return 0;
        }

#### 3.5 **引用计数**存储方式
#### 在64bit中,引用计数可以直接存储在优化过的isa指针中,也可以存储在SideTable类中,见Runtime源码
        struct SideTable {
        spinlock_t slock;
        RefcountMap refcnts;       是一个存放着对象引用计数的散列表
        weak_table_t weak_table;
        ......
        }
        
#### 找到retainCount方法,我们详细看下引用计数是如何获取的
        - (NSUInteger)retainCount {
            return ((id)self)->rootRetainCount();
        }
        
        objc_object::rootRetainCount() {
            //判断是否是TaggedPointer,如果是直接返回(之前验证过,如果是TaggedPointer,那么引用计数就是-1)
            if (isTaggedPointer()) return (uintptr_t)this;  
            sidetable_lock();
            isa_t bits = LoadExclusive(&isa.bits);
            ClearExclusive(&isa.bits);
            if (bits.nonpointer) {      //优化过的isa指针
                uintptr_t rc = 1 + bits.extra_rc;
                if (bits.has_sidetable_rc) {  //如果引用计数不是存储在isa中,而是存储在sideTable结构中
                    rc += sidetable_getExtraRC_nolock();
                }
                sidetable_unlock();
                return rc;
            }
            sidetable_unlock();
            return sidetable_retainCount();
        }
        
        objc_object::sidetable_getExtraRC_nolock() {
            assert(isa.nonpointer);
            //通过key获取到一个value(对象的地址作为Key)
            SideTable& table = SideTables()[this];  
            // 将对象的地址this传给散列表,获取到对象对应的引用计数,然后返回
            RefcountMap::iterator it = table.refcnts.find(this);
            if (it == table.refcnts.end()) return 0;
            else return it->second >> SIDE_TABLE_RC_SHIFT;
        }
#### 查看release方法源码
        -(void) release {
            _objc_rootRelease(self);
        }

        _objc_rootRelease(id obj) {
            assert(obj);
            obj->rootRelease();
        }

        objc_object::rootRelease() {
            return rootRelease(true, false);
        }

        objc_object::rootRelease(bool performDealloc, bool handleUnderflow) { //简化后的
            if (isTaggedPointer()) return false;
            bool sideTableLocked = false;
                if (slowpath(!newisa.nonpointer)) {  //如果不是优化过的isa指针,那么就从sideTable里找
                    ClearExclusive(&isa.bits);
                    if (sideTableLocked) sidetable_unlock();
                    return sidetable_release(performDealloc);
                }
        }
        
        objc_object::sidetable_release(bool performDealloc) {
            //以对象的地址为key,从SideTables散列表中找到一个value
            SideTable& table = SideTables()[this];
            bool do_dealloc = false;
            table.lock();
            RefcountMap::iterator it = table.refcnts.find(this);
            if (it == table.refcnts.end()) {
                do_dealloc = true;
                table.refcnts[this] = SIDE_TABLE_DEALLOCATING;
            } else if (it->second < SIDE_TABLE_DEALLOCATING) {
                // SIDE_TABLE_WEAKLY_REFERENCED may be set. Don't change it.
                do_dealloc = true;
                it->second |= SIDE_TABLE_DEALLOCATING;
            } else if (! (it->second & SIDE_TABLE_RC_PINNED)) {
                it->second -= SIDE_TABLE_RC_ONE;    //减操作
            }
            table.unlock();
            //一旦上面引用计数-1,就有可能会减为0,所以就需要判断是否需要dealloc,如果需要,就通过objc_msgSend发送dealloc消息
            if (do_dealloc  &&  performDealloc) {
                ((void(*)(objc_object *, SEL))objc_msgSend)(this, SEL_dealloc);
            }
            return do_dealloc;
        }
#### 查看retain方法源码
        -(id) retain {
            return _objc_rootRetain(self);
        }

        _objc_rootRetain(id obj){
            assert(obj);
            return obj->rootRetain();
        }

        objc_object::rootRetain() {
            return rootRetain(false, false);
        }

        objc_object::rootRetain(bool tryRetain, bool handleOverflow) { //简化后的
            if (isTaggedPointer()) return (id)this;
                if (slowpath(!newisa.nonpointer)) {  //如果不是优化过的isa指针,那么就从sideTable里找
                    ClearExclusive(&isa.bits);
                    if (!tryRetain && sideTableLocked) sidetable_unlock();
                    if (tryRetain) return sidetable_tryRetain() ? (id)this : nil;
                    else return sidetable_retain();
                }
        }
        
        objc_object::sidetable_retain()
            //以对象的地址为key,从SideTables散列表中找到一个value
            SideTable& table = SideTables()[this];
            table.lock();
            size_t& refcntStorage = table.refcnts[this];
            if (! (refcntStorage & SIDE_TABLE_RC_PINNED)) {
                refcntStorage += SIDE_TABLE_RC_ONE;   //加操作
            }
            table.unlock();
            return (id)this;
        }
#### 3.6 weak指针的实现原理
        @implementation Person
        -(void)dealloc {
            NSLog(@"%s---",__func__);
        }
        @end

        - (void)viewDidLoad {
            [super viewDidLoad];
            NSLog(@"begin");
            {
                Person *person = [[Person alloc]init];
            }
            NSLog(@"end");
        }
        打印结果: begin
                -[Person dealloc]---
                end
#### 一旦出了{},person对象就会被销毁
        - (void)viewDidLoad {
            [super viewDidLoad];
            __strong Person *person1;    //__strong可以不写,因为默认都是强引用
            __weak Person *person2;
            __unsafe_unretained Person *person3;
            NSLog(@"begin");
            {
                Person *person = [[Person alloc]init];
                //1. person1是强引用,所以出了{},person对象并不会销毁,而是在viewDidLoad方法执行结束后销毁
                //所以打印结果是: begin  -->   end   --> -[Person dealloc]---
                //person1 = person;
                
                //2. person2是弱引用,所以出了{},person对象就销毁了
                //所以打印结果是: begin  -->   -[Person dealloc]---   -->   end
                //person2 = person;
                
                //3. person3也是弱引用,所以出了{},person对象就销毁了
                //所以打印结果是: begin  -->   -[Person dealloc]---   -->   end
                person3 = person;
                
                //4.__weak和__unsafe_unretained都是弱指针,区别就是__weak弱引用在对象销毁时,会对对象自动置为nil; 而__unsafe_unretained弱引用在对象销毁时,不会对对象自动置为nil,会出现野指针问题,即虽然对象销毁了,但是它的内存仍然存在,如果继续访问该对象,会导致坏内存访问
            }
            NSLog(@"end");
        }
#### 要想知道weak的原理,即对象销毁后,系统是如何对销毁的对象自动置为nil的,我们需要查看dealloc方法源码
        - (void)dealloc {
            _objc_rootDealloc(self);
        }

        _objc_rootDealloc(id obj) {
            assert(obj);
            obj->rootDealloc();
        }

        objc_object::rootDealloc() {
            if (isTaggedPointer()) return;  // fixme necessary?
            if (fastpath(isa.nonpointer  &&             //是否是优化过的isa指针
                         !isa.weakly_referenced  &&     //是否有弱引用表(取反)
                         !isa.has_assoc  &&             //是否有关联对象(取反)
                         !isa.has_cxx_dtor  &&          //是否有C++的析构函数(取反)
                         !isa.has_sidetable_rc)) {      //是否有sideTable(取反)
                assert(!sidetable_present());
                free(this);  //如果上面条件成立,直接释放,不需要其他查询,释放效率会更快
            } else {
                object_dispose((id)this);
            }
        }
        
        object_dispose(id obj) {
            if (!obj) return nil;
            objc_destructInstance(obj);    
            free(obj);   //释放对象前,先去忙其他事情(objc_destructInstance方法)
            return nil;
        }
        
        void *objc_destructInstance(id obj) {
            if (obj) {
                // Read all of the flags at once for performance.
                bool cxx = obj->hasCxxDtor();
                bool assoc = obj->hasAssociatedObjects();
                // This order is important.
                if (cxx) object_cxxDestruct(obj);            //清除成员变量
                if (assoc) _object_remove_assocations(obj);  //移除关联对象
                obj->clearDeallocating();                    //将指向当前对象的弱指针置为nil
            }
            return obj;
        }
        
        objc_object::clearDeallocating() {
            //是否是优化过的isa指针,如果不是(就是普通的isa指针),直接调用sidetable_clearDeallocating方法
            if (slowpath(!isa.nonpointer)) {  
                // Slow path for raw pointer isa.
                sidetable_clearDeallocating();
            } else if (slowpath(isa.weakly_referenced  ||  isa.has_sidetable_rc)) {  
                //判断是否有弱引用表
                // Slow path for non-pointer isa with weak refs and/or side table data.
                clearDeallocating_slow();
            }
            assert(!sidetable_present());
        }
        
        objc_object::clearDeallocating_slow(){
            //弱引用表也是一个散列表, 将对象的地址作为key,找到对应的value值,
            SideTable& table = SideTables()[this];
            table.lock();
            if (isa.weakly_referenced) {  //如果是弱引用表
                weak_clear_no_lock(&table.weak_table, (id)this);
            }
            if (isa.has_sidetable_rc) {
                table.refcnts.erase(this);
            }
            table.unlock();
        }
        
        weak_clear_no_lock(weak_table_t *weak_table, id referent_id)  {
            objc_object *referent = (objc_object *)referent_id;
            //根据对象的地址(key)找出对应的东西weak_entry_t
            weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
            ......
            //将找到的东西weak_entry_t从表中移除
            weak_entry_remove(weak_table, entry);
        }
        
        weak_entry_for_referent(weak_table_t *weak_table, objc_object *referent) {
            //将弱引用对象的地址 & weak_table->mask = 索引 (哈希表操作)
            size_t begin = hash_pointer(referent) & weak_table->mask;
        }
#### 总结: weak实现原理:将弱引用指针存到哈希表中,当弱引用对象销毁时,取出当前对象对应的弱引用表,将弱引用表中存储的弱引用都清楚掉并且置为nil

#### 3.7 ARC帮我们做了什么
1. ARC其实就是LLVM+RunTime系统相互协助的一个结果,
2. ARC利用LLVM编译器自动帮我们生成了release、retain、autorelease代码 
3. 像弱引用这样的存在,是需要运行时Runtime来支持的,由Runtime监控到对象销毁后,利用RunTime来销毁对象的


#### 3.8 autorelease原理
#### 在MRC环境下,我们探究下源码
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                WGPerson *p = [[[WGPerson alloc]init] autorelease];
            }
            return 0;
        }

        转为C++代码
        int main(int argc, const char * argv[]) {
            /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
                WGPerson *p = ((WGPerson *(*)(id, SEL))(void *)objc_msgSend)((id)((WGPerson *(*)(id, SEL))(void *)objc_msgSend)((id)((WGPerson *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("WGPerson"), sel_registerName("alloc")), sel_registerName("init")), sel_registerName("autorelease"));
            }
            return 0;
        }
        简化为
        {   
            __AtAutoreleasePool __autoreleasepool; 
            WGPerson *p = [[[WGPerson alloc]init] autorelease];
        }
#### 找到对应的结构体
        struct __AtAutoreleasePool {
            //C++构造函数,在创建结构体时调用
            __AtAutoreleasePool() { 
                atautoreleasepoolobj = objc_autoreleasePoolPush();
            }
            //C++析造函数,在结构体销毁时调用
            ~__AtAutoreleasePool() {
                objc_autoreleasePoolPop(atautoreleasepoolobj);
            }
            void * atautoreleasepoolobj;
        };
        
        {   
            //定义了局部变量,就会创建结构体__AtAutoreleasePool,所以会调用对应的构造函数,调用objc_autoreleasePoolPush
            __AtAutoreleasePool __autoreleasepool;   
            WGPerson *p = [[[WGPerson alloc]init] autorelease];
        }//当出了{}大括号,局部变量会销毁,所以调用析构函数,调用objc_autoreleasePoolPop方法
#### 分析, 一旦调用autorelease,会生成对应的结构体,刚开始时调用objc_autoreleasePoolPush方法,当结束时调用objc_autoreleasePoolPop方法,接下来我们通过RunTime源码来探究这两个方法及它的底层结构

        
#### 3.8.1 自动释放池的底层数据结构
1. 自动释放池的底层数据结构是__AtAutoreleasePool、AutoreleasePoolPage.
2. 调用autorelease的对象最终都是通过AutoreleasePoolPage对象来管理的
3. 每个AutoreleasePoolPage对象占用4096个字节的内存,除了用来存放它内部的成员变量(7个成员变量占56个字节),剩下的空间(4040个字节)用来存放autorelease对象的地址
4. 所有的AutoreleasePoolPage对象通过双向链表的形式连接在一起

        // push方法和AutoreleasePoolPage有关系
        objc_autoreleasePoolPush(void) {
            return AutoreleasePoolPage::push();
        }
        
        
        class AutoreleasePoolPage  {  //简化后的
            magic_t const magic;
            id *next;   //存放 下一个能存放autorelease对象 的地址
            pthread_t const thread;
            AutoreleasePoolPage * const parent;  //存放上一个AutoreleasePoolPage对象的地址,如果是第一个对象,则为nil
            AutoreleasePoolPage *child;  //存放下一AutoreleasePoolPage对象的地址,如果是最后一个对象,则为nil
            uint32_t const depth;
            uint32_t hiwat;
        }
        
        id * begin() { //存放autorelease对象的开始地址
            return (id *) ((uint8_t *)this+sizeof(*this));
        }

        id * end() {  //存放autorelease对象的结束地址
            return (id *) ((uint8_t *)this+SIZE);  //SIZE = 4096个字节
        }
#### 假如我们有1000个autorelease对象需要存储,它的存储过程是怎样的,1000个autorelease对象,用AutoreleasePoolPage对象来存储的,一个AutoreleasePoolPage对象存储4040个字节,而一个对象的地址占用8个字节,也就是需要8000个字节的空间来存储,那么就需要2个AutoreleasePoolPage对象才能存储的下
        for (int i = 0 ; i < 1000; i++) {
            WGPerson *p = [[[WGPerson alloc]init] autorelease];
        }
#### 3.8.2 存储过程
1. 当调用push时(此时next指针指向的就是可以存放对象的地址),会将**POOL_BOUNDARY**入栈,并且返回其存放的内存地址(此时next指针指向的就是挨着POOL_BOUNDARY地址的下一个地址空间),存放的位置假如说存放的是第一个AutoreleasePoolPage对象开始存放autorelease对象的开始地址

        atautoreleasepoolobj = objc_autoreleasePoolPush();
        假如存放POOL_BOUNDARY的地址为0x1038,那么atautoreleasepoolobj的地址就是0x1038

2. 当第一个对象调用autorelease方法时,会将第一个对象的地址存放在和POOL_BOUNDARY地址挨着的下一个内存空间
3. 依次循环存储,当第一个AutoreleasePoolPage的存储空间(4040个字节)占满时,就会继续创建第二个AutoreleasePoolPage对象来存储
4. 当循环结束时,会调用objc_autoreleasePoolPop方法,调用Pop方法时传入一个**POOL_BOUNDARY**的内存地址,然后会从最后一个入栈的对象开始,发送release方法,直到遇到**POOL_BOUNDARY**的地址,**POOL_BOUNDARY**其实就是一个标记

        //将POOL_BOUNDARY的地址传给pop方法
        objc_autoreleasePoolPop(atautoreleasepoolobj);

        #define POOL_BOUNDARY nil
        
        static inline void *push() {
            id *dest;
            if (DebugPoolAllocation) {
                // Each autorelease pool starts on a new pool page.
                dest = autoreleaseNewPage(POOL_BOUNDARY);
            } else {
                dest = autoreleaseFast(POOL_BOUNDARY);
            }
            assert(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
            return dest;
        }
        
#### 3.8.3 利用**extern void _objc_autoreleasePoolPrint(void)**函数可以查看自动释放池的情况
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                WGPerson *p1 = [[[WGPerson alloc]init] autorelease];
                WGPerson *p2 = [[[WGPerson alloc]init] autorelease];
                //_objc_autoreleasePoolPrint();
                @autoreleasepool {
                    for (int i = 0; i < 500; i++) {
                        WGPerson *p3 = [[[WGPerson alloc]init] autorelease];
                    }
                    //_objc_autoreleasePoolPrint();
                    @autoreleasepool {
                        WGPerson *p4 = [[[WGPerson alloc]init] autorelease];
                        WGPerson *p5 = [[[WGPerson alloc]init] autorelease];
                    }
                    _objc_autoreleasePoolPrint();
                }
            }
            return 0;
        }
        
        打印内存: objc[68116]: ##############
                objc[68116]: AUTORELEASE POOLS for thread 0x1000aa5c0
                objc[68116]: 4 releases pending.
                objc[68116]: [0x101006000]  ................  PAGE  (hot) (cold)  //cold冷,存满的page
                objc[68116]: [0x101006038]  ################  POOL 0x101006038
                objc[68116]: [0x101006040]       0x100539370  WGPerson
                objc[68116]: [0x101006048]       0x100539180  WGPerson
                objc[68116]: [0x101006050]  ################  POOL 0x101006050
                objc[68116]: ##############
                Program ended with exit code: 0
#### 分析:  PAGE  (full) (cold): cold冷,表示存满的page; PAGE (hot):hot热,表示当前使用的page

#### 3.9 autorelease释放时机
#### 












        




    4. autorelease在什么时机释放
    5. 方法里有局部对象，出了方法会立即释放吗
    6. ARC都帮我们做了什么？
    7. weak指针的实现原理
    
















#### 上面是MJExtension总结

## 内存管理

### 一 自动释放池AutoreleasePool  https://www.jianshu.com/p/9c8139fc3100
#### 1 自动释放池简介
#### Autorelease机制是为了延时释放对象, OC对象的生命周期取决于引用计数, 有两种方式可以释放对象: (1)直接调用release释放(2)调用autorelease将对象加入自动释放池中。而自动释放池用来存放那些需要在某个时刻(当次的RunLoop事件循环将要结束的时候会释放掉)释放的对象,如果没有自动释放池而给对象发送autorelease消息,控制台会报错,但一般我们不需要担心自动释放池的创建问题,系统会自动创建一些线程,例如主线程和GCD中的线程,都默认拥有自动释放池,每次执行“事件循环”(event loop)时，就会将自动释放池清空,简单说就是在当次的RunLoop将要结束的时候调用objc_autoreleasePoolPop，并push进来一个新的AutoreleasePool

#### 2. 自动释放池的底层结构 https://www.jianshu.com/p/afdf1e081fa2
####  1.1 自动释放池的底层结构是以栈为节点，以双向链表形式组合而成的一个数据结构。通俗讲自动释放池是以多个AutoreleasePoolPage为结点，通过链表的方式串连起来的结构，这一整串就是自动释放池,即每个自动释放池都是由若干个AutoreleasePoolPage组成的双向链表结构。每个AutoreleasePoolPage对象占用4096个字节,除了存放它内部的成员变量,剩下的用来存放autorelease对象的地址,所有的AutoreleasePoolPage对象通过双向链表的形式连接在一起

#### 1.2 AutoreleasePoolPage中的parent、child指针分别指向上一个和下一个page,当前page的空间被占满(每个AutorelePoolPage的大小为4096字节)时，就会新建一个AutorelePoolPage对象并连接到链表中，后来的 Autorelease对象也会添加到新的page中；另外，当next== begin()时，表示AutoreleasePoolPage为空；当next == end()，表示AutoreleasePoolPage已满。

        class AutoreleasePoolPage {
            #define EMPTY_POOL_PLACEHOLDER ((id*)1)  //空池占位
            #define POOL_BOUNDARY nil                //边界对象(即哨兵对象）
            magic_t const magic;        //校验AutoreleasePagePoolPage结构是否完整
            id *next;                   //指向新加入的autorelease对象的下一个位置，初始化时指向begin()
            pthread_t const thread;     //当前所在线程，AutoreleasePool是和线程一一对应的
            AutoreleasePoolPage * const parent;  //双向链表中指向父节点page，第一个结点的parent值为nil
            AutoreleasePoolPage *child;          //双向链表中指向子节点page，最后一个结点的child值为nil
            uint32_t const depth;                //链表深度，节点个数
            uint32_t hiwat;                      //数据容纳的一个上限
        }
        
#### 1.3 哨兵对象(边界对象)(POOL_BOUNDARY)的作用
        #define POOL_BOUNDARY nil
#### 边界对象其实就是nil的别名,作用也就是为了起到一个标识的作用,每当自动释放池初始化调用objc_autoreleasePoolPush方法时，总会通过AutoreleasePoolPage的push方法，将POOL_BOUNDARY放到当前page的栈顶，并且返回这个边界对象;而在自动释放池释放调用objc_autoreleasePoolPop方法时，又会将边界对象以参数传入，这样自动释放池就会向释放池中对象发送release消息，直至找到第一个边界对象为止


#### 3 自动释放池释放
        @autoreleasepool {
            id obj = [[NSObject alloc]init];
        }
        编辑器会将上面的代码转为, 整个程序中push和pop的操作都是一一对应的
        void *atautoreleasepoolobj = objc_autoreleasePoolPush(void)
        id obj = [[NSObject alloc]init];
        objc_autoreleasePoolPop(atautoreleasepoolobj)
        
#### 下面我们通过Runtime源码了解下详细的方法含义
#### 3.1 push的调用方法
        //调用方法1
        void * _objc_autoreleasePoolPush(void) {
            return objc_autoreleasePoolPush();
        }
        //调用方法2
        void * objc_autoreleasePoolPush(void) {
            return AutoreleasePoolPage::push();
        }
        //调用方法3
        static inline void *push() {
            id *dest;
            if (DebugPoolAllocation) { // Each autorelease pool starts on a new pool page.
                dest = autoreleaseNewPage(POOL_BOUNDARY);
            } else {
                dest = autoreleaseFast(POOL_BOUNDARY);
            }
            return dest;
        }
        //调用方法4
        //这个函数的作用就是，找到最顶层的一个AutoreleasePoolPage对象，如果没有那就创建一个；
        //如果找到了，判断他是否已经装满了full()，因为一个AutoreleasePoolPage只有4096个字节大小，
        //如果满了那就会调用autoreleaseNoPage()创建一个AutoreleasePoolPage对象并添加add；如果没满则直接执行add(obj)。
        static inline id *autoreleaseFast(id obj) {
            //hotPage()函数会对应线程去取自动释放池，这里也可以看出释放池和线程是一一对应的关系
            AutoreleasePoolPage *page = hotPage();
            if (page && !page->full()) {
                //obj是一个POOL_BOUNDARY对象(哨兵对象)，并不是我们的autorelease的对象
                //每次执行push操作时都会插入一个哨兵对象，并且把哨兵对象的地址作为返回值返回了,pop函数需要用到这个哨兵对象的地址
                //对应的每次pop都是寻找到上一个哨兵对象，对期间所有的autorelease对象执行一次release操作。
                return page->add(obj);
            } else if (page) {
                return autoreleaseFullPage(obj, page);
            } else {
                return autoreleaseNoPage(obj);
            }
        }
#### 观察上述代码，每次调用push其实就是创建一个新的AutoreleasePool，在对应的AutoreleasePoolPage中插入一个POOL_BOUNDARY,并且返回插入的POOL_BOUNDARY的内存地址。push方法内部调用的是autoreleaseFast方法，并传入边界对象(POOL_BOUNDARY)。hotPage可以理解为当前正在使用的AutoreleasePoolPage。自动释放池最终都会通过page->add(obj)方法将边界对象添加到释放池中，而这一过程在autoreleaseFast方法中被分为三种情况：
1. 当前page存在且不满,调用page->add(obj)方法将对象添加至page的栈中，即next指向的位置
2. 当前page存在但是已满,调用autoreleaseFullPage初始化一个新的page，调用page->add(obj)方法将对象添加至page的栈中
3. 当前page不存在时,调用autoreleaseNoPage创建一个hotPage，再调用page->add(obj) 方法将对象添加至page的栈中

#### 3.2 Pop函数
#### AutoreleasePool的释放调用的是objc_autoreleasePoolPop方法，此时需要传入边界对象作为参数。这个边界对象正是每次执行objc_autoreleasePoolPush方法返回的对象atautoreleasepoolobj；
        //调用方法1
        void _objc_autoreleasePoolPop(void *ctxt) {
            objc_autoreleasePoolPop(ctxt);
        }
        //调用方法2:
        void objc_autoreleasePoolPop(void *ctxt) {
            AutoreleasePoolPage::pop(ctxt);
        }
        //调用方法3: 核心方法 向栈中的对象发送release消息，直到遇到第一个哨兵对象
        void releaseUntil(id *stop)  {
            while (this->next != stop) { //一直遍历
                // Restart from hotPage() every time, in case -release 
                // autoreleased more objects
                AutoreleasePoolPage *page = hotPage();
                // fixme I think this `while` can be `if`, but I can't prove it
                // 如果当前page中的autorelease对象已释放完毕则会重新遍历父结点的page，知道找到传递来的哨兵对象为止
                while (page->empty()) {
                    page = page->parent;
                    setHotPage(page);
                }
                page->unprotect();
                id obj = *--page->next;
                memset((void*)page->next, SCRIBBLE, sizeof(*page->next));
                page->protect();

                if (obj != POOL_BOUNDARY) {
                    objc_release(obj);
                }
            }
            setHotPage(this);
            #if DEBUG
            // we expect any children to be completely empty
            for (AutoreleasePoolPage *page = child; page; page = page->child) {
                assert(page->empty());
            }
            #endif
        }
#### 首先根据传入的边界对象地址找到边界对象所处的page；然后选择当前page中最新加入的对象一直向前清理，可以向前跨越若干个page，直到边界所在的位置；清理的方式是向这些对象发送一次release消息，使其引用计数减一；另外，清空page对象还会遵循一些原则：
1. 如果当前的page中存放的对象少于一半，则子page全部删除；
2. 如果当前的page存放的多余一半,(意味着马上将要满),则保留一个子page,节省创建新page的开销;


#### 4. autorelease方法
#### autorelease方法最终也会调用上面提到的autoreleaseFast方法,将当前对象加到AutoreleasePoolPage中。
autorelease函数和push函数一样，关键代码都是调用autoreleaseFast函数向自动释放池的链表栈中添加一个对象，不过push函数入栈的是一个边界对象，而autorelease函数入栈的是一个具体的Autorelease的对象。


#### 5. 自动释放池(autoreleasepool)作用
1. 延迟对象的释放时间
2. 合理运用自动释放池，可以降低程序的内存峰值
3. 可以避免无意间误用那些在清空池之后已被系统回收的对象, 如果用了编辑器会提示的

#### 5.1 @autoreleasepool的作用可以用来降低内存峰值,先看一个面试题
        //面试题: 修改代码中的错误
        for (int i = 0; i < 10000; i++) {
            NSString *str = @"Zhang San";
            str = [str lowercaseString];
            str = [str stringByAppendingString:@"Li Si"];
            NSLog(@"%@",str);
        }
        
#### 分析: stringByAppendingString方法可能会创建一个临时对象,这个临时对象很可能会放在自动释放池中,即便临时对象在调用完方法后就不再使用了，它们也依然处于存活状态,等待系统稍后进行回收,但自动释放池却要等到该线程执行下一次事件循环时才会清空,这就意味着在执行for循环时，会有持续不断的新的临时对象被创建出来，并加入自动释放池。要等到结束for循环才会释放。在for循环中内存用量会持续上涨，而等到结束循环后，内存用量又会突然下降,为了优化性能,我们可以这么解决,通过这种方式可以发现尽管字符串在不断地创建，但由于得到了及时的释放，堆内存始终保持在一个很低的水平。

        for (int i = 0; i < 10000; i++) {
            //在循环中自动释放的对象就会放在这个池，而不是在线程的主池里面
            @autoreleasepool {
                NSString *str = @"Zhang San";
                str = [str lowercaseString];
                str = [str stringByAppendingString:@"Li Si"];
                NSLog(@"%@",str);
            }
        }
#### 5.2 避免无意间误用那些在清空池之后已被系统回收的对象,
        @autoreleasepool {
            id obj = [[NSObject alloc]init];
        }
        [self useObject:obj];
        在编译时就会基于错误警告，因为obj出了自动释放池就不可用了。
#### 6 总结
####  自动释放池排布在栈中，对象受到autorelease消息后，系统将其放入栈顶的池里;自动释放池的机制就像“栈”。系统创建好池之后，将其压入栈中，而清空自动释放池相当于将池从栈中弹出。在对象上执行自动释放操作，
就等于将其放入位于栈顶的那个池;
    
#### 7.AutoreleasePool与NSThread、NSRunLoop的关系
#### 7.1 RunLoop和NSThread的关系
1. RunLoop与线程是一一对应关系,每个线程(包括主线程)都有一个对应的RunLoop对象,其对应关系保存在一个全局的Dictionary里；
2. 主线程的RunLoop默认由系统自动创建并启动；而其他线程在创建时并没有RunLoop，若该线程一直不主动获取，就一直不会有RunLoop；
3. 苹果不提供直接创建RunLoop的方法；所谓其他线程Runloop的创建其实是发生在第一次获取的时候，系统判断当前线程没有RunLoop就会自动创建；
4. 当前线程结束时，其对应的Runloop也被销毁；

#### 7.2 RunLoop和AutoreleasePool的关系
#### 主线程的NSRunLoop在监测到事件响应开启每一次event loop之前，会自动创建一个autorelease pool，并且会在event loop结束的时候执行drain操作，释放其中的对象。

#### 7.3 Thread和AutoreleasePool的关系
#### 包括主线程在内的所有线程都维护有它自己的自动释放池的堆栈结构。新的自动释放池被创建的时候，它们会被添加到栈的顶部，而当池子销毁的时候，会从栈移除。对于当前线程来说，Autoreleased对象会被放到栈顶的自动释放池中。当一个线程线程停止，它会自动释放掉与其关联的所有自动释放池。

#### 8. AutoreleasePool在线程上的释放时机
#### 8.1 主线程上自动释放池的使用过程如下
1. App启动后，苹果在主线程RunLoop里注册了两个Observer
2. 第一个Observer监视的事件是Entry(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush()创建自动释放池
3. 第二个Observer监视了两个事件

        BeforeWaiting(准备进入休眠)时调用_objc_autoreleasePoolPop()和_objc_autoreleasePoolPush()释放旧的池并创建新池；
        Exit(即将退出Loop) 时调用 _objc_autoreleasePoolPop()来释放自动释放池。
4. 在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop创建好的AutoreleasePool环绕着，所以不会出现内存泄漏，开发者也不必显示创建AutoreleasePool了;

6. 程序启动到加载完成后，主线程对应的RunLoop会停下来等待用户交互
7. 用户的每一次交互都会启动一次运行循环，来处理用户所有的点击事件、触摸事件。
8. RunLoop检测到事件后，就会创建自动释放池;
9. 所有的延迟释放对象都会被添加到这个池子中;
10. 在一次完整的运行循环结束之前，会向池中所有对象发送release消息，然后自动释放池被销毁;

#### 8.2 AutoreleasePool子线程上的释放时机
#### 子线程默认不开启RunLoop,那么其中的延时对象该如何释放呢?依然要从Thread和AutoreleasePool的关系来考虑：每一个线程都会维护自己的 Autoreleasepool栈，所以子线程虽然默认没有开启RunLoop，但是依然存在AutoreleasePool，在子线程退出的时候会去释放autorelease对象。所以，一般情况下，子线程中即使我们不手动添加自动释放池，也不会产生内存泄漏。

#### 9. AutoreleasePool需要手动添加的情况
#### 尽管ARC已经做了诸多优化，但是有些情况我们必须手动创建AutoreleasePool，而其中的延时对象将在当前释放池的作用域结束时释放.苹果文档中说明了三种情况，我们可能会需要手动添加自动释放池：
1. 编写的不是基于UI框架的程序，例如命令行工具；
2. 通过循环方式创建大量临时对象；
3. 使用非Cocoa程序创建的子线程；

#### https://www.jianshu.com/p/7bd2f85f03dc
