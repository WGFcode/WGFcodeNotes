## Swift基础语法
### 1. 协议protocol
#### 在Swift中苹果将protocol这种语法发扬的更加深入和彻底。Swift中的protocol不仅能定义方法还能定义属性，配合extension扩展的使用还能提供一些方法的默认实现，swift中类、结构体、枚举都可以遵守协议；协议规定了有哪些属性和方法，至于属性值是多少、方法怎么实现协议都不管，留给实现协议的类/结构体/枚举去实现，类似Java中的接口

    //声明一个协议
    protocol MyProtocol {
        /*
         协议中定义属性要求
         1. 必须用var修饰，不能用let修饰
         2. 必须指定属性类型，且要指定是只读的{get}还是可读可写的{get set}
         3. 不能定义可选类型的属性、不能设置默认值
         4. 可以定义类型属性，只能用static来修饰，不能用class来修饰
         类/结构体/枚举中协议属性的实现
         1. 遵守协议的类/结构体/枚举 必须实现协议中的属性，否则编译器报错
         2. 实现协议中的属性，其实就是在遵守协议的类/结构体/枚举中写上初始值即可
         3. 协议中实现属性，若属性是可读可写的，必须用var修饰；若属性是只读的，则可用let或var修饰都可以
         */
        var name: String { get set }         //读写属性
        var age: Int { get }                 //只读属性
        static var sex: Bool { get }         //类属性-只读
        static var height: Double{ get set } //类属性-读写属性
        //var sex: bool? { get set }         //不能为协议添加可选类型属性
        //let aaa: String { get set }        //不能添加let属性，只能添加可变属性var
        //var aaa: Bool = false              //属性不能有默认值
        //class var aaa : String {get set}   //定义类属性，不能用class来修饰，只能用static来修饰
        
        /*
         协议中定义方法要求
         1. 只能声明方法，方法实现由遵守协议的类/结构体/枚举去实现，即方法不能有方法体
         2. 方法参数不能有默认值，否则编译器会报错
         3. 可以定义实例方法、类型方法(类方法)
         4. swift官方不建议在struct、enum(class本身都可以不受影响)的普通方法中修改属性变量，但若方法用mutating修饰，就可以在方法内修改
         类/结构体/枚举中协议方法的实现
         1. 方法的实现过程中参数可以指定默认值
         2. 若是类遵守了协议，在实现类型方法(类方法)时，可以用class或static修饰都可以；若是结构体、枚举则只能用static修饰
         3. 若方法用mutating修饰，若是类，在实现方法时方法前不能写mutating；若是结构体、枚举，需要修改内部成员时需要添加mutating来修饰，若不需要修改，则去掉mutating也可以
         */
        func testA(paramer1: String) -> String    //实例方法
        static func testB()                       //类型方法/类方法
        mutating func testC()                     //实例方法
        //class func testC()                      //声明类型方法不能用class修饰，只能用static
        
        /* 协议中定义初始化器方法
         1. 实现协议中初始化器方法时，非final类实现时必须加上required，若是finial类则可不加
         2. 若父类遵守了协议，子类可以遵守也可不遵守，类的继承体系中不会强制子类也继承属性的，和OC一样的
         */
        init(name: String)
    }

    //类遵守协议
    public class MyClass : MyProtocol {
        //协议中属性的实现
        var name: String = ""
        var age: Int = 0  //对只读属性var换成let也可以
        static var sex: Bool = false
        static var height: Double = 1.0
        
        //协议中方法的实现
        func testA(paramer1: String) -> String {
            return ""
        }
        static func testB() { //static换成class也可以
        }
        func testC() {  //在类中mutating不能写，否则编译器会报错
        }
        
        //协议中初始化器方法的实现
        required init(name: String) {
        }
    }
#### 协议中可以定义属性和方法(包括初始化器方法)，协议中属性和方法有以下要求
1. 协议中可以定义属性、实例方法、类型方法(类方法)、构造器函数
2. 协议中属性必须指定属性类型、指定是只读{get}还是可读可写{get set}的、必须用var来修饰，不能用let修饰
3. 协议中可以定义方法，但是定义的方法中参数不能有默认值、方法不能有方法体
4. class、struct、enum都可以遵守协议，切都需要实现协议中的属性、方法，有一个没有实现，编译器都会报错
5. class、struct、enum遵守协议并实现属性时，只读的属性可以用var或let修饰都可以，可读可写的属性只能用var修饰
6. class、struct、enum遵守协议并实现方法时，方法参数可以设置默认值;static修饰的方法，class实现过程可以用class或static修饰都可以，而struct、enum只能用static修饰
#### 1.1 协议中定义的属性、方法，如何能够实现可选的属性、方法
1. 通过@objc optional来实现（不推荐）

        @objc protocol MyProtocol {
            @objc optional var name: String {get set}
            @objc optional func testB()
        }
        //类遵守协议
        public class MyClass : MyProtocol {
           
        }
2. 通过协议扩展实现(推荐)

        extension MyProtocol {
            //var name: String = "" 协议扩展中这样写不是协议中属性的默认实现，编译器会报错
            var name: String {
                get {
                    return ""
                }
                set{
                }
            }
            var age: Int {
                return 0
            }
            static var sex: Bool {
                get{
                    return false
                }
            }
            static var height: Double {
                get{
                    return 0.0
                }
                set{
                }
            }
            func testA(paramer1: String) -> String {
                return ""
            }
            static func testB() {  //协议扩展中只能用static，不能用class修饰
                
            }
            mutating func testC(){ //协议扩展中mutating可写也可以不写
                
            }
        }
#### 若遵守协议的class/enum/struct不想实现协议中的属性或方法，可以通过协议扩展来对协议中的属性和方法提供个默认实现，这样class/enum/struct即便没有实现协议中的属性或方法，编译器也不会报错

#### 1.2 协议继承
#### swift中的协议能够继承一个或多个其他协议，可以在继承的协议基础上增加新的内容要求。协议的继承语法与类的继承相似，多个被继承的协议间用逗号分隔。
        //声明一个协议
        protocol  MyBaseProtocol {
            //协议中定义的属性、方法
            var name: String { get set }
            func testA(paramer1: String) -> String
        }

        //协议继承
        protocol MyProtocol : MyBaseProtocol {
            func testB()
        }


        //类遵守协议
        public class MyClass : MyProtocol {
            //实现协议中属性和方法
            var name: String = ""

            func testA(paramer1: String) -> String {
                return ""
            }
            func testB() {
                
            }
        }
#### 1.3 多个协议重名方法调用冲突
#### 在Swift中并没有规定不同的协议内方法不能重名,所以若多个协议中定义相同了方法名只是返回值不同，那么就容易导致重名方法调用冲突的问题，如下
        protocol WGOneProtocol {
            func testA() -> String
        }
        protocol WGTwoProtocol {
            func testA() -> Int
        }
        class WGMyClass : WGOneProtocol, WGTwoProtocol {
            func testA() -> String {
                return ""
            }
            func testA() -> Int {
                return 0
            }
        }
        class WGMyVC : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let cls = WGMyClass()
                cls.testA()  //Ambiguous use of 'testA()'
            }
        }
#### 当创建WGMyClass实例对象，调用协议中的方法testA()时，编译器会报错:Ambiguous use of 'testA()',意思就是调用的方法是模糊的，因为编译器不知道协议中同名的方法到底调用的哪个？解决方案就是指定特定调用特定协议的方法，即将调用者进行类型转换

        class WGMyVC : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let cls = WGMyClass()
                (cls as WGOneProtocol).testA()  //调用的是返回值为String的方法
                (cls as WGTwoProtocol).testA()  //调用的是返回值为Int的方法
            }
        }
#### 1.4 协议的继承、聚合、检查、关联类型
#### 1.4.1 协议的继承：协议可以继承一个或者多个其他协议并且可以在它继承的基础之上添加更多要求，协议继承的语法与类继承的语法相似，使用逗号分隔；
        protocol  MyBaseProtocol {
            var name: String { get set }
            func testA(paramer1: String) -> String
        }

        //协议继承
        protocol MyProtocol : MyBaseProtocol {
            func testB()
        }
#### 1.4.2 协议的聚合: 开发中要求一个类型同时遵守多个协议是很常见的，除了用协议继承，我们还可以用协议聚合复合多个协议到一个要求中
        protocol WGOneProtocol {
            func testA() -> String
        }
        protocol WGTwoProtocol {
            func testA() -> Int
        }
        typealias Three = WGOneProtocol & WGTwoProtocol

        class WGMyClass{
            //参数类型使用了协议的聚合，这里我们并不关心参数是什么类型，只要参数遵守WGOneProtocol、WGTwoProtocol协议的要求就行
            func testA(paramer: Three) {
                
            }
            func testB(paraamer: WGOneProtocol & WGTwoProtocol) {
                
            }
        }
#### 协议的继承和协议的聚合区别
* 协议的继承是定义了一个全新的协议，我们希望它能够“大展拳脚”得到普遍使用
* 协议的聚合并没有定义固定协议类型，它只是定义了一个临时的拥有所有聚合协议要求的局部协议，可能是“一次性需求”
* 协议聚合保持了代码的简洁性、易读性，去除了不必要的新类型的繁琐，定义和使用的地方如此接近，见名知意
* 协议聚合也被称为匿名协议聚合，但它表达的信息就少一些，所以需要开发者斟酌使用
#### 1.4.3 协议检查： 检查一个类型是否遵守了某个协议

        class WGMyVC : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let cls = WGMyClass()
                let isConfirm = cls is WGOneProtocol
                if isConfirm {
                    NSLog("实现了该协议")
                }
            }
        }
#### 如何让定义的协议只能被class类遵守，而struct、enum不能？就是让协议继承class或者AnyObject即可;swift提供了两种特殊的类型Any、AnyObject，Any可以代表任意类型(枚举、结构体、类，也包括函数类型),而AnyObject可以代表任意类类型(在协议后面写上: AnyObject代表只有类能遵守这个协议)
        protocol WGOneProtocol : class {
            func testA() -> String
        }
        或者
        protocol WGOneProtocol : AnyObject {
            func testA() -> String
        }
        
        class WGMyClass : WGOneProtocol{
            func testA() -> String {
                return ""
            }
        }
        //如果是枚举、结构体继承，编译器就会报错
        //编译器报错信息： Non-class type 'MyEnum' cannot conform to class protocol 'WGOneProtocol'
        enum MyEnum : WGOneProtocol { 
        }
#### 1.4.4 协议的关联类型：根据使用场景的变化，如果协议中某些属性存在“逻辑相同的而类型不同”的情况，可以使用关键字associatedtype来为这些属性的类型声明“关联类型”
#### 例如我们想设置性别，若是学生类型我们设置性别为Bool类型(true/false)，若是动物类型我们设置为Int类型(0/1),这种情况就属于逻辑相同而类型不同，如果没有协议的关联类型，那么就需要创建2个协议，分别设置性别属性为Bool和Int类型，所以关联类型在某些情况下更简洁

        protocol WGOneProtocol : class {
            //设置关联类型
            associatedtype GenderType
            var sex: GenderType {get}
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
        
        class WGMyVC : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let stu = Student()
                stu.sex = true          //设置stu对象的性别为true
                
                let ani = Animal()
                ani.sex = 1             //设置ani对象的性别为1
            }
        }
#### 1.5 协议扩展的作用
1. 通过协议的扩展提供协议中某些属性和方法的默认实现，将公共的代码和属性统一起来极大的增加了代码的复用，同时也增加了协议的灵活性和使用范围，这样的协议不仅仅是一系列接口的规范，还能提供相应的逻辑，是面向协议编程的基础。
2. 协议可以作为类型来使用

        1. 在函数、方法或者初始化器里作为形式参数类型或者返回类型
        2. 作为常量、变量或者属性的类型；
        3. 作为数组、字典或者其他存储器的元素的类型。

### 2. 枚举
#### 2.1 枚举定义、使用
        enum MyEnum {
            case one
            case two
            case three
        }
        enum MyEnum1 {
            case one, two, three
        }
        
        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                var num = MyEnum.one
                var num1: MyEnum = .one
            }
        }
#### swift枚举中每个元素前有关键字case,或者用一个case 然后把多个元素用逗号隔开也行

#### 2.2 给枚举成员赋值
        //指定枚举类型，给枚举成员赋值
        enum MyEnum : String {
            case one = "第一"
            case two  = "第二"
            case three = "第三"
        }
        
        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                NSLog("枚举元素one的值是:\(MyEnum.one.rawValue)")
            }
        }
#### 给枚举成员赋值，可以通过枚举变量的rawValue获取枚举元素的值
#### 通过枚举元素的值给枚举变量赋值：假如我们只知道一个枚举成员的值是"第一"，而不知道"第一"这个值对应的枚举成员是"one",Swift中是可以通过“第一”这个值给枚举变量赋一个枚举成员“one”的
        enum MyEnum : String {
            case one = "第一"
            case two  = "第二"
            case three = "第三"
        }

        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                //因为不知道枚举中是否有对应的成员变量，所以是可选的
                var num: MyEnum? = MyEnum.init(rawValue: "第一")
                if num == MyEnum.one {
                    NSLog("第一这个值对应的枚举变量是one")
                }
            }
        }

#### 2.3 枚举值自增
#### swift中枚举值如果是Int类型，第一个赋值后，后面的会自增的;若是声明了枚举类型为Int,但是没有对枚举元素赋值，默认是从0开始递增的;若枚举类型是String类型，但是没有赋值，则通过rawValue打印的内容是枚举变量的名称
        enum MyEnum : Int {
            case one = 1
            case two
            case three
        }

        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                NSLog("---\(MyEnum.one.rawValue)----\(MyEnum.two.rawValue)----\(MyEnum.three.rawValue)") //---0----1----2
            }
        }
#### 2.4 枚举关联值
#### 给枚举变量赋值时，给枚举变量关联一个值,定义枚举变量时在后面添加小括号(类型)即可；swift支持4种关联值类型(整型/浮点数/字符串/布尔类型)
        enum MyEnum {
            case one (String)
            case two (String, Int)
            case three (Bool)
        }

        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let num1 = MyEnum.one("张三")
                let num2 = MyEnum.two("李四", 18)
                let num3 = MyEnum.three(false)
            }
        }
        
#### 2.4 枚举函数
#### swift中枚举是可以添加函数的
        enum MyEnum {
            case one (String)
            case two (String, Int)
            case three (Bool)
            func descrip() -> String {
                switch self {
                case MyEnum.one(let para):
                    return "this is \(para)"
                case .two(let para1, let para2):
                    return "this is \(para1)-\(para2)"
                default:
                    return "this is di san"
                }
            }
        }

        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let num = MyEnum.one("diyi")
                num.descrip()    
                //打印结果--this is diyi
            }
        }
#### 2.4 枚举嵌套
        enum MyEnum : String {
            //东西南北 东西有上下 南有左右
            enum east {
                case top
                case bottom
            }
            enum west {
                case top
                case bottom
            }
            enum south {
                case left
                case right
            }
            case north
        }

        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let dic = MyEnum.east.top
                
            }
        }

#### 2.5 枚举中添加属性
#### swift枚举中不能添加存储属性，但是可以添加基于枚举变量的计算属性
        enum MyEnum {
            case one
            case two
            case three
            //计算属性
            var name: String {
                switch self {
                case .one:
                    return "1"
                case .two:
                    return "2"
                default:
                    return "3"
                }
            }
        }
#### 2.6 枚举中添加静态方法
        enum MyEnum {
            case one
            case two
            case three
            
            static func prin(num: String) -> MyEnum?{
                if num == "zero" {
                    return .one
                }
                return nil
            }
        }
        
        class MyClass : UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                let numType = MyEnum.prin(num: "zero")
            }
        }
#### 2.7 枚举中添加可变方法(mutating)
#### 枚举、结构体是无法修改内部的成员变量的，如果想要修改，需要在方法前面添加mutating关键字
        enum MyEnum {
            case one
            case two
            case three
            mutating func next() {
                switch self {
                case .one:
                    self = .two
                case .two:
                    self = .three
                case .three:
                    self = .one
            }
        }

### 3. 结构体
####  结构体是由一系列相同类型或不同类型的数据构成的集合，swift中结构体是值类型，一般情况(类对象是是引用类型，通常存放在堆空间，如果结构体对象是类对象的属性，那么该结构体对象也相应存放在堆空间) 存放在栈空间且是连续内存地址存储的，由系统来管理内存；结构体总是通过被复制的方式在代码中传递，因此它的值是不可修改的
        /* swift结构体: 
         swift结构体中定义属性
         1. 定义属性可以是常量let也可以是变量var
         2. 默认情况下系统会为每个结构体提供一个默认的构造函数，且该构造函数要求给每个成员属性进行赋值
         3. 定义的属性若不提供初始化值，那么在创建该结构体时必须使用系统提供的默认构造器init(x1:type,x2:type...)进行初始化
         4. 定义的属性若提供了初始化值，那么在创建该结构体时就可以不使用系统提供的默认构造器方法而使用WGStruct()进行初始化即可
         5. 定义的属性若有些提供了初始化值，有些没有提供，那么创建该结构体时必须使用系统提供的构造器进行初始化(系统会根据情况提供多个构造器函数，目的就是让所有的成员变量在初始化),该构造器能够将没有初始化的成员进行初始化赋值
         
         swift结构体中定义方法
         1. 可以定义普通方法,方法参数可以包含默认值
         2. 可定义可变方法:struct默认情况下是不能修改成员变量值的，若需要修改，需要在方法前面添加关键字mutating
         3. 可定义类型方法,只能用static关键字来修饰
         */
        struct WGStruct {
            //定义属性(变量或常量)
            var name: String = ""
            var age: Int = 0
            let sex: Bool = false
            //定义普通方法
            func testA(param: String = "") {
                NSLog("this is swift struct common method")
            }
            //定义可以修改成员变量的方法
            mutating func testB() {
                age += 10
            }
            //定义类型方法(类方法)
            static func testC() {
                NSLog("this is swift struct static method")
            }
        }
#### 3.1 struct中方法调用
#### swift中方法调用分两种
1. 静态调度(static dispatch):  静态调度在执行的时候，会直接跳到方法的实现，静态调度可以进行inline和其他编译期优化。
2. 动态调度 dynamic dispatch. 动态调度在执行的时候，会根据运行时(Runtime)，采用table的方式，找到方法的执行体，然后执行。动态调度也就没有办法像静态那样，进行编译期优化。
#### struct中方法调用时静态调度





### 4. swift值类型和引用类型区别
1. 值类型，在赋值时，会进行拷贝；
2. 值类型是线程安全的，每次都是获得一个copy，不存在同时修改一块内存(不可变状态),使用值类型,不需要考虑别处的代码可能会对当前代码有影响
2. 引用类型，在赋值的时候，只会进行引用（指针）拷贝
