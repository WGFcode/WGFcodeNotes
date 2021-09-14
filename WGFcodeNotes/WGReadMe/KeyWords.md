##  iOS开发中常用关键字(含swift)
### 1.extern
#### extern,翻译过来是“外面的、外部的”，作用就是声明外部全局变量或常量；需要注意extern只能声明，不能用于实现；开发中我们通常会单独创建一个类来管理一些全局的变量或常量，例如管理通过通知名称

    /*
     extern都是写在.h文件中，声明全局变量或常量；这里仅仅是声明，实现是在.m文件中
     如果这里只声明，而在.m文件中没有实现，外部如果使用的话编译会报错
     */
    extern NSString *name1;         //声明全局变量-外部可以修改
    extern NSString *const name2;   //声明全局常量-外部不能修改

    @interface Person : NSObject
    @end
    
    #import "Person.h"
    /*
     extern声明全局变量或常量的实现，必须实现，否则外部使用时，编译期会报错
     */
    NSString *name1 = @"zhangsan";
    NSString *const name2 = @"lisi";

    @implementation Person
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
#### 使用场景：我们在WGMainObjcVC文件中想要访问Person文件的全局变量/常量，而不需要导入Person的头文件就可以访问，只需要Person的.h文件中的全局变量/常量用extern修饰即可
#### 分析，extern用来修饰全局变量或常量，一般在.h文件中声明，因为extern仅仅负责声明，而实现部分是需要我们在.m文件中实现的，如果不实现,外部使用变量/常量时会报错的;extern作用是用来获取全局变量或常量的，而不能用于定义变量；


### 2.static
#### static,翻译过来是“静态的”意思，static可以用来修饰局部变量、全局变量；被static修饰的变量统称为**静态变量**；
* 生命周期: 这个变量能存活多久，它所占用的内存什么时候分配，什么时候收回
* 作用域：说白了就是这个变量在什么区域是可见的，可以拿来用的。
* 局部变量： 在函数或者说代码块内部声明的变量叫局部变量，局部变量存储在栈区，它的生命周期和作用域都是整个代码块

1. static修饰局部变量
* 修饰的局部变量只会初始化一次
* 局部变量在程序中只有一份内存
* 不会改变局部变量的作用域，仅仅改变了局部变量的生命周期(只有程序结束，这个局部变量才会销毁)
* 保证局部变量只会被初始化一次,在程序运行过程中,只会分配一次内存,生命周期类似全局变量,但作用域不变

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

4. 修饰函数
* 被修饰的函数被称为静态函数，使得外部文件无法访问这个函数，仅本文件可以访问

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
#### @dynamic name; 告诉编译器，不要自动生成对应属性name的getter/setter方法实现，方法实现需要我们程序员自己实现，如果我们没有实现，那么在访问属性过程中程序就会crash
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
#### synchronized是递归锁，使用该关键字，可以将一段代码限制在一个线程内使用，其它线程想要访问，就必须等上一个线程访问完后才能访问，即保证了线程安全
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
#### 给已有类型重新定义名称，方便代码阅读
    typealias Location = CGPoint

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
### 4. mutating
#### mutating关键字指的是可变即可修改。用在结构体struct和枚举enum中,虽然结构体和枚举可以定义自己的方法，但是默认情况下，实例方法中是不可以修改值类型的属性的。为了能够在实例方法中修改属性值，可以在方法定义前添加关键字mutating。本质上mutating这个关键字就做了一件事情，默认给结构体LGStack添加了一个intou关键字，这个inout关键字传递的过程中传递的就是所谓的引用
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
### 5. final 
#### final关键字可以在class、func和var前修饰,表示**不可重写**，可以将类或者类中的部分实现保护起来,从而避免子类破坏；
final用在swift中，可以指定函数派发机制，若用final修饰，通过final可以显示的指定函数的派发机制采用**直接派发**的方式，即直接调用函数地址进行方法调用

        class WGMyClass {
            final var name = ""
            final func testFunc(){
                NSLog("WGMyClass->testFunc")
            }
        }

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
