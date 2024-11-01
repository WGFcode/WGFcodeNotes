## iOS内存分配和分区
### 1. iOS内存分区(由高到低顺序)
1. 栈区(stack):
* 栈是一块连续的内存区域，遵循先进后出(FILO)原则，方便用来函数跳转地址/保存调用现场/恢复调用现场
* 栈区一般由编译器在运行时自动分配并释放的,不会产生内存碎片，访问快速高效；栈区地址是从高到低分配
* 栈区存储局部变量、函数参数，出了作用域就会被销毁
* 栈的内存大小有限制，数据不灵活(iOS主线程栈大小是1MB、其他主线程是512KB、MAC只有8M)

2. 堆区(heap): 
* 堆是不连续的内存区域，类似于链表结构(便于增删，不便于查询)，遵循先进先出(FIFO)原则，内存分配靠遍历链表查找
* 堆是用于存放进程运行中被动态分配的内存段,它的大小并不固定,可动态扩张或缩减，
* 堆的内存分配一般是在运行时，分配和释放需要程序员手动管理、速度慢、容易产生内存碎片；堆是向高地址扩展的数据结构，
* 当调用alloc、new、malloc等函数分配内存时，新分配的内存就被动态添加到堆上，当利用realse释放内存时，被释放的内存从堆中被剔除
* 当需要访问堆中内存时，一般需要先通过对象读取到栈区的指针地址，然后通过指针地址访问堆区

3. 全局区(静态区)
* 全局区是编译时分配的内存空间，在程序运行过程中，此内存中的数据一直存在，程序结束后由系统释放
* 主要为全局变量和静态变量分配内存，包含未初始化的和已经初始化的两个部分
* 未初始化的全局变量和静态变量，即BSS区（.bss）
* 已初始化的全局变量和静态变量，即数据区（.data）
* static修饰的变量就是静态变量，该变量的内存在编译阶段完成分配，且仅分配一次。
* 全局变量是指变量值可以在运行时被动态修改，而静态变量是static修饰的变量，包含静态局部变量和静态全局变量

4. 常量区
* 常量区是在编译时分配内存空间的，在程序运行过程中，此内存中的数据一直存在，程序结束后由系统释放
* 专门用于存放常量(字符串)等，程序结束后由系统释放

5. 代码区
* 通常是指用来存放程序执行代码的一块内存区域。
* 代码区的内存大小在程序运行前就已经确定，并且内存区域通常属于只读,某些架构也允许代码段为可写，即允许修改程序
* 在代码段中，也有可能包含一些只读的常数变量，例如字符串常量等。
#### 当app启动后，代码区、常量区、全局区(静态区)大小已固定，程序结束后由系统释放，所以指向这些区的指针不会产生崩溃性的错误，但堆和栈区就不同了，堆区和栈区内存是时刻变化的(堆的创建销毁，栈的弹入弹出),所以开发中一般关注栈区和堆区；如下是内存分区图

                                      |---全局(静态)区-|
    栈                 堆              BSS段      数据段          常量区       代码区
    高地址------------------------------------------------------------------->低地址           
    从高到低分配->    从低到高分配<-   BSS:未初始化的全局变量和静态变量          
                                  数据段:已经初始化的全局变量和静态变量
#### 数据段中包含只读数据段(常量区)和读写数据段(已经初始化的全局变量和静态变量),所以我们知道内存分区可能有2种分法
1. 栈区、堆区、全局(静态区)、常量区、代码区
2. 栈区、堆区、BSS段(未初始化的全局变量和静态变量)、数据段(只读数据段(常量区)和读写数据段(初始化的全局变量和静态变量))、代码区

### 2 堆和栈区别
1. 分配方式不同：栈区由编译器自动分配和释放；堆区是由程序员来分配和释放
2. 栈区内存由编译器分配和释放，在函数执行时分配，在函数结束时收回。只要栈区剩余内存大于所申请的内存，那么系统将为程序提供内存
3. 系统有一个存放空闲内存地址的链表，当程序员申请堆内存的时候，系统会遍历该链表，找到第一个内存大于所申请内存的堆节点，并把这个堆节点从链表中移除。由于这块内存的大小很多时候不是刚刚好所申请的一样大，所以剩余的那一部分还会回到这个空闲链表中(内存碎片)。
4. 申请大小的限制： 栈区是向低地址扩展的数据结构，栈的容量一般是2M，当申请的栈内存大于2M时就会出现栈溢出，可分配的空间比较小
5. 申请大小的限制： 堆是向高地址扩展的数据结构，是不连续的。堆的大小受限于计算机系统中有效的虚拟空间，因此堆可分配的空间比较大
6. 栈：栈由系统自动分配、速度较快，但是不受程序员控制；堆：堆是由alloc分配的内存、速度较慢，并且容易产生内存碎片。


### 3. 内存泄漏、内存溢出
* 内存泄漏: 是指申请的内存空间使用完毕之后未回收
* 内存溢出: 是指程序在申请内存时，没有足够的内存空间供其使用(通俗内存不够用了)。


### 4. iOS中变量-OC
#### iOS中存储方式有以下两种
1. 静态存储方式: 程序一开始运行时就分配存储空间,从程序开始运行到程序结束，存储空间都保持不变的存储方式。
2. 动态存储方式: 程序在运行时，需要使用时才分配存储空间，不需要使用时立即释放的存储方式

#### iOS中变量需要从存储方式、生命周期、作用域来详细研究它们,变量分类主要有4种
1. 全局变量
* 静态存储，存放在全局(静态)区；
* 静态存储方式决定了它的生命周期为**从程序运行开始到结束**
* 作用域是整个程序的所有文件
2. 局部变量
* 动态存储，存放在栈区(数据类型)或堆区(对象类型)
* 动态存储方式决定了它的生命周期为**变量使用期间**
* 作用域是方法或函数体结束

3. 静态全局变量
* 静态存储，存放在全局(静态)区；
* 静态存储方式决定了它的生命周期为**从程序运行开始到结束**
* 作用域是只有申明该变量的文件才可以访问到

4. 静态局部变量
* 静态存储，存放在全局(静态)区；
* 静态存储方式决定了它的生命周期为**从程序运行开始到结束**
* 作用域是方法或函数体结束

#### 总结如下
* 存储方式：全局变量/静态全局变量/静态局部变量是静态存储，都存放在全局(静态)区；局部变量是动态存储,存放在堆区或栈区；
* 生命周期：全局变量/静态全局变量/静态局部变量是**从程序运行开始到结束**；局部变量是在函数或方法体内；
* 作用域: 全局变量是整个工程的所有文件；全局静态变量只能在声明所在的文件内访问；局部变量和静态局部变量是在函数或方法体内；
* static作用有两个：第一个是改变全局变量的作用域，第二个是改变局部变量的生命周期


#### 5. 堆栈溢出
#### 一般情况下应用程序是不需要考虑堆和栈的大小的，但是事实上堆和栈都不是无上限的，过多的递归会导致栈溢出，过多的alloc变量会导致堆溢出，预防堆栈溢出的方法
* 避免层次过深的递归调用；
* 不要使用过多的局部变量，控制局部变量的大小；
* 避免分配占用空间太大的对象，并及时释放;
* 实在不行，适当的情景下调用系统API修改线程的堆栈大小；


#### 6.iOS程序的内存布局(从低到高)
*  保留
*  代码段：编译之后的代码
*  数据段
   字符串常量: 比如NSString *str = @"111"
   已初始化数据:已初始化的全局变量/静态变量 
   未初始化数据:未初始化的全局变量/静态变量   
*  堆：从低到高分配内存；通过alloc/malloc,calloc等动态分配的空间，分配的内存空间地址越来约大
*  栈：从高到低分配内存；汉书还调用开销，比如局部变量。分配的内存空间地址越来越小

#### 7.字符串NSString总结，类型有以下三种
* __NSCFConstantString: alloc/字面值创建出来的；以字面量方式生成的，retainCount是-1；无论copy或者retain都不会变化retainCount的。相当于指针指向一个常量地址。
* NSTaggedPointerString： 通过类方法stringWithFormat方法创建出来的(mac平台最低有效位是1，ios平台最高有效位是1)
* __NSCFString: 通过类方法stringWithFormat方法创建出来的(字符位数比较多)
        NSString *str1 = [NSString stringWithFormat:@"111111111"];  //0xd14b741d98e6e005 NSTaggedPointerString  mac平台最低有效位是1
        
        NSString *str2 = [NSString stringWithFormat:@"111111111111"]; //0x0000000101d04640 __NSCFString  局部变量在栈区
        
        NSString *str3 = [[NSString alloc]initWithString:@"111111111"];  //0x0000000100004050 __NSCFConstantString  字符串常量
        
        NSString *str4 = [[NSString alloc]initWithString:@"111111111111"]; //0x0000000100004070 __NSCFConstantString  字符串常量
        
        NSString *str5 = [[NSString alloc]init];   
        //0x00007ff852cb0148 __NSCFConstantString  


## swift内存对齐
1. Stack(栈): 存储值类型的临时变量，函数调用栈，引用类型的临时变量指针
2. Heap(堆): 存储引用类型的实例

### 1. MemoryLayout工具类
#### swift3.0之后swift推出了一个工具类MemoryLayout，用来计算数据占用内存的大小,该工具类主要有3个比较重要的属性且返回值都是int类型
        1. 一个 T 数据类型实例占用连续内存字节的大小（实际占用内存的字节数）
        MemoryLayout.size(ofValue: T)  
        2. 数据类型 T 的内存对齐原则（内存对齐的字节数）
        MemoryLayout.alignment(ofValue: T)
        3. 在一个 T 类型的数组中，其中任意一个元素从开始地址到结束地址所占用的连续内存字节的大小就是stride（系统分配的字节数）
        MemoryLayout.stride(ofValue: T)
          
           stride
        |-------------|
        [___元素T1___  ___元素T2___  ___元素T3___  ___元素T4___  ___元素T5___  ]
        |-----------|
            size
        数组中有5个T类型元素，虽然每个T元素的大小为size个字节，但是因为需要内存对齐的限制，每个T类型元素实际消耗的内存
        空间为stride个字节，而 stride-size个字节则为每个元素因为内存对齐而浪费的内存空间,所以可以
        把stride理解为系统为类型T分配的内存

#### MemoryLayout工具类简单总结
1. 实际占用的内存大小: MemoryLayout.size(ofValue:)  
2. 系统分配的内存大小: MemoryLayout.stride(ofValue:) 
3. 内存对齐大小: MemoryLayout.alignment(ofValue:) 
4. ⚠️类对象的size、stride、alignment都是8个字节，因为class是对象类型数据,使用MemoryLayout对class类型计算其内存结果实际上是对其class类型的引用指针进行操作，所以不建议利用MemoryLayout工具对类对象进行内存分析
5. 可以借助第三方工具(WGCore-MJMemoryTool-Mems.swift)来打印一般项目中无法打印的变量内存地址

#### 什么是内存对齐？
#### 计算机内存空间是按照byte字节进行划分的，从理论上讲似乎对任何类型的变量的访问可以从任何地址开始，但实际情况是在访问特定类型变量的时候经常在特定的内存地址访问，这就需要各种类型数据按照一定的规则在空间上排列，而不是顺序的一个接一个的排放，这就是对齐。比如Bool的内存对齐字节数是1，那么在内存中位置就是 0 1 2 3...,Float的内存对齐字节数是4，那么就是0-4存放一个Float类型数据，5-8存放一个Float类型数据，4位为一组内存来存放的

#### 为什么要内存对齐？
1. 平台原因(移植原因)：并不是所有的硬件平台都能访问任意地址上的任意数据的；某些硬件平台只能在某些地址处取某些特定类型的数据，否则抛出硬件异常。
2. 性能原因：数据结构(尤其是栈)应该尽可能地在自然边界上对齐。原因在于为了访问未对齐的内存，处理器需要作两次内存访问；而对齐的内存访问仅需要一次访问。
3. 简单理解就是为了适应硬件和和提高软件的性能问题


### 2. swift中各数据类型占用的内存空间分析
        类型      占用内存大小      系统分配内存大小        内存对齐原则      
        Bool         1                1                  1
        Int          8                8                  8
        Int8 
        Int32        4                4                  4
        Int64        8                8                  8
        NSInteger    8                8                  8
        Float        4                4                  4
        CGFloat      8                8                  8
        Double       8                8                  8
        String       16               16                 8
        Character    16               16                 8
        Array        8                8                  8
        Dictionary   0                8                  8
        Set          8                8                  8
#### ⚠️Dictionary是因为创建的空字典导致的所以占用内存大小为0字节，如果创建一个有元素的字典，则占用的内存大小为8字节


### 3. swift内存对齐之枚举enum
#### swift枚举分为两类：
1. 无关联值枚举：无原始值枚举(无类型枚举)/有原始值枚举(有类型枚举) 
2. 有关联值枚举：(不能声明枚举类型)

#### 3.1 无关联值枚举

    //无类型枚举(无原始值枚举)             //有类型枚举(有原始值枚举)
    enum DirectionEnumNoType {         enum DirectionEnum : String {
        case left                           case left
        case right                          case right
        case top                            case top
        case bottom                         case bottom
    }                                  }

    public override func viewDidLoad() {
        super.viewDidLoad()
        //无原始值(无类型)枚举-没有rawValue方法(rawValue方法是获取枚举的原始值的)
        let leftNoType = DirectionEnumNoType.left
        NSLog("\n无类型枚举: \n实际占用内存大小:\(MemoryLayout.size(ofValue: leftNoType))\n
        系统分配内存大小:\(MemoryLayout.stride(ofValue: leftNoType))\n 
        内存对齐大小:\(MemoryLayout.alignment(ofValue: leftNoType))")
        
        //有原始值(有类型)枚举-有rawValue方法
        let left = DirectionEnum.left
        NSLog("\n有类型枚举: \n实际占用内存大小:\(MemoryLayout.size(ofValue: left))\n
        系统分配内存大小:\(MemoryLayout.stride(ofValue: left))\n 
        内存对齐大小:\(MemoryLayout.alignment(ofValue: left))")
        
        //若没有对枚举成员赋原始值，则有如下规则:枚举类型是String->原始值为枚举成员的字符 类型是Int->原始值是从0开始依次递增
        NSLog("有类型枚举原始值:\(left.rawValue)")
    }
    打印结果: 无类型枚举: 
                实际占用内存大小:1
                系统分配内存大小:1
                内存对齐大小:1
            有类型枚举: 
                实际占用内存大小:1
                系统分配内存大小:1
                内存对齐大小:1
            有类型枚举原始值:left
#### swift无关联值枚(有原始值-有类型枚举和无原始值-无类型枚举)总结
1. 无关联值的枚举，占用的内存空间都是1字节，不受原始值类型的影响
2. 若枚举没有定义枚举类型 (无原始值)，就没有rawValue方法，rawValue方法是用来获取原始值的
3. 若枚举定义了枚举类型(有原始值)，可以通过rawValue方法获取原始值；
4. 若枚举定于了类型，但是没有在枚举中写原始值，那么String类型的默认的原始值就是各枚举项名称的字符串，Int类型的默认枚举第一项的原始值是0，依次递增

#### 接下来我们可以借助小码哥写**Mems.swift**的内存打印工具来窥探无关联类型枚举占用1字节内存空间是如何存储的？工具使用介绍:先打断点，然后通过Xcode工具栏的Debug->Debug workflow->View Memory,将变量地址输入进入即可查看内存地址的二进制 
        //无原始值(无类型)枚举-没有rawValue方法(rawValue方法是获取枚举的原始值的)
        var leftNoType = DirectionEnumNoType.left
        var rightNoType = DirectionEnumNoType.right
        var topNoType = DirectionEnumNoType.top
        var bottomNoType = DirectionEnumNoType.bottom
        //00 C0 C6 E0 2B 01 00 00  -------用1个字节(00)来保存枚举元素leftNoType
        NSLog("leftNoType内存地址:\(Mems.ptr(ofVal: &leftNoType))")
        //01 00 C0 C6 E0 2B 01 00  -------用1个字节(01)来保存枚举元素rightNoType
        NSLog("rightNoType内存地址:\(Mems.ptr(ofVal: &rightNoType))")
        //02 01 00 C0 C6 E0 2B 01  -------用1个字节(01)来保存枚举元素topNoType
        NSLog("topNoType内存地址:\(Mems.ptr(ofVal: &topNoType))")
        //03 02 01 00 C0 C6 E0 2B  -------用1个字节(01)来保存枚举元素bottomNoType
        NSLog("bottomNoType内存地址:\(Mems.ptr(ofVal: &bottomNoType))")
        
        //有原始值(有类型)枚举-
        var left = DirectionEnum.left
        var right = DirectionEnum.right
        var top = DirectionEnum.top
        var bottom = DirectionEnum.bottom
        //00 60 02 D1 0D 01 00 00  -------用1个字节(00)来保存枚举元素left
        NSLog("left内存地址:\(Mems.ptr(ofVal: &left))")
        //01 00 60 02 D1 0D 01 00  -------用1个字节(01)来保存枚举元素right
        NSLog("right内存地址:\(Mems.ptr(ofVal: &right))")
        //02 01 00 60 02 D1 0D 01  -------用1个字节(01)来保存枚举元素top
        NSLog("top内存地址:\(Mems.ptr(ofVal: &top))")
        //03 02 01 00 60 02 D1 0D  -------用1个字节(01)来保存枚举元素bottom
        NSLog("bottom内存地址:\(Mems.ptr(ofVal: &bottom))")

#### 分析：无关联值枚举占用一个字节内存，用这一个字节可以保存枚举中的各个枚举项；这一个字节存储的值是按照各个枚举顺序依次存储为0、1、2、3...，无论枚举类型是String、Int、Double,枚举底层是不存储枚举的原始值的，而是存储0、1、2、3、4.....,枚举的原始值可以直接通过rawValue方法来获取即可，没必要存储

#### 特例：枚举中只有一个枚举项

        enum DirectionEnum {
            case left
        }
        
        var left = DirectionEnum.left
        NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: left))\n 
        系统分配内存大小:\(MemoryLayout.stride(ofValue: left))\n 
        内存对齐大小:\(MemoryLayout.alignment(ofValue: left))")
        打印结果: 实际占用内存大小:0
                系统分配内存大小:1
                内存对齐大小:1
#### 为什么占用的内存大小是0个字节？因为枚举就一项，不需要再单独拿一个字节来标识到底是枚举中的那个项，因为就一个枚举项，不需要区分，但是为什么系统还分配了内存空间，主要就是内存对齐大小为1个字节，所以系统要分配一个字节的内存大小

#### 3.2 有关联值枚举
#### 关联值枚举是不能声明枚举类型的
        enum DirectionEnum {
            case left(Bool,Bool,Bool)
            case right(Bool,Bool)
            case bottom(Bool)
        }
        打印结果: 实际占用内存大小:3---系统分配内存大小:3---内存对齐大小:1

        enum DirectionEnum {
            case left(Bool,Bool,Bool)
            case right(Float,Bool)
            case bottom
        }
        打印结果: 实际占用内存大小:5---系统分配内存大小:8---内存对齐大小:4

        enum DirectionEnum {
            case left(String,Bool,Bool)
            case right(Float,Bool)
            case bottom
        }
        打印结果: 实际占用内存大小:18---系统分配内存大小:24---内存对齐大小:8

        enum DirectionEnum {
            case left(String,String,Bool)
            case right(Float,Float)
            case bottom(String)
        }
        打印结果: 实际占用内存大小:33---系统分配内存大小:40---内存对齐大小:8
#### 关联值枚举占用内存总结如下
1. 关联值枚举的内存对齐大小：各个枚举项中关联值类型最大的内存对齐字节数作为枚举的内存对齐字节数

        { case left(String,Bool,Bool) case right(Float,Bool) case bottom } 
        string内存对齐8字节/Bool内存对齐1字节/Float内存对齐4个字节  
        取最大的String类型的对齐字节数作为内存对齐数，即该枚举内存对齐8字节
2. 关联值枚举实际占用内存大小: 每个枚举项所占用内存=该枚举项关联值类型所占用内存的和，然后比较各个枚举项，取最大的内存(+1或不加)作为枚举实际占用的内存大小

        { case left(String,Bool,Bool) case right(Float,Bool) case bottom } 
        letf: 实际占用16+1+1=18  right:实际占用4+1=5  bottom=0  
        取最大的枚举项所占用的内存作为枚举实际占用内存大小，即该枚举实际占用18个字节
        这里不加1的原因是left(String,Bool,Bool)中，第18个字节既可以保存Bool类型,也可以用来标示属于哪个枚举项，
        所以没必要再占据一个字节来存储标识
3. 关联值枚举系统分配的内存大小: 根据实际占用内存大小和内存对齐字节数来判断的，

        { case left(String,Bool,Bool) case right(Float,Bool) case bottom } 
        实际占用18个字节，由于内存对齐是8个字节，所以系统要分配8的倍数的字节数且要大于实际占用的18字节，
        所以系统分配24个字节

#### 关联值枚举的实际内存大小=所有项中占用内存最大项的内存值+1字节(标识枚举属于哪个项),这里需要注意的就是+1字节(标识枚举属于哪个项)有些情况下是不需要+的，这个需要看情况而定，接下来我们来验证

    enum Direction {
        case left(Int,String,Bool) //8+16+1 = 25字节
        case right(Bool) //1字节
        case bottom
    }

    var dir1 = Direction.left(120, "a", true)
    NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
    NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
    NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
    //78 00 00 00 00 00 00 00                          前8字节存储第一个关联值：120
    //61 00 00 00 00 00 00 00 00 00 00 00 00 00 00 E1  接着16字节用来存储关联值：字符a
    //01 00 00 00 00 00 00 00                          第25个字节存储关联值：true
    NSLog("dir1:\(Mems.ptr(ofVal: &dir1))")
    
    //01 00 00 00 00 00 00 00                          前8字节存储第一个关联值：true
    //00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 第二位没有对应的关联值，所以什么都不存储
    //40 71 FC 6E 01 00 00 00                          第25个字节用来标识枚举类型属于.right
    var dir2 = Direction.right(true)
    NSLog("dir2:\(Mems.ptr(ofVal: &dir2))")
    
    //00 00 00 00 00 00 00 00                          没有对应的关联值，什么也不存储 
    //00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  没有对应的关联值，什么也不存储 
    //80 C2 F2 03 01 00 00 00                          第25个字节用来标示枚举类型.bottom
    var dir3 = Direction.bottom
    NSLog("dir3:\(Mems.ptr(ofVal: &dir3))")

    打印结果：实际占用内存大小:25---系统分配内存大小:32---内存对齐大小:8
#### 分析，通过第三方工具来打印枚举变量的内存地址，然后利用内存地址可以窥探枚举变量在内存中存储布局。枚举的关联值是存储在枚举变量的内存中的，而原始值是不会被存储在枚举变量的内存中的；枚举实际占用的内存大小=枚举各个项中关联值的内存之和的最大值(+标识枚举属于哪个项的1个字节)具体要不要+1字节，不一定，要视情况而定


### 3.3 swift枚举总结
1. 无关联值枚举(有原始值-枚举有类型、无原始值-枚举无类型)占用的内存大小是1个字节，跟有无原始值无关；1个字节表示枚举项最多是256个，那么如果超过256个case,枚举就会分配2个字节来存储
2. 有关联值的枚举，关联值是存储在枚举变量的内存中的
3. 有关联值枚举，实际占用内存大小是对各个枚举项的关联值内存之和进行对比，取最大枚举项的内存+1字节来表示枚举实际占用内存空间的，要不要+1要根据具体情况分析
4. 关联值枚举中，需要注意枚举关联值类型的顺序，这些顺序会影响内存占用情况，具体要根据实际业务进行比较


### 4. swift内存对齐之结构体struct
#### 观察下面的案例，定义了结构体，属性一摸一样仅仅是顺序不同，导致的结构体占用内存就不一样了
    struct DirectionStruct {
        var sex = false           //Bool类型占1字节内存，由于内存对齐是8字节，所以这里分配8个字节来存储该属性      
        var name = ""             //String类型占16字节，内存对齐是8字节，所以这里分配16字节来存储该属性
        var height: Float = 0.0   //Float类型占4字节，内存对齐是8字节，所以这里分配8字节，前4字节用来存储该属性
    }
    打印结果: 实际占用内存大小:28---系统分配内存大小:32---内存对齐大小:8
#### 结构体1分析
1. 系统分配内存大小 = sex(8字节) + name(16字节) + height(8字节)
2. 实际占用字节: 

        sex分配了8个字节，只用了1个字节来保存sex,按道理应该还剩7字节可以保存数据，但是接下来要保存的是name，占16个字节，
        由于内存对齐是8字节所以剩下的7字节其实是不能用的，但是仍然要归sex占用的内存，
        所以sex实际占用8字节；name占16字节，所以实际占用就是16字节,height占4字节，
        由于内存对齐系统分配了8字节，只是前4个字节得到了利用，所以height实际占用的就是4个字节
        综上该结构体实际占用的内存大小 = sex(8字节) + name(16字节) + height(4字节) = 28字节
        
        
        struct DirectionStruct {
            var name = ""          
            var sex = false     
            var height: Float = 0.0
        }
        打印结果: 实际占用内存大小:24---系统分配内存大小:24---内存对齐大小:8
#### 结构体2分析
1. 系统分配内存大小 = name(16字节) + 8字节(前4字节存储sex,后4字节存储height)
2. 实际占用字节: 

        name占16字节，所以实际占用就是16字节
        sex占1字节，但是由于内存对齐8字节，所以系统分配8字节来存储，
        接下来要存储height,height占4个字节，而上一个系统为sex属性分配的8字节还有7个字节没有用到，所以可以放在系统
        为sex分配的8个字节的后4个字节进行存储综上该结构体实际
        占用的内存大小 = name(16字节) + 8字节(前4字节存储sex，后4字节存储height) = 24
        
        
        struct DirectionStruct {
            var height: Float = 1
            var name = "a"
            var sex = true  
        }
        打印结果: 实际占用内存大小:25---系统分配内存大小:32---内存对齐大小:8
#### 结构体3分析
1. 系统分配内存大小 = height(8字节) + name(16字节) + sex(8字节) = 32字节
    2. 实际占用字节: 

        height占4字节，由于内存对齐系统分配8字节，前4个字节用来存储height,还剩4个字节留给接下来要存储的属性
        name占16字节，由于系统为height分配8字节还剩余4字节，加之内存对齐是8字节所以不够name存储，
        所以系统重新分配16字节来存储name到这里我们知道height虽然还剩余4字节，但是无法存储name，
        所以height实际占用就是8个字节，name实际占用就是16字节,sex占用1字节，系统分配8字节，但是实际占用就是1字节
        综上该结构体实际占用的内存大小 = height(8字节) + name(16字节) + sex(1字节) = 25字节


        struct DirectionStruct {   
            var age = 3      
            var name = 12     
            var height = 4   
        }
        var stru = DirectionStruct()
        NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: stru))\n 
        系统分配内存大小:\(MemoryLayout.stride(ofValue: stru))\n 
        内存对齐大小:\(MemoryLayout.alignment(ofValue: stru))")
        
        let ssss = UnsafePointer(&stru)
        NSLog("结构体stru的内存地址:\(Mems.ptr(ofVal: &stru))")
        
        打印结果: 实际占用内存大小:24---系统分配内存大小:24---内存对齐大小:8
                结构体stru的内存地址:0x000000016fc19000
#### 通过打断点->Xcode->Debug->Debug Workflow->View Memory,将 0x000000016fc19000地址写入Address,内存布局如下1，很明显结构体中的属性值存储在对应的内存空间中；或者我们通过Xcode的控制台的lldb指令 x 0x000000016fc19000 或者 x/3g 0x000000016fc19000 打印三个成员变量的地址如下2
    一 03 00 00 00 00 00 00 00 0C 00 00 00 00 00 00 00 04 00 00 00 00 00 00 00
    二 0x16fc19000: 0x0000000000000003 0x000000000000000c
       0x16fc19010: 0x0000000000000004

####  swift结构体总结
1. swift结构体中内存对齐字节数 = 结构体中成员中最大的内存对齐字节数
2. swift结构体中系统分配的内存大小要根据成员变量占用内存的大小 + 内存对齐字节数 来综合判断
3. swift结构体中实际分配的内存大小要根据成员变量占用内存的大小 + 内存对齐字节数 来综合判断
4. swift结构体中成员变量的顺序会影响结构体占用内存的情况，为了减少内存空间的占用，需要自己认证研判视情况而定
5. struct 是值类型，一个没有引用类型的 Struct 临时变量都是在栈上存储的：
