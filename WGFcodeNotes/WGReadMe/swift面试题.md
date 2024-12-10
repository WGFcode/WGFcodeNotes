#### 1. Swift 到底是面向对象还是函数式的编程语言？
* swift是混合型的编程语言，既支持面向对象编程又支持函数式编程
* 面向对象编程特性体现在: 类和对象的概念；具有面向对象编程的三大特性(封装、继承、多态)
* 函数式编程特性体现在: 高阶函数、闭包、map/reduce/filter/compactMap等函数式编程范式的函数

#### 2. swift中class、struct区别    

              class                                       struct
             引用类型                                       值类型
           变量赋值是浅拷贝                               变量赋值是深拷贝
            能够支持继承                                    不能够继承
         在堆上，手动内存管理                            通常在栈上，自动内存管理
       引用类型大多是非线程安全的                          值类型通常是线程安全的
           不需要任何关键字                          方法中修改属性需要添加mutating关键字
    支持与OC混编(通过继承NSObject实现)                  不支持与OC混编(OC无法调用struct)
    属性初始化:需要自己创建构造方法(除非所属性都有默认值)     属性初始化:可用默认构造直接初始化
    通过实现NSCoding协议支持序列化                    struct本身不支持序列化，但可以通过转换为字节流后存储
    
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

#### struct 是苹果推荐的，原因在于使用struct是值类型，在传递值的时候它会进行值的copy，所以在多线程是安全的；
struct存储在栈stack中，操作起来效率更高struct没有引用计数器，所以不会因为循环引用导致内存泄漏

#### struct缺点 内存问题+
#### 值类型 有哪些问题？比如在两个 struct 赋值操作时，可能会发现如下问题： 解决方案：COW(copy-on-write) 写时拷贝机制
* 内存中可能存在两个巨大的数组；
* 两个数组数据是一样的；
* 重复的复制。

#### 写时拷贝 Copy-on-Write
* Copy-on-Write 是一种用来优化占用内存大的值类型的拷贝操作的机制，写时拷贝只会发生在值类型的集合(数组/字典)上
* 对于Int，Double，String 等基本类型的值类型，它们在赋值的时候就是深拷贝(内存增加)
* 对于 Array、Dictionary，当它们赋值的时候不会发生拷贝，只有在修改的之后才会发生拷贝
* 写时拷贝机制减少的是内存的增加; 写时拷贝只会发生在数组Array、字典Dictionary中；而集合Set不会发生写时拷贝
* 对于自定义的数据类型不会自动实现COW，可按需实现

        func address(of object: UnsafeRawPointer) {
            let addr = Int(bitPattern: object)
            print(String(format: "%p", addr))
        }
    
        //1.基本数据类型 赋值时会发生拷贝
        var name = "a"
        var win = name
        address(of: &name)
        address(of: &win)
        
        0x16af92a98
        0x16af92a88
        
        //2.集合类型 赋值时不会发生拷贝 只有在修改时才会发生拷贝
        var arr = [1,2,3]
        var arr1 = arr
        address(of: &arr)
        address(of: &arr1)
        arr.append(5)
        address(of: &arr)
        address(of: &arr1)
        NSLog("arr----\(arr)\narr1:----\(arr1)")
        
        //赋值
        0x302392a20
        0x302392a20
        //修改
        0x30152ad70
        0x302392a20
        arr----[1, 2, 3, 5]
        arr1:----[1, 2, 3]

        //3.struct类型
        struct WGA {
            var name: String
            var age: Int
        }
        var a = WGA(name: "1", age: 18)
        var b = a
        address(of: &a)
        address(of: &b)
        a.age = 1
        address(of: &a)
        address(of: &b)
        NSLog("a.age----\(a.age)\nb:----\(b.age)")
        
        //struct结构体类型赋值直接就拷贝，并没有发生写时拷贝机制,即自定义结构体并没有实现写时拷贝
        0x16d47aaa8
        0x16d47aa90
        0x16d47aaa8
        0x16d47aa90
        a.age----1
        b:----18
        
        /* 
        1. isKnownUniquelyReferenced函数用于判断一个对象是否只被一个强引用持有，从而决定是否需要进行深拷贝。
        如果对象只被一个强引用持有，返回true；否则返回false
        2.自定义实现写时拷贝：主要就是通过isKnownUniquelyReferenced函数 
        ⚠️⚠️⚠️这里必须在类Ref中写上final，否则赋值过程两个对象的地址还是不同的
        */
        //final 1.避免类的继承 2.保持引用计数的一致性
        // 如果 Ref<T> 类是可继承的，其他子类可能会引入对引用计数的修改
        final class Ref<T> {
          var val : T
          init(_ v : T) {val = v}
        }

        struct Box<T> {
            var ref : Ref<T>
            init(_ x : T) { ref = Ref(x) }

            var value: T {
                get { return ref.val }
                set {
                  if (!isKnownUniquelyReferenced(&ref)) {
                    ref = Ref(newValue)
                    return
                  }
                  ref.val = newValue
                }
            }
        }
        
        struct Persion {
            var name = "oldbirds"
            var sex: Bool = false
        }
        
        let p = Persion()
        var box = Box(p)
        var newBox = box
        //必须通过ref获取到val，val其实就是结构体Persion
        address(of: &(box.ref.val))
        address(of: &(newBox.ref.val))
        box.value.name = "lisi"
        address(of: &(box.ref.val))
        address(of: &(newBox.ref.val))
        //赋值前
        0x3038a9d50
        0x3038a9d50
        //修改值后
        0x3038a9cc0
        0x3038a9d50
        box.name----lisi-----newBox.name----zhangsan
#### 自定义实现Struct写时拷贝步骤
1. 声明一个final的泛型类，必须是final类型(避免类继承和保持引用计数的一致性)
2. 定义一个装载泛型类的结构体，在这个结构体中，定义一个存储泛型类的属性
3. 在这个结构体初始化是对这个泛型类进行初始化，然后定一个get/set属性用来获取外部传进来的结构体对象
在get/set方法中通过isKnownUniquelyReferenced方法判断是否需要拷贝外部传进来的结构体对象        
4.自定义一个结构体，然后将其装载到定义好的结构体对象中，通过定义好的结构体对象中声明的get/set方法来获取到自定义的结构体
进行修改对应属性的内容        


#### 3. swift定义常量和OC中定义常量有什么区别
* OC中 const 表明的常量类型和数值是在**编译时**确定的
* Swift中let只是表明常量(只能赋值一次)，其类型和值既可以是静态的，也可以是一个动态的计算方法，它们在运行时确定的
* OC中用 const 是用来表示常量的；Swift 中用 let 是用来判断是不是常量。
* OC中的常量（const）是编译期决定的，Swift中的常量（let）是运行时确定的
* Swift中的常量可以是非特定类型的，即它们的类型可以在运行时确定  

    OC定义常量: const int number = 0;
    swift定义常量: let number = 0

 

#### 4. 说说Swift为什么将String,Array,Dictionary设计成值类型？
* 值类型相对引用类型，最大的优势在于内存使用的高效，值类型在栈上操作的，引用类型在堆上操作的；
* 栈上的操作仅仅是单个指针的上下移动，而堆上的操作则涉及到合并、移动、重新链接等，
* swift将String,Array,Dictionary设计为值类型，大幅减少了堆上的内存分配和回收的次数，
同时写时复制又将值传递和复制的开销降到了最低；
* 设计为之值类型，也是为了线程安全考虑


#### 5. 聊聊swift的方法派发
#### OC中的方法都是【动态派发】(方法调用)，swift中的方法分为【动态派发】和【静态派发】
* swift静态派发就是在编译期方法的地址已经确定了，运行时直接调用函数地址即可
* swift动态派发分为两种: 一种是虚函数表(Vtable)派发;一种是objc_msgSend动态派发(和OC的消息发送流程一样)
* swift中值类型、扩展(值类型扩展引用类型扩展)中的方法都是通过静态派发的
* 纯swift类和继承自NSObject的子类在声明位置定义的方法使用的是函数表(Vtable)派发;在扩展中使用的是静态派发
* final修饰的方法采用静态派发/ @objc+dynamic采用的是objc_msgSend消息发送
* 继承自NSObject的子类中@objc / dynamic采用的是函数表(VTable)派发/ 扩展了NSObject子类中的@objc是objc_msgSend消息发送
* 协议中的方法，当调用方法时声明的对象类型是协议类型时，采用的是通过witness Table派发
* witness Table派发实际上就是通过witness Table找到对应类型进行方法调用(若是值类型，通过witness Table找到值类型中的
函数地址直接调用；弱是引用类型，则通过witness Table找到引用类型中的VTable进行方法调用)



#### 6. dynamic framework 和 static framework的区别是什么？
* 库(Library)是一段编译好的二进制代码,加上.h头文件后就可以供给别人使用；
* 什么时候会用到库？    

        1.模块代码需要给别人使用，但不希望别人看到源码 
        2.模块不会进行大的改动的代码，想减少编译的时间可以打包成库(库是已经编译好的二进制了,编译的时候只需要Link一下)
        
* 库分为动态库和静态库

        1.静态库格式： .a / .framework     
        2.动态库格式:  .tdb / .dylib / .framework 
        3..a是纯二进制文件，.framework中有二进制文件和资源文件
        4..a文件不能直接使用，至少要有.h文件配合；.framework文件可以直接使用
        5..a + .h + sourceFile = .framework
        
* 静态库(静态链接库)在编译的时候会被直接拷贝一份到目标程序里，在目标程序里，这段代码不会再改变；
* 静态库会使用目标程序的体积增大; 编译期链接到目标代码中；编译完成之后，这个静态库也就没有什么作用了
* 动态库(动态链接库)在编译时不会被拷贝到目标程序中，目标程序中会存储指向动态库的引用。等到程序运行时，动态库才会被真正
加载进来，所以可以随时对库进行替换，且不需要重新编译代码；运行时加载动态库
* 动态库同一份库可以被多个程序使用，也称共享库；不需要拷贝到目标程序中，不会影响目标程序的体积
* Framework是一种打包方式,将库的二进制文件、头文件、有关的资源文件打包到一起，方便管理和分发
* Framework种类有三种

        1.Dynamic Framework 系统动态库: 
        具有动态库的特征;系统提供;不需要拷贝到目标App中;用户不可以制作
        
        2.static framework 静态库; 
        具有静态库的特征;用户可以制作(二进制代码 + 头文件+资源文件)
        
        3.embedded framework 伪动态库;
        具有部分动态特征;
        不能像系统动态库那样，在不同App之间共享
        只能在App Extension和App之间共享动态库
        需要在工程General->Embedded Binaries添加这个动态库
        拷贝到目标App中；所以在每个App的IPA的framework目录下都会有一份(极光广告中的快手SDK)
        开发者手动创建的，就是这种伪动态库，和系统的动态库是有区别的
        
* Embed&Sign选择：动态库选择Embed嵌入；静态库选择Do not embed；Sign用于动态库
* 通知扩展用的是Embed Without Signing；快手渠道广告用的是Embed&Sign
* 区分动态库和静态库：.a肯定是静态库，.dylib肯定是动态库，区分主要区分的就是framework
* cd xxx.framework 然后file xxx 查看静态库包含current ar archive random library 动态库:dynamically linked shared library



#### 8. Any和AnyObject的区别
* Any: 表示任意类型，包括基本数据类型、结构体、枚举、类和函数等。适用于需要处理多种不同类型的值的情况
* AnyObject: 表示任意**类类型**的实例。适用于需要处理任意类实例的情况;AnyObject是Any的子集;只能存储类的实例


#### 9.inout关键字
* inout的本质就是引用传递（地址传递），用于解决在函数内修改外部变量，函数执行完成后将改变后的值反馈给外部变量
* inout关键字只能修饰变量，无法修饰常量，因为常量和字面量不能被修改(若myName用let修饰，则编译器会报错)
* inout参数不能有默认值，可变参数不能标记为inout
* 调用函数的时候，应该在变量名前放置&符号表示该变量可以由函数修改

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
        
#### 将外部变量传递给函数，函数内部对参数进行了修改，且在函数结束时，修改的值被保留了下来     

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
#### inout参数是存储属性时：存储属性有自己的内存地址，所以直接把存储属性的地址传递给需要修改的函数，在函数内部修改存储属性的值
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

#### inout参数是计算属性时：由于计算属性没有自己的地址值，所以会调用getter方法获取一个局部变量，把局部变量的值传递给
需要修改的函数，在函数内部修改局部变量的值，最后把局部变量的值传递给setter方法

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
1.如果实参有物理内存地址，且没有设置属性观察器(如存储属性)

        直接将实参的内存地址传入函数（实参进行引用传递）
        
2.如果实参是计算属性或设置了属性观察器，采取Copy In Copy Out的做法

        调用该函数时，先复制实参的值，产生一个副本（局部变量-执行get方法）
        将副本的内存地址传入函数（副本进行引用传递），在函数内部可以修改副本的值
        函数返回后，再将副本的值覆盖实参的值（执行set方法）
3.什么是Copy In Copy Out？先Copy到函数里，修改后再Copy到外面。     
4.inout参数的本质是地址传递 (引用传递)，不管什么情况都是传入一个地址。                 
5. Swift 值类型中，属性的默认行为是不可变的。mutating关键字，用于在结构体或枚举的方法中修改属性；
使用mutating修饰的方法（func）在修改属性后更新原始值，而不是返回一个新的副本。     
mutating关键字只能用于值类型，mutating关键字本质是包装了inout关键字，加上mutating关键字后参数值会变成地址传递。         
类对象是指针，传递的本身就是地址值，所以 mutating关键字对类是透明的，加不加效果都一样           

#### 10 聊聊swift中的闭包
* 闭包是⼀个捕获了上下⽂的常量或者是变量的函数
* swift闭包主要有以下几种形式: 

        1.‌闭包表达式‌：闭包表达式是一种轻量级语法，用于表示内联闭包
        2.全局函数‌：有名字但不会捕获任何值的闭包
        3.‌嵌套函数‌：有名字并可以捕获其封闭函数域内值的闭包
        4.尾随闭包‌：在函数调用时，将闭包作为最后一个参数传递
        5.逃逸闭包‌：在异步操作中使用的闭包，其生命周期超过函数调用本身
    
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
dynamic 修饰符可以让扩展声明（extension）中的函数也能够被 override
#### @objc 典型的用法就是给 selector 一个命名空间 @objc(xxx_methodName)，从而允许该函数可以被 Objective-C 的运行时捕获到
#### @nonobjc： 会改变派发方式，可以禁用消息派发，从而阻止函数注册到 Objective-C 的运行时中。
@nonobjc 的效果类似于 final，使用的场景几乎也是一样，个人猜测，@nonobjc 主要是用于兼容 Objective-C，
final 则是作为原生修饰符，以用于让 Swift 写服务端之类的代码

####final+@objc： 在使用 final 修饰符的同时，可以使用 @objc 修饰符让函数可以使用消息派发。同时使用这两个修饰符的结果是：调用函数时会使用直接派发，但也会在 Objective-C 运行时中注册响应的 selector。函数可以响应 perform(seletor:) 以及别的 Objective-C 特性，但在直接调用时又可以具有直接派发的性能
#### @inline 修饰符告诉编译器函数可以使用直接派发。




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
#### 为了解决协议支持泛型问题Swift提供 关联类型(associatetype) 以完善其语法体系
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


#### 25. Swift中的any、some区别
#### 在swift中，any、some关键字是在处理泛型和协议时常用的概念；它们的作用是让我们能够在编写代码的时候处理未知类型的值
* any表示可以是任意类型(包括值类型/引用类型/函数类型等)，它引入了"抽象类型"的概念
* some用于表示返回某种特定类型，它引入了"具体类型"的概念；
* some和any都用于类型擦除和泛型的实现


        protocol WGAAA {
            //计算面积
            func area() -> Double
        }

        struct WGBBB : WGAAA {
            var radius: Double
            func area() -> Double {
                return Double.pi * radius * radius
            }
        }

        //函数返回任意实现了WGAAA协议的类型： 使用any实现抽象类型
        func calculateAny(radius: Double) -> any WGAAA {
            return WGBBB(radius: radius)
        }

        @available(iOS 13.0.0, *)
        //函数返回一些实现了WGAAA协议的具体类型: 使用some实现具体类型
        func calculateSome(radius: Double) -> some WGAAA {
            return WGBBB(radius: radius)
        }

#### some常用于泛型代码中；用于表示"某种类型的值"，也可以称为"不透明类型"；
在函数返回值或协议关联类型中，使用some类型可以隐藏具体的类型信息，提供更加抽象的接口

#### some比any更高效，some函数调用采用静态派发;any为动态派发


#### 26 swift高阶函数
#### sort是排序的；map/compactMap返回的是一个新的集合;reduce返回的是一个结果；reduce(info:)返回的是一个指定类型的数据可以是集合可以是单个值
#### 26.1 sort、sorted排序
#### sort排序的是基于原始集合数据，即不会产生新的集合数据，而是在原始数据集合中进行排序
#### sorted排序会生成一个新的集合对象存放排好序的数据，不影响原始集合数据
#### sort、sorted最大区别就是在对原始数据的处理上不同，sort在原始数据中进行排序；sorted将排序好的数据放在新的集合中

        
        let arr = [100,3,45,99]
        //方式一: 默认升序
        let newArr = arr.sorted()
        //方式二: 完整版 返回一个bool类型
        //arr.sorted(by: <#T##(Self.Element, Self.Element) -> Bool#>)
        let newArr1 = arr.sorted { item1, item2 in
            return item1 < item2
        }
        //方式三: 通过 简写方式 降序 升序
        let newArr2 = arr.sorted(by: >)
        let newArr3 = arr.sorted(by: <)
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)\nnewArr2:\(newArr2)\nnewArr3:\(newArr3)")
        
        newArr:[3, 45, 99, 100]
        newArr1:[3, 45, 99, 100]
        newArr2:[100, 99, 45, 3]
        newArr3:[3, 45, 99, 100]

#### 26.2 map高阶函数
* 将集合中的每一个元素通过映射转换为另外一个类型。
* map函数返回一个新的数组，并且数组的类型不要求和原数组类型一致
* map 函数不会自动帮我们去掉转换失败的 nil 值(可以使用 compactMap 函数)
        
        let arr = [100,3,45,99]
        //将每个元素 + 2
        let newArr = arr.map({ $0 + 2 })
        //将每个元素转为字符串类型
        let newArr1 = arr.map { item in
            String(item)
        }
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)")
        
        newArr:[102, 5, 47, 101]
        newArr1:["100", "3", "45", "99"]
        
        //map 函数不会自动帮我们去掉转换失败的 nil 值
        struct WGA {
            var name: String
            var age: Int
            var teacher: String?
        }
        let arr = [WGA(name: "zhangsan", age: 18),
                   WGA(name: "lisi", age: 30, teacher: "wanglaoshi"),
                   WGA(name: "wangwu", age: 80)]
        let newArr = arr.map { item in
            item.teacher
        }
        NSLog("newArr:\(newArr)")
        
        newArr:[nil, Optional("wanglaoshi"), nil]

        //使用compactMap可以剔除映射结果为nil的数据
        let newCompactArr = arr.compactMap { item in
            item.teacher
        }
        NSLog("newArr:\(newCompactArr)")
        
        newArr:["wanglaoshi"]

#### 26.3 flatMap (flatMap在swift4.1已经被移除了，需要使用compactMap代替)
#### flatMap和map其实类似，都是对每个元素做转换，返回一个新的集合。不同的是它对每个元素转换的返回值可以是集合类型的，
并会将所有的结果集合合并成一个；多于用于数组的降维度
* 能把数组中存有数组的数组（二维数组、N维数组）一同打开变成一个新的数组
* flatMap也能把两个不同的数组合并成一个数组，这个合并的数组元素个数是前面两个数组元素个数的乘积

        let arr = [1,3,0,2]
        let newArr = arr.flatMap { item in
            item + 2
        }
        let newArr1 = arr.flatMap { item in
            String(item)
        }
        let newArr2 = arr.flatMap { item in
            Array.init(repeating: item, count: item)
        }
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)\nnewArr2:\(newArr2)")
        
        newArr:[3, 5, 2, 4]
        newArr1:["1", "3", "0", "2"]
        newArr2:[1, 3, 3, 3, 2, 2]
        
        //数组的降维度
        let arr = [1,3,0,2]
        let newArr = arr.map { item in
            Array.init(repeating: item, count: item)
        }
        let newArr1 = arr.flatMap { item in
            Array.init(repeating: item, count: item)
        }
       
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)")
        
        newArr:[[1], [3, 3, 3], [], [2, 2]]
        newArr1:[1, 3, 3, 3, 2, 2]
        
        //flatMap也能把两个不同的数组合并成一个数组
        let arr1 = [1,2,3]
        let arr2 = ["apple", "orange"]
        
        let newArr = arr1.flatMap { item1 in
            arr2.map { item2 in
                return item2 + "\(item1)"
            }
        }
        NSLog("newArr:\(newArr)")
        
        newArr:["apple1", "orange1", "apple2", "orange2", "apple3", "orange3"]

#### 26.4 compactMap
#### compactMap函数作用和 map、flatMap 函数一样，唯一不同的是它会剔除结果集合中转换失败的 nil 值

        let arr = ["1", "orange", "5"]
        let newArr = arr.map { item in
            Int(item)
        }
        let newArr1 = arr.flatMap { item in
            Int(item)
        }
        let newArr2 = arr.compactMap { item in
            Int(item)
        }
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)\nnewArr2:\(newArr2)")
        
        newArr:[Optional(1), nil, Optional(5)]
        newArr1:[1, 5]
        newArr2:[1, 5]
        
        // 过滤nil，并解包返回值
        let arr = [1, 5, nil, 4]
        let result = arr.compactMap {
            $0
        }
        // arr的结果：[1, 5, 4]
        
        
        let arr2 = [1, 2, 3, 4, 5, 6, 7, 8]
        let result2 = arr2.compactMap {
            $0 % 4 == 0 ? $0 : nil
        }
        //arr2结果： [4, 8]  虽然闭包的返回值是可选的，但是这个函数的返回值结果并不是可选的

#### 26.5 filer过滤函数
#### 它主要用于过滤数组、集合和字典等类型对象中的元素。它接受一个闭包参数，该闭包返回的结果为 true，该元素就会保留，否则就会被移除

        let arr = ["1", "orange", "5"]
        let newArr = arr.filter { item in
            return Int(item) == nil
        }
        NSLog("newArr:\(newArr)")
        
        newArr:["orange"]

#### 26.6 reduce 函数
#### 基础思想是将一个序列转换为一个不同类型的数据，期间通过一个累加器（Accumulator）来持续记录递增状态
#### reduce 是 map、flatMap 或 filter 的一种扩展的形式（后三个函数能干嘛，reduce 就能用另外一种方式实现


        两种方式的reduce高阶函数
        initialResult: 初始值(类型和最后函数返回的结果类型是一致的)
        Result: 一般是指上次得到的结果之和
        Int: 一般指本次遍历集合中的元素
        let arr = [1,2,43,2]
        //将集合中的元素组合成一个值，通过应用一个累计的操作。它需要一个初始值和一个合并操作
        arr.reduce(<#T##initialResult: Result##Result#>, <#T##nextPartialResult: (Result, Int) throws -> Result##(Result, Int) throws -> Result##(_ partialResult: Result, Int) throws -> Result#>)
        
        //用来将集合的元素聚合成一个新集合
        arr.reduce(into: <#T##Result#>, <#T##updateAccumulatingResult: (inout Result, Int) throws -> ()##(inout Result, Int) throws -> ()##(_ partialResult: inout Result, Int) throws -> ()#>)
        
        
        
        let arr = [1,4,23,5]
        //求和
        let newArr = arr.reduce(0) { partialResult, item in
            return partialResult + item
        }
        let newArr0 = arr.reduce(0, { $0 + $1 })  //等价上面代码
        let newArr00 = arr.reduce(0, +)           //等价上面代码
        //求最小值
        let newArr1 = arr.reduce(0) { partialResult, item in
            return min(partialResult, item)
        }
        let newArr11 = arr.reduce(0) { partialResult, item in
            return min(item, partialResult)
        }
        //求最大值
        let newArr2 = arr.reduce(0) { partialResult, item in
            return max(partialResult, item)
        }
        let newArr22 = arr.reduce(0) { partialResult, item in
            return max(item,partialResult)
        }
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)\nnewArr11:\(newArr11)\nnewArr2:\(newArr2)\nnewArr22:\(newArr22)")
        
        newArr:33
        newArr1:0
        newArr11:0
        newArr2:23
        newArr22:23
        
        
        let arr = [1,2,43,2]
        //将集合数据合并成
        let newArr1 = arr.reduce(0) { partialResult, item in
            return partialResult + item
        }
        let newArr2 = arr.reduce(into: [Int]()) { partialResult, item in
            return partialResult.append(item * 2)
        }
        NSLog("newArr:\(newArr)\nnewArr1:\(newArr1)")
        newArr: 48
        newArr1: [2, 4, 86, 4]

#### 26.7 stride 函数
#### 用于创建一个由指定范围内元素组成的序列
        // 创建一个【10，20),步长为2的序列
        for i in stride(from: 10, to: 20, by: 2) {
            NSLog("1-----\(i)")
        }
        // 10 12 14 16 18
        // 创建一个【10，20】,步长为2的序列
        for i in stride(from: 10, through: 20, by: 2) {
            NSLog("2-----\(i)")
        }
        //10 12 14 16 18 20

#### 26.8 partition(by:):  partition(分区)
#### 将集合划分成两个部分，使得满足某个条件的元素放在前面，不满足条件的放在后面，并返回分界点索引
        //大于30的放在右边(后面) 不满足条件的放在左边(前面) 40满足条件放在最后边(和10的位置进行交换)
        var numbers = [30, 40, 20, 30, 30, 60, 10]
        //分区分界点索引
        let p = numbers.partition(by: { $0 > 30 })
        NSLog("p:-----\(p)\nnumbers:-----\(numbers)")
        
        p:-----5
        numbers:-----[30, 10, 20, 30, 30, 60, 40]
        
#### 26.9 zip: 
#### 将两个集合中的元素一一对应起来，组成一个新的元组数组。
        let numbs = [1, 2, 3]
        let letters = ["A", "B", "C"]
        let pairs = zip(numbs, letters)
        NSLog("pairs:-----\(Array(pairs))")
        
        pairs:-----[(1, "A"), (2, "B"), (3, "C")]


#### 27 无论是类还是结构体都存在如下规则；以结构体为例
* 如果协议中有方法声明，则会根据对象的实际类型进行调用; 
* 如果协议中没有方法声明，则会根据对象的声明类型进行调用。       
            protocol Chef {
                func makeFood()
            }

            extension Chef {
                func makeFood() {
                    print("make food")
                }
            }

            struct SeafoodChef: Chef {
                func makeFood() {
                    print("make seafood")
                }
            }
            
            let chefOne: Chef = SeafoodChef()        //实际类型SeafoodChef
            let chefTwo: SeafoodChef = SeafoodChef() //实际类型SeafoodChef
            chefOne.makeFood()
            chefTwo.makeFood()
            
            打印结果: 
            make seafood
            make seafood
#### 如何将协议中声明的方法去除,则会根据对象的声明类型进行调用
            protocol Chef {
            }

            extension Chef {
                func makeFood() {
                    print("make food")
                }
            }

            struct SeafoodChef: Chef {
                func makeFood() {
                    print("make seafood")
                }
            }
            
            let chefOne: Chef = SeafoodChef()     //声明类型是Chef 调用的是扩展协议中的方法
            let chefTwo: SeafoodChef = SeafoodChef() //声明类型是SeafoodChef 调用的SeafoodChef中的方法
            chefOne.makeFood()
            chefTwo.makeFood()
            打印结果: 
            make food
            make seafood
    
#### 28 下面代码会有问题，编译器会报错，因为weak 关键词是ARC环境下，为引用类型提供引用计数这样的内存管理，它是不能被用来修饰值类型的
        protocol SomeProtocol {
            func doSomething()
        }

        class Person {
            weak var delegate: SomeProtocol?
        }
        
        //修改方法如下
        方案一 在SomeProtocol之后添加 class 关键词。如此一来就声明该协议只能由类(class)来实现
        protocol SomeProtocol : AnyObject {
            func doSomething()
        } 
        方案二 在 protocol 前面加上@objc。在OC中协议只能由class来实现，这样一来，weak修饰的对象与OC一样，只不过是class类型
        @objc protocol SomeProtocol {
            func doSomething()
        }  
        
#### 29.当声明闭包的时候，捕获列表会创建一份变量的 copy，被捕获到的值是不会改变的，即使外界变量的值发生了改变
        var car = "Benz" 
        let closure = { [car] in 
          print("I drive \(car)")
        } 
        car = "Tesla" 
        closure()
        打印结果: I drive Benz
        
        
        var car = "Benz" 
        let closure = {
          print("I drive \(car)")
        } 
        car = "Tesla" 
        closure()
        打印结果: I drive Tesla
#### 如果去掉闭包中的捕获列表，编译器会使用引用代替 copy。在这种情况下，当闭包被调用时，变量的值是可以改变的。所以 clousre 用的还是全局的 car 变量      













