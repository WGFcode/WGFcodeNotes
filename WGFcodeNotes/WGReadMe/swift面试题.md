#### 1. Swift 到底是面向对象还是函数式的编程语言？
#### swift既是面向对象的(因为swift支持类的封装、继承、和多态)，又是函数式的编程语言(Swift 支持 map, reduce, filter, flatmap 这类去除中间状态、数学函数式的方法，更加强调运算结果而不是中间过程)

#### 2. swift中class、struct区别
1. class: 引用类型
2. struct: 值类型
3. 二者的本质区别：struct是深拷贝；class是浅拷贝
4. struct分配在栈中，class分配在堆中。
5. struct不可以继承，class可以继承。
6. struct 的 function 要去改变 property 的值的时候要加上 mutating，而 class 不用。
7. swift的可变内容和不可变内容用var和let来甄别，如果初始为let的变量再去修改会发生编译错误；class不存在这样的问题
8. 变量赋值方式不同：struct是值拷贝；class是引用拷贝

        class WGClassTest{
            var age = 0
        }
        struct WGStructTest {
            var age = 0
        }

        public override func viewDidLoad() {
            super.viewDidLoad()
            var a = WGClassTest()
            var b = a
            b.age = 20
            NSLog("Class:a.age:\(a.age)----b.age:\(b.age)")
            //因为 a 和 b 都是引用类型，本质上它们指向同一内存,改变b对象属性的值，a对象属性的值也会改变
            
            var a1 = WGStructTest.init()
            var b1 = a1
            b1.age = 30
            NSLog("struct:a1.age:\(a1.age)----b1.age:\(b1.age)")
            // a1 和 b1都是值类型，a1 和 b1 是不同的东西，改变b1对a1不会有任何的影响
        }
        打印结果:Class:a.age:20----b.age:20
                struct:a1.age:0----b1.age:30

#### struct 是苹果推荐的，原因在于它在小数据模型传递和拷贝时比 class 要更安全，在多线程和网络请求时尤其好用
#### 3. swift定义常量和OC中定义常量有什么区别
    OC定义常量: const int number = 0;
    swift定义常量: let number = 0
####  OC中 const 表明的常量类型和数值是在**编译时**确定的，而Swift中let只是表明常量(只能赋值一次)，其类型和值既可以是静态的，也可以是一个动态的计算方法，它们在**运行时**确定的

#### 4. 说说Swift为什么将String,Array,Dictionary设计成值类型？
#### 值类型相对引用类型，最大的优势在于内存使用的高效，值类型在栈上操作的，引用类型在堆上操作的；栈上的操作仅仅是单个指针的上下移动，而堆上的操作则涉及到合并、一定、重新链接等，swift将String,Array,Dictionary设计为值类型，大幅减少了堆上的内存分配和回收的次数，同时写时复制又将值传递和复制的开销降到了最低；同时设计为之值类型，也是为了线程安全考虑


#### 5. swift的静态派发
#### OC中的方法都是**动态派发**(方法调用)，swift中的方法分为**动态派发**和**静态派发**
1. 动态派发:  指的是方法在运行时才找到具体实现，swift中的动态派发和OC中的动态派发是一样的
2. 静态派发: 静态派发是指运行时调用方法不需要查表，直接跳转到方法的代码中执行
3. 静态派发特点：更高效(因为免去了查表操作);静态派发的条件是方法内部的代码必须对编译器透明，且在运行时不能被修改
4. swift中的值类型不能被继承，也就是值类型的方法实现不能被修改或者被重写，因此值类型的方法满足静态派发

#### 6. dynamic framework 和 static framework的区别是什么？
1. 静态库是每个程序单独打包一份；动态库则是多个程序之间共享
2. 静态库和动态库是相对编译期和运行期的。静态库在程序编译时会被链接到目标代码中，程序运行时将不再更改静态库；而动态库在程序编译期时并不会被链接到目标代码中，只是在程序运行时才被载入
3. 静态库在链接时，会被完整的拷贝到可执行文件中，若有多个app都使用了同一个静态库，那么每个app都会拷贝一份，缺点是浪费内存
4. 动态库不会拷贝，只有一份，程序运行时动态加载到内存中，系统只会加载一次，多个程序共用一份，节约了内存
5. 相同点：静态库和动态库都是闭源库只能拿来满足某个功能的使用,不会暴露内部具体的代码信息.

#### 7.Swift中的常量和OC中的常量有啥区别？
1.OC中用 const 是用来表示常量的；Swift 中用 let 是用来判断是不是常量。
2.OC中的常量（const）是编译期决定的，Swift中的常量（let）是运行时确定的
3.Swift中的常量可以是非特定类型的，即它们的类型可以在运行时确定

#### 8.指定构造器和便利构造器有什么区别？
1. 指定构造器: 标配，每个类至少要有一个指定构造器，可以没有便利构造器；初始化类中的所有属性
2. 便利构造器: 次要、辅助；最终调用本类中的里的指定构造函数；

        public class WGTest {
            var name: String
            //1.指定构造器: 将初始化类中提供的所有属性，并调用合适的父类构造器让构造过程沿着父类链继续往上进行
            init(name: String) {
                self.name = name
                //若WGTest有父类，则需要调用父类的指定构造器 例如: super.init
            }
            
            //2.便利构造器: 用convenience修饰的构造器都是便利构造器，便利构造器是类中比较次要的、辅助型的构造器
            //定义便利构造器来调用同一个类中的指定构造器，并为部分形参提供默认值
            convenience init() {
                self.init(name: "zhangsan")
            }
        }
#### 类类型的构造器规则
1. 指定构造器必须调用其直接父类的的指定构造器(若有父类则调用，没有父类则不调用)
2. 便利构造器必须调用同类中定义的其它构造器
3. 便利构造器最后必须调用指定构造器。

*一个更方便记忆的方法是：
1. 指定构造器必须总是向上代理
2. 便利构造器必须总是横向代理 

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/init.jpg)
                   
#### 8.1 指定构造器和便利构造器的继承
#### swift 中的子类默认情况下不会继承父类的构造器，子类去继承父类中的构造函数有条件，遵循规则
1. 如果子类中没有任何构造函数，它会自动继承父类中所有的构造器
2. 如果子类提供了所有父类指定构造函数的实现，那么它会自动继承所有父类的便利构造函数；如果重写了部分父类指定构造器，那么是不会自动继承便利构造器函数的

        验证规则一
        class Car{
            var speed:Double
            var banner:String
            //指定构造函数
            init(speed:Double,banner:String){
                print("父类指定1------start")
                self.speed = speed
                self.banner = banner
                print("父类指定1------end")
            }
            //指定构造函数
             init(speed:Double){
                 print("父类指定2------start")
                 self.speed = speed
                 self.banner = "A123"
                 print("父类指定2------end")
            }
            //便利构造函数
            convenience init(){
                print("父类便利-----start")
                self.init(speed:20,banner:"B890")
                print("父类便利-----end")
            }
        }

        class Bus:Car{
        }
        
        //调用便利构造器
        var b1 = Bus.init()       
            父类便利-----start
            父类指定1------start
            父类指定1------end
            父类便利-----end
            
        //调用指定构造器
        var b2 = Bus.init(speed: 10) 
            父类指定2------start
            父类指定2------end
            
        //调用指定构造器
        var b3 = Bus.init(speed: 20, banner: "zhangsan") 
            父类指定1------start
            父类指定1------end
        
        验证规则二
        class Big:Car{
            var weight:Double 
            
            //重写父类指定构造函数
            override init(speed:Double,banner:String){
                print("Bus---------start")
                self.weight = 100
                super.init(speed:speed,banner:banner)
                print("Bus---------end")
            }
            //重写父类指定构造函数
            override init(speed:Double){
                print("Businit(speed---------start")
                self.weight = 100
                super.init(speed:speed,banner:"BBBB")
                print("Businit(speed---------end")
            }
        }
        
        var B1 = Big()
            父类便利-----start
            Bus---------start
            父类指定1------start
            父类指定1------end
            Bus---------end
            父类便利-----end

#### 8.2 可失败构造函数
#### 为什么需要可失败的构造函数？
* 对一个类或者结构体初始化的时候可能失效
* 失败原因：初始化传入的形参值无效，缺少外部资源

#### 如何来定义可失败的构造函数？
* 其语法在 init 关键字后面添加问号 （init?)
* 可失败的构造函数里应该设计一个return nil语句 （没有也不会报错）
* 通过可失败的构造函数构造出来一个实例是一个可选型

        普通的构造函数
        class Animal{
            var species:String 
            init(species:String){
                self.species = species
            }
        }

        //提问：cat1是什么类型？  Animal 
        var cat1 = Animal(species:"Cat")
        
        可失败的构造函数
        class Animal2{
            var species:String
            init?(species:String){
                if species.isEmpty{
                    return nil //一旦传进来的是空值，就构造失败
                }
                self.species = species
            }
        }
        //提问：dog是什么类型？Animal的可选型
        var dog = Animal2(species:"Dog")
        print(dog!.species)
        var tmp = Animal2(species:"")
        print(tmp)//传进去的是空值，构造失败，结果为nil

#### 总结: 指定构造器和便利构造器有什么区别？
1. 类必须要至少有一个指定构造器，可以没有便利构造器
2. 便利构造器必须调用本类中的另一个构造器，最终调用到本类的指定构造器
3. 便利构造器前面需要添加convenience关键字

#### 9. Any和AnyObject的区别
* Any: 表示任意类型，包括基本数据类型、结构体、枚举、类和函数等。适用于需要处理多种不同类型的值的情况
* AnyObject: 表示任意**类类型**的实例。适用于需要处理任意类实例的情况;AnyObject是Any的子集

#### 10.inout关键字
#### 总结：inout的本质就是引用传递（地址传递）
#### 默认情况下，函数参数默认是常量，试图从函数体中去改变一个函数的参数值会报编译错误

        //编译器报错: Cannot assign to value: 'name' is a 'let' constant
        func test(name: String) {
            name = "张三"
        }
#### 如果希望函数内部可以修改参数的值，并在函数结束后修改的值仍能反映在原始变量上，则需要在参数名后面添加inout关键词来修饰函数参数

        var myName: String = "lisi"
        func test( name: inout String) {
            name = "zhangsan"
        }
        
        print("start------myName:\(myName)")
        self.test(name: &myName)
        print("end------myName:\(myName)")
        //打印结果:    
        start------myName:lisi
        end------myName:zhangsan
        
        将外部变量传递给函数，函数内部对参数进行了修改，且在函数结束时，修改的值被保留了下来
* inout关键字只能修饰变量，无法修饰常量，因为常量和字面量不能被修改(若myName用let修饰，则编译器会报错)
* inout参数不能有默认值，可变参数不能标记为inout
* 调用函数的时候，应该在变量名前放置&符号表示该变量可以由函数修改     

        struct Shape {
            //1.存储属性
            var width: Int
            //2.属性观察器
            var side: Int {
                willSet {
                    print("willSet", newValue)
                }
                didSet {
                    print("didSet", oldValue, side)
                }
            }
            //3.计算属性
            var girth: Int {
                set {
                    print("setGirth")
                    width = newValue / side
                }
                get {
                    print("getGirth")
                    return width * side
                }
            }
            func show() {
                print("show------start")
                print("width=\(width), side=\(side), girth=\(girth)")
                print("show------end")
            }
        }

        func test(_ num: inout Int) {
            print("test------start")
            num = 20
            print("test------end")
        }
        //参数时
        var s = Shape(width: 10, side: 4)
        test(&s.width)
        s.show()
        
        //打印结果:
        test------start
        test------end
        show------start
        getGirth
        width=20, side=4, girth=80
        show------end
#### inout参数是存储属性时：
#### 存储属性有自己的内存地址，所以直接把存储属性的地址传递给需要修改的函数，在函数内部修改存储属性的值
把实例s中存储属性width的内存地址传给了test函数；结构体的存储属性使用inout的本质和全局/局部变量都一样，都是地址传递。

        //参数是计算类型
        var s = Shape(width: 10, side: 4)
        test(&s.girth)
        s.show()
        
        //打印结果:
        getGirth
        test------start
        test------end
        setGirth
        show------start
        getGirth
        width=5, side=4, girth=20
        show------end
#### 上面的&s.girth不是地址传递了，因为girth是计算属性，不占用结构体的内存，那么是如何传递值的那
* 执行代码test(&s.girth)首先调用了girth的getter方法，getter方法会返回一个值，这个值放在临时空间内（局部变量）
* 调用test方法时是把getter返回的临时变量作为参数传递的（传递的还是地址值），这时候在test方法内部修改的是临时变量内存的值
* 当修改局部变量内存时，会调用girth的setter方法，把局部变量的值作为参数传递给setter方法
* 最终的结果就是值被修改了

#### inout参数是计算属性时：
#### 由于计算属性没有自己的地址值，所以会调用getter方法获取一个局部变量，把局部变量的值传递给需要修改的函数，在函数内部修改局部变量的值，
最后把局部变量的值传递给setter方法

        //参数有属性观察器时
        var s = Shape(width: 10, side: 4)
        test(&s.side)
        s.show()
        
        //打印结果:
        test------start
        test------end
        willSet 20
        didSet 4 20
        show------start
        getGirth
        width=10, side=20, girth=200
        show------end
#### 修改带有属性观察器的存储属性值时，和计算属性的过程有点类似。先拿到属性的值给局部变量，然后把局部变量的地址值传递给需要修改的函数，
函数内部会修改局部变量的值。函数执行完成后把已经修改过的局部变量的值赋值给属性。赋值时，优先执行属性的willset方法，willset执行结束后，
才会真正修改属性的值，最后调用didset

#### inout关键字总结:
1. 如果实参有物理内存地址，且没有设置属性观察器
    直接将实参的内存地址传入函数（实参进行引用传递）
2.如果实参是计算属性或设置了属性观察器，采取Copy In Copy Out的做法
    调用该函数时，先复制实参的值，产生一个副本（局部变量-执行get方法）
    将副本的内存地址传入函数（副本进行引用传递），在函数内部可以修改副本的值
    函数返回后，再将副本的值覆盖实参的值（执行set方法）
3.什么是Copy In Copy Out？先Copy到函数里，修改后再Copy到外面。
4.inout参数的本质是地址传递 (引用传递)，不管什么情况都是传入一个地址。
5. Swift 值类型中，属性的默认行为是不可变的。mutating关键字，用于在结构体或枚举的方法中修改属性
使用mutating修饰的方法（func）在修改属性后更新原始值，而不是返回一个新的副本
mutating关键字只能用于值类型，mutating关键字本质是包装了inout关键字，加上mutating关键字后参数值会变成地址传递。
类对象是指针，传递的本身就是地址值，所以 mutating关键字对类是透明的，加不加效果都一样

#### 11.什么是自动闭包、逃逸闭包、非逃逸闭包？
#### 11.1 非逃逸闭包: 
#### 非逃逸闭包: 永远不会离开一个函数的局部作用域的闭包就是非逃逸闭包


#### 11.2 逃逸闭包: 
#### 逃逸闭包: 当一个闭包作为参数传到一个函数中，但是这个闭包在函数返回之后才被执行，我们称该闭包从函数中逃逸。称为逃逸闭包，
在形式参数前写@escaping来明确闭包是允许逃逸的；直白点就是逃逸闭包是**传递给函数的闭包会在函数返回后执行**
#### ⚠️逃逸闭包可能导致循环引用（retain cycle）问题。当闭包在函数之外执行，尤其是在闭包和类实例之间产生相互引用时
应使用捕获列表（capture list），指定捕获方式为 weak 或 unowned


#### 11.3 自动闭包： 
#### 自动闭包：是一种自动创建的闭包，用来把作为实际参数传递给函数的表达式打包的闭包.他不接受任何实际参数,
并且当它被调用时,它会返回内部打包的表达式的值
#### 自动闭包（autoclosure）是 Swift 中一种特殊的闭包类型，它可以自动将表达式封装在一个没有参数的闭包中。
当函数需要延迟求值或执行特定表达式时，可以用自动闭包将表达式传递给函数。这种类型的闭包在调用时不需要使用括号

#### 自动闭包： 主要特点
1. **无参数**：自动闭包是一种无参数的闭包，它从上下文中捕获值，而不是通过参数传递
2. **延迟求值**：自动闭包在调用时才执行，这意味着它们只有在显示调用时才对表达式求值。因此，可以在需要时触发表达式的执行，实现代码的延迟计算
3. **语法简洁**：自动闭包允许对实际的闭包表达式进行简化，使代码更可读和易理解。
4. 要使用自动闭包，可以在函数参数类型前加上 **@autoclosure** 关键字

#### swift 将函数作为一等公民: 意味着它们可以像其他数据类型一样，被用作变量、常量、参数或返回值

#### 12 什么是Optional(可选项或者叫可选类型)?
#### 在变量类型后面加问号？表示该变量可能有值可能没有值
#### 底层Optional是一个包含None和Some(Wrapped)两种类型的泛枚举类型，Optional.None即nil，Optional.Some非nil
        @frozen public enum Optional<Wrapped> : ExpressibleByNilLiteral {
            /// The absence of a value.
            ///
            /// In code, the absence of a value is typically written using the `nil`
            /// literal rather than the explicit `.none` enumeration case.
            case none

            /// The presence of a value, stored as `Wrapped`.值的存在，存储为“Wrapped”
            case some(Wrapped)
        }
        var optional1: String? = nil
        var optional2: String? = .none

* 在OC中， nil是一个指向不存在对象的指针(OC非对象类型也可以设置成nil但是会有警告⚠️：指针不兼容)
* 在Swift中，nil不是指针，而是值缺失的一种特殊类型，任何类型的可选项都可以设置为nil而不仅仅是对象类型
*Swift 是一种类型安全的语言，而 Objective-C 不是。这意味着在 Swift 中，每个类型的 nil 都是不同的，例如 Int? 的 nil 和 String? 的 nil 是不同的，它们所代表的空值的类型不同。
* 非可选项类型，不可设置为nil。Optional既可以包装值类型也可以包装引用类型

#### 13. swift的派发机制
#### 函数的派发机制：
1. 静态派发（直接派发）
2. 函数表派发
3. 消息派发

#### 影响 Swift 的派发方式有以下几个方面
1. 声明位置
2. 指定派发
3. 优化派发
#### 在 Swift 中，一个函数有两个可以声明的位置
* 初始声明的作用域
* 扩展声明的作用域

        // 初始声明的作用域
        class MyClass {
            func mainMethod() { ... }
        }

        // 扩展声明的作用域
        extension MyClass {
            func extensionMethod() { ... }
        }


* swift中所有值类型：struct、enum使用直接派发。
* swift中协议的extensions(扩展)使用直接派发，初始声明的作用域内函数使用函数表派发
* swift中class中extensions使用直接派发，初始声明的作用域内函数使用函数表派发
* swift中NSObject的子类用，初始声明的作用域内函数使用函数表派发，扩展声明的作用域内的函数使用消息发送

                      Initial Declaration    Extension Declaration
        Value Type          static                 static
        Protocol            table                  static
        Class               table                  static
        NSObject Subclass   table                  message


#### swift（关键字）显示指定派发方式
1. 添加**final/static**关键字的函数使用直接派发
2. 添加**dynamic/@objc**关键字函数使用消息派发
3. 添加@inline关键字的函数告诉编译器可以使用直接派发

#### final 修饰符允许类中的函数使用 直接派发。final 修饰符会让函数失去动态性。任何函数都可以使用 final 修饰符，包括 extension 中原本就是直接派发的函数
#### dynamic 修饰符允许类中的函数使用 消息派发。使用 dynamic 修饰符之前，必须导入 Foundation 框架，因为框架中包含了 NSObject 和 Objective-C 的运行时。dynamic 修饰符可以修饰所有的 NSObject 子类和 Swift 原生类





#### 14 try、try？、try

try: 需要用“ do catch”捕捉异常，如果在“try”代码块中出现异常，程序会跳转到相应的“catch”代码块中执行异常处理逻辑，然后继续执行“catch”代码块后面的代码
try?: 是返回一个可选值类型，如果“try?”代码块中出现异常，返回值会是“nil”，否则返回可选值。可以在运行时判断是否有异常发生。
try!: 类似于可选型中的强制解包，它不会对错误进行处理，如果“try!”代码块中出现异常，程序会在异常发生处崩溃


#### 15.存储属性、计算属性、类型属性区别
存储属性: 用来进行数据的存储；需要分配内存；子类(无论是let var static修饰)不能直接重写存储属性；
         重写（Override）通常用于子类覆盖父类的方法、计算属性或观察者
         
计算属性: 用来定义计算的过程, 不需要分配空间.计算属性必须使用var关键字进行定义

类型属性: 用于定义某个类所有实例共享的数据;oc和swift都可以有类型属性
        oc需要添加属性关键字class定义类型属性
        swift用static/class来定义类型属性；static(不支持重写) class(支持子类重写)


#### 16.extension 中能增加存储属性吗?
#### extension :可以增加计算属性，不能增加存储属性
#### extension是用来给存在的类型添加新行为的并不能改变类型或者接口本身。因为 extension 不能为类或结构体增加实际的存储空间

#### 17.swift 中 closure闭包 与 OC 中 block 的区别？
#### 相同点：都是一段可以执行的代码块
1、closure 是匿名函数，block 是一个结构体对象。
2、closure 可以通过逃逸闭包来在内部修改变量，block 通过 __block 修饰符

#### 18.作用域关键字的区别
* private 只可以在本类而且在同一个作用域中被访问.
* fileprivate 可以在本类中进行访问.
* internal (默认值) 只能访问自己module(模块)的任何internal实体，不能访问其他模块中的internal实体.
* public 类似于final，可以被其他module被访问，不可以被重载和继承.
* open 可以被其他module被访问、被重载、被继承.

#### 19 什么是柯里化？



柯里化：把接受多个参数的函数变成接受一个单一参数（最初函数的第一个）的函数，并且返回接受余下的参数和返回结果的新函数

#### 20 什么是函数式编程？
面向对象编程：将要解决的问题抽象成一个类，通过给类定义属性和方法，让类帮助我们解决需要处理的问题(即命令式编程，给对象下一个个命令)
函数式编程：数学意义上的函数，即映射关系（如：y = f(x)，就是 y 和 x 的对应关系，
         可以理解为"像函数一样的编程")。它的主要思想是把运算过程尽量写成一系列嵌套的函数调用

        数学表达式
        (1 + 2) * 3 - 4
        传统编程
        var a = 1 + 2
        var b = a * 3
        var c = b - 4
        函数式编程
        var result = subtract(multiply(add(1,2), 3), 4)
函数式编程的好处：代码简洁，开发迅速；接近自然语言，易于理解；更方便的代码管理；易于"并发编程"；

#### 21. associatedtype 的作用
#### 简单来说就是 protocol 使用的泛型

        protocol ListProtcol {
            associatedtype Element
            func push(_ element:Element)
            func pop(_ element:Element) -> Element?
        }
        
        实现协议的时候, 可以使用 typealias 指定为特定的类型, 也可以自动推断
        class IntList: ListProtcol {
            typealias Element = Int // 使用 typealias 指定为 Int
            var list = [Element]()
            func push(_ element: Element) {
                self.list.append(element)
            }
            func pop(_ element: Element) -> Element? {
                return self.list.popLast()
            }
        }
        
        class DoubleList: ListProtcol {
            var list = [Double]()
            func push(_ element: Double) {// 自动推断
                self.list.append(element)
            }
            func pop(_ element: Double) -> Double? {
                return self.list.popLast()
            }
        }


#### 22.Self 的使用场景
#### Self 通常在协议中使用, 用来表示实现者或者实现者的子类类型.
#### 在 Swift 中，self通常是指类或结构中的当前对象，Self表示任何当前类型
#### 在 Swift 中，Self指的是一种类型——通常是当前上下文中的当前类型。正如小写self可以表示当前对象，大写Self可以表示当前类型
        protocol CopyProtocol {
            func copy() -> Self
        }
        
        //如果是结构体去实现, 要将Self 换为具体的类型
        struct SomeStruct: CopyProtocol {
            let value: Int
            func copySelf() -> SomeStruct {
                return SomeStruct(value: self.value)
            }
        }
        
        class SomeCopyableClass: CopyProtocol {
            func copySelf() -> Self {
                return type(of: self).init()
            }
            required init(){}
        }
        
        //例如 : Self指的是符合Numeric协议的类型。在示例中2去调用则Self将是具体类型Int。如果是2.0则Self将是具体类型Double
        extension Numeric {
            func squared() -> Self {
                return self * self
            }
        }
        2.squared() 
        2.0.squared() 

#### 23. OC中的协议和swift中的协议 有什么区别？
1. Objective-C 的协议：声明方法，不能实现
2. Swift 中的协议：它可以定义计算属性、方法、关联类型、静态方法和静态计算属性等
3. Swift 的协议还支持泛型、默认实现、条件约束。


#### 24.Swift 中的类型擦除
#### 协议如何支持泛型？在 Swift 中，protocol 支持泛型的方式与 class/struct/enum 不同
1. 对于 class/struct/enum，其采用 类型参数（Type Parameters） 的方式
2. 对于 protocol，其采用 抽象类型成员（Abstract Type Member） 的方式，具体技术称为 关联类型（Associated Type）

        class WGAAA<T> { }
        struct WGBBB<T> { }
        enum WGCCC<T> { }
        
        
        protocol WGDDD {
            associatedtype D
            func generate() -> D
        }
        
#### 为什么类/枚举/结构体支持泛型采用的是类型参数的方式，而协议采用的是抽象类型成员的方式？

* 采用类型参数的泛型其实是定义了整个类型家族，我们可以通过传入类型参数可以转换成具体类型（类似于函数调用时传入不同参数），
如：Array<Int>，Array<String>，很显然类型参数适用于多次表达。然而，协议的表达是一次性的，我们只会实现 WGDDD，
而不会特定地实现 WGDDD<Int> 或 WGDDD<String>

* 协议在 Swift 中有两个目的，第一个目的是 用来实现多继承（Swift 语言被设计成单继承），第二个目的是 强制实现者必须遵守协议所指定的泛型约束
很明显，协议并不是用来表示某种类型，而是用来约束某种类型，比如：WGDDD 约束了 generate() 方法的返回类型，而不是定义 WGDDD的类型。
而抽象类型成员则可以用来实现类型约束的

#### 24.1如何存储非泛型协议？

        protocol Drawable { 
            func draw() 
        }

        struct Point: Drawable {
            var x, y: Double
            func draw() { ... }
        }

        struct Line: Drawable {
            var x1, y1, x2, y2: Double
            func draw() { ... }
        }

        let value: Drawable = arc4random()%2 == 0 ? Point(x: 0, y: 0) : Line(x1: 0, y1: 0, x2: 1, y2: 1)
#### value 既可以表示 Point 类型，又可以表示 Line 类型。事实上，value 的实际类型是编译器生成的一种特殊数据类型 Existential Container
Existential Container 对具体类型进行封装，从而实现存储一致性
#### Existential Container 是编译器生成的一种特殊的数据类型，用于管理遵守了相同协议的协议类型。因为这些数据类型的内存空间尺寸不同，
使用 Extential Container 进行管理可以实现存储一致性

        let point = Point.init(x: 10, y: 20)
        let line = Line(x1: 10, y1: 20, x2: 30, y2: 40)
        print("point原始类型内存大小:\(MemoryLayout.size(ofValue: point))")
        print("line原始类型内存大小:\(MemoryLayout.size(ofValue: line))")
        
        let arr: [Drawable] = [point, line]
        for item in arr {
            print("协议类型的内存大小:\(MemoryLayout.size(ofValue: item))")
        }
        //打印结果: 
        point原始类型内存大小:16
        line原始类型内存大小:32
        协议类型的内存大小:40
        协议类型的内存大小:40

#### Extential Container 类型占用5个字节
    
        
        Value Buffer: 占3个字节: 
        
        Value Witness Table: 占1个字节
        Protocol Witness Table: 占1个字节
1. Value Buffer(3个字节): 存储的可能是值，也可能是指针;对于 Small Value（存储空间小于等于 Value Buffer），
可以直接内联存储在 Value Buffer 中对于 Large Value（存储空间大于 Value Buffer），
则会在堆区分配内存进行存储，Value Buffer 只存储对应的指针

        point            line
        x:0.0            存地址------>x1:0.0
        y:0.0                        y1:0.0
                                     x2:0.0
        vwt               vwt        y2:0.0
        pwt               pwt
#### Value Witness Table(1个字节): Value Witness Table 则是对协议类型的生命周期进行专项管理，从而处理具体类型的初始化、拷贝、销毁

        vwt -------> allocate:
                     copy:
                     destruct:
                     deallocate:


#### Protocol Witness Table(1个字节):管理协议类型的方法调用
#### 在 OOP 中，基于继承关系的多态是通过 Virtual Table 实现的；在 POP 中，没有继承关系，因为无法使用 Virtual Table 实现基于协议的多态，取而代之的是 Protocol Witness Table
#### 关于 Virtual Table 和 Protocol Witness Table 的区别?
* 它们都是一个记录函数地址的列表（即函数表），只是它们的生成方式是不同的。
* 对于 Virtual Table，在编译时，子类的函数表是通过对基类函数表进行拷贝、覆写、插入等操作生成的。
* 对于 Protocol Witness Table，在编译时，函数表是通过检查具体类型对协议的实现，直接生成的。

#### Value Buffer 相关内容可知，协议类型的存储分两种情况
1. 对于 Small Value，直接内联存储在 Existential Container 的 Value Buffer 中；
2. 对于 Large Value，通过堆区分配进行存储，使用 Existential Containter 的 Value Buffer 进行索引。

#### 24.2如何存储泛型协议？

        protocol Generator {
            associatedtype AbstractType
            func generate() -> AbstractType
        }

        struct IntGenerator: Generator {
            typealias AbstractType = Int
            
            func generate() -> Int {
                return 0
            }
        }

        struct StringGenerator: Generator {
            typealias AbstractType = String
            
            func generate() -> String {
                return "zero"
            }
        }

        let value: Generator = arc4random()%2 == 0 ? IntGenerator() : StringStore()
        let x = value.generate()
#### Generator 协议约束了 generate() 方法的返回类型，在本例中，x 的类型既可能是 Int，又可能是 String。而 Swift 本身又是一种强类型语言，所有的类型必须在编译时确定。因此，swift 无法直接支持泛型协议的存储;那么，如何解决泛型协议的存储呢？

#### 问题的本质是要将泛型协议的所约束的类型进行擦除，即 类型擦除 （Type Erase），从而骗过编译器，解决该问题的思路就是**泛型协议封装成的具体类型**
为此，我们可以使用 thunk 技术来解决，说到底，就是通过创造一个中间层来解决遇到的问题
#### 具体的解决方法是：
1. 定义一个『中间层结构体』，该结构体实现了协议的所有方法
2. 在『中间层结构体』实现的具体协议方法中，再转发给『实现协议的抽象类型』。
3. 在『中间层结构体』的初始化过程中，『实现协议的抽象类型』会被当做参数传入


        protocol Generator {
            associatedtype AbstractType
            func generate() -> AbstractType
        }

        struct GeneratorThunk<T>: Generator {
            private let _generate: () -> T
            
            init<G: Generator>(_ gen: G) where G.AbstractType == T {
                _generate = gen.generate
            }
            
            func generate() -> T {
                return _generate()
            }
        }
#### 当我们拥有一个 thunk，我们可以把它当做类型使用（需要提供具体类型）

        struct StringGenerator: Generator {
            typealias AbstractType = String
            func generate() -> String {
                return "zero"
            }
        }

        let gens: GeneratorThunk<String> = GeneratorThunk(StringGenerator())

#### 采用 thunk 技术，我们把泛型协议封装成的具体类型，其本质就是对泛型协议进行了 类型擦除（Type Erase），从而解决了泛型类型的存储问题
#### 关于类型擦除，在 Swift 标准库的实现中，一般会创建一个包装类型（class 或 struct）
将遵循了协议的对象进行封装。包装类型本身也遵循协议，它会将对协议方法的调用传递到内部的对象中
















