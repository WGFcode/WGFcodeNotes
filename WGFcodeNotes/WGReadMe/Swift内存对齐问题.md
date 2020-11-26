## swift内存对齐
### 1. swift中各种数据类型占用的内存空间大小
        let BoolValue: Bool = true
        let Boolsize = MemoryLayout.size(ofValue: BoolValue)
        let BoolaligSize = MemoryLayout.alignment(ofValue: BoolValue)
        
        let IntValue: Int = 1
        let IntSize = MemoryLayout.size(ofValue: IntValue)
        let IntaligSize = MemoryLayout.alignment(ofValue: IntValue)
        
        let Int32Value: Int = 1
        let Int32Size = MemoryLayout.size(ofValue: Int32Value)
        let Int32aligSize = MemoryLayout.alignment(ofValue: Int32Value)
        
        let Int64Value: Int = 1
        let Int64Size = MemoryLayout.size(ofValue: Int64Value)
        let Int64aligSize = MemoryLayout.alignment(ofValue: Int64Value)
        
        let FloatValue: Float = 0.2
        let FloatSize = MemoryLayout.size(ofValue: FloatValue)
        let FloataligSize = MemoryLayout.alignment(ofValue: FloatValue)
        
        let DoubleValue: Double = 0.2
        let DoubleSize = MemoryLayout.size(ofValue: DoubleValue)
        let DoublealigSize = MemoryLayout.alignment(ofValue: DoubleValue)
        
        let CFFloatValue: CGFloat = 0.2
        let CFFloatSize = MemoryLayout.size(ofValue: CFFloatValue)
        let CGFloataligSize = MemoryLayout.alignment(ofValue: CFFloatValue)
        
        let NSIntegerValue: NSInteger = 1
        let NSIntegerSize = MemoryLayout.size(ofValue: NSIntegerValue)
        let NSIntegeraligSize = MemoryLayout.alignment(ofValue: NSIntegerValue)
        
        let StringValue: String = "1231234123123"
        let StringSize = MemoryLayout.size(ofValue: StringValue)
        let StringaligSize = MemoryLayout.alignment(ofValue: StringValue)
        
        let CharacterValue = Character("*")
        let CharacterSize = MemoryLayout.size(ofValue: CharacterValue)
        let CharacteraligSize = MemoryLayout.alignment(ofValue: CharacterValue)
        
        let ArrValue = ["1","2"]
        let ArrSize = MemoryLayout.size(ofValue: ArrValue)
        let ArraligSize = MemoryLayout.alignment(ofValue: ArrValue)
        
        let DicValue = ["key": "value"]
        let DicSize = MemoryLayout.size(ofValue: DicValue)
        let DicaligSize = MemoryLayout.alignment(ofValue: DicValue)
        
        let objcSize = MemoryLayout.size(ofValue: self)
        let objcaligSize = MemoryLayout.alignment(ofValue: self)
        
        NSLog("\n Boolsize:-------\(Boolsize)字节---内存对齐字节数:\(BoolaligSize),\n IntSize:-------\(IntSize)字节---内存对齐字节数:\(IntaligSize), \n Int32Size:-------\(Int32Size)字节---内存对齐字节数:\(Int32aligSize), \n Int64Size:-------\(Int64Size)字节---内存对齐字节数:\(Int64aligSize), \n FloatSize:-------\(FloatSize)字节---内存对齐字节数:\(FloataligSize), \n DoubleSize:-------\(DoubleSize)字节---内存对齐字节数:\(DoublealigSize), \n CFFloatSize:-------\(CFFloatSize)字节---内存对齐字节数:\(CGFloataligSize), \n NSIntegerSize:-------\(NSIntegerSize)字节---内存对齐字节数:\(NSIntegeraligSize), \n StringSize:-------\(StringSize)字节---内存对齐字节数:\(StringaligSize), \n CharacterSize:-------\(CharacterSize)字节---内存对齐字节数:\(CharacteraligSize), \n ArrSize:-------\(ArrSize)字节---内存对齐字节数:\(ArraligSize), \n DicSize:-------\(DicSize)字节---内存对齐字节数:\(DicaligSize), \n 对象的内存空间:-------\(objcSize)字节---内存对齐字节数:\(objcaligSize)")

        打印结果：Boolsize:-------1字节---内存对齐字节数:1,
                IntSize:-------8字节---内存对齐字节数:8, 
                Int32Size:-------8字节---内存对齐字节数:8, 
                Int64Size:-------8字节---内存对齐字节数:8, 
                FloatSize:-------4字节---内存对齐字节数:4, 
                DoubleSize:-------8字节---内存对齐字节数:8, 
                CFFloatSize:-------8字节---内存对齐字节数:8, 
                NSIntegerSize:-------8字节---内存对齐字节数:8, 
                StringSize:-------16字节---内存对齐字节数:8, 
                CharacterSize:-------16字节---内存对齐字节数:8, 
                ArrSize:-------8字节---内存对齐字节数:8, 
                DicSize:-------8字节---内存对齐字节数:8, 
                对象的内存空间:-------8字节---内存对齐字节数:8
#### 总结：内存对齐字节数是什么意思：就是每次在内存中可以排序的最大位置， 比如Bool的内存对齐字节数是1，那么在内存中位置就是 0 1 2 3..., Float的内存对齐字节数是4，那么就是0-4存放一个Float类型数据，5-8存放一个Float类型数据，4位为一组内存来存放的，
#### 2.为什么要内存对齐？ 
1. 平台原因(移植原因)：并不是所有的硬件平台都能访问任意地址上的任意数据的；某些硬件平台只能在某些地址处取某些特定类型的数据，否则抛出硬件异常。
2. 性能原因：数据结构(尤其是栈)应该尽可能地在自然边界上对齐。原因在于为了访问未对齐的内存，处理器需要作两次内存访问；而对齐的内存访问仅需要一次访问。
#### 总结： 简单理解就是为了适应硬件和和提高软件的性能问题

#### 3. 内存对齐之枚举
        // 没有原始值
        enum WGSexType {
            case Man
            case Woman
            case RenYao
        }
        //有原始值
        enum WGSexType: String {
            case Man = "男人"
            case Woman = "女人"
            case RenYao = "人妖"
        }

        class ViewController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                self.view.backgroundColor = UIColor.red
                let sexEnum = WGSexType.Man
                // 实际占用的内存大小
                let sexEnumSize0 = MemoryLayout.size(ofValue: sexEnum)
                // 系统分配的内存大小
                let sexEnumSize1 = MemoryLayout.stride(ofValue: sexEnum)
                // 内存对齐的字节数长度
                let sexEnumSize2 = MemoryLayout.alignment(ofValue: sexEnum)
                NSLog("\n枚举实际占用的内存大小：----\(sexEnumSize0)个字节, \n枚举被系统分配的内存大小：----\(sexEnumSize1)个字节, \n 枚举内存对齐的字节数长度：----\(sexEnumSize2)个字节, \n")
            }
        }
        
        打印结果: 枚举实际占用的内存大小：----1个字节, 
                枚举被系统分配的内存大小：----1个字节, 
                枚举内存对齐的字节数长度：----1个字节, 
#### 总结1：枚举在没有原始值和有原始值的情况下，枚举只占用一个字节的内存大小，说明有无原始值并不会影响枚举所占内存空间的大小

#### 3.1 枚举中关联值对枚举内存占用情况的影响
#### 最终我们可以得出结论枚举中的关联值对枚举占用内存的大小是有影响的，那么我们接下来主要分析一个枚举中涉及到的三个重要概念和内存大小
1. 枚举内存对齐的字节数
2. 枚举实际占用内存的大小
3. 枚举被系统分配内存的大小

#### 3.1.1 首先我们分析：1.枚举内存对齐的字节数

        class ViewController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                self.view.backgroundColor = UIColor.red
                
                let sexEnum = WGSexType.Man("1","1",true)
                // 实际占用的内存大小
                let sexEnumSize0 = MemoryLayout.size(ofValue: sexEnum)
                // 系统分配的内存大小
                let sexEnumSize1 = MemoryLayout.stride(ofValue: sexEnum)
                // 内存对齐的字节数长度
                let sexEnumSize2 = MemoryLayout.alignment(ofValue: sexEnum)
                NSLog("\n枚举实际占用的内存大小：----\(sexEnumSize0)个字节, \n枚举被系统分配的内存大小：----\(sexEnumSize1)个字节, \n 枚举内存对齐的字节数长度：----\(sexEnumSize2)个字节, \n")
            }
        }

        enum WGSexType {
            case Man(Bool,Bool,Bool)
            case Woman(Bool,Bool)
            case RenYao(Bool)
        }
        打印结果: 枚举实际占用的内存大小：----3个字节,
                 枚举被系统分配的内存大小：----3个字节,
                 枚举内存对齐的字节数长度：----1个字节,
                
        enum WGSexType {
            case Man(Bool,Bool,Bool)
            case Woman(Float,Bool)
            case RenYao(Bool)
        }
        打印结果: 枚举实际占用的内存大小：----5个字节,
                枚举被系统分配的内存大小：----8个字节,
                枚举内存对齐的字节数长度：----4个字节,
            
        enum WGSexType {
            case Man(String,Bool,Bool)
            case Woman(Float,Bool)
            case RenYao(Bool)
        }
        打印结果: 枚举实际占用的内存大小：----18个字节,
                枚举被系统分配的内存大小：----24个字节,
                枚举内存对齐的字节数长度：----8个字节,
                
        enum WGSexType {
            case Man(String,String,Bool)
            case Woman(Float,Float)
            case RenYao(String)
        }
        打印结果: 枚举实际占用的内存大小：----33个字节,
                枚举被系统分配的内存大小：----40个字节,
                枚举内存对齐的字节数长度：----8个字节,
#### 总结1：从以上打印结果我们知道，枚举的内存对齐的字节数是由各个枚举值中关联值类型的最大内存对齐字节数决定的，比如枚举关联值中有Float(内存对齐4个字节)/Bool(内存对齐1个字节)/String(内存对齐8个字节)类型，那么枚举的内存对齐字节数就取其中最大的内存字节数作为枚举内存对齐字节数，即String的内存对齐字节数8个字节
#### 总结2: 枚举实际占用的内存字节数，是由各个枚举值中各个关联值类型占用内存的总和表示的，而是取的是各个枚举值中的最大值，比如枚举关联值case Man(String,String,Bool)：它占用的内存就是16+16+1=33个字节，case Woman(Float,Float)：它占用的内存就是4+4=8个字节 ，case RenYao(String)：它占用的内存就是16个字节，取各个枚举值中的最大值，所以该枚举实际占用的内存字节数就是33个字节
#### 总结3: 系统给枚举分配的内存字节数，是根据枚举对齐字节数和枚举实际占用的内存字节数来判断的，case Man(String,String,Bool)：系统分配的字节数 16 + 16 + 8(内存对齐数为8)=40个字节；case Woman(Float,Float)：系统分配的字节数4 + 4（对齐字节数为8，所以两个4刚好分配一块8字节的内存）；case RenYao(String)：系统分配的字节数为16，取这三个中的最大值，即系统给这个枚举分配的字节数就是40个字节

#### 枚举中无原始值/有原始值的情况下，占用的内存空间就是1字节大小，如果有关联值，那么就是关联值项中占用的最大字节数+1，+1是基于有多个case的情况下，用1字节大小来保存类型的


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
### MJ小码哥
#### swift中使用MemoryLayout来窥探内存,主要涉及到以下三个方法，同时可以借助第三方工具(WGCore-MJMemoryTool-Mems.swift)来打印一般项目中无法打印的变量内存地址
        1.实际占用的内存大小
        MemoryLayout.size(ofValue:)  
        2.系统分配的内存大小
        MemoryLayout.stride(ofValue:) 
        3.内存对齐大小
        MemoryLayout.alignment(ofValue:) 

#### 4. 枚举主要有两类：无关联值枚举/有关联值枚举
#### 4.1 无关联值枚举：无原始值和有原始值的枚举
#### 4.1.1 无类型的枚举(无原始值)
        enum Direction {          
            case left
            case right
            case top
            case bottom
        }
        public override func viewDidLoad() {
            super.viewDidLoad()
            var dir1 = Direction.left
            NSLog("dic:\(dic)") 
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
        }
        
        打印结果: dic:left
                实际占用内存大小:1
                系统分配内存大小:1
                内存对齐大小:1
#### 分析：如果枚举没有声明类型，那么是没有rawValue方法的，rawValue方法是获取枚举的原始值的；为什么只占用一个字节？因为枚举变量只需要一个字节就可以来保存对应的枚举类型即可，这一个字节可以用来保存left或者right或者top或者bottom，接下来我们可以借助**Mems.swift**内存打印工具来窥探
        public override func viewDidLoad() {
            super.viewDidLoad()
            var dir1 = Direction.left
            //第一个字节保存的是0---00
            //00 90 AC B8 05 01 00 00 00 28 F0 FD 02 01 00 00
            NSLog("dir1内存地址:\(Mems.ptr(ofVal: &dir1))")
            
            var dir2 = Direction.right
            //第一个字节保存的是1---01
            //01 B7 70 40 6D 01 00 00 00 23 00 00 00 00 00 00
            NSLog("dir2内存地址:\(Mems.ptr(ofVal: &dir2))")
            
            var dir3 = Direction.top
            //第一个字节保存的是2---02
            //02 4F 70 40 6D 01 00 00 00 23 00 00 00 00 00
            NSLog("dir3内存地址:\(Mems.ptr(ofVal: &dir3))")
            
            var dir4 = Direction.bottom
            //第一个字节保存的是3---03
            //03 2F 70 40 6D 01 00 00 00 23 00 00 00 00 00 00
            NSLog("dir4内存地址:\(Mems.ptr(ofVal: &dir4))")
        }
#### 工具使用介绍。获取内存二进制的方式是先获取到变量的地址，然后通过Xcode工具栏的Debug->Debug workflow->View Memory,将变量地址输入进入即可查看内存地址的二进制
#### 分析，可以看出无关联值的枚举，占用的就是一个字节的空间来保存各个枚举变量，并且这一个字节存储的值是按照各个枚举顺序依次存储为0、1、2、3...
#### 4.1.2 有类型的枚举(有原始值)
        enum Direction: String {
            case left
            case right
            case top
            case bottom
        }
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            let dic = Direction.left
            NSLog("dic:\(dic)----rawValue:\(dic.rawValue)")
        }
        打印结果： dic:left----rawValue:left
#### 如果定义了枚举类型，但是在枚举中没有写原始值，那么默认的原始值就是各枚举项名称的字符串；如果写了原始值，那么通过rawValue就可以获取到原始值
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            let dir1 = Direction.left
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
        }
        
        打印结果：实际占用内存大小:1
                系统分配内存大小:1
                内存对齐大小:1
#### 分析，通过验证，无论枚举Direction属于String、Int、Double...打印的结果都是一样的，即占用内存的空间大小都是1个字节，这一个字节用来标识不同的枚举项。所以我们可以得出结论：**无关联值的枚举，占用的内存空间都是1字节，不受原始值类型的影响**，枚举底层是不存储枚举的原始值的，原始值的获取可以直接通过rawValue来获取即可，没必要存储
        
        enum Direction: Double {
            case left
        }
        public override func viewDidLoad() {
            super.viewDidLoad()
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
        }
        打印结果：实际占用内存大小:0
                系统分配内存大小:1
                内存对齐大小:1
#### 分析，为什么占用的内存大小是0个字节？因为枚举就一项，不需要再单独拿一个字节来标识到底是枚举中的那个项，因为就一个枚举项，不需要区分，但是为什么系统还分配了内存空间，主要就是内存对齐大小为1个字节，所以系统要分配一个字节的内存大小

#### 4.2 有关联值的枚举
#### 关联值的枚举就不能再声明枚举类型了，
        enum Direction {
            case left(Int,Int,Int)
            case right(Bool)
            case bottom
        }
        public override func viewDidLoad() {
            super.viewDidLoad()
            let dir1 = Direction.left(10, 20, 30)
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
        }
        
        打印结果：实际占用内存大小:25
                系统分配内存大小:32
                内存对齐大小:8
#### 分析，三个关联值类型都是int，一个占8个字节，那么就是占用24个字节，剩下一个字节用来标识属于哪个枚举项，所以实际占用25个字节；内存对齐是8个字节，所以系统分配必须是8的倍数，并且要大于25个字节，所以就是32个字节了。
#### 关联值枚举的实际内存大小=所有项中占用内存最大项的内存值+1字节(标识枚举属于哪个项),这里需要注意的就是+1字节(标识枚举属于哪个项)有些情况下是不需要+的，如下情况

        enum Direction {
            case left(Int,String,Bool) //8+16+1 = 25字节
            case right(Bool) //1字节
            case bottom
        }
        public override func viewDidLoad() {
            super.viewDidLoad()
            let dir1 = Direction.left(120, "3r", false)
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir1))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir1))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir1))")
            
            let dir2 = Direction.bottom
            NSLog("实际占用内存大小:\(MemoryLayout.size(ofValue: dir2))")
            NSLog("系统分配内存大小:\(MemoryLayout.stride(ofValue: dir2))")
            NSLog("内存对齐大小:\(MemoryLayout.alignment(ofValue: dir2))")
        }

        打印结果：实际占用内存大小:25
                系统分配内存大小:32
                内存对齐大小:8
                
                实际占用内存大小:25
                系统分配内存大小:32
                内存对齐大小:8
#### 无论枚举变量类型是属于哪个枚举项，所占的内存都是一样的；上面结论中:实际占用的内存大小就是取最大项所占的内存大小(25)+1字节(标识属性哪个枚举项)，这里为什么是25个字节而不是26个字节？因为第25个字节用来存放left(Int,String,Bool)中的最后一个关联值Bool，也可以用来标示属于哪个枚举项，所以没必要再占据一个字节来存储标识了，所以实际占用25个字节就够了，接下来我们来验证
    enum Direction {
        case left(Int,String,Bool) //8+16+1 = 25字节
        case right(Bool) //1字节
        case bottom
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    打印结果：实际占用内存大小:25
            系统分配内存大小:32
            内存对齐大小:8
#### 分析，通过第三方工具来打印枚举变量的内存地址，然后利用内存地址可以窥探枚举变量在内存中存储布局。枚举的关联值是存储在枚举变量的内存中的，而原始值是不会被存储在枚举变量的内存中的；枚举实际占用的内存大小=枚举各个项中关联值的内存之和的最大值(+标识枚举属于哪个项的1个字节)具体要不要+1字节，不一定，要视情况而定

























                
































































        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
































































































