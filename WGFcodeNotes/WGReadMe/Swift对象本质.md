## swift对象的本质
### 1. swift对象的本质
#### 通过汇编探究swift对象的创建过程，通过Xcode->Debug->Debug Workflow->Alway show Disassembly打开汇编调试器，然后在创建swift对象处打断点
Debug Workflow

    class WGMyClass {
        var name = ""
        func testFunc(){
            NSLog("WGMyClass->testFunc")
        }
    }

    public class WGMainVC : UIViewController {
        public override func viewDidLoad() {
            super.viewDidLoad()
            var cls = WGMyClass() //打断点运行项目
        }
    }
#### 通过断点查看在创建swift对象过程中的汇编码我们可以发现，创建swift对象底层流程如下：然后通过swift源码全局搜索swift_allocObject，找到对应的底层方法
1. __allocating_init()
2. swift_allocObject

        static HeapObject *_swift_allocObject_(HeapMetadata const *metadata, size_t requiredSize, size_t requiredAlignmentMask) {
            //⚠️swift_slowAlloc方法: 通过malloc在堆内存中开辟size大小的内存空间，并返回内存地址
            auto object = reinterpret_cast<HeapObject *>(swift_slowAlloc(requiredSize, requiredAlignmentMask));

            //⚠️初始化一个实例对象
            new (object) HeapObject(metadata);

            // If leak tracking is enabled, start tracking this object.
            SWIFT_LEAKS_START_TRACKING_OBJECT(object);

            SWIFT_RT_TRACK_INVOCATION(object, swift_allocObject);
            //⚠️返回对象是HeapObject，说明对象的底层结构就是个HeapObject结构体
            return object;
        }
        
        //引用计数类型是InlineRefCounts，而InlineRefCounts是RefCounts的别名
        typedef RefCounts<InlineRefCountBits> InlineRefCounts;
        define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts  
        struct HeapObject {
          /// This is always a valid pointer to a metadata object.
          HeapMetadata const *__ptrauth_objc_isa_pointer metadata;  //指向元数据的指针-8字节
          SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;                        //引用计数
        };
        
        class RefCounts {
            std::atomic<RefCountBits> refCounts;  
        }
#### 到此我们可以知道，swift对象本质是一个HeapObject结构体，占用16个字节，里面有两个成员，一个是指向元数据的指针、一个是引用计数;

#### 1.1 HeapObject中的元数据HeapMetadata

    #define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts
    struct HeapObject {
        //指向元数据的指针-8字节(可以理解为OC中类对象和元类对象)
        HeapMetadata const *__ptrauth_objc_isa_pointer metadata;  
        //引用计数-8字节
        SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;                        
    }
    
    //HeapMetadata是TargetHeapMetadata的别名
    template <typename Target> struct TargetHeapMetadata;
    using HeapMetadata = TargetHeapMetadata<InProcess>;
    
    // TargetHeapMetadata继承自TargetMetadata结构体
    struct TargetHeapMetadata : TargetMetadata<Runtime> {
        using HeaderType = TargetHeapMetadataHeader<Runtime>;
        TargetHeapMetadata() = default;
        //初始化方法 这里传入的参数是MetadataKind kind，其实就是传入的InProcess
        constexpr TargetHeapMetadata(MetadataKind kind)
        : TargetMetadata<Runtime>(kind) {}
    };
    
    struct TargetMetadata {
        //kind属性，就是之前传入的Inprocess，主要用于区分是哪种类型的元数据
        StoredPointer Kind;  
        //若kind > 0x7FF(LastEnumeratedMetadataKind) 则kind为MetadataKind::Class，否则返回MetadataKind(kind)
        MetadataKind getKind() const {
            return getEnumeratedMetadataKind(Kind);
        }
        //通过去匹配kind，返回值是TargetClassMetadata类型，如果有则获取它的类对象，若类型不是class,则返回nil
        const TargetClassMetadata<Runtime> *getClassObject() const;
    }
    
    struct TargetClassMetadata : public TargetAnyClassMetadata<Runtime> {
      TargetClassMetadata() = default;   //初始化
      ClassFlags Flags;                 //Swift-specific class flags. swift特有的标记
      uint32_t InstanceAddressPoint;    //The address point of instances of this type. 实例对象的地址（首地址）
      uint32_t InstanceSize;            //The required size of instances of this type.实例对象内存大小
      uint16_t InstanceAlignMask;       //The alignment mask of the address point of instances of this type 实例对象内存对齐字节大小
      uint16_t Reserved;                //Reserved for runtime use.  运行时保留字段
      uint32_t ClassSize;               //类的内存大小
      uint32_t ClassAddressPoint;       //The offset of the address point within the class object.类的内存首地址
    }
    
    struct TargetAnyClassMetadata : public TargetHeapMetadata<Runtime> {
        Superclass;
        CacheData[2];
        StoredSize Data;
    };
    
#### 当metadata的kind为Class时，继承关系如下
    TargetClassMetadata : TargetAnyClassMetadata : TargetHeapMatadata : TargetMetadata
    Flags                      Superclass                                    kind
    InstanceAddressPoint       CacheData[2]                            getClassObject():根据kind拿到对应的metadata类型TargetClassMetadata
    InstanceSize               Data
    InstanceAlignMask 
    Reserved
    ClassSize
    ClassAddressPoint

#### 总结：更详细的底层结构可以看HeapObject.h文件中的分析
1. swift类对象的底层是个HeapObject结构体，该结构体中包含了两个成员，一个是指向元数据的指针，占用8个字节，一个是引用计数，占用8个字节
2. 元数据类型是HeapMetadata，它的别名是TargetHeapMetadata类型，继承关系是： TargetHeapMetadata : TargetMetadata
3. TargetMetadata结构体中只有一个kind成员，用来表示该元数据是哪种类型
4. 若元数据类型kind是MetadataKind::Class:即纯swift类，则元类对象类型就是TargetClassMetadata，继承关系是: TargetClassMetadata : TargetAnyClassMetadata : TargetHeapMetadata
 

### 1.3 swift对象和OC对象区别
1. OC中的实例对象本质是结构体，通过底层的objc_object模版创建，类是继承自objc_class
2. Swift中的实例对象本质是结构体，类型是HeapObject，比OC多了一个refCounts
3. OC中的方法列表存储在objc_class结构体(class_rw_t)的methodList中
4. Swift中的方法存储在metadata元数据中sil_vtable
5. OC中的ARC是存储在全局的sidetable中
6. Swift中的引用计数是对象内部由一个refCounts属性存储


### 2. swift方法调用/派发
#### swift中方法派发主要分两大类动态派发和静态派发，但是实际上应该有四种：内联inline(最快)、静态派发、动态虚拟表派发、动态消息派发
* 静态派发 (直接派发): 直接调用函数地址，最快且最高效的一种方法派发类型，编译阶段编译器就已经知道了所有被静态派发的方法在内存中的地址，因而在运行阶段，这些方法可以被立即执行。
* 动态派发：表派发(VTable)和消息派发，方法地址是在运行时确定的
1. vtable派发 (函数表派发): 编译阶段编译器会为每一个类创建一个vtable,存放的是一个包含若干函数指针的数组，这些函数指针指向这个类中相对应函数的实现代码，运行阶段调用实现代码时，表派发需要比静态派发多执行两个指令(读取该类的vtable和该函数的指针).函数表派发也是一种高效的方式。不过和直接派发相比，编译器对某些含有副作用的函数却无法优化，也是导致函数表派发变慢的原因之一。
2. 消息派发: objc_method方式，和OC方法调用流程一样，是最动态但也是最慢的一种派发技术。在派发消息后，runtime需要爬遍该类的整个层级体系，才可以确定要执行哪个方法实现。不过这也为在运行阶段改变程序的行为提供了可能，也使得Swizzling技术得以实现。Objective-C非常依赖消息派发，同时，它通过Objective-C runtime为Swift也提供了消息派发这一功能。
* 内联inline: 内联派发可以理解成不需要进行函数地址跳转，直接运行函数中的代码块


#### 接下来我们将swift源码通过编译器swiftc获取对应的SIL文件（swift使用的编译器为swiftc，OC使用的为Clang）
    1. 创建swift文件：WGSwiftMethodDispatch.swift
    2. 终端cd到改文件的上级目录  
    3. 终端输入: swiftc -emit-sil WGMemAModelVC.swift >> WGMemAModelVC.sil   在同目录中生成.sil文件
             或 swiftc -emit-sil WGMemAModelVC.swift  在终端生成对应的SIL代码
             
#### 方式一：静态派发 
#### 源码WGSwiftMethodDispatch.swift和生成的SIL文件(截取部分)如下
    final public class WGMethodDispatchStatic {
        public init() {}
        
        func printMethodName() -> String {
            let name = getMethodName()
            return name
        }
        
        func getMethodName() -> String {
            let name = "swift static dispatch method"
            return name
        }
    }
    
    import Foundation
    //如果final修饰类，那么它里面所有的方法和属性都会被final修饰
    final public class WGMethodDispatchStatic {
        public init()
        final func printMethodName() -> String
        final func getMethodName() -> String
        @objc deinit
    }
    
    // WGMethodDispatchStatic.__allocating_init()
    sil [serialized] [exact_self_class] @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC : $@convention(method) (@thick WGMethodDispatchStatic.Type) -> @owned WGMethodDispatchStatic {
        ......
    } 

    // WGMethodDispatchStatic.init()
    sil @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfc : $@convention(method) (@owned WGMethodDispatchStatic) -> @owned WGMethodDispatchStatic {
        ......
    }

    
    // WGMethodDispatchStatic.printMethodName()
    sil hidden @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String {
    // %0 "self"                                      // users: %3, %1
    bb0(%0 : $WGMethodDispatchStatic):
      debug_value %0 : $WGMethodDispatchStatic, let, name "self", argno 1 // id: %1
      // function_ref WGMethodDispatchStatic.getMethodName()
      %2 = function_ref @$s21WGSwiftMethodDispatch08WGMethodC6StaticC03getB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String // user: %3
      %3 = apply %2(%0) : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String // users: %5, %4
      debug_value %3 : $String, let, name "name"      // id: %4
      return %3 : $String                             // id: %5
    } // end sil function '$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF'


    // WGMethodDispatchStatic.getMethodName()
    sil hidden @$s21WGSwiftMethodDispatch08WGMethodC6StaticC03getB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String {
        ......
    } 

    //sil_vtable中只有init和deinit两个方法，没有
    sil_vtable [serialized] WGMethodDispatchStatic {
        // WGMethodDispatchStatic.__allocating_init()
        #WGMethodDispatchStatic.init!allocator: (WGMethodDispatchStatic.Type) -> () -> 
        WGMethodDispatchStatic : @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC
        // WGMethodDispatchStatic.__deallocating_deinit
        #WGMethodDispatchStatic.deinit!deallocator: @$s21WGSwiftMethodDispatch08WGMethodC6StaticCfD    
    }
    
#### 上面的SIL代码重点观察如下代码

    // function_ref WGMethodDispatchStatic.getMethodName()
    %2 = function_ref @$s21WGSwiftMethodDispatch08WGMethodC6StaticC03getB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String

#### 分析: **function_ref**关键字表明**getMethodName方法**是通过方法指针来调用的，并且通过符号 **s21WGSwiftMethodDispatch08WGMethodC6StaticC03getB4NameSSyF**来定位方法地址，同时sil_vtable中也未包含该方法

#### 方式二：Vtable派发
    //MARK: VTable派发
    public class WGMethodDispatchStatic {
        public init() {}
        
        func printMethodName() -> String {
            let name = getMethodName()
            return name
        }
        
        func getMethodName() -> String {
            let name = "swift static dispatch method"
            return name
        }
    }


    public class WGMethodDispatchStatic {
      public init()
      func printMethodName() -> String
      func getMethodName() -> String
      @objc deinit
    }
    
    // WGMethodDispatchStatic.printMethodName()
    sil hidden @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String {
    // %0 "self"                                      // users: %3, %2, %1
    bb0(%0 : $WGMethodDispatchStatic):
      debug_value %0 : $WGMethodDispatchStatic, let, name "self", argno 1 // id: %1
      %2 = class_method %0 : $WGMethodDispatchStatic, #WGMethodDispatchStatic.getMethodName : (WGMethodDispatchStatic) -> () -> String, $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String // user: %3
      %3 = apply %2(%0) : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String // users: %5, %4
      debug_value %3 : $String, let, name "name"      // id: %4
      return %3 : $String                             // id: %5
    } // end sil function '$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF'

    sil_vtable [serialized] WGMethodDispatchStatic {
        //1. WGMethodDispatchStatic.__allocating_init()
        #WGMethodDispatchStatic.init!allocator: (WGMethodDispatchStatic.Type) -> () -> 
        WGMethodDispatchStatic : @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC 
        
        //2. WGMethodDispatchStatic.printMethodName()
        #WGMethodDispatchStatic.printMethodName: (WGMethodDispatchStatic) -> () -> 
        String : @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF    
        
        //3. WGMethodDispatchStatic.getMethodName()
        #WGMethodDispatchStatic.getMethodName: (WGMethodDispatchStatic) -> () -> 
        String : @$s21WGSwiftMethodDispatch08WGMethodC6StaticC03getB4NameSSyF    
        
        //4. WGMethodDispatchStatic.__deallocating_deinit
        #WGMethodDispatchStatic.deinit!deallocator: @$s21WGSwiftMethodDispatch08WGMethodC6StaticCfD   
    }

#### 上面的SIL代码重点观察如下代码

    %2 = class_method %0 : $WGMethodDispatchStatic, #WGMethodDispatchStatic.getMethodName : (WGMethodDispatchStatic)
    -> () -> String, $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String 

#### 分析: **class_method**关键字表明表明**getMethodName**使用类对象方法的方式，即函数表的方式，通过 sil_vtable 中的信息也能印证这一点，WGMethodDispatchStatic 类的 vtable 表包含了这个方法。


#### 方式三：消息派发
    //MARK: 消息派发
    public class WGMethodDispatchStatic {
        public init() {}
        
        func printMethodName() -> String {
            let name = getMethodName()
            return name
        }
        
        @objc dynamic func getMethodName() -> String {
            let name = "swift static dispatch method"
            return name
        }
    }

    public class WGMethodDispatchStatic {
      public init()
      func printMethodName() -> String
      @objc dynamic func getMethodName() -> String
      @objc deinit
    }
    
    
    // WGMethodDispatchStatic.printMethodName()
    sil hidden @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF : $@convention(method) (@guaranteed WGMethodDispatchStatic) -> @owned String {
    bb0(%0 : $WGMethodDispatchStatic):
    debug_value %0 : $WGMethodDispatchStatic, let, name "self", argno 1
      %2 = objc_method %0 : $WGMethodDispatchStatic, #WGMethodDispatchStatic.getMethodName!foreign : (WGMethodDispatchStatic) -> () -> String, $@convention(objc_method) (WGMethodDispatchStatic) -> @autoreleased NSString // user: %3
        ......
    } 

    sil_vtable [serialized] WGMethodDispatchStatic {
        /1. WGMethodDispatchStatic.__allocating_init()
        #WGMethodDispatchStatic.init!allocator: (WGMethodDispatchStatic.Type) -> () -> 
        WGMethodDispatchStatic : @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC
        
        //2. WGMethodDispatchStatic.printMethodName()
        #WGMethodDispatchStatic.printMethodName: (WGMethodDispatchStatic) -> () -> 
        String : @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF   
        
        //3. WGMethodDispatchStatic.__deallocating_deinit
        #WGMethodDispatchStatic.deinit!deallocator: @$s21WGSwiftMethodDispatch08WGMethodC6StaticCfD    
    }
#### 分析: **objc_method**关键字表明了方法已经转为了使用OC中的方法派发方式，即消息派发，并且方法签名中，返回类型已经变为了 NSString，vtable中也没有了**getMethodName**方法。




#### 2.1 swift中方法调用情况汇总
#### swift函数可以声明在两个地方，一个是类型声明的作用域，一个是扩展extension中
                      类型声明所在的作用域内        扩展声明Extension 
        class             Vtable派发                static派发
        value type        static派发                static派发
        protocol          Vtable派发                static派发
        NSObject          Vtable派发            消息派发(objc_method)
#### Swift 的一些修饰符可以指定派发方式
* struct是值类型，其中函数的调度属于直接调用地址，即静态调度；struct的extension的方法依然是直接调用(静态派发)
* 在Swift中，调用一个结构体的方法是直接拿到函数的地址直接调用，包括初始化方法
* Swift是一门静态语言，许多东西在编译器就已经确定了，所以才可以直接拿到函数的地址进行调用，这个调用的形式也可以称作静态派发
* class是引用类型，其中函数的调度是通过V-Table函数表来进行调度的，即动态调度
* extension中的函数调度方式是直接调度
* final修饰的函数调度方式是直接调度
* @objc修饰的函数调度方式是函数表调度，如果OC中需要使用，class还必须继承NSObject
* dynamic修饰的函数的调度方式是函数表调度，使函数具有动态性
* @objc + dynamic 组合修饰的函数调度，是执行的是 objc_msgSend流程，即 动态消息转发
* @inline 告诉编译器可以使用直接派
#### 2.2 建议
1. 能用值类型地方就有值类型，不仅仅是因为其拷贝速度快，方法调度也快
2. 多使用private final 等关键字，一方面提高代码阅读性，编译器内部也对消息调度进行优化
3. 代码分类多使用拓展，拓展中的方法是静态派发（除了定义成运行时方法）
4. 遵守的协议(这里说的是Swift协议)尽量写在拓展中，如果希望被子类重写的话。建议不要使用类的多态，而是使用协议进行抽象，将需要属性和多种实现的方法抽取到协议中，拓展实现一些共用方法。这样不仅移除对父类的依赖也可以实现‘多继承’
5. OC混编时候，使用了一些OC特性的框架（例如KVO），不仅仅只需要对属性或者方法进行@objc 声明，还需要对其进行dynamic修饰才能按照预期的来
6. Swift 编写函数大部分走的是静态方法，这也就是Swift快的原因所在
7. 协议继承和类继承确保对象多态性会使用虚函数表进行动态派发
8. 继承自NSObject对象通过 dynamic/ @objc dynamic 关键字让其走消息机制派发

#### 2.3 swift函数调用 https://www.jianshu.com/u/06658dd306de
#### swift中函数调用分为了3个步骤
1. 找到metadata
2. 确定函数地址（metadata + 偏移量）；函数地址存放在函数表sil_vtable；函数表用来存储类中的方法，存储方式类似于数组，方法连续存放在函数表中
3. 执行函数

#### 3.0 Swift底层原理-类与对象
#### 3.1 对象的创建流程
    swift_allocObject --> _swift_allocObject_ --> swift_slowAlloc --> malloc
#### 最终返回的对象类型是HeapObject,是TargetHeapMetadata的别名
        define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts
        struct HeapObject {
            HeapMetadata const * metadata;                
            SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;  //refCounts是引用计数，和内存管理相关           
        };
        
        using HeapMetadata = TargetHeapMetadata<InProcess>;
#### 继承关系,
    TargetHeapMetadata : TargetMetadata
                           kind成员变量
    当kind是Class时，会将this强转为TargetClassMetadata类型
    
    TargetClassMetadata : TargetAnyClassMetadata : TargetHeapMetadata
    继承自TargetHeapMetadata，证明类本身也是对象
    
#### Class在内存结构由下面三类中的属性所构成
    TargetClassMetadata属性 + TargetAnyClassMetaData属性 + TargetMetaData属性构成
    所以得出的metadata的数据结构体如下
    struct Metadata {
        var kind: Int
        var superClass: Any.Type
        var cacheData: (Int, Int)
        var data: Int
        var classFlags: Int32
        var instanceAddressPoint: UInt32
        var instanceSize: UInt32
        var instanceAlignmentMask: UInt16
        var reserved: UInt16
        var classSize: UInt32
        var classAddressPoint: UInt32
        var typeDescriptor: UnsafeMutableRawPointer //TargetClassDescriptor 类型的类
        var iVarDestroyer: UnsafeRawPointer
    }
* 虚函数表的内存地址，是 TargetClassDescriptor 中的最后一个成员变量，添加方法的形式是追加到数组的末尾。所以这个虚函数表是按顺序连续存储类的方法的指针
#### swift中class的extension为什么用的是静态派发，而不是写到虚函数表中？
* 一方面是类是可以继承的，如果给父类添加extension方法，继承该类的所有子类都可以调用这些方法
* 每个子类都有自己的函数表，所以这个时候方法存储就成为问题
* 所以为了解决这个问题，直接把 extension 独立于虚函数表之外，采用静态调用的方式。在程序进行编译的时候，函数的地址就已经知道了

#### 关键字影响函数的派发
* final： 添加了final关键字的函数无法被写， 使用静态派发， 不会在vtable中出现， 
且对objc运行时不可见。 如果在实际开发过程中，属性、方法、类不需要被重载的时候，可以添加final关键字
* dynamic： 函数均可添加dynamic关键字，为非objc类和值类型的函数赋予动态性，但派发方式还是函数表派发
* @objc： 该关键字可以将swift函数暴露给Objc运行时， 依旧是函数表派发
* @objc + dynamic： 消息发送的方式

#### 总结
* Swift中的方法调用分为静态派发和动态派发两种
* 值类型中的方法就是静态派发
* 引用类型中的方法就是动态派发，其中函数的调度是通过V-Table函数表来进行调度的
     类型        调度方式        extension
    值类型        静态派发        静态派发
     类           函数表派发      静态派发
  NSObject子类    函数表派发      静态派发
  
  
### 4. Swift底层原理-属性

#### 4.1 存储属性
1. 存储属性是一个作为特定类和结构体实例一部分的常量或变量
2. 存储属性要么是变量存储属性 (由 var 关键字引入)要么是常量存储属性(由 let 关键字引入)
3. 在类中有一个原则：当类实例被构造完成时，必须保证类中所有的属性都构造或者初始化完成
4. 会占用分配实例对象的内存空间
    class Test {
        let a: Int = 10
        var b: Int = 0
    }
    
    生成对应sil文件
    
    class Test {
        @_hasStorage @_hasInitialValue final let a: Int { get }
        @_hasStorage @_hasInitialValue var b: Int { get set }
        @objc deinit
        init()
    }
    
    存储属性存放的位置
    HeapObject
      metadata
      refCounts
         a
         b
         
* 存储属性在编译的时候，编译器默认会合成get/set方式，而我们访问/赋值 存储属性的时候，实际上就是调用get/set
* let声明的属性默认不会提供setter

#### 4.2 计算属性
1. 类、结构体和枚举也能够定义计算属性，计算属性并不存储值，他们提供 getter 和 setter 来修改和获取值
2. 对于存储属性来说可以是常量或变量，但计算属性必须定义为变量
3. 我们定义计算属性时候必须包含类型，因为编译器需要知道返回值是什么
4. 不占用内存空间，本质是get/set方法的属性
    class Test {
        var a: Int = 0
        var b: Int {
            set {
                self.a = newValue
            }
            get {
                return 10
            }
        }
    }
    
    生成对应sil文件
    
    class Test {
        @_hasStorage @_hasInitialValue var a: Int { get set }
        var b: Int { get set }
        @objc deinit
        init()
    }
* a和b虽然后面都有{ get set }，但是前面修饰符有区别，a有@_hasStorage，b没有。说明a是一个可存储的值，b没有存储，只有getter和setter方法
* b在setter中，成一个名为 newValue 的常量，并且会把外部传进来的值赋值给 newValue，然后调用setter方法，把newValue作为参数传递给setter方法
* 计算属性根本不会有存储在实例的成员变量，那也就意味着计算属性不占内存

#### 4.3 延迟属性
1. 使用 lazy 可以定义一个延迟存储属性，在第一次用到属性的时候才会进行初始化
2. lazy 属性必须是 var，不能是 let，因为 let 必须在实例的初始化方法完成之前就拥有值
3. 如果多条线程同时第一次访问 lazy 属性，无法保证属性只被初始化 1 次
4. 定义延迟初始化的属性。这种属性不会在对象实例化时立即初始化，而是在第一次访问该属性时才进行初始化。
这种技术可以提高对象初始化的效率，并且可以减少不必要的开销
5. lazy属性必须是变量（var修饰符），因为常量属性（let修饰符）必须在初始化之前就有值，所以常量属性不能定义为lazy
    class Test {
        lazy var a: Int = 20
    }
    
    生成对应sil文件
        
    class Test {
        lazy var a: Int { get set }
        @_hasStorage @_hasInitialValue final var $__lazy_storage_$_a: Int? { get set }
        @objc deinit
        init()
    }
    
* 存储属性在添加了lazy修饰后，除了拥有存储属性的特性之外，还拥有 final 修饰符，说明 lazy 修饰的属性不能被重写
* 并且，它是一个可选项。拥有可选项就意味着，其实在初始的时候是有值的，只是这个值是一个nil
* lazy修饰的属性，底层默认是optional,可选的，没有被访问时，默认是nil，内存中表现就是0x0
* 延迟属性必须有一个默认值 lazy var name: String?这种写法也不行编译器会报错；lazy var name: String?=nil这种写法可以
* 只有在第一次被访问时才会赋值，且是线程不安全的
* 使用lazy和不使用lazy会对实例对象的内存大小有影响，主要是因为lazy底层是可选类型optional,optional的本质是枚举，除了存储属性本身
的内存大小，还需要一个字节用于存储case

#### 4.4 属性观察器
1.属性观察者会用来观察属性值的变化， willSet 当属性将被改变调用，即使这个值与原有的值相同，而 didSet 在属性已经改变之后调用
2.在初始化器中设置属性值不会触发 willSet 和 didSet。在属性定义时设置初始值也不会触发 willSet 和 didSet

        class Test {
            var a: Int = 10 {
                willSet {
                    print("new value = \(newValue)")
                }
                didSet {
                    print("old value = \(oldValue)")
                }
            }
        }
* 在a的setter方法中，调用了willset 和 didset方法，这两个方法拥有两个参数，第一个参数对应的应该是 newValue 和 oldValue
* willSet: 新值存储之前调用newValue
* didSet: 新值存储之后调用oldValue
* 在 init 方法中，如果调用属性，是不会触发属性观察者的； 在定义时设置默认值(即在didSet中调用其他属性值)，也不会触发属性观察者

##### 哪里可以添加属性观察器？
1. 类中定义的存储属性
2. 通过类继承的存储属性
3. 通过类继承的计算属性

##### 子类和父类的计算属性同时存在willSet、didSet，调用顺序是什么?
1.先调用子类的willSet方法
2.调用父类的willSet方法
3.调用父类的didSet方法
4.调用子类的didSet方法

##### 子类调用了父类的init方法会触发属性观察器吗？
##### 会触发属性观察器，因为子类调用父类的init方法已经初始化过了,再次赋值就会触发属性观察器

#### 4.5 类型属性
1. 严格来说，属性可以分为实例属性和类型属性；使用关键字 static 来定义类型属性
2. 类型属性在整个程序运行过程中，就只有1份内存（类似于全局变量），且是线程安全的
3. 不同于存储实例属性，你必须给存储类型属性设定初始值，因为类型没有像实例那样的 init 初始化器来初始化存储属性
4. 存储类型属性默认就是 lazy ，会在第一次使用的时候才初始化，就算被多个线程同时访问，保证只会初始化一次
5. 存储类型属性可以是 let
6. 为类定义计算型类型属性时，可以改用关键字 class 来支持子类对父类的实现进行重写

        class Test {
            static var a: Int = 10
        }

        生成对应sil文件
        
        class Test {
          @_hasStorage @_hasInitialValue static var a: Int { get set }
          @objc deinit
          init()
        }

        // one-time initialization token for a
        sil_global private @$s4main4TestC1a_Wz : $Builtin.Word

        // static Test.a
        sil_global hidden @$s4main4TestC1aSivpZ : $Int
* a变量变成了全局变量
* 在a变量的初始化方法中，发现了swift_once函数的调用，在swift_once源码中发现调用了dispatch_once_f也就是GCD的实现
* 所以在swift中单例的实现可以通过static
* 类型属性必须有一个默认的初始值，且只会被初始化一次
* 类型属性也是一个全局变量

#### 总结
存储属性： 结构体/类，存储属性可以是变量也可以是常量;
计算属性：结构体/类/枚举，计算属性只能是变量；计算属性必须声明类型；
延迟属性: lazy属性必须是变量
类型属性： 结构体/类/枚举  


### 5. Swift底层原理-属性

#### Swift语言延续了和Objective-C语言一样的思路进行内存管理，都是采用引用计数的方式来管理实例的内存空间
#### Swift对象本质是一个HeapObject结构体指针。HeapObject结构中有两个成员变量，metadata 和 refCounts

     define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts
     struct HeapObject {
         HeapMetadata const *metadata;      是指向元数据对象的指针，里面存储着类的信息，比如属性信息，虚函数表等
         SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS; 它是一个引用计数信息相关的东西
     }
     
     //InlineRefCounts是一个模版类：RefCounts接收一个InlineRefCountBits类型的范型
     typedef RefCounts<InlineRefCountBits> InlineRefCounts; 
     
     class RefCounts {
         std::atomic<RefCountBits> refCounts;
         void incrementSlow(RefCountBits oldbits, uint32_t inc) SWIFT_CC(PreserveMost);
         void incrementNonAtomicSlow(RefCountBits oldbits, uint32_t inc);
         bool tryIncrementSlow(RefCountBits oldbits);
         bool tryIncrementNonAtomicSlow(RefCountBits oldbits);
         void incrementUnownedSlow(uint32_t inc);
         public:
            enum Initialized_t { Initialized };
            enum Immortal_t { Immortal };
     }
     
     实质上是在操作我们传递的泛型参数InlineRefCountBits
     它也是一个模板函数，并且也有一个参数 RefCountIsInline
     typedef RefCountBitsT<RefCountIsInline> InlineRefCountBits;
     
     class RefCountBitsT {
        BitsType bits;  //该属性是由RefCountBitsInt的Type属性定义的
     }
     
     struct RefCountBitsInt<refcountIsInline, 8> {
         //存储的是64位原有的strong RC + unowned RC + flags
         typedef uint64_t Type;      //一个 uint64_t 的位域信息，在这个 uint64_t 的位域信息中存储着运行生命周期的相关引用计数
         typedef int64_t SignedType;
     };
     
     最终bits存储信息如下
        第0位：标识是否是永久的
        第1-31位：存储无主引用
        第32位：标识当前类是否正在析构
        第33-62位：标识强引用
        第63位：是否使用SlowRC
* swift中默认都是强引用，强引用就是通过bits这种位域来实现引用计数的增加、减少的
* 进行强引用的时候，本质上是调用 refCounts 的 increment 方法，也就是引用计数 +1
* 引用计数的变化，并不是直接+1，而是refercount存储的信息发生变化(第33-62位)
    
#### swift内存管理主要通过ARC(Automatic Reference Counting)自动引用计数机制来实现；ARC 用于管理对象类型（类的实例）的内存分配和释放；
#### 对于值类型（如枚举、结构体、基础数据类型），他们通常存储在栈上，由编译器负责管理内存，当值类型的变量超出其作用域时，内存会自动释放
#### 值类型在赋值或传递参数时会进行复制。Swift 采用了 Copy-On-Write（COW，写时复制）优化策略，只有当值类型需要被修改时，Swift 才会进行实际的复制操作

#### swift中没有像Objective-C中那么多涉及内存管理的关键字，所以谈swift内存管理，主要就是谈强引用、弱引用、无主引用
* 一个新的实例被创建时，传入的是RefCountBits(strongExtraCount: 0，unownedCount: 1)
 
#### 5.1 强引用
#### 默认情况下，引用都是强引用；通过前面对refCounts的结构分析，得知它是存储引用计数信息的东西，在创建一个对象之后它的初始值为 0x0000000000000003
#### 如果我对这个实例对象进行多个引用，引用计数会增加。底层会通过调用_swift_retain_方法；在进行强引用的时候，本质上是调用 refCounts 的 increment 方法，也就是引用计数 +1

#### 5.2 弱引用weak
#### 在实际开发的过程中，我们大多使用的都是强引用，在某些场景下使用强引用，用不好的话会造成循环引用
#### 在Swift中我们通过关键字**weak**来表明一个弱引用；
* weak关键字的作用是在使用这个实例的时候并不保有此实例的引用
* 使用weak关键字修饰的引用类型数据在传递时不会使引用计数加1，不会对其引用的实例保持强引用，因此不会阻止ARC释放被引用的实例
* ARC会在被引用的实例释放时，自动地将弱引用设置为nil。由于弱引用需要允许设置为nil，因此它一定是**可选类型**
* 用 weak 修饰之后，变量变成了一个可选项，内部会生成WeakReference类型的变量
* 当对象销毁时，弱引用修饰的对象会自动置为nil
* swift中弱引用必须是可选类型，因为引用的实例被释放后，ARC会自动将其置为nil

        WeakReference *swift::swift_weakInit(WeakReference *ref, HeapObject *value) {
            ref->nativeInit(value);
            return ref;
        }
        
        void nativeInit(HeapObject *object) {
            auto side = object ? object->refCounts.formWeakReference() : nullptr;
            nativeValue.store(WeakReferenceBits(side), std::memory_order_relaxed);
        }
        // 本质就是创建了一个散列表，散列表的创建可以分为4步
        HeapObjectSideTableEntry* RefCounts<InlineRefCountBits>::formWeakReference(){
            auto side = allocateSideTable(true);
            if (side)
                return side->incrementWeak();
            else
                return nullptr;
        }
        1.取出原来的 refCounts引用计数的信息
        2.判断原来的 refCounts 是否有散列表，如果有直接返回，如果没有并且正在析构直接返回nil
        3.创建一个散列表
        4.对原来的散列表以及正在析构的一些处理

        //没有弱引用情况
        HeapObject {
            isa
            InlineRefCounts {
                atomic<InlineRefCountBits> {
                    strong RC + unowned RC + flags
                    OR
                    HeapObjectSideTableEntry*
                }
            }
        }
          
         //有弱引用情况
        HeapObjectSideTableEntry {
            SideTableRefCounts {
                object pointer
                atomic<SideTableRefCountBits> {
                    strong RC + unowned RC + weak RC + flags
                }
            }   
        }
        
        typedef RefCounts<SideTableRefCountBits> SideTableRefCounts;
        class HeapObjectSideTableEntry {
            std::atomic<HeapObject*> object;  //存着对象的指针
            SideTableRefCounts refCounts;     //SideTableRefCountBits继承自前面我们学习的RefCountBitsT
    
            public:
            HeapObjectSideTableEntry(HeapObject *newObject)
                : object(newObject), refCounts()
            { }
        }
        
        class alignas(sizeof(void*) * 2) SideTableRefCountBits : public RefCountBitsT<RefCountNotInline> {
          uint32_t weakBits;       //存储者weak RC
          public:
          LLVM_ATTRIBUTE_ALWAYS_INLINE
          SideTableRefCountBits() = default;
        }
        
        //前面学习强引用时用到的RefCountBitsT类
        class RefCountBitsT {
            BitsType bits;  //该属性是由RefCountBitsInt的Type属性定义的
        }
        
        总结:HeapObjectSideTableEntry存储的内容是
        64位原有的strong RC + unowned RC + flags 再加上 32位的weak RC
        当我们用 weak 修饰之后，这个散列表就会存储对象的指针和引用计数信息相关的东西
        
        
#### 从上面可以分析出：在Swift中本质上存在两种引用计数
1.如果是强引用，那么是strong RC + unowned RC + flags
2.如果是弱引用，那么是 HeapObjectSideTableEntry
3.一个实例对象在首次初始化的时候，是没有sideTable的，当我们创建一个弱引用的时候，才会创建sideTable

#### 5.3 无主引用unowned
* 在Swift中通过 unowned 定义无主引用，unowned 不会产生强引用，实例销毁后仍然存储着实例的内存地址（类似于OC中的 unsafe_unretained）
* 实例销毁后访问无主引用，会产生运行时错误（野指针）。
* 在使用unowned的时候，要确保其修饰的属性一定有值

#### weak弱引用 和 无主引用unowned的区别？
1. unowned 要比 weak 少一些性能消耗，性能更高，因为weak需要操作散列表，而unowned只需要操作64位位域信息
2. weak相对于unowned更兼容，更安全
3. weak弱引用修饰的对象销毁时**会**将对象自动置为nil；而unowned无主引用修饰的对象销毁时**不会**将对象自动置为nil
4. 不同于弱引用的是，无主引用是假定永远有值的


#### weak弱引用 和 无主引用unowned如何选择？
* 如果强引用的双方生命周期没有任何关系，使用weak
* 如果其中一个对象销毁，另一个对象也跟着销毁，则使用unowned
* 使用无主引用时，需要确保对象的生命周期至少与引用它的对象一样长

### 6.Swift底层原理-枚举
#### 在Swift中可以通过enum 关键字来声明一个枚举；枚举是一种包含自定义类型的数据类型，它是一组有共同特性的数据的集合
#### 枚举中不能有存储属性，只能有计算属性、实例方法、类型方法
#### 枚举分为以下三种： 无原始值 有原始值 有关联值

#### 6.1 无原始值: 没有指定枚举类型

        enum WGTestA {
            case A
            case B
            case C
        }
        var a = WGTestA.A
        NSLog("实际占用内存:------\(MemoryLayout<WGTestA>.size)个字节")
        NSLog("内存对齐占用内存------\(MemoryLayout<WGTestA>.stride)个字节")
         
        实际占用内存:------1个字节
        内存对齐占用内存------1个字节  
        
* 无原始值的枚举，内部没有计算属性rawValue
* 无原始值的枚举占用的内容大小是1个字节

#### 6.2 有原始值： 指定了枚举类型(枚举类型可以是字符串、字符、任意整型值、任意浮点型值)

        //如果枚举的原始值类型是 Int、String、Double，Swift会自动分配原始值，隐式 RawValue 分配是建立在 Swift 的类型推断机制上的
        enum WGTestA: Int {
            case A        //原始值默认是0
            case B        //原始值默认是1
            case C        //原始值默认是2
        }
        enum WGTestA: String {
            case A        //原始值默认是字符串A
            case B        //原始值默认是字符串B
            case C        //原始值默认是字符串C
        }
        enum WGTestA : Double {
            case A        //原始值默认是0.0
            case B        //原始值默认是1.0
            case C        //原始值默认是2.0
        }
        enum WGTestA: String {
            case A = "zhangdan"  //原始值是"zhangdan"
            case B = "lisi"      //原始值是"lisi"
            case C = "wo"        //原始值是"wo"
        }
        
        var a = WGTestA.A
        NSLog("实际占用内存:------\(MemoryLayout<WGTestA>.size)个字节")
        NSLog("内存对齐占用内存------\(MemoryLayout<WGTestA>.stride)个字节")
        
        实际占用内存:------1个字节
        内存对齐占用内存------1个字节 

* 拥有原始值的枚举，内部有计算属性rawValue，通过rawValue可以获取到枚举的原始值
* 枚举的原始值特性可以将枚举值与另一个数据类型进行绑定
* 拥有原始值的枚举占用的内容大小是1个字节
* 原始值并不会存储在枚举的内存空间中，而是给枚举添加原始值时，编译器帮我们实现了**RawRepresentable协议**,
实现了init?(rawValue:）方法和属性rawValue
* rawValue计算属性内部通过对self参数进行swift判断，一次返回不同的原始值
* 给枚举添加原始值，不会影响枚举自身的任何结构


#### 6.3 关联值： Swift中枚举值可以跟其他类型关联起来存储在一起，从而来表达更复杂的案例

        //无原始值，但是有关联值，有无原始值看的是定义枚举的时候有没有指定类型
        enum Season {
            case spring(month: Int)
            case summer(startMonth: Int, endMonth: Int)
        }
        
        //❌编译器会报错，这里Fcode总结的应该就是枚举设置了类型(原始值),就不能设置关联值了；设置了关联值就不能设置类型(原始值)了
        enum Season: Int {
            case spring(month: Int)
            case summer(startMonth: Int)
        }

        
* 枚举的关联值和原始值本质区别是：关联值占用枚举的内存，原始值不占用枚举的内存
* 添加关联值会影响枚举自身的内存结构，关联值被存储在枚举变量中，枚举变量的大小取决于占用内存最大的那个类型
* 对于没有添加关联值的枚举，系统会默认帮我们实现**Hashable/Equatable**

#### 6.4 枚举内存分析
1. 原始值不存储在枚举内存中，不占用枚举内存空间，枚举的原始值是通过编辑器自动遵守**RawRepresentable协议**并实现了其中的rawValue计算属性和init(rawValue:)方法，通过计算属性rawValue来获取原始值的
2.枚举的内存分析主要从两个方便讨论: 无关联值 有关联值
* 无关联值： 默认是以一个字节的方式去存储，1个字节可以存储256个case。如果超出这个现实，枚举会升级成2个字节去存储

        enum Season {
            case spring
            case summer
            case autumn
            case winter
        }

        print(MemoryLayout<Season>.size)   // 1
        print(MemoryLayout<Season>.stride) // 1
        
* 有关联值

        (1)有一个关联值,关联值类型为Bool
        enum Season {
            case spring(Bool)
            case summer
            case autumn
            case winter
        }
        print(MemoryLayout<Season>.size)   // 1
        print(MemoryLayout<Season>.stride) // 1
        
        当枚举的关联值为Bool类型时,枚举只占 1 个字节。对于Bool类型来说，它本身是 1 个字节的大小，但实际上它只需要 1 位来存储Bool值
        枚举的1个字节(8位)当中，有 1 位是用来存储Bool值的，余下的 7 位才是用来存储case的，那此时这个枚举最多只能有 128 个case

        (2)有一个关联值,关联值类型为Int
        enum Season {
            case spring(Int)
            case summer
            case autumn
            case winter
        }

        print(MemoryLayout<Season>.size) // 9
        print(MemoryLayout<Season>.stride) // 16
        当枚举的关联值为Int类型时，枚举占用 9 个字节。
        对于Int类型来说，其实系统是没有办法推算当前负载所要使用的位数，这个时候我们就需要额外开辟内存空间来存储我们的case值


        (3)有多个关联值
        enum Season1 {
            case spring(Bool)
            case summer(Bool)
            case autumn(Bool)
            case winter(Bool)
        }

        enum Season2 {
            case spring(Int)
            case summer(Int)
            case autumn(Int)
            case winter(Int)
        }

        enum Season3 {
            case spring(Bool)
            case summer(Int)
            case autumn
            case winter
        }

        enum Season4 {
            case spring(Int, Int, Int)
            case summer
            case autumn
            case winter
        }

        print(MemoryLayout<Season1>.size) // 1
        print(MemoryLayout<Season2>.size) // 9
        print(MemoryLayout<Season3>.size) // 9
        print(MemoryLayout<Season4>.size) // 25

        如果枚举中多个成员有关联值，且最大的关联值类型大于 1 个字节（8 位）的时候，此时枚举的大小为：最大关联值的大小 + 1
        
        特殊情况
        enum Season {
            case season
        }
        print(MemoryLayout<Season>.size)  // 0
        对于当前的Season只有一个case，此时不需要用任何东⻄来去区分当前的case，所以当我们打印当前的Season大小是 0
        

### 7.Swift底层原理-闭包

#### swift中函数和闭包都属于引用类型，
#### 函数类型由形式参数类型和返回类型组成，函数类型的本质就是引用类型；
#### 函数类型的本质在Swift中是通过TargetFunctionTypeMetadata来表示的，它继承自TargetMetadata
#### TargetFunctionTypeMetadata拥有自己的Flags和ResultType，以及参数列表的存储空间
#### 函数是引用类型，意味着函数本身在内存中是通过引用访问的，而不是通过值复制。这使得函数可以作为参数传递或作为返回值

        //由于TargetFunctionTypeMetadata继承自TargetMetadata，那么它必然有Kind
        struct TargetFunctionTypeMetadata : public TargetMetadata<Runtime> {
        
            TargetFunctionTypeFlags<StoredSize> Flags;
            //返回值类型的元数据
            ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> ResultType; 
             
            Parameter *getParameters() { return reinterpret_cast<Parameter *>(this + 1); }

            //将 (this + 1) 强制转换成Parameter *类型，然后返回的是指针类型
            //这个函数返回的是一块连续的内存空间，这一块连续的内存空间存储的是Parameter类型的数据
            const Parameter *getParameters() const {
                return reinterpret_cast<const Parameter *>(this + 1);
            }

            Parameter getParameter(unsigned index) const {
                assert(index < getNumParameters());
                return getParameters()[index];
            }
        }

#### 7.1 闭包
#### 闭包是一个可以捕获上下文的常量或者变量的函数，闭包的表现形式有三种
1. 全局函数是一个有名字但不会捕获任何值的闭包。
2. 嵌套函数是一个有名字并可以捕获到其封闭函数域内的值的闭包
3. 闭包表达式是一个利用轻量级语法所写的，可以捕获其上下文中变量或常量值的匿名闭包。

        //1. 全局函数是一个有名字但不会捕获任何值的闭包
        public let WG_font = {(size: CGFloat) -> UIFont in
            var baseSize: CGFloat = 16
            if size < 12 {
                baseSize = 12
            }else if size < 18 {
                baseSize = 16
            }else {
                baseSize = 20
            }
            return UIFont.systemFont(ofSize: baseSize)
        }
        
        //2.嵌套函数
        func makeIncrementer() -> () -> Int {
            var runningTotal = 10
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
                
            }
            return incrementer
        }
        let fn = makeIncrementer()
        print(fn())      //11
        print(fn())      //12
        print(fn())      //13
        
        //3.定义闭包表达式: 作用域（花括号）、函数参数类型/返回值类型、关键字in、函数体构成
        { (param type) -> (returnType) in
            //to do
        }

#### 7.1.1闭包～捕获值
#### 闭包可以在其被定义的上下文中捕获常量或变量。即使定义这些常量和变量的原作用域已经不存在，闭包仍然可以在闭包函数体内引用和修改这些值
#### 闭包捕获值的本质就是：在堆上开辟一块空间、把我们的变量放到其中
#### 当我们每次修改的捕获值的时候，修改的是堆区中的 value 值
#### 当每次重新执⾏当前函数时候，都会重新创建内存空间
#### 当闭包捕获一个常量或变量时，会捕获该常量或变量的拷贝，外部变量或常量的值发生改变也不会影响闭包内部的使用。
闭包内部会在堆上申请一个地址，并将该地址给了常量或变量，常量或变量存储在堆上。
直接从堆上获取变量或常量交给闭包使用，所以闭包会开辟堆空间的内存
        func makeIncrementer() -> () -> Int {
            var runningTotal = 10
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
                
            }
            return incrementer
        }
        let fn = makeIncrementer()
        print(fn())      //11
        print(fn())      //12
        print(fn())      //13
        
#### 7.1.2闭包～捕获全局变量

        var runningTotal = 10
        func makeIncrementer() -> () -> Int {
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
            }
            return incrementer
        }

        let fn = makeIncrementer()
        print(fn())     //11
        print(fn())     //12
        print(fn())     //13

#### 闭包针对全局变量，不会捕获的，而是直接拿来用的，内部并没有进行任何堆内存开辟操作


#### 7.1.3闭包～捕获引用类型
#### 闭包在捕获引用类型时候，其实也不需要捕获实例对象，因为它已经在堆区了，就不需要再去创建一个堆空间的实例包裹它了
#### 只需要将它的地址存储到闭包的结构中，操作实例对象的引用计数+1即可
####  当闭包捕获一个引用类型的变量时，会捕获该变量的引用。即闭包内部使用的是外部变量的引用，而不是拷贝。这意味着闭包内部对外部变量的修改会影响外部作用域中的变量

#### 7.1.4闭包～捕获多个值
        func makeIncrementer() -> () -> Int {
            var runningTotal = 10      //11  12
            var runningTotal1 = 11      //22  34
            func incrementer() -> Int {
                runningTotal += 1      
                runningTotal1 += runningTotal
                return runningTotal1
            }
            return incrementer
        }

        let fn = makeIncrementer()
        print(fn())  //22
        print(fn())  //34
        print(fn())  //47
        
        struct ClosureData<MutiValue> {
            /// 函数地址
            var ptr: UnsafeRawPointer
            /// 存储捕获堆空间地址的值
            var object: UnsafePointer<MutiValue>
        }

        struct MutiValue<T1,T2> {
            var object: HeapObject
            var value: UnsafePointer<Box<T1>>
            var value1: UnsafePointer<Box<T2>>
        }

        struct Box<T> {
            var object: HeapObject
            var value: T
        }

        struct HeapObject {
            var matedata: UnsafeRawPointer
            var refcount: Int
        }
#### 捕获单个值和多个值的区别就在于
1. 单个值中，ClosureData内存储的堆空间地址直接就是这个值所在的堆空间
2. 对于捕获多个值，ClosureData内存储的堆空间地址会变成一个可以存储很多个捕获值的结构
简单来说，从原来直接指向单个实例对象，变成指向一片连续内存空间，内存空间中存储着指向变量的地址

#### 7.2 闭包分类
#### 7.2.1 尾随闭包
#### 如果你需要将一个很长的闭包表达式作为最后一个参数传递给函数，可以使用尾随闭包来增强函数的可读性。
尾随闭包是一个书写在函数括号之后的闭包表达式，函数支持将其作为最后一个参数调用。
在使用尾随闭包时，你不用写出它的参数标签
        func test(closure: () -> Void) {

        }
        // 以下是使用尾随闭包进行函数调用
        test {
            
        }

        // 以下是不使用尾随闭包进行函数调用
        test(closure: {
            
        })
        
#### 7.2.2 逃逸闭包
#### 当一个闭包作为参数传到一个函数中，但是这个闭包在函数返回之后才被执行，我们称该闭包从函数中逃逸。
当你定义接受闭包作为参数的函数时，你可以在参数名之前标注@escaping，用来指明这个闭包是允许“逃逸”出这个函数的

#### 逃逸闭包存在的可能情况？
* 当闭包被当作属性存储，导致函数完成时闭包生命周期被延长。
* 当闭包异步执行，导致函数完成时闭包生命周期被延长。
* 可选类型的闭包默认是逃逸闭包

#### 逃逸闭包所需的条件？
* 作为函数的参数传递。
* 当前闭包在函数内部异步执行或者被存储。
* 函数结束，闭包被调用，闭包的生命周期未结束

#### 逃逸闭包 vs 非逃逸闭包 区别？
* 非逃逸闭包：一个接受闭包作为参数的函数，闭包是在这个函数结束前内被调用，即可以理解为闭包是在函数作用域结束前被调用
        1.不会产生循环引用，因为闭包的作用域在函数作用域内，在函数执行完成后，就会释放闭包捕获的所有对象
        2.针对非逃逸闭包，编译器会做优化：省略内存管理调用
        3.非逃逸闭包捕获的上下文保存在栈上，而不是堆上
* 逃逸闭包：一个接受闭包作为参数的函数，逃逸闭包可能会在函数返回之后才被调用，即闭包逃离了函数的作用域
        1.可能会产生循环引用，因为逃逸闭包中需要显式的引用self(猜测其原因是为了提醒开发者，这里可能会出现循环引用)
        而self可能是持有闭包变量的（与OC中block的的循环引用类似）
        2.一般用于异步函数的返回，例如网络请求
        
#### 使用建议：如果没有特别需要，开发中使用非逃逸闭包是有利于内存优化的，所以苹果把闭包区分为两种，特殊情况时再使用逃逸闭包


#### 7.2.3 自动闭包
#### 自动闭包是一种自动创建的闭包，用于包装传递给函数作为参数的表达式。这种闭包不接受任何参数，当它被调用的时候，
会返回被包装在其中的表达式的值。这种便利语法让你能够省略闭包的花括号，用一个普通的表达式来代替显式的闭包


#### 总结
1.一个闭包能够从上下文中捕获已经定义的常量/变量，即使其作用域不存在了，闭包仍然能够在其函数体内引用、修改
    (1)每次修改捕获值：本质修改的是堆区中的value值
    (2)每次重新执行当前函数，会重新创建新的内存空间
2.捕获值原理：本质是在堆区开辟内存空间，并将捕获值存储到这个堆空间
3.闭包是一个引用类型（本质是函数地址传递），底层结构为：闭包 = 函数地址 + 捕获变量的地址
4.函数也是引用类型（本质是结构体，其中保存了函数的地址）


### 8.Swift底层原理-协议
#### 使用protocol关键字来申明协议;协议可以用来定义方法、属性、下标的声明;协议可以被枚举、结构体、类遵守（多个协议之间用逗号隔开）

#### 8.1.1 协议中的属性    

        protocol WGTest {
            //var sex: Bool { get <#set#> }
            var name: String { get set}       //要求可读可写，该属性不能是常量属性，也不能是只读的计算型属性
            var age: Int { get }              //要求可读，该属性不仅可以是只读的，若需要还可以是可写的
            static var sex: Bool { get set }  //声明静态变量
        }
* 协议中定义属性时必须用var关键字
* 在定义属性时，我们必须指定属性至少是可读,即我们需要给属性添加 { get } 属性，也可以是可读可写的{get set}
* 同时要注意 这个 get 并不一定指定属性就是计算属性
* 协议不指定属性是存储属性还是计算属性，它只指定属性的名称和类型
* 若协议要求一个属性为可读和可写的，那么该属性要求不能用常量存储属性(let)或只读计算属性来满足
* 若协议只要求属性为可读的，那么任何种类的属性都能满足这个要求，而且如果你的代码需要的话，该属性也可以是可写的
* 如果协议要求未被完全满足，在编译时会报错（这句话意思就是协议中属性如何是仅可读，那么实现它的类至少是可读的，且也可以是可写的，只要满足了协议要求就行了）


        protocol WGTest {
            var name: String { get set}
            var age: Int { get }
        }

        class WGAAAA : WGTest {
            //变量存储属性，可读写
            var name: String = ""
            //变量存储属性，可读写
            var age: Int = 0
        }

#### 8.1.2 协议中的方法
#### 协议中可以定义实例方法，也可以定义类型方法

        protocol WGTest {
            //1.定义实例方法
            func test1()
            
            //2.通过static定义类型方法, 在遵守协议的类中，可以使用static或class来实现类型方法      
            static func test2()
            
            //3.异变方法: 将实例方法用mutating修饰就变成了异变方法，允许结构体、枚举的具体实现修改自身属性
            //若是类遵守协议并实现该方法时，不需要写mutating关键字。 mutating关键字只在结构体和枚举类型中需要书写
            mutating func test3()
            
            //4.初始化方法
            //遵循这个协议时，我们需要在实现这个初始化方法时 在init前加上required关键字，否则编译器会报错的
            //类的初始化 器前添加 required 修饰符来表明所有该类的子类都必须实现该初始化器；结构体和枚举可以不实现这个init方法也不会报错
            //由于final的类不会有子类，如果协议初始化器实现的类使用了final标记，你就不需要使用required来修饰了
            init()
            
        }
        
        class WGAAAA : WGTest {
            required init() {
            }
        }
        
        //final可以不实现init方法，或者实现了init方法的话可以不用写required
        final class WGBBBB : WGTest {
    
        }

#### 8.1.3 协议可选
#### 默认情况写，协议中的方法和属性是必须要实现的，但是也可以通过以下方式实现协议可选
        protocol WGTest {
            func test1()
            func test2()
        }

        //可选协议方式一
        @objc protocol WGTest {
            @objc optional func test1()
            func test2()
        }

        //可选协议方式二: 通过扩展协议，在扩展中实现需要可选的方法
        extension WGTest {
            func test1() {
                
            }
        }
        
        //在协议后面写上:AnyObject 或者:class代表只有类能遵守这个协议
        protocol BaseProtocol: AnyObject {}
        protocol BaseProtocol: class {}

#### 8.1.4 协议的底层原理

        protocol BaseProtocol {
            func test(_ number: Int)
        }

        class TestClass: BaseProtocol {
            var x: Int?
            func test(_ number: Int) {
                x = number
            }
        }
        //1.变量test是确定的类型(静态类型为类类型)
        var test: TestClass = TestClass()
        test.test(10)
#### 如果实例对象的静态类型就是确定的类型(例如下面的test变量就是确定的TestClass类型)，那么这个协议方法通过VTalbel进行调度。        
        
        //2.现在把变量test修改成协议类型(静态类型为协议类型)
        var test: BaseProtocol = TestClass()
        test.test(10)
        
#### 如果实例对象的静态类型是协议类型，那么这个协议方法通过witness_table中对应的协议方法，然后通过协议方法去查找遵守协议的类的VTable进行调度
#### 结构体/枚举中实现协议中的方法，调用过程都是拿到函数的地址进行直接调用的，
若调用方法的结构体变量是确定的类型，拿到函数地址直接调用；
若调用方法的结构体变量是协议类型，那么就是通过witness_table中对应的协议方法，然后通过协议方法去查找遵守协议的结构体或枚举中的函数地址直接调用
        
#### 8.2 协议的扩展
#### 协议可以通过extention的方式去实现定义的方法，实现之后，遵循协议的类可以不再实现该方法
#### 8.2.1 协议中未声明方法，分类中声明并实现
        protocol BaseProtocol {
    
        }

        extension BaseProtocol {
            func test() {
                print("BaseProtocol")
            }
        }

        class TestClass: BaseProtocol {
            func test() {
                print("TestClass")
            }
        }

        var test: BaseProtocol = TestClass()
        test.test()        //打印结果: BaseProtocol 静态类型为协议类型，通过函数地址直接调用。

        var test1: TestClass = TestClass()
        test1.test()       //打印结果: TestClass  静态类型为类类型，则是通过VTable调用。

#### 8.2.2 协议中声明方法，分类中实现

        protocol BaseProtocol {
            func test()
        }

        extension BaseProtocol {
            func test() {
                print("BaseProtocol")
            }
        }

        class TestClass: BaseProtocol {
            func test() {
                print("TestClass")
            }
        }

        var test: BaseProtocol = TestClass()
        test.test()          //打印结果: TestClass  在协议中声明了函数，并且在分类中实现了该函数，会优先调用类中的方法。

        var test1: TestClass = TestClass()
        test1.test()         //打印结果: TestClass  在协议中声明了函数，并且在分类中实现了该函数，会优先调用类中的方法。

#### 8.3 协议的结构
#### 通过上面的例子，我们发现静态类型不同，会影响函数调用，是不是会影响实例对象的结构呢

        protocol BaseProtocol {
            func test()
        }

        extension BaseProtocol {
            func test() {
            }
        }

        class TestClass: BaseProtocol {
            var x: Int = 10
            func test() {
                
            }
        }


        var test: BaseProtocol = TestClass()

        var test1: TestClass = TestClass()

        print("test size: \(MemoryLayout.size(ofValue: test))")      //40
        print("test1 size: \(MemoryLayout.size(ofValue: test1))")    //8
#### 静态类型不同，居然会影响内存中的大小。test1的8字节很好理解，是实例对象的地址
        
        var test: BaseProtocol = TestClass() 占用40个字节
        第一个8字节存储着实例对象的地址
        第二个和第三个8字节存储的是啥目前不知道。
        第四个8字节存储的是实例对象的metadate
        最后的8字节存储的其实是witness_table的地址。
* 每个遵守了协议的类，都会有自己的PWT(protocol winess_table)，遵守的协议越多，PWT中存储的函数地址就越多
* PWT的本质是一个指针数组，第一个元素存储TargetProtocolConformanceDescriptor，其后面存储的是连续的函数地址
* PWT的数量与协议数量一致


### 9 Swift底层原理-反射Mirror
#### 反射：是指可以动态获取类型、成员信息，在运行时可以调用方法、属性等行为的特性
#### 对于一个纯swift类来说，并不支持直接像OC runtime那样的操作,但是swift标准库依旧提供了反射机制，用来访问成员信息，即Mirror
#### 在使⽤OC开发时很少强调其反射概念，因为OC的Runtime要⽐其他语⾔中的反射强⼤的多。但是Swift是⼀⻔类型 安全的语⾔，不⽀持我们像OC那样直接操作，它的标准库仍然提供了反射机制来让我们访问成员信息
#### Mirror是Swift中的反射机制的实现，它的本质是一个结构体

        public struct Mirror {
            public let subjectType: Any.Type        //表示类型，被反射主体的类型
            public let children: Mirror.Children    //子元素集合
            public let displayStyle: Mirror.DisplayStyle?  //显示类型，基本类型为nil
            public var superclassMirror: Mirror? { get }   //父类反射， 没有父类为nil
        }
        
        class Test {
            var age: Int = 18
            var name: String = "ssl"
        }

        var t = Test()

        var mirror = Mirror(reflecting: t.self)
        print("对象类型：\(mirror.subjectType)")
        print("对象属性个数：\(mirror.children.count)")
        print("对象的属性及属性值")
        for child in mirror.children {
            print("\(child.label!)---\(child.value)")
        }
        
        打印结果：
        对象类型：Test
        对象属性个数：2
        对象的属性及属性值
        age---18
        name---ssl
        
        
        ReflectionMirrorImpl有以下6个子类：
            TupleImpl元组的反射
            StructImpl结构体的反射
            EnumImpl枚举的反射
            ClassImpl类的反射
            MetatypeImpl元数据的反射
            OpaqueImpl不透明类型的反射
#### 所以支持反射的类型应该有：类/结构体/枚举/元组/元数据/不透明类型


#### 总结： https://www.jianshu.com/p/12efe13e3e20
1.Mirror通过初始化方法返回一个Mirror实例
2.这个实例对象根据传入对象的类型去对应的Metadata中找到Description
3.在Description可以获取name也就是属性的名称
4.通过内存偏移获取到属性值
5.还可以通过numFields获取属性的个数


### 10.Swift底层原理-Codable
#### Swift 4.0 支持了一个新的语言特性—Codable，其提供了一种非常简单的方式支持模型和数据之间的转换。
#### Codable能够将程序内部的数据结构序列化成可交换数据，也能够将通用数据格式反序列化为内部使用的数据结构，大大提升对象和其表示之间互相转换的体验

        typealias Codable = Decodable & Encodable

        //Encodable 协议要求目标模型必须提供编码方法 func encode(from encoder: Encoder)，从而按照指定的逻辑进行编码
        public protocol Encodable {
            func encode(to encoder: Encoder) throws
        }

        //Decodable 协议要求目标模型必须提供解码方法 func init(from decoder: Decoder)，从而按照指定的逻辑进行解码
        public protocol Decodable {
            init(from decoder: Decoder) throws
        }

### 11 swift中的可选类型
#### 在变量类型后加问号（?）表示该变量可能有值也可能没有值



#### 底层Optional是一个包含None和Some(Wrapped)两种类型的泛枚举类型，Optional.None即nil，Optional.Some非nil。
        @frozen public enum Optional<Wrapped> : ExpressibleByNilLiteral {
            //在代码中，值的缺失通常使用‘ nil ’来编写。
            case none
            //
            case some(Wrapped)
        }
#### 在Swift中，nil不是指针，而是值缺失的一种特殊类型，任何类型的可选项都可以设置为nil而不仅仅是对象类型
#### 每个类型的 nil 都是不同的，例如 Int? 的 nil 和 String? 的 nil 是不同的，它们所代表的空值的类型不同














