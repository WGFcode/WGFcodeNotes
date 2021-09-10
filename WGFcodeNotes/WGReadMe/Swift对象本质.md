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
        #define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts  
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
* 动态派发：表派发(VTable)和消息派发
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
* final修饰的类，类里面的所有函数都将使用直接派发，或final修饰的方法，也采用直接派发
* dynamic 可以让类里面的函数使用消息机制派发
* @inline 告诉编译器可以使用直接派发
* @objc 和 @nonobjc 显示声明一个函数能否被 Objective-C 的运行时捕获到。
* @nonojc 用这个修饰符声明的方法，在被调用时，将不再采用消息派发的方式
#### 2.2 建议
1. 能用值类型地方就有值类型，不仅仅是因为其拷贝速度快，方法调度也快
2. 多使用private final 等关键字，一方面提高代码阅读性，编译器内部也对消息调度进行优化
3. 代码分类多使用拓展，拓展中的方法是静态派发（除了定义成运行时方法）
4. 遵守的协议(这里说的是Swift协议)尽量写在拓展中，如果希望被子类重写的话。建议不要使用类的多态，而是使用协议进行抽象，将需要属性和多种实现的方法抽取到协议中，拓展实现一些共用方法。这样不仅移除对父类的依赖也可以实现‘多继承’
5. OC混编时候，使用了一些OC特性的框架（例如KVO），不仅仅只需要对属性或者方法进行@objc 声明，还需要对其进行dynamic修饰才能按照预期的来
6. Swift 编写函数大部分走的是静态方法，这也就是Swift快的原因所在
7. 协议继承和类继承确保对象多态性会使用虚函数表进行动态派发
8. 继承自NSObject对象通过 dynamic/ @objc dynamic 关键字让其走消息机制派发
