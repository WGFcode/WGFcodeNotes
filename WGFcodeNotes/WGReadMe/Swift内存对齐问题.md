## swift内存对齐


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
        数组中有5个T类型元素，虽然每个T元素的大小为size个字节，但是因为需要内存对齐的限制，每个T类型元素实际消耗的内存空间为stride个字节，而 stride-size个字节则为每个元素因为内存对齐而浪费的内存空间,所以可以把stride理解为系统为类型T分配的内存

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
            NSLog("\n无类型枚举: \n实际占用内存大小:\(MemoryLayout.size(ofValue: leftNoType))\n 系统分配内存大小:\(MemoryLayout.stride(ofValue: leftNoType))\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: leftNoType))")
            
            //有原始值(有类型)枚举-有rawValue方法
            let left = DirectionEnum.left
            NSLog("\n有类型枚举: \n实际占用内存大小:\(MemoryLayout.size(ofValue: left))\n 系统分配内存大小:\(MemoryLayout.stride(ofValue: left))\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: left))")
            
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
        NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: left))\n 系统分配内存大小:\(MemoryLayout.stride(ofValue: left))\n 内存对齐大小:\(MemoryLayout.alignment(ofValue: left))")
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
        string内存对齐8字节/Bool内存对齐1字节/Float内存对齐4个字节  取最大的String类型的对齐字节数作为内存对齐数，即该枚举内存对齐8字节
2. 关联值枚举实际占用内存大小: 每个枚举项所占用内存=该枚举项关联值类型所占用内存的和，然后比较各个枚举项，取最大的内存(+1或不加)作为枚举实际占用的内存大小

        { case left(String,Bool,Bool) case right(Float,Bool) case bottom } 
        letf: 实际占用16+1+1=18  right:实际占用4+1=5  bottom=0  取最大的枚举项所占用的内存作为枚举实际占用内存大小，即该枚举实际占用18个字节
        这里不加1的原因是left(String,Bool,Bool)中，第18个字节既可以保存Bool类型,也可以用来标示属于哪个枚举项，所以没必要再占据一个字节来存储标识
3. 关联值枚举系统分配的内存大小: 根据实际占用内存大小和内存对齐字节数来判断的，

        { case left(String,Bool,Bool) case right(Float,Bool) case bottom } 
        实际占用18个字节，由于内存对齐是8个字节，所以系统要分配8的倍数的字节数且要大于实际占用的18字节，所以系统分配24个字节

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

        sex分配了8个字节，只用了1个字节来保存sex,按道理应该还剩7字节可以保存数据，但是接下来要保存的是name，占16个字节，由于内存对齐是8字节
        所以剩下的7字节其实是不能用的，但是仍然要归sex占用的内存，所以sex实际占用8字节；
        name占16字节，所以实际占用就是16字节
        height占4字节，由于内存对齐系统分配了8字节，只是前4个字节得到了利用，所以height实际占用的就是4个字节
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
        接下来要存储height,height占4个字节，而上一个系统为sex属性分配的8字节还有7个字节没有用到，所以可以放在系统为sex分配的8个字节的后4个字节进行存储
        综上该结构体实际占用的内存大小 = name(16字节) + 8字节(前4字节存储sex，后4字节存储height) = 24
        
        
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
            name占16字节，由于系统为height分配8字节还剩余4字节，加之内存对齐是8字节所以不够name存储，所以系统重新分配16字节来存储name
            到这里我们知道height虽然还剩余4字节，但是无法存储name，所以height实际占用就是8个字节，name实际占用就是16字节
            sex占用1字节，系统分配8字节，但是实际占用就是1字节
            综上该结构体实际占用的内存大小 = height(8字节) + name(16字节) + sex(1字节) = 25字节

####  swift结构体总结
1. swift结构体中内存对齐字节数 = 结构体中成员中最大的内存对齐字节数
2. swift结构体中系统分配的内存大小要根据成员变量占用内存的大小 + 内存对齐字节数 来综合判断
3. swift结构体中实际分配的内存大小要根据成员变量占用内存的大小 + 内存对齐字节数 来综合判断
4. swift结构体中成员变量的顺序会影响结构体占用内存的情况，为了减少内存空间的占用，需要自己认证研判视情况而定
















            




































### struct结构体之内存对齐
#### struct的内存对齐字节数是定义的成员变量中，内存对齐数最大的值作为结构体的内存对齐字节数；实际占用的内存就是定义的所有的成员变量所占用的内存字节数之和；系统分配的内存就是按照定义的成员变量顺序再加上最大内存对齐字节数来判断的
        struct WGSexType {
            var age: Int = 0            //8---分配8个字节        
            var name: String = ""       //16---分配16个字节 
            var sex: Bool = false       //1---分配8个字节
        }
        结构体实际占用的内存大小：----25个字节, 
        结构体被系统分配的内存大小：----32个字节, 
        结构体内存对齐的字节数长度：----8个字节, 

        struct WGSexType {
            var sex: Bool = false       //1---分配8个字节
            var age: Int = 0            //8---分配8个字节
            var name: String = ""       //16---分配16个字节
        }
        结构体实际占用的内存大小：----32个字节, 
        结构体被系统分配的内存大小：----32个字节, 
        结构体内存对齐的字节数长度：----8个字节,


   



































        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
































































































