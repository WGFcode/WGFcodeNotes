##  NSNotification

## 总结
* 通知可以是一对一、一对多的消息通知模式
* 实现通知流程:向通知中心添加观察者(调用addObserver方法) -> 向通知中心发送通知(调用postNotification方法) -> 和观察者对象即将消失的时候从通知中心中移除该观察者(removeObserver)
* 观察者消失的时候，必须要移除观察者，否则会造成内存泄露
* 添加观察者和发送通知必须在同一个线程中，通知中心发送通知给观察者是同步的，也可以用通知队列(NSNotificationQueue)异步发送通知

#### NSNotification(通知)是iOS中重要的一种设计模式，一种通知分发机制，允许将信息广播给注册的观察者。发送通知的本身不需要知道观察者是谁，也不需要知道有几个观察者就可以实现消息的传递，是一对多的。首先我们先看下它的基本属性和方法
    //通知对象(其实可以理解成一个消息对象)
    @interface NSNotification : NSObject <NSCopying, NSCoding>
    //通知名称,通知的唯一标识
    @property (readonly, copy) NSNotificationName name;  
    //发送通知的对象,谁发出通知,nil:匿名发送
    @property (nullable, readonly, retain) id object;    
    //发送方在发送消息的同时想要传递的参数
    @property (nullable, readonly, copy) NSDictionary *userInfo;  
    初始化方法创建通知 对象
    - (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object  
    userInfo:(nullable NSDictionary *)userInfo;
    - (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
    类方法创建通知对象
    + (instancetype)notificationWithName:(NSNotificationName)aName   
    object:(nullable id)anObject;
    + (instancetype)notificationWithName:(NSNotificationName)aName   
    object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
    不能通过init创建对象对象 /* do not invoke; not a valid initializer for this class */
    - (instancetype)init /*API_UNAVAILABLE(macos, ios, watchos, tvos)*/;    

    通知中心
    @interface NSNotificationCenter : NSObject {
        @package
        void *_impl;
        void *_callback;
        void *_pad[11];
    }
    //通知中心(单例)，程序只有一个通知中心
    @property (class, readonly, strong) NSNotificationCenter *defaultCenter; 
    1.在通知中心添加观察者
    - (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)  
    aName object:(nullable id)anObject;
    2.向通知中心发送通知
    - (void)postNotification:(NSNotification *)notification;
    - (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
    - (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject  
    userInfo:(nullable NSDictionary *)aUserInfo;
    3.移除通知中心中的观察者
    - (void)removeObserver:(id)observer;
    - (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName   
    object:(nullable id)anObject;
     以block的形式代替selector方式为通知中心添加观察者，并且也可以设置操作队列
    - (id <NSObject>)addObserverForName:(nullable NSNotificationName)name   
    object:(nullable id)obj queue:(nullable NSOperationQueue *)queue   
    usingBlock:(void (^)(NSNotification *note))block API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

### 1. NSNotification基本使用
    @implementation WGMainObjcVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1.向通知中心注册一个观察者，当观察者接收到通知的时候，会去调用change方法
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change)   
        name:@"customStr" object:nil];
    }

    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        //2.向通知中心发送通知 方式一、二任选其一
        //方式一
        [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr" object:nil];
        //方式二
        NSNotification *notification = [NSNotification notificationWithName:@"customStr" object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }

    //3.当通知中心收到通知消息时，会将通知消息发送给观察者，观察者收到通知后调用change方法
    -(void)change {
        NSLog(@"变化了");
    }

    -(void)viewWillDisappear:(BOOL)animated {
        //4.页面消失的时候 从通知中心移除观察者 方式一、二任选其一
        //方式一: 移除通知中心中针对观察者的所有通知
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        //方式二: 移除通知中心中针对观察者的名字为customStr的通知
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"customStr" object:nil];
    }
    @end
#### 分析:每次点击屏幕都会打印"变化了"的信息，说明观察者收到了通知；NSNotification通知的基本使用分以下几步：向通知中心注册观察者 -> 在数据改变的时候向通知中心发送通知 -> 通知中心接收到通知信息后通知观察者，观察者实现相应的方法 -> 在对象或者页面消失的时候从通知中心中移除观察者；
### 1.1 通知中携带额外信息传递给观察者

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //1.向通知中心注册一个观察者
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change:)   
        name:@"customStr" object:nil];
    }

    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        //2.向通知中心发送通知，在通知中携带信息
        NSDictionary *dataDic = @{@"name": @"zhangsan", @"age": @18};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr"   
        object:nil userInfo:dataDic];
    }

    //3.当通知中心收到通知消息时，会将通知消息发送给观察者，观察者收到通知后调用change方法
    -(void)change:(NSNotification *)noti {
        NSDictionary *dic = noti.userInfo;
        NSLog(@"变化了--%@",dic);
    }
    
    打印结果:变化了--{
            age = 18;
            name = zhangsan;
            }

### 1.2 添加观察者和发送通知中object参数作用
#### 一般我们添加观察者和发送通知都将object参数设置为nil，今天我们来研究下这个参数的作用究竟是什么
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change:)   
        name:@"customStr" object:nil];
    }

    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr"   
        object:nil userInfo:nil];
    }

    -(void)change:(NSNotification *)noti {
        NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",noti.name,noti.object,noti.userInfo);
    }

    -(void)viewWillDisappear:(BOOL)animated {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"customStr" object:nil];
    }
#### 分析:通过验证，在通知名称一致的情况下，object参数的设置与是否能接收到通知有如下情况
    * 当post中的object为nil,add中的object为nil，可以接收到通知
    * 当post中的object为nil,add中的object不为nil，接收不到通知
    * 当post中的object不为nil,add中的object为nil，可以接收到通知
    * 当post中的object不为nil,add中的object不为nil，可以接收到通知
#### 从这里可以知道object参数并不能作为是否触发通知的一个条件，也不能作为参数传递；object其实就是一个发送通知的对象，谁发出了通知，object就是谁,如果设置为nil，则表示匿名发送。其实这个是对消息发送方的一个过滤，此参数据说明当前监听器仅对某个对象发出的消息感兴趣
#### 简单总结
1. 添加通知时，若指定了object参数，那么该响应者只会接收发送通知时object参数指定为同一实例的通知。
2. 添加通知时，若object为nil,那么无论发送通知时的object参数为nil或者不为nil，都可以接收到通知。
3. 添加通知时，若object不为nil,那么发送通知时的object参数必须和添加通知时object的参数一致才能接收到通知。
4. 发送通知时，若指定了object参数，并不会影响添加通知时没有指定object参数的响应者接收通知。


### 1.3 从通知中心移除观察者
#### 当对象销毁的时候，一定要从通知中心移除观察者，否则会造成内存泄露;移除通知有两种方式；对一个已经销毁的观察者发送通知是收不到通知消息的
    //方式一： 移除观察者所有的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //方式二: 移除观察者中[通知名称是customStr 发送通知对象是123]的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"customStr" object:@"123"];

### 1.4 通知中NSOperationQueue的用法
#### 我们在注册观察者方法的时候，除了将通知方法设置到selector方式外，也可以使用block的方式；我们需要明确的就是发送通知所在的线程和接收通知所在的线程必须是同一个线程；

    @implementation WGMainObjcVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        //queue参数: 就是将usingBlock提交到queue队列里面执行，一般是设置为主队列用于更新UI，  
        主队列任务都是在主线程中更新的
        [[NSNotificationCenter defaultCenter] addObserverForName:@"customStr" object:nil  
        queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",note.name,note.object,note.userInfo);
        }];
    }

    -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr" object:nil];
    }

    -(void)change:(NSNotification *)noti {
        NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",noti.name,noti.object,noti.userInfo);
    }

    @end

    打印结果: 通知名称:customStr,通知对象:(null),通知携带参数:(null)

### 1.5 NSNotificationQueue 通知队列
#### NSNotificationQueue通知队列充当通知中心的缓冲区。尽管NSNotificationCenter已经分发通知，但放入队列的通知可能会延迟，直到当前的runloop结束或runloop处于空闲状态才发送.；NSNotificationCenter都是同步发送的，而这里介绍关于NSNotificationQueue的异步发送，从线程的角度看并不是真正的异步发送，或可称为延时发送，它是利用了runloop的时机来触发的
    @interface NSNotificationQueue : NSObject {
    @property (class, readonly, strong) NSNotificationQueue *defaultQueue;
    初始化方法来关联外部的通知中心，最终也是通过通知中心来管理通知的发送、注册
    - (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

    - (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle;
    - (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle  
    coalesceMask:(NSNotificationCoalescing)coalesceMask forModes:(nullable NSArray<NSRunLoopMode> *)modes;

    - (void)dequeueNotificationsMatching:(NSNotification *)notification coalesceMask:(NSUInteger)coalesceMask;

    @end

    设置通知什么时候发送
    typedef NS_ENUM(NSUInteger, NSPostingStyle) { 
        NSPostWhenIdle = 1,     当runloop处于空闲时发出通知
        NSPostASAP = 2,           在当前通知调用或者计时器结束发出通知
        NSPostNow = 3              在合并通知完成之后立即发出通知
    };

    设置如何合并通知
    typedef NS_OPTIONS(NSUInteger, NSNotificationCoalescing) { 
        NSNotificationNoCoalescing = 0,              不合并通知
        NSNotificationCoalescingOnName = 1,     按照通知名字合并通知
        NSNotificationCoalescingOnSender = 2    按照传入的object(发送推送的对象)合并通知
    };
#### 如果有多个相同的通知，可以在NSNotificationQueue进行合并，这样只会发送一个通知。NSNotificationQueue会通过先进先出的方式来维护NSNotification的实例，当通知实例位于队列首部，通知队列会将它发送到通知中心，然后依次的像注册的所有观察者派发通知；通知中心发送通知给观察者是同步的，也可以用通知队列（NSNotificationQueue）异步发送通知。
1. 依赖runloop，所以如果在其他子线程使用NSNotificationQueue，需要开启runloop
2. 最终还是通过NSNotificationCenter进行发送通知，所以这个角度讲它还是同步的
3. 所谓异步，指的是非实时发送而是在合适的时机发送，并没有开启异步线程


### 2.0  NSNotification实现原理(https://juejin.cn/post/6844904082516213768)
#### NSNotificationCenter是通知的管理类，其核心就是操作两个Table及一个链表通知中心底层结构简化如下
    根容器，NSNotificationCenter持有
    typedef struct NCTbl {
      Observation    *wildcard;  //链表结构，保存既没有name也没有object的通知 
      MapTable       nameless;   //存储没有name但是有object的通知
      MapTable       named;      //存储带有name的通知，不管有没有object
    } NCTable;
    
    Observation 存储观察者和响应结构体，基本的存储单元
    typedef struct  Obs {
      id        observer;   观察者,接收通知消息的对象
      SEL       selector;   观察者接收到通知后执行的方法
      struct Obs    *next;  下一个观察者对象的地址
      int       retained;   /* Retain count for structure.  */
      struct NCTbl  *link;      /* Pointer back to chunk table  */
    } Observation;

1. named表是以通知名称作为Key,因为注册观察者的时候，有可能传入了一个object参数用于接收指定对象发送的通知，并且一个通知可能有多个观察者对象，所以还需要一张表来保存object和观察者observer的对应关系，这张表以object为Key,observer观察者为value,如何实现同一个通知保存多个观察者的情况？答案就是使用链表；所以name表的结果如下:外层是个Table(表)，通知名称作为其Key,value又是一个Tabel(内嵌表)，内层表以object为key,value为observer的一个链表，用来保存所有的观察者
2. 实际开发中我们经常传入object的值为nil，这时系统会根据nil自动生成一个key,对应的value就是当前通知传入了NotificationName没有传入object的所有观察者，当对应的NotificationName的通知发送时，链表中所有的观察者都会收到通知
3. nameless表，因为没有NotificationName，所以只有一个Table(表),以object作为Key，value是一个链表,链表中保存的就是注册了通知(没有传入通知名称而传入了object)的所有观察者
4. wildcard其实是一种链表结构，注册观察时没有传入通知名称，也没有传入object，就会被添加到wildcard链表中，注册到这里的观察者能接收到所有的系统通知

### 2.1 添加观察者流程
1. 初始化通知中心对象时，会创建一个对象，该对象保存了wildcard、nameless表、named表等信息
2. 根据传入的参数，生成一个Observation对象，该对象中保存了观察者对象、接收到通知后观察者执行的方法、下个观察者对象的地址
3. 根据是否传入NotificationName通知名称，选择操作nameless表还是named表
4. 若传入了通知名称，则会以通知名称为Key在named表中找到对应的value,若找到value，直接取出value；若没有找到，新建一个table(表)，然后以通知名称为Key将这个新建的表添加到named表中，那么value(内层表)如何操作那，如果添加观察者时，携带了object，则以object为key,在内层表中找到对应的链表，然后在链表的尾部插入之前实例化的对象Observation；若添加观察者时没有携带object，则以nil为key找到对应的链接并将之前实例化好的Observation对象作为头节点插入进去
5. 若没有传入通知名称，则会操作nameless表，若添加观察者时携带了object，则以object为Key，找出对应的链接，在链接尾部插入之前实例化的Observation对象；若没有携带object，则将实例化的对象添加到wildcard链表中

### 2.2 发送通知的流程
#### 发送通知的流程总体来说是根据NotificationName和object找到对应的链表，然后遍历整个链表，给每个Observation节点中保存的oberver发送对应的SEL消息
1. 创建一个observerArray数组，用来保存需要通知的观察者observer
2. 遍历wildcard链表，将observer添加到observerArray数组中
3. 若发送通知时携带了object，则以object为key在nameless表中，找到链表，然后遍历链表，将observer添加到observerArray数组中
4. 若发送通知时携带了通知名称，则以通知名称为Key在named表中找到对应的表(内层表)，然后在内层表中以object中key,找到对应的链表，然后遍历链表，将observer添加到observerArray数组中；若object为nil,则以nil为key,找到对应的链表，然后遍历链表，将observer添加到observerArray数组中
5.  到此所有关于当前通知的observer都已经添加到数组中，然后遍历数组，取出其中的observer节点(包含了观察者对象和selector)进行消息调用
### 2.3 移除通知流程
1. 若NotificationName和object都为nil，则清空wildcard链表。
2. 若NotificationName为nil，遍历named表，若object为nil,则清空named表；若object不为nil,则以object为key找到对应的链表，然后清空链表；在nameless table中以object为key找到对应的observer链表，然后清空，若object也为nil，则清空nameless table
3. 若NotificationName不为nil，在named table中以NotificationName为key找到对应的table，若object为nil，则清空找到的table，若object不为nil，则以object为key在找到的table中取出对应的链表，然后清空链表。

### 2.3 总结流程
#### 2.3.1 简化源码

    // 根容器，NSNotificationCenter持有
    typedef struct NCTbl {
      Observation   *wildcard;    链表结构，保存既没有name也没有object的通知
      GSIMapTable   nameless;     存储没有name但是有object的通知    
      GSIMapTable   named;        存储带有name的通知，不管有没有object    
        ...
    } NCTable;

    //Observation 存储观察者和响应结构体，基本的存储单元
    typedef struct Obs {
      id   observer;      观察者，接收通知的对象    
      SEL  selector;      响应方法        
      struct Obs *next;   Next item in linked list.  
      ...
    } Observation;

    /*
     observer：观察者，即通知的接收者   selector：接收到通知时的响应方法
     name: 通知name                 object：携带对象
     */
    -(void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName
    object:(nullable id)anObject {
        //1.创建一个observation对象，持有观察者和SEL，下面进行的所有逻辑就是为了存储它
        o = obsNew(TABLE, aSelector, observer);
        
        // case1: 如果aName存在
        if (aName) {
            //NAMED是个宏，表示名为named字典。以aName为key，从named表中获取对应的mapTable
            n = GSIMapNodeForKey(NAMED, (GSIMapKey)(id)aName);
            if (n == 0) {
                //不存在，则创建
                m = mapNew(TABLE);  //先取缓存，如果缓存没有则新建一个map
                GSIMapAddPair(NAMED, (GSIMapKey)(id)aName, (GSIMapVal)(void*)m);
            }else {
                //存在则把值取出来 赋值给m
                m = (GSIMapTable)n->value.ptr;
            }
        
            //以anObject为key，从字典m中取出对应的value，其实value被MapNode的结构包装了一层，这里不追究细节
            n = GSIMapNodeForSimpleKey(m, (GSIMapKey)anObject);
            if (n == 0) {
                //不存在，则创建,然后将新创建的observation对象进行保存
                o->next = ENDOBS;
                GSIMapAddPair(m, (GSIMapKey)anObject, (GSIMapVal)o);
            }else {
                //存在，则将新创建的observation对象进行保存
                list = (Observation*)n->value.ptr;
                o->next = list->next;
                list->next = o;
            }
            //case2: 如果name为空，但object不为空
        }else if (anObject) { 
            //以anObject为key，从nameless字典中取出对应的value，value是个链表结构
            n = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)anObject);
            if (n == 0) {
                //不存在则新建链表，并存到map中
                o->next = ENDOBS;
                GSIMapAddPair(NAMELESS, (GSIMapKey)object, (GSIMapVal)o);
            }else {
                //存在 则把值接到链表的节点上
            }
        }else { //case3: name 和 object 都为空
            // 则存储到wildcard链表中
            o->next = WILDCARD;
            WILDCARD = o;
        }
    }
#### 2.3.2 逻辑分析
#### NCTable结构体中核心的三个变量: wildcard、named、nameless,对应的功能如下
##### 2.3.2.1 存在name（无论object是否存在）
1. 注册通知，如果通知的name存在，则以name为key从named字典中取出值n(这个n其实被MapNode包装了一层，便于理解这里直接认为没有包装)，这个n还是个字典，各种判空新建逻辑不讨论
2. 然后以object为key，从字典n中取出对应的值，这个值就是Observation类型(后面简称obs)的链表，然后把刚开始创建的obs对象o存储进去
3. 如果注册通知时传入name，那么会是一个双层的存储结构
4. 找到NCTable中的named表，这个表存储了还有name的通知；以name作为key，找到value，这个value依然是一个map；map的结构是以object作为key，obs对象为value，这个obs对象的结构上面已经解释，主要存储了observer & SEL

                   named表(mapTab)
           |--------------------------|
       key(通知名称)             value(mapTab)
                       |--------------------------|
                     key(object)             value(observation对象)





##### 2.3.2.2 只存在object
1. 以object为key，从nameless字典中取出value，此value是个obs类型的链表
2. 把创建的obs类型的对象o存储到链表中
3. 只存在object时存储只有一层，那就是object和obs对象之间的映射

                nameless表(mapTab)
        |--------------------------|
        key(object)             value(observation对象-链表)


##### 2.3.2.3 没有name和object
1. 这种情况直接把obs对象存放在了Observation  *wildcard链表结构中


        
### 3.通知的优缺点
#### 优点
* 对于一个发出的通知，可以有多个对象来响应，即一对多的实现方式简单
* 发送通知的时候，可以携带自定义的信息进行传递
#### 缺点
* 在编译期不会检查通知是否能够被观察者正确的处理；
* 在释放注册的对象时，需要在通知中心取消注册；
* 在调试的时候应用的工作流程和控制过程难跟踪，因为添加观察者和发送通知可能在不同的地方，甚至不同的文件中
* 通知发出后，不能从观察者获得任何的反馈信息。通知一旦发出，就不会再收到有关观察者的任何反馈
* 通知名称、发送通知对象object、携带的自定义信息userInfo，需要在添加观察者和发送通知的地方保持统一，如果没有指定的位置去处理，很容易出现拼写错误

### 4.GNUstep介绍
#### GNU是一个自由软件操作系统—就是说，它尊重其使用者的自由。GNU操作系统包括GNU软件包（专门由GNU工程发布的程序）和由第三方发布的自由软件。GNU的开发使你能够使用电脑而无需安装可能会侵害你自由的软件。
#### GNUstep 提供 GNUstep Make 来简化编译 Objective-C 程序，对于IOS开发中使用Objective-C语言的开发者来说

1. GNUstep将Cocoa的OC库重新开源实现了一遍
2. 虽然GNUstep不是苹果官方源码，但还是具有一定的参考价值 !!
3. 由于Cocoa 框架中有很多代码实现是不开源的，开发者如果想了解底层实现没有很好的办法，现在GNUstep就可以辅助开发者了解其实现原理。
4. GNUstep是Cocoa框架的互换框架，从源代码的实现上来说，虽然和Apple不完全一样，但是从开发者角度看，两者的行为和实现方式是一样的，或者说非常相似，因为NSObject类的Foundation框架是不开源的，所以想了解GNUstep的实现方式，有助于我们去理解Apple的实现方式
#### 上面我们研究的通知底层原理就是通过GNUstep Base来窥探的，GNUstep Base 的官网下载地址:http://www.gnustep.org/resources/downloads.php,


### 5. 特殊验证
    public class WGTestNotification : WGBaseVC {
        public override func layoutUI() {
            self.title = "收银员"
            self.addNavBackBtn()
            //向通知中心注册观察者
            NotificationCenter.default.addObserver(self, selector: #selector(getNotification(noti:)),  
            name: nil, object: nil)
        }
        
        @objc func getNotification(noti: NSNotification) {
            let userInfoDic = noti.userInfo
            NSLog("收到的通知内容:\(userInfoDic)")
        }
        
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            NotificationCenter.default.post(name: NSNotification.Name.init("A"), object: nil,  
            userInfo: ["A": "a"])
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
#### 当addObserver添加通知时，若通知名称和object都设置为nil，在没有点击屏幕进行发送通知情况下，控制台也会打印很多类似"收到的通知内容...."的内容，说明在使用通知过程中，name和 object参数不能都设置为nil，否则会导致打印很多脏乱数据，这里猜测是打印了系统和项目中所有在通知中心注册过的观察者。总之这两个参数不能全部设置为nil

#### ⚠️ name和object参数不能全部设置为nil

#### 5.1 发送通知方式
#### 5.1.1通知中心发送通知
    public override func layoutUI() {
        self.title = "测试通知"
        self.addNavBackBtn()
        //向通知中心注册观察者
        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(notifi:)), name: NSNotification.Name.init("111"), object: nil)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //通知中心发送通知
        self.notificationCenterSendNotification()
    }

    @objc func getNotification(notifi: Notification) {
        NSLog("2.get notification message")
    }

    //1. 通知中心发送通知
    private func notificationCenterSendNotification() {
        NSLog("1.before send notification")
        NotificationCenter.default.post(name: NSNotification.Name("111"), object: nil, userInfo: nil)
        NSLog("3.after send notification")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    打印结果：1.before send notification
            2.get notification message
            3.after send notification
#### 分析，使用最常用的NSNotificationCenter通知中心发送通知，这是在同一线程里发送的，并且是同步执行的。

#### 5.1.2通知队列发送通知
    public override func layoutUI() {
        self.title = "收银员"
        self.addNavBackBtn()
        //向通知中心注册观察者
        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(notifi:)), name: NSNotification.Name.init("111"), object: nil)
    }


    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //通知队列发送通知
        self.queueSendNotification()
    }

    @objc func getNotification(notifi: Notification) {
        NSLog("2.get notification message")
    }

    //2. 通知队列发送通知
    private func queueSendNotification() {
        NSLog("1.before send notification")
        //创建通知对象、通知队列对象，将通知放到通知队列中
        let notifi = Notification.init(name: NSNotification.Name.init(rawValue: "111"), object: nil)
        let notifiQueue = NotificationQueue.default
        /*
         postingStyle: 通知的发送时机
         enum PostingStyle: UInt{
         case whenIdle = 1 runloop空闲时发送通知，简单地说就是当本线程的runloop空闲时即发送通知到通知中心--异步执行132(延迟执行)
         case asap = 2  (As Soon As Possible)尽可能快的发送，这种时机是穿插在每次事件完成期间来做的--异步执行132(延迟执行)
         case now = 3  立刻发送或者合并通知完成之后发送，NotificationCenter就是这种方式发送的--同步执行的123
         }
         
         coalesceMask: 通知合并的策略,有些时候同名通知只想存在一个，这时候就可以用到它了
         struct NotificationCoalescing : OptionSet {
         var none    默认不合并
         var onName  只要name相同，就认为是相同通知,合并相同名称的通知
         var onSender object相同，就认为是相同通知，合并相同object的通知
         }
         forModes:[RunLoop.Mode]?
         当指定了某种特定runloop mode后，该通知只有在当前runloop为指定mode的下，才会被发出。
         */
        notifiQueue.enqueue(notifi, postingStyle: NotificationQueue.PostingStyle.whenIdle, coalesceMask: NotificationQueue.NotificationCoalescing.onName, forModes: nil)
        NSLog("3.after send notification")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
#### 分析：利用通知队列可以实现异步执行通知的效果，但有限制条件，就是发送通知的时机必须设置为whenIdle或者asap，若设置为now，则和通知中心发送通知的效果是一样的，都是同步的。其实这里的异步发送通知并不是线程意义上的异步，只是通知延迟至行而已；
1.
通知中心默认是以同步的方式发送通知的，也就是说，当一个对象发送了一个通知，只有当该通知的所有接受者都接受到了通知中心分发的通知消息并且处理完成后，发送通知的对象才能继续执行接下来的方法

2. 将通知加到通知队列中，就可以将一个通知异步的发送到当前的线程，这些方法调用后会立即返回，不用再等待通知的所有监听者都接收并处理完。
#### ⚠️ 如果通知入队的线程在该通知被通知队列发送到通知中心之前结束了，那么这个通知将不会被发送了。


#### 5.3 通知中的多线程
    public override func layoutUI() {
        self.title = "收银员"
        self.addNavBackBtn()
        //向通知中心注册观察者
        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(notifi:)), name: NSNotification.Name.init("111"), object: nil)
    }


    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //子线程发送通知
        self.sendSubThreadNotification()
    }

    @objc func getNotification(notifi: Notification) {
        NSLog("2.get notification message---\(Thread.current)")
    }

    //主线程发通知
    private func sendMainThreadNotification() {
        NSLog("1 before send--\(Thread.current)")
        NotificationCenter.default.post(name: NSNotification.Name.init("111"), object: nil, userInfo: nil)
        NSLog("3 after send--\(Thread.current)")
    }

    //子线程发送通知
    private func sendSubThreadNotification() {
        DispatchQueue.global().async {
            NSLog("1 before send--\(Thread.current)")
            NotificationCenter.default.post(name: NSNotification.Name.init("111"), object: nil, userInfo: nil)
            NSLog("3 after send--\(Thread.current)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    打印结果: 1 before send--<NSThread: 0x283e8af00>{number = 7, name = (null)}
            2.get notification message---<NSThread: 0x283e8af00>{number = 7, name = (null)}
            3 after send--<NSThread: 0x283e8af00>{number = 7, name = (null)}
#### 分析，接收通知处理消息代码(观察者接收到消息并处理/getNotification方法)的线程，是由发出通知(post)的线程决定,因为发出通知是在子线程，所以处理接受到的消息的代码也是在子线程中，并且和发出通知是在同一个线程中




#### 5.2.3 发送通知到指定线程
#### 通知中心分发通知的线程一般就是通知的发出者发送通知的线程。但是有时候，你可能想自己决定通知发出的线程，而不是由通知中心来决定
