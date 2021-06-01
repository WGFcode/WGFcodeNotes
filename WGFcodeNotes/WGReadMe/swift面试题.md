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


























