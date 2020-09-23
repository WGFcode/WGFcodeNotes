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

        打印结果： Boolsize:-------1字节---内存对齐字节数:1,
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
