## Swift基础语法
### 1. 协议protocol
#### 协议规定了用来实现某一特定功能所必需的方法和属性，任意能满足协议要求的类型被称为遵守了这个协议，swift中类、结构体、枚举都可以遵守协议，并提供具体实现来完成下一定义的方法和功能；协议规定了有哪些属性和方法，至于属性值是多少、方法怎么实现协议都不管，留给实现协议的类/结构体/枚举去实现，类似Java中的接口

    //声明一个协议
    protocol MyProtocol {
        /*
         协议中定义属性要求
         1. 必须用var修饰，不能用let修饰
         2. 必须指定属性类型，且要指定是只读的还是可读可写的
         3. 不能定义可选类型的属性、不能设置默认值
         4. 可以定义类属性，只能用static来修饰，不能用class来修饰
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
    }
#### 协议中可以定义属性和方法，协议中属性和方法有以下要求
1. 协议中可以定义属性、实例方法、类型方法(类方法)
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
2. 通过协议扩展实现  

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

