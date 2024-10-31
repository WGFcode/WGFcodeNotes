##  iOS开发中常用关键字(含swift)
### 1.extern
#### extern,翻译过来是“外面的、外部的”，作用就是声明外部全局变量或常量；需要注意extern只能声明，不能用于实现；开发中我们通常会单独创建一个类来管理一些全局的变量或常量，例如管理通过通知名称；extern只能用来修饰全局常量或变量

    /*
     extern都是写在.h文件中，声明全局变量或常量；这里仅仅是声明，实现是在.m文件中
     如果这里只声明，而在.m文件中没有实现，外部如果使用的话编译会报错
     */
    extern NSString *name1;         //声明全局变量-外部可以修改
    extern NSString *const name2;   //声明全局常量-外部不能修改

    @interface Person : NSObject
        //显式声明extern表明其不是成员变量，而是全局变量
        extern NSString *name;
        extern int age;
    @end
    
    #import "Person.h"
    /*
     extern声明全局变量或常量的实现，必须实现，否则外部使用时，编译期会报错
     */
    NSString *name1 = @"zhangsan";
    NSString *const name2 = @"lisi";

    @implementation Person
        NSString *name = "zhangsan";
        age = 18;
    @end

    #import "WGMainObjcVC.h"
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        NSLog(@"修改前--全局变量name1:%@",name1);  //
        name1 = @"zhangsan11111";
        NSLog(@"修改后--全局变量name1:%@",name1);
        NSLog(@"修改前--全局常量name2:%@",name2);
        //name2 = @"lisi"; 编译器会报错:Cannot assign to variable 'name2' with const-qualified   
        type 'NSString *const  _Nonnull __strong'
    }
    @end
    
    打印结果: 修改前--全局变量name1:zhangsan
            修改后--全局变量name1:zhangsan11111
            修改前--全局常量name2:lisi
#### 分析，extern用来修饰全局变量或常量，一般在.h文件中声明，因为extern仅仅负责声明，而实现部分是需要我们在.m文件中实现的，如果不实现,外部使用变量/常量时会报错的;extern作用是用来获取全局变量或常量的，而不能用于定义变量；
#### 如何引用：Person类中定义了全局变量，如果在WGBaseVC类中想要使用就需要import Person的.h文件或者Person有子类的话 import Person的子类Student的头文件都可以访问Person类中定义的全局变量； 第二种方式是通过不导入头文件的方式进行调用，通过extern调用，来获取全局变量的值
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        //只是用来获取全局变量(包括全局静态变量)的值，不能用于定义变量
        extern NSString *name1;
        NSLog(@"获取到的全局变量值是:%@",name1);
    }
    @end



### 2.static
#### static,翻译过来是“静态的”意思，static可以用来修饰局部变量、全局变量；被static修饰的变量统称为**静态变量**；
* 生命周期: 这个变量能存活多久，它所占用的内存什么时候分配，什么时候收回
* 作用域：说白了就是这个变量在什么区域是可见的，可以拿来用的。
* 局部变量： 在函数或者说代码块内部声明的变量叫局部变量，局部变量存储在栈区，它的生命周期和作用域都是整个代码块

1. static修饰局部变量
* 存储区由栈区变为静态区
* 修饰的局部变量只会初始化一次;局部变量在程序中只有一份内存
* 不会改变局部变量的作用域，仅仅改变了局部变量的生命周期(只有程序结束，这个局部变量才会销毁)
* 保证局部变量只会被初始化一次,在程序运行过程中,只会分配一次内存,生命周期类似全局变量,但作用域不变
* 好处: 定义后只会存在一份值，只会初始化一次，每次调用都是使用的同一个对象内存地址的值，并没有重新创建，节省空间
* 坏处: 存在的生命周期长，从定义直到程序结束


        - (void)viewDidLoad {
            [super viewDidLoad];
            [self test];
            [self test];
            NSLog(@"-----------");
            [self test1];
            [self test1];
        }

        -(void)test {
            /* 局部变量
             作用域: test函数内，出了test函数就不能再被访问了
             声明周期: 和test函数声明周期一样，调用完test函数后就被销毁了
             */
            int num = 10;
            num = num + 1;
            NSLog(@"test: 当前的num值为:%d",num);
        }
        -(void)test1 {
            /* 被static修饰的局部变量-静态局部变量
             作用域: test1函数内，出了test1函数就不能再被访问了
             生命周期: test1函数执行结束后，该变量的生命周期仍然不会被销毁，它的生命周期是直到程序运行结束后才会被系统销毁
             内存中只会存在一份，第一次调用后num=11，再次调用后num值仍然是11，然后执行num = num + 1后就变成12了
             */
            static int num = 10;
            num = num + 1;
            NSLog(@"test1: 当前的num值为:%d",num);
        }
        打印结果: test: 当前的num值为:11
                test: 当前的num值为:11
                -----------
                test1: 当前的num值为:11
                test1: 当前的num值为:12
                

2. static修饰全局变量
* 将全局变量的作用域限制在当前文件中，在其它文件中无法访问
* 全局变量的作用域仅限于当前文件内部，即当前文件内部才能访问该全局变量
* ⚠️: 若全局变量在A文件的.h头文件中定义，那么在B文件中如果想访问，则impot A的头文件，则一样可以访问A文件中的静态全局变量，但是如果静态全局变量定义在A文件的.m文件中，则即便导入impot A的头文件也无法访问的
* 好处:定义后只会指向固定的指针地址，供当前文件使用,同一源程序的其他文件中可以使用相同名字的变量，不会发生冲突
* 坏处: 存在的生命周期长，从定义直到程序结束
* 建议: 内存优化和程序编译的角度来说,尽量少用全局静态变量，因为存在的生命周期长，一直占用空间;
* 程序运行时会单独加载一次全局静态变量，过多的全局静态变量会造成程序启动慢

4. 修饰函数
* 被修饰的函数被称为静态函数，使得外部文件无法访问这个函数，仅本文件可以访问
* 同一源程序的其他文件中可以使用相同名字的函数，不会发生冲突；编译器可对static静态函数进行更多的优化，因为已知该函数不会在其他源文件中使用

5. static修饰全局变量和修饰局部变量共同点
* 被static修饰后，无论全局变量还是局部变量，都会存储在全局数据区(全局变量原本都存储在全局数据区，即使不加static)
* 全局数据区的数据在程序启动时就被初始化，一直到程序运行结束后才会被系统回收内存
* 全局数据区的数据只会被初始化一次，以后只能改变其值，不能再被初始化

6. static作用
* 隐藏: 程序有多个文件时，将全局变量或函数的作用范围限制在当前文件，对其他文件隐藏。
* 保持变量内容的持久化: 将局部变量存储到全局数据区，使它不会随着函数调用结束而被销毁。

 
### 3.const
#### const，翻译过来是“常量”的意思，const用来修饰它右边的基本变量或指针变量，被const修饰的变量是不被允许修改变量值的
* const修饰的变量是针对它右边的变量的，即const右边的变量值不能被修改
* const修饰的变量是在**编译阶段**进行编译检查的
* const修饰的变量仅在编译阶段初始化一次，存储在**常量区**，直到程序运行结束后由系统回收

        const修饰变量的右边都不能被修改
        1. const修饰基本数据类型变量
        const int age1 = 10;                        //age1不能被修改
        int const age2 = 20;                        //age2不能被修改
        
        2. const修饰指针类型变量
        const NSString *name1 = @"zhangsan1";       //*name1不能被修改，name1可以被修改
        NSString const *name2 = @"zhangsan2";       //*name2不能被修改，name2可以被修改
        NSString *const name3 = @"zhangsan3";       //name3不能被修改，*name3可以被修改

        3. const嵌套使用
        const NSString *const name4 = @"zhangsan4";  //name4和*name4都不能被修改
        
        编译器会报错->Cannot assign to variable 'name3' with const-qualified type 'NSString *const __strong'
        //name3 = @"lisi";  

#### const使用场景
* 一般是联合static和const使用，来定义一个只能在当前文件中访问的、不能被修改的变量；类似#define定义，不过优点就在于这种方式可以指定变量类型，而#define不能

        static NSString *const name = @"zhangsan";
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
        }
        @end
#### const和宏(#define)区别
* 编译时刻不同：宏是预编译(编译之前处理)； const是编译阶段
* 编译检查: 宏不做检查、不会报编译错误、只是替换；const会编译检查、会报编译错误
* 宏优点就是可以定义函数、方法；const不能
* 宏缺点: 大量使用宏，会造成编译时间太长，每次都需要重新替换

### 4 考点
#### 项目中定义常量的方法有哪些？
1. 使用static和const定义全局静态变量(其实就是常量),只能在当前文件中使用

        static NSString *const name = @"zhangsan";
2. 使用extern和const,定义一个全局变量(其实就是常量),多个文件都可以访问,而且不需要导入对应的头文件都可以访问

        extern NSString *const name;
        @interface Person : NSObject
        @end

        #import "Person.h"
        NSString *const name = @"zhangsan";
        @implementation Person
        @end
3. 使用宏#define定义(切记后面不能添加分号;,否则编译器会报错)

        #define WGName @"张三"
    
### 5. @dynamic、@synthesize
#### iOS 6 之后 LLVM 编译器引入property autosynthesis，即属性自动合成，下面定义的属性会自定生成成员变量_name、getter/setter方法声明、getter/setter方法实现
        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, copy) NSString *name;
        @end
        
        @implementation WGMainObjcVC
        @dynamic name;   
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            self.name = @"zhangsan";
        }
        @end
#### @dynamic name; 告诉编译器，不要自动生成对应属性name的getter/setter方法实现，同时也不会自动生成属性对应的成员变量，方法实现需要我们程序员自己实现，如果我们没有实现，那么在访问属性过程中程序就会crash
        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, copy) NSString *name;
        @end

        @implementation WGMainObjcVC
        //这句代码也可以不写，默认生成成员变量的名称是_name
        @synthesize name = AAA;  
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            self.name = @"zhangsan";
        }
        @end
#### @synthesize name = AAA; 告诉编译期生成成员变量的名称为AAA,即在iOS6之后，@synthesize作用就是给成员变量起别名；@dynamic和@synthesize都没有写时，@property默认是@synthesize XXX = _XXX，@synthesize表示如果我们没有手动实现setter/getter方法，编译器会自动加上这两个方法，如果我们手动实现了setter/getter，那么系统就不会再自动生成setter/getter方法了


### 6. synchronized
#### synchronized是递归锁(@synchronized关键字在多线程环境中还具备递归锁定的能力。这意味着同一线程可以多次获取同一把锁，而不会导致死锁的产生，极大地提升了递归调用的安全性和可行性)，使用该关键字，可以将一段代码限制在一个线程内使用，其它线程想要访问，就必须等上一个线程访问完后才能访问，即保证了线程安全
        @interface WGMainObjcVC()
        @property(nonatomic, assign) int totalTicket;  //总票数
        @end
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            _totalTicket = 10;
            //线程1 卖5张
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                for (int i = 0; i < 5; i++) {
                    [self sealTicket];
                }
            });
            //线程1 卖5张
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                for (int i = 0; i < 5; i++) {
                    [self sealTicket];
                }
            });
        }

        -(void)sealTicket {
            _totalTicket -= 1;
            NSLog(@"当前剩余票数:%d",_totalTicket);
        }
        @end
        打印结果: 当前剩余票数:8
                当前剩余票数:9
                当前剩余票数:7
                当前剩余票数:7
                当前剩余票数:6
                当前剩余票数:5
                当前剩余票数:4
                当前剩余票数:3
                当前剩余票数:2
                当前剩余票数:1
#### 当多个线程同时去访问资源(_totalTicket变量)时，会导致资源数据错乱，为了保证同一时间只有一个线程访问资源，我们可以使用关键字synchronized来达到这个要求
        -(void)sealTicket {
            @synchronized (self) { //会对传入的对象分配一个递归锁
                _totalTicket -= 1;
                NSLog(@"当前剩余票数:%d",_totalTicket);
            }
        }
#### @synchronized关键字是实现线程同步和递归锁定的关键技术,内部实现原理基于Objective-C的运行时（Runtime）和底层的锁机制;
#### @synchronized关键字在编译时会被转换成Objective-C运行时库中的一个函数调用，即objc_sync_enter(获取锁)和objc_sync_exit(释放锁)
#### @synchronized关键字的递归锁定能力是通过在运行时维护一个线程到锁计数器的映射来实现的。当同一线程多次进入同一个@synchronized代码块时，锁计数器会递增，而不是重新获取锁。这样，即使线程多次进入临界区，也不会导致死锁。当线程离开@synchronized代码块时，锁计数器会递减，直到计数器归零，此时锁才会被释放，允许其他线程进入临界区https://www.51cto.com/article/795665.html
#### OC中的@synchronized在swift中已经被删除了，swift用objc_sync_enter/objc_sync_exit代替；
#### @synchronized内部为每一个obj分配一把recursive_mutex递归互斥锁。针对每个obj，通过这个recursive_mutex递归互斥锁进行加锁、解锁

## swift中关键词
### 1. fallthrough
#### fallthrough贯穿，主要用在switch条件语句中，Swift中的switch不会从上一个case分支落入到下一个 case 分支中；fallthrough 语句让 case 之后的语句会按顺序继续运行，且不论条件是否满足都会执行

        var score = 70                          var score = 70
        switch score {                          switch score {
        case 0...60:                            case 0...60:
            print("成绩不及格")                       print("成绩不及格")
        case 61...70:                           case 61...70:
            print("成绩良好")                         print("成绩良好")
        default:                                     fallthrough
            print("成绩优秀")                     case 31...60: 
        }                                            print("成绩不及格")
                                                     fallthrough
                                                default:
                                                    print("成绩优秀") 
                                                }                    

        打印结果: 成绩良好                         打印结果: 成绩良好
                                                        成绩不及格
                                                        成绩优秀
### 2. typealias 
#### 给已有类型重新定义名称，方便代码阅读;
    typealias Location = CGPoint
* 类型别名允许您为程序中的现有数据类型提供新名称。声明类型别名后，可以在整个程序中使用别名代替现有类型
* 类型别名不会创建新类型。它们只是为现有类型提供一个新名称
* typealias 的主要目的是使我们的代码更具可读性，并且在上下文中更清晰易懂，以供人类理解


### 3. associatedtype
#### associatedtype关联类型，关联类型为协议中的某个类型提供了一个占位名，其代表的实际类型在协议被遵守时才会被指定
    protocol WGOneProtocol : class {
        //设置关联类型
        associatedtype GenderType
        var sex: GenderType {get}  //性别
    }

    class Student : WGOneProtocol{
        //实现协议中的属性 必须通过typealias指定类型
        typealias GenderType = Bool
        var sex: GenderType = false 
    }

    class Animal : WGOneProtocol {
        //实现协议中的属性 必须通过typealias指定类型
        typealias GenderType = Int
        var sex: GenderType = 0
    }
* 在 Swift 中 associatedtype 是一种与协议（Protocol）相关的高级特性
* 它允许协议在定义时包含一个或多个占位类型，而不具体指明这些类型是什么，留待采用协议的具体类型来定义
* associatedtype 用于定义协议中的一个或多个关联类型;它们作为占位符，用来表示协议中某些属性或方法的类型，
但这些类型在协议定义时是不确定的。关联类型的具体类型由遵循协议的类型在实现时提供。
* associatedtype 只能在 protocol 中使用，class 中应该使用typealias进行代替。
* associatedtype 在协议中引入了一种灵活性，使得协议可以用于更广泛的类型，而不需要在协议定义时明确具体类型
* 协议中不支持泛型，如果在协议中需要达到泛型这种类似的效果,可以使用 associatedtype 关键字
        //错误例子: protocol 不支持范型，需要使用 associatedtype 来代替
        protocol Stack<Element> {

        }
        //正确例子： associatedtype 支持在 protocol 中实现范型的功能。
        protocol Stack {
            associatedtype Element
            func push(e: Element) -> Void
            func pop() -> Element
        }

### 4. mutating
#### mutating关键字指的是可变即可修改。用在结构体struct和枚举enum中,虽然结构体和枚举可以定义自己的方法，但是默认情况下，实例方法中是不可以修改值类型的属性的(值类型的属性不能被自身的实例方法修改)。为了能够在实例方法中修改属性值，可以在方法定义前添加关键字mutating。本质上mutating这个关键字就做了一件事情，默认给结构体LGStack添加了一个intou关键字，这个inout关键字传递的过程中传递的就是所谓的引用
        struct MyStruct {
            var name = ""
            var age = 0
            mutating func testFunc() {
                age = 18
            }
        }
        public override func viewDidLoad() {
            super.viewDidLoad()

            //这里必须是var修饰，否则编译器会报错
            var a = MyStruct()
            a.testFunc()
            NSLog("age:\(a.age)")
        }
        打印结果: age:18
        
#### 默认情况下,不能在实例方法中修改值类型的属性.若在实例方法中使用 mutating关键字,不仅可以在实例方法中修改值类型的属性,而且会在方法实现结束时将其写回到原始结构.
* Swift的结构体或者枚举的方法中，如果方法中需要修改当前结构体或者枚举的属性值，则需要再func前面加上mutating关键字，否则编译器会直接报错
* 普通函数传值参数是值传递，加mutating关键字后参数会变成地址传递
* mutating关键字本质是包装了inout关键字，加上mutating关键字后参数值会变成地址传递。
类对象是指针，传递的本身就是地址值，所以 mutating关键字对类是透明的，加不加效果都一样



### 5. final 
#### final关键字可以在class、func和var前修饰,表示**不可重写**，可以将类或者类中的部分实现保护起来,从而避免子类破坏；

        class WGMyClass {
            final var name = ""
            final func testFunc(){
                NSLog("WGMyClass->testFunc")
            }
        }
* final关键字表示不允许对其修饰的内容进行继承或者重新操作(重写)
* final在swift中，可以指定函数派发机制，通过final可以显示的指定函数的派发机制采用**直接派发**的方式，即直接调用函数地址进行方法调用

### 6. static
#### static关键字声明静态变量或者函数，它保证在对应的作用域当中只有一份, 同时也不需要依赖实例化,用static关键字指定的方法是类方法，他是不能被子类重写的

### 7. lazy
#### lazy修饰的变量, 只有在第一次被调用的时候才会去初始化值(懒加载),提高程序的性能


### 8. convenience
#### 使用convenience修饰的构造函数叫做便利构造函数,便利构造函数通常用在对系统的类进行构造函数的扩充时使用。
1. 便利构造函数通常都是写在extension里面
2. 便利函数init前面需要加载convenience
3. 在便利构造函数中需要明确的调用self.init()

### 9. deinit
#### deinit属于析构函数,当对象结束其生命周期时,系统自动执行析构函数。和OC中的dealloc 一样的,我们通常在deinit函数中进行一些资源释放和通知移除等
1. 对象销毁
2. KVO移除
3. 移除通知
4. NSTimer销毁


### 10. willSet、didset
#### 在Swift语言中用了willSet和didSet这两个特性来监视属性的除初始化之外的属性值变化

### 11 @objc、@objcMembers
#### @objc修饰符的根本目的是用来暴露接口给Objective-C的运行时(类、协议、属性、方法等)；添加@objc修饰并不意味着这个方法或属性会采用Objective-C的方式变成动态派发，swift仍可能会将其优化为静态调用；
1. selector调用的方法前需要加@objc，目的是允许函数在“运行时”通过oc消息机制调用
2. 协议的方法可选时，协议和可选方法前要用@objc声明
3. 用weak修饰协议时，协议前面要用@objc声明
4. 类前加上 @objcMembers，那么它及其子类、扩展里的方法都会隐式的加上 @objc
5. 扩展前加上 @objc，那么里面的方法都会隐式加上 @objc


### 12 defer
#### defer 语句块中的代码, 会在当前作用域结束前调用, 常用场景如异常退出后, 关闭数据库连接
    public override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("1111")
        defer {
            NSLog("------")
        }
        NSLog("2222")
    }
    
    打印结果: 1111
             2222
             ------
#### 如果有多个 defer, 那么后加入的先执行
        public override func viewDidLoad() {
            super.viewDidLoad()
            NSLog("1111")
            defer {
                NSLog("2222------")
            }
            defer {
                NSLog("3333------")
            }
            defer {
                NSLog("4444------")
            }
            NSLog("5555")
        }
        打印结果: 1111
                5555
                4444------
                3333------
                2222------

### 13 inout
#### inout 输入输出参数: 用inout定义的一个输入输出参数，可以在函数内部修改外部实参的值
1. 可变参数不能标记为inout
2. inout参数不能有默认值
3. inout参数的本质是地址传递(引用传递)
4. inout参数只能传入可以被多次赋值的

### 14. throws 和 rethrows 
#### throws 用在函数上, 表示这个函数会抛出错误； rethrows 与 throws 类似, 不过只适用于参数中有函数, 且函数会抛出异常的情况, rethrows可以用throws 替换, 反过来不行


## OC & swift 关键词
### swift和OC相比最大的优势是什么?
1. swift语法简洁,类型安全的语言.swift在编译期会进行类型检查,使我们开发过程中更早的发现问题
2. swift多了元组/反射的概念
3. swift面向协议编程,函数式编程,面向对象编程,swift函数是一等公民(函数可以作为变量,可以作为其它函数的参数,可以作为其它函数的返回值)
4. swift中值类型增强,swift中的struct/enum/元组等都是值类型;使用值类型好处就是它的不可变性/独立性
5. swift中的枚举增强,枚举可以使用整型/浮点型/字符串等,枚举还可以拥有属性和方法,还支持范型/协议/扩展等
6. swift支持泛型,也支持泛型约束,swift支持可选类型
7. swift的协议和扩展更丰富,扩展性更好. swift中的结构体+协议可以模拟class继承


## 属性修饰符
#### 一 iOS中属性修饰符主要有以下几种
1. copy
2. assign
3. strong
4. weak
5. readonly
6. readwrite
7. automic
8. nonautomic
9. retain

#### 如果按照ARC和MRC来区分的话，主要方式如下
    MRC手动管理（7个）: assign/retain/copy/readwrite/readonly/nonatomic/atomic  
    ARC自定管理（8个）: assign/strong/copy/readwrite/readonly/nonatomic/atomic/weak

### 1. assign修饰符
#### assign修饰符一般用来修饰基本数据类型(NSInteger/CGFloat/Int/Float/Double等)，被assign修饰的属性的setter方法是直接赋值的，不会进行任何retain操作,在MRC和ARC下都可以使用assign, 它的setter方法如下
    直接进行赋值操作
    -(void)setAge:(NSInteger)age {
        _age = age;
    }
#### 如果用assign修饰对象类型会如何？
    @interface WGMainObjcVC()
    @property(nonatomic, assign) Person *p1;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.p1 = nil;
        {
            Person *p0 = [[Person alloc]init];
            //p1是用assign修饰的，所以既不持有对象的强引用也不持有对象的弱引用
            self.p1 = p0;
            NSLog(@"p1的地址是：%@---p0的地址是:%@",self.p1, p0);
        }
        NSLog(@"p1的地址是：%@",self.p1);
    }
    @end
        
    打印结果: p1的地址是：<Person: 0x600003438430>---p0的地址是:<Person: 0x600003438430>
            编辑可以通过，但是在运行的时候会报错，报错信息如下
            message sent to deallocated instance 0x600003438430
#### 分析: 出了代码块后，p0因为超出作用域，所以会被销毁，那么p0指针指向的对象也会被销毁，而p1和p0指向了同一块内存，所以此时p1指针指向的对象也就跟着被销毁了，此时p1就是个野指针
* 野指针：指针指向的对象/内容已经被销毁了，即指针指向了一块“垃圾内存”；给野指针发消息会crash的，野指针并不是nil指针；
* 空指针：指的是没有存储任何内存地址的指针；给空指针发消息不会报错的；
* 僵尸对象： 一个OC对象引用计数为0被释放后就变成僵尸对象了，僵尸对象的内存已经被系统回收，虽然可能该对象还存在，数据依然在内存中，但僵尸对象已经是不稳定对象了，不可以再访问或者使用，它的内存是随时可能被别的对象申请而占用的。
#### 总结：assign一般用来修饰基本数据类型，若修饰对象，会出现野指针的问题；assign和weak的区别：就是weak在对象销毁的时，会自动将对象置为nil，而assign不会从而导致野指针问题（对象销毁了，指针指向了一个垃圾内存）;另外一个原因就是assgin修饰的基本数据类型，内存是分配在栈上的，栈内存的分配和销毁是由系统控制的，而对象类型的数据是分配在堆上的，用assign修饰的对象，在对象销毁时，对象的指针地址是还存在的，也就是说指针并没有被置为nil,

#### 2. atomic(原子属性)和nonatomic(非原子属性)
#### atomic原子属性是线程安全的，即多线程访问能够保证数据的完整性，为什么是线程安全的？因为系统在atomic属性的setter方法中添加了自旋锁来保证多线程访问的安全性，但是这样就耗费了系统资源。使用atomic原子属性并不都是线程安全的，因为atomic属性只有在setter/getter方法中是原子操作，是安全的，但是在setter/getter方法外不是原子操作的，例如++/--运算符情况下
#### nonatomic非原子属性，不是线程安全的，因为系统没有在属性的setter方法中添加自旋锁，它的特点是多线程并发访问性能高但不安全，所以nonatomic要注意多线程间通信的线程安全，项目中我们仍然会大量使用nonatomic非原子属性的原因也是因为访问性能高

    Runtime源代码 
    id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic) {
        if (offset == 0) {
            return object_getClass(self);
        }

        // Retain release world
        id *slot = (id*) ((char*)self + offset);
        if (!atomic) return *slot;

        // Atomic retain release world
        spinlock_t& slotlock = PropertyLocks[slot];
        slotlock.lock();   //加锁
        id value = objc_retain(*slot);
        slotlock.unlock();  //解锁
        
        //for performance, we (safely) issue the autorelease OUTSIDE of the spinlock.
        return objc_autoreleaseReturnValue(value);
    }

    using spinlock_t = mutex_tt<LOCKDEBUG>;
    class mutex_tt : nocopy_t {
        os_unfair_lock mLock;  //这是iOS10之后用到的互斥锁
    }
#### iOS 10之前atomic是用的自旋锁, iOS 10之后使用的是os_unfair_lock，这是一把互斥锁！(因为自旋锁会导致优先级反转问题)，那么自旋锁和互斥锁的区别是什么那？
* 自旋锁: 自旋锁会忙等: 所谓忙等，即在访问被锁资源时，调用者线程不会休眠，而是不停循环在那里，直到被锁资源释放锁。自旋锁的优点在于，因为自旋锁不会引起调用者睡眠，所以不会进行线程调度、CPU时间片轮转等耗时操作。所有如果能在很短的时间内获得锁，自旋锁的效率远高于互斥锁,缺点在于，自旋锁一直占用CPU，他在未获得锁的情况下，一直运行－－自旋，所以占用着CPU，如果不能在很短的时 间内获得锁，这无疑会使CPU效率降低。自旋锁不能实现递归调用。
* 互斥锁: 互斥锁会休眠: 所谓休眠，即在访问被锁资源时，调用者线程会休眠，此时CPU可以调度其他线程工作。直到被锁资源释放锁。此时会唤醒休眠线程。互斥锁可以传入不同参数，实现递归锁

#### 3. retain
#### MRC下使用的，会使引用计数+1，但在ARC下已经被舍弃了，改用strong来修饰了,如果我们在ARC环境的工程中想让某些文件支持MRC，可以在Build Phaes—>Compile Sources—>XXX文件 找到对应文件配置 -fno-objc-arc来支持MRC

    setter方法释放旧对象，retain新对象
    -(void)setName:(NSString *)name {
        if (_name != name) {
            [_name release];
            _name = [name retain];
        }
    }
        
#### 4. strong
#### ARC环境下才使用的，对应MRC环境下的retain。表示对对象的强引用，对象的引用计数+1，只要有一个strong指针指向对象，该对象就不会被销毁，ARC 下不显式指定任何属性关键字时，基本数据默认的关键字是 atomic、readwrite、assign，普通的OC对象: atomic、readwrite、strong。strong只能用来修饰对象类型，如果修饰基本数据类型，编译器会报错


#### 5. readonly/readwrite
#### readonly声明你的属性是只读的，并且告诉编译器不用自动生成setter方法；当你尝试给一个readonly的属性赋值时，会Xcode提示错误； readwrite声明的属性是可读可写的，编译器会自动生成setter/getter方法；readwrite是默认的；

#### 关于属性的setter/getter方法问题
#### 一般我们声明@property属性时，系统会自动为我们生成对应的成员变量(也叫实例变量)+setter/getter方法的声明和实现，当我们使用@dynamic XXX，此时系统就不会自动生成XXX对应的setter/getter方法实现，也不会生成对应的成员变量，但是不影响setter/getter方法的声明，如果我们自己又没有手动实现setter/getter方法，那么在调用存取方法时程序运行就会crash（编译期不会报错）；@synthesize XXX = _XXX,当我们@dynamic和@synthesize都没有写时，@property默认是@synthesize XXX = _XXX，@synthesize表示如果属性没有手动实现setter和getter方法，编译器会自动加上这两个方法，如果我们手动实现了setter/getter，那么系统就不会再自动生成setter/getter
    @interface Person : NSObject
    @property(nonatomic, strong) NSString *name;
    @end
    
    //@dynamic 告诉编辑器不自动生成name属性的getter和setter方法实现和对应的成员变量
    @implementation Person
    @dynamic name;   
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *p = [[Person alloc]init];
        //程序编译期不会报错，但在运行时会报错：因为@dynamic的声明，系统没有生成对应的setter/getter方法
        //reason: '-[Person setName:]: unrecognized selector sent to instance 0x600001d6a9a0'
        p.name = @"zhangsan";
    }
        
* @dynamic name1
#### 作用：告诉编译器不再生成成员变量_name1;不再生成name1属性的getter/setter的实现；但是不影响name1属性的setter/getter方法声明

* @synthesize name1 = _name1

#### 作用：告诉编译器生成成员变量_name1;生成name1属性的getter/setter的声明;生成name1属性的getter/setter的实现，如果自己手动实现了setter/getter方法，那么@synthesize就告诉编译器不再生成setter/getter方法的实现了,Xcode中我们编写属性后，默认就是这种模式，@synthesize的另一个作用就是给自定义生成成员变量的名称
        
#### 6. weak 
#### ARC环境下才会使用，weak弱引用不增加引用计数也不持有对象，适用于NSObject对象，weak修饰的对象在释放之后，指针地址会被置为nil，weak弱引用作用可以用来解决循环引用问题，并且weak不会造成野指针的问题
    weak修饰基本数据类型时，编译器会报错，weak只能用于对象类型
    @property(nonatomic, weak) NSInteger age;
    Property with 'weak' attribute must be of object type
        
#### weak是如何自动为释放了的对象的指针置为nil的？
#### Runtime维护了一个全局weak引用表(weak_table_t)，存储是以Id类型的对象作为key,用weak_entry_t结构体作为Value值来存储的
    /**
     * The global weak references table. Stores object ids as keys,
     * and weak_entry_t structs as their values.
     */
    
    struct weak_table_t {
        weak_entry_t *weak_entries;       //保存了所有指向指定对象的weak指针
        size_t    num_entries;            //weak对象的存储空间
        uintptr_t mask;                   //参与判断引用计数辅助量
        uintptr_t max_hash_displacement;  //hash key 最大偏移值
    };
    
    //weak全局表中存储weak定义的对象的表结构weak_entry_t,它负责维护和存储指向一个对象的所有弱引用hash表
    struct weak_entry_t {
        //是对泛型对象的指针做了一个封装,通过这个泛型类来解决内存泄漏的问题
        DisguisedPtr<objc_object> referent; 
        union {
            struct {
                weak_referrer_t *referrers;
                uintptr_t        out_of_line_ness : 2;
            uintptr_t        num_refs : PTR_MINUS_2;
            uintptr_t        mask;
            uintptr_t        max_hash_displacement;
        };
        struct {
            // out_of_line_ness field is low bits of inline_referrers[1]
            weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];
        };
    };
    ...
    }
        
#### weak_table_t(weak全局表)，采用hash哈希表的方式，来存储所有引用weak的对象，用weak指向的对象的内存地址作为key，用weak指针的地址(这个地址的值是所指对象指针的地址)数组作为Value来存储了,为什么value是数组？因为一个对象可能被多个弱引用指针指向

#### 6.1 weak底层实现原理及步骤
1. 初始化时，Runtime会调用objc_initWeak函数，初始化一个新的weak指针指向对象的地址。
 
        objc_initWeak(id *location, id newObj) {
            if (!newObj) {  //查看对象实例是否有效,无效对象直接导致指针释放
                *location = nil;
                return nil;
            }
            //对象实例有效，则通过storeWeak函数，对象实例被注册为一个指向value的__weak对象
            return storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
                (location, (objc_object*)newObj);
        }
2. 添加引用时，objc_initWeak函数会调用 objc_storeWeak() 函数， objc_storeWeak() 的作用是更新指针指向，创建对应的弱引用表。
3. 释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。

#### 6.2 weak对象释放自动置为nil的过程
1. 调用objc_release
2. 因为对象的引用计数为0，所以执行dealloc
3. 在dealloc中，调用了_objc_rootDealloc函数
4. 在_objc_rootDealloc中，调用了object_dispose函数
5. 调用objc_destructInstance
6. 最后调用objc_clear_deallocating。
7. 对象准备释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。

#### 总结： weak是Runtime维护了一个全局的哈希表，用来存放指向某个对象的所有weak指针，weak表其实是一个hash（哈希）表，Key是所指对象的地址，Value是weak指针的地址（这个地址的值是所指对象指针的地址）数组。


#### 7. copy/mutableCopy

    源对象类型        拷贝方法         副本对象类型      是否产生新对象      拷贝类型
    NSString         copy           NSString           NO         浅拷贝(指针拷贝)
                     mutableCopy    NSMutableString    YES        深拷贝(内容拷贝)
                                     
    NSMutableString  copy           NSString           YES        深拷贝(内容拷贝)
                     mutableCopy    NSMutableString    YES        深拷贝(内容拷贝)
                                     
    NSArray          copy           NSArray             NO        浅拷贝(指针拷贝)
                     mutableCopy    NSMutableArray      YES       深拷贝(内容拷贝)
                                     
    NSMutableArray   copy           NSArray             YES       深拷贝(内容拷贝)
                     mutableCopy    NSMutableArray      YES       深拷贝(内容拷贝)
                                     
    NSXXXX           copy           NSXXXX              NO        浅拷贝(指针拷贝)
                     mutableCopy    NSMutableArray      YES       深拷贝(内容拷贝)
                                      
    NSMutableXXXX    copy           NSXXXX              YES       深拷贝(内容拷贝)                         
                     mutableCopy    NSMutableXXXX       YES       深拷贝(内容拷贝)
                                     
#### iOS中对象拷贝有2种类型：深拷贝+浅拷贝，浅拷贝不会产生新的对象，深拷贝会产生新的对象
     array1    浅拷贝    array2      array1   深拷贝    array2   深拷贝        
       0------->A<--------0           0------->A        0------->A
       1------->B<--------1           1------->B        1------->B
       2------->C<--------2           2------->C        2------->C
       3------->D<--------3           3------->D        3------->D

#### copy关键字有两个需要注意的地方，第一是什么时候使用Copy?第二是深拷贝浅拷贝问题；
#### 7.1什么时候用copy? 
1. 修饰block，在MRC下，copy可用来修饰block,block内部的代码块是在栈区的，使用copy关键字可以把它放在堆区；在ARC环境下，使用strong和copy效果是一样的
2. 修饰NSString、NSArray、NSDictionary

#### 7.2 修饰不可变字符串
    //.m文件
    @interface WGMainObjcVC()
    @property(nonatomic, strong) NSString *strongStr;
    @property(nonatomic, copy) NSString *copyyStr;
    @end

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        //1. 用不可变字符串赋值操作, 无论strong或者copy，其指向的地址都是baseStr的地址，即copy拷贝的是对象的地址
        NSString *baseStr = [NSString stringWithFormat:@"123"];
        _strongStr = baseStr;
        _copyyStr = baseStr;
        NSLog(@"baseStr对象地址: %p,对象的指针地址:%p, 值:%@",baseStr,&baseStr,baseStr);
        NSLog(@"strongStr对象地址: %p,对象的指针地址:%p, 值:%@",_strongStr,&_strongStr,_strongStr);
        NSLog(@"copyyStr对象地址: %p,对象的指针地址:%p, 值:%@",_copyyStr,&_copyyStr,_copyyStr);
    }
    @end
        
    打印结果: baseStr对象地址: 0x8c43b6f85e3255c4,对象的指针地址:0x7ffee68ae790, 值:123
            strongStr对象地址: 0x8c43b6f85e3255c4,对象的指针地址:0x7f9726c08790, 值:123
            copyyStr对象地址: 0x8c43b6f85e3255c4,对象的指针地址:0x7f9726c08798, 值:123
#### 总结，对于用不可变的源对象NSString/NSArray/NSDictionary来给copy和strong修饰的对象进行赋值操作，都是对源对象的地址拷贝并没有开辟新的内存，即指针都是指向了源对象，copy进行的是浅拷贝
    //1. 用不可变字符串赋值操作, 无论strong或者copy，其指向的地址都是baseStr的地址，即copy拷贝的是对象的地址
    NSString *baseStr = [NSString stringWithFormat:@"123"];
    NSLog(@"baseStr对象地址: %p,对象的指针地址:%p, 值:%@",baseStr,&baseStr,baseStr);
    _strongStr = baseStr;
    _copyyStr = baseStr;
    //当重新对baseStr进行赋值时，因为baseStr是不可变字符串，为了保持不可变性，系统会另外开辟内存空间来存放变更后的内容
    //但是这并不会影响copy和strong修饰的对象
    baseStr = @"456";
    NSLog(@"baseStr对象地址: %p,对象的指针地址:%p, 值:%@",baseStr,&baseStr,baseStr);
    NSLog(@"strongStr对象地址: %p,对象的指针地址:%p, 值:%@",_strongStr,&_strongStr,_strongStr);
    NSLog(@"copyyStr对象地址: %p,对象的指针地址:%p, 值:%@",_copyyStr,&_copyyStr,_copyyStr);
    
    打印结果: baseStr对象地址: 0xf113747087f4ecf8,对象的指针地址:0x7ffee2874790, 值:123
            baseStr对象地址: 0x10d390610,对象的指针地址:0x7ffee2874790, 值:456
            strongStr对象地址: 0xf113747087f4ecf8,对象的指针地址:0x7f8391a0e980, 值:123
            copyyStr对象地址: 0xf113747087f4ecf8,对象的指针地址:0x7f8391a0e988, 值:123


#### 7.3 数组拷贝
#### 数据拷贝规则：
1. 不可变数组1->copy=不可变数组2，不可变数组1和不可变数组2的地址是一样的，即浅拷贝
2. 不可变数组1->mutableCopy=可变数组2，不可变数组1和可变数组2的地址是不一样的，即深拷贝
3. 可变数组1->copy=不可变数组2，可变数组1和不可变数组2的地址是不一样的，即深拷贝
4. 可变数组1->mutableCopy=可变数组2，可变数组1和可变数组2的地址是不一样的，即深拷贝
#### 数组里面装的元素是基本数据类型时，遵循上面的规则；如果数据里面装的是模型数据，同样遵循上面的规则，但是模型元素不会进行深拷贝
    Person *p1 = [[Person alloc]init];
    Person *p2 = [[Person alloc]init];
    Person *p3 = [[Person alloc]init];

    NSArray *baseArr = @[p1, p2, p3];
    NSArray *copyArr = [baseArr copy];
    NSMutableArray *mutableCopyArr = [baseArr mutableCopy];

    NSLog(@"\n源数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",baseArr,baseArr[0],baseArr[1],baseArr[2]);
    NSLog(@"\n浅拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",copyArr,copyArr[0],copyArr[1],copyArr[2]);
    NSLog(@"\n深拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",mutableCopyArr,mutableCopyArr[0],mutableCopyArr[1],mutableCopyArr[2]);
        
    打印结果: 源数组地址:0x600000045eb0
                ---元素1:0x60000001ecf0
                ---元素2:0x60000001ed20
                ---元素3:0x60000001ed40
            浅拷贝copy后数组地址:0x600000045eb0
                ---元素1:0x60000001ecf0
                ---元素2:0x60000001ed20
                ---元素3:0x60000001ed40
            深拷贝copy后数组地址:0x600000046000
                ---元素1:0x60000001ecf0
                ---元素2:0x60000001ed20
                ---元素3:0x60000001ed40
#### 如果数组里面装的是模型数据，那么经过copy和mutableCopy后仍然遵守上面的拷贝规则，但是深拷贝后，数组中的模型数据的地址仍然指向的是之前的模型元素对象，即深拷贝中，模型数据是不会进行深拷贝的； 如果我们想深拷贝的时候，也把模型数据拷贝一份，该如何解决？


#### 存放模型元素的数组如何进行深拷贝，达到数组中的模型元素也进行深拷贝？
#### 方案1：数组拷贝时不再调用mutableCopy，而是调用initWithArray:baseArr copyItems:YES 方法，该方法要求数组中的元素要遵守NSCopying协议 ，实现copyWithZone方法

    @interface Person : NSObject
    @property(nonatomic, strong) NSString *name;
    @end

    @interface Person()<NSCopying>
    @end


    @implementation Person
    -(id)copyWithZone:(NSZone *)zone {
        Person *p = [[self class] allocWithZone:zone];
        p.name = [_name copy];
        return p;
    }
    @end

    Person *p1 = [[Person alloc]init];
    Person *p2 = [[Person alloc]init];
    Person *p3 = [[Person alloc]init];

    NSArray *baseArr = @[p1, p2, p3];
    NSArray *copyArr = [baseArr copy];
    NSMutableArray *mutableCopyArr = [[NSMutableArray alloc]initWithArray:baseArr copyItems:YES];

    NSLog(@"\n源数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    baseArr,baseArr[0],baseArr[1],baseArr[2]);
    NSLog(@"\n浅拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    copyArr,copyArr[0],copyArr[1],copyArr[2]);
    NSLog(@"\n深拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    mutableCopyArr,mutableCopyArr[0],mutableCopyArr[1],mutableCopyArr[2]);

    打印结果: 源数组地址:0x610000055ea0
                ---元素1:0x610000006180
                ---元素2:0x610000006190
                ---元素3:0x6100000061a0
            浅拷贝copy后数组地址:0x610000055ea0
                ---元素1:0x610000006180
                ---元素2:0x610000006190
                ---元素3:0x6100000061a0
            深拷贝copy后数组地址:0x610000055ff0
                ---元素1:0x6100000061b0
                ---元素2:0x6100000061c0
                ---元素3:0x6100000061d0

#### 如果模型中含有模型数据，怎么办？ (如person中含有stu模型)
* 那么Student类也要遵守NSCopying协议并实现copyWithZone方法，这样就是开辟了新的空间，实现了内容的深拷贝

        @interface Person : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, strong) Student *stu;
        @end
#### 结论：生成新的Student模型，开辟新的存储空间，Student模型基本元素相互不影响。
#### 如果模型中数组属性含有模型，怎么办？(如person中属性studentArr存放的是Student模型)
        @interface Person : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, strong) NSArray *studentArr;
        @end
#### 结论：主模型(Person)数组(studentArr)中的模型(Student)不会开辟新的内存空间，仍然是同一个对象。

#### 方案2 归档和解档
#### 模型遵守NSCoding协议，并实现协议方法，如下
    @interface Person : NSObject
    @property(nonatomic, strong) NSString *name;
    @end

    @interface Person()<NSCoding>
    @end

    @implementation Person
    -(instancetype)initWithCoder:(NSCoder *)coder {
        self = [super init];
        if (self) {
            self.name = [coder decodeObjectForKey:@"name"];
        }
        return self;
    }
    -(void)encodeWithCoder:(NSCoder *)coder {
        [coder encodeObject:self.name forKey:@"name"];
    }
    @end
        
    Person *p1 = [[Person alloc]init];
    Person *p2 = [[Person alloc]init];
    Person *p3 = [[Person alloc]init];
    NSArray *baseArr = @[p1, p2, p3];
    NSArray *copyArr = [baseArr copy];

    //2、归档和解档
    //归档
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:baseArr];
    //接档
    NSMutableArray *mutableCopyArr = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    NSLog(@"\n源数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    baseArr,baseArr[0],baseArr[1],baseArr[2]);
    NSLog(@"\n浅拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    copyArr,copyArr[0],copyArr[1],copyArr[2]);
    NSLog(@"\n深拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",  
    mutableCopyArr,mutableCopyArr[0],mutableCopyArr[1],mutableCopyArr[2]);
    
    打印结果：源数组地址:0x600000243300
                ---元素1:0x60000000ea80
                ---元素2:0x60000000ea90
                ---元素3:0x60000000eaa0
            浅拷贝copy后数组地址:0x600000243300
                ---元素1:0x60000000ea80
                ---元素2:0x60000000ea90
                ---元素3:0x60000000eaa0
            深拷贝copy后数组地址:0x600000243900
                ---元素1:0x60000000eab0
                ---元素2:0x60000000eaf0
                ---元素3:0x60000000eb00

#### 归档解档能够完美完成数组中模型对象的深拷贝，无论是模型嵌套模型还是模型中数组属性包含模型都可以实现深拷贝

#### 数组中元素是模型数据，实现深拷贝方案总结：
1. initWithArray:copyItems：模型遵守NSCopying(对象可以copy)或NSMutableCopying(对象可以mutableCopy)协议，并实现copyWithZone和mutableCopyWithZone方法，

        @interface Person : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) NSInteger age;
        @end

        @interface Person()<NSCopying,NSMutableCopying>  
        @end

        @implementation Person
        -(id)copyWithZone:(NSZone *)zone {
            Person *p = [[[self class] allocWithZone:zone]init];
            p.name = [_name copy];
            p.age = _age;
            return p;
        }
        -(id)mutableCopyWithZone:(NSZone *)zone {
            Person *p = [[[self class] allocWithZone:zone]init];
            p.name = [_name mutableCopy];
            p.age = _age;
            return p;
        }
        @end

2. 归档解档：模型遵守NSCoding协议，并实现initWithCoder和encodeWithCoder方法

        @interface Person : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) NSInteger age;
        @end

        @interface Person()<NSCoding> 
        @end

        @implementation Person
        -(instancetype)initWithCoder:(NSCoder *)coder {
            self = [super init];
            if (self) {
                self.name = [coder decodeObjectForKey:@"name"];
                self.age = (int)[coder decodeObjectForKey:@"age"];
            }
            return self;
        }
        -(void)encodeWithCoder:(NSCoder *)coder {
            [coder encodeObject:self.name forKey:@"name"];
            [coder encodeInteger:self.age forKey:@"age"];
        }
        @end
3. 两种方式中，initWithArray:copyItems方式只能对一级模型进行拷贝，如果模型中含有数组模型，它就无能为力了；而利用归档和解档就不存在这个问题


### 8 案例题目
#### 为什么NSString、NSArray、NSDictionary等一般用copy修饰？

    @interface WGMainObjcVC : UIViewController
    @property(nonatomic, strong) NSArray *arr;
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        
        NSMutableArray *sourceArr = [NSMutableArray arrayWithObject:@"123"];
        //用可变的数组给arr进行赋值
        self.arr = sourceArr;
        
        //修改sourceArr的元素
        [sourceArr addObject:@"123"];
        
        NSLog(@"arr地址:---%p----arr元素:---%@",self.arr,self.arr);
        NSLog(@"sourceArr地址:---%p----sourceArr元素:---%@",sourceArr,sourceArr);
    }
    
    打印结果: arr地址:---0x600000059a70----arr元素:---(123, 123)
                sourceArr地址:---0x600000059a70----sourceArr元素:---(123, 123)
#### 若用strong关键字来修饰NSArray属性，当外部源数组是可变类型时，并且对数组进行赋值，其实是个浅拷贝，就是数组和外部的数组的地址是一样的，如果此时修改外部数组的元素(添加或删除)，那么当前的属性数组的内容就也会跟着改变，这在开发中是不允许的；而用copy修饰的话，即使外部的源数组是可变的，但是copy修饰的数组被外部可变数组赋值后是深拷贝，即重新生成了一份新的对象，即使修改外部可变数组的元素(添加或删除)，也不会影响当前的属性数组的内容，所以**开发中，NSString、NSArray、NSDictionary类型一般用copy修饰**
