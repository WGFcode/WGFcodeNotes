##  NSNotification

## 总结
* 通知可以是一对一、一对多的消息通知模式
* 实现通知流程:向通知中心添加观察者(调用addObserver方法) -> 向通知中心发送通知(调用postNotification方法) -> 和观察者对象即将消失的时候从通知中心中移除该观察者(removeObserver)
* 观察者消失的时候，必须要移除观察者，否则会造成内存泄露
* 添加观察者和发送通知必须在同一个线程中，通知中心发送通知给观察者是同步的，也可以用通知队列(NSNotificationQueue)异步发送通知

#### NSNotification(通知)是iOS中重要的一种设计模式，一种通知分发机制，允许将信息广播给注册的观察者。发送通知的本身不需要知道观察者是谁，也不需要知道有几个观察者就可以实现消息的传递，是一对多的。首先我们先看下它的基本属性和方法
        //通知对象(其实可以理解成一个消息对象)
        @interface NSNotification : NSObject <NSCopying, NSCoding>
        @property (readonly, copy) NSNotificationName name;  通知名称,通知的唯一标识
        @property (nullable, readonly, retain) id object;    发送通知的对象,谁发出通知,nil:匿名发送
        @property (nullable, readonly, copy) NSDictionary *userInfo;  发送方在发送消息的同时想要传递的参数
        初始化方法创建通知 对象
        - (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;
        - (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
        类方法创建通知对象
        + (instancetype)notificationWithName:(NSNotificationName)aName object:(nullable id)anObject;
        + (instancetype)notificationWithName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
        不能通过init创建对象对象
        - (instancetype)init /*API_UNAVAILABLE(macos, ios, watchos, tvos)*/;    /* do not invoke; not a valid initializer for this class */

        通知中心
        @interface NSNotificationCenter : NSObject {
            @package
            void *_impl;
            void *_callback;
            void *_pad[11];
        }
        @property (class, readonly, strong) NSNotificationCenter *defaultCenter; 通知中心(单例)，程序只有一个通知中心
        1.在通知中心添加观察者
        - (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;
        2.向通知中心发送通知
        - (void)postNotification:(NSNotification *)notification;
        - (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
        - (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
        3.移除通知中心中的观察者
        - (void)removeObserver:(id)observer;
        - (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject;
         以block的形式代替selector方式为通知中心添加观察者，并且也可以设置操作队列
        - (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

### 1. NSNotification基本使用
        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //1.向通知中心注册一个观察者，当观察者接收到通知的时候，会去调用change方法
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change) name:@"customStr" object:nil];
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
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change:) name:@"customStr" object:nil];
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            //2.向通知中心发送通知，在通知中携带信息
            NSDictionary *dataDic = @{@"name": @"zhangsan", @"age": @18};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr" object:nil userInfo:dataDic];
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
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change:) name:@"customStr" object:nil];
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr" object:nil userInfo:nil];
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
            //queue参数: 就是将usingBlock提交到queue队列里面执行，一般是设置为主队列用于更新UI，主队列任务都是在主线程中更新的
            [[NSNotificationCenter defaultCenter] addObserverForName:@"customStr" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
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
#### NSNotificationQueue通知队列充当通知中心的缓冲区。尽管NSNotificationCenter已经分发通知，但放入队列的通知可能会延迟，直到当前的runloop结束或runloop处于空闲状态才发送.
        @interface NSNotificationQueue : NSObject {
        @property (class, readonly, strong) NSNotificationQueue *defaultQueue;
        初始化方法来关联外部的通知中心，最终也是通过通知中心来管理通知的发送、注册
        - (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

        - (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle;
        - (void)enqueueNotification:(NSNotification *)notification postingStyle:(NSPostingStyle)postingStyle coalesceMask:(NSNotificationCoalescing)coalesceMask forModes:(nullable NSArray<NSRunLoopMode> *)modes;

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

### 2.0  NSNotification实现原理
#### NSNotificationCenter是通知的管理类，其核心就是操作两个Table及一个链表通知中心底层结构简化如下
        typedef struct NCTbl {
          Observation    *wildcard;  
          MapTable       nameless;   
          MapTable       named;  
        } NCTable;
        
        typedef struct  Obs {
          id        observer;   观察者对象
          SEL       selector;   观察者接收到通知后执行的方法
          struct Obs    *next;  下一个观察者对象的地址
          int       retained;   /* Retain count for structure.  */
          struct NCTbl  *link;      /* Pointer back to chunk table  */
        } Observation;
* wildcard 保存既没有通知名称也没有object的通知
* named表 保存传入通知名称的通知
* nameless表 保存没有传入通知名称的通知

1. named表是以通知名称作为Key,因为注册观察者的时候，有可能传入了一个object参数用于接收指定对象发送的通知，并且一个通知可能有多个观察者对象，所以还需要一张表来保存object和观察者observer的对应关系，这张表以object为Key,observer观察者为value,如何实现同一个通知保存多个观察者的情况？答案就是使用链表；所以name表的结果如下:外层是个Table(表)，通知名称作为其Key,value又是一个Tabel(内嵌表)，内层表以object为key,value为一个链表，用来保存所有的观察者
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