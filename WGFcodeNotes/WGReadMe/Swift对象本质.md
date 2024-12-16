## 一. =============== swift对象本质 ===============

* swift类对象的底层是个HeapObject结构体，该结构体中包含了两个成员，一个是指向元数据的指针，占用8个字节，一个是引用计数，占用8个字节
* 元数据类型是HeapMetadata，它的别名是TargetHeapMetadata类型，继承关系是： TargetHeapMetadata : TargetMetadata
* TargetMetadata结构体中只有一个kind成员，用来表示该元数据是哪种类型
* 若元数据类型kind是MetadataKind::Class:即纯swift类，则元类对象类型就是TargetClassMetadata，继承关系是: TargetClassMetadata : TargetAnyClassMetadata : TargetHeapMetadata
 
#### 通过汇编探究swift对象的创建过程，通过Xcode->Debug->Debug Workflow->Alway show Disassembly打开汇编调试器，然后在创建
swift对象处打断点Debug Workflow

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
3._swift_allocObject_                 
4.swift_slowAlloc                               
5.malloc                   

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

        struct HeapObject {
            HeapMetadata const *metadata;  //8字节
            InlineRefCounts refCounts      //8字节
        }
        

#### 1.1 HeapObject中的元数据HeapMetadata

    define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS InlineRefCounts refCounts
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
    Description
    IVarDestroyer
#### swift中class底层结构如下

        struct ClassMetadata {
            //TargetMetadata
            kind  //在oc中放的就是isa，在swift中kind大于0x7FF表示的就是类；根据kind获取元数据metadata的类型
            
            //TargetAnyClassMetadata
            Superclass      //父类的Metadata，如果是null说明是最顶级的类了
            CacheData[2]    //指针数组，总共占16个字节 缓存数据用于某些动态查找，通常需要与Objective-C的使用进行互操作
            Data
            
            //TargetClassMetadata
            Flags                      
            InstanceAddressPoint       
            InstanceSize          //实例对象在堆内存的大小     
            InstanceAlignMask     //根据这个mask来获取内存中的对齐大小
            Reserved              //预留给运行时使用
            ClassSize
            ClassAddressPoint
            Description           //TargetClassDescriptor 类型的类
            IVarDestroyer
        }
* 虚函数表的内存地址，是 TargetClassDescriptor 中的最后一个成员变量，添加方法的形式是追加到数组的末尾。所以这个虚函数表是按顺序连续存储类的方法的指针
#### swift中class的extension为什么用的是静态派发，而不是写到虚函数表中？
##### 一方面是类是可以继承的，如果给父类添加extension方法，继承该类的所有子类都可以调用这些方法每个子类都有自己的函数表，
所以这个时候方法存储就成为问题。为了解决这个问题，直接把extension独立于虚函数表之外，采用静态调用的方式。在程序进行编译的时候，函数的地址就已经知道了


#### 1.3 swift对象和OC对象区别
1. OC中的实例对象本质是结构体，通过底层的objc_object模版创建，类是继承自objc_class
2. Swift中的实例对象本质是结构体，类型是HeapObject，比OC多了一个refCounts
3. OC中的方法列表存储在objc_class结构体(class_rw_t)的methodList中
4. Swift中的方法存储在metadata元数据中sil_vtable
5. OC中的ARC是存储在优化过的isa指针中，如果存不下会存储在全局的sidetable中
6. Swift中的引用计数是对象内部由一个refCounts属性存储



## 二. =============== swift方法调用/派发 ===============

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/swiftMethod.png)
#### swift方法调用分两大类
1.静态派发

2.动态派发

        函数表派发: VTable(虚函数表) + witness Table(见证表)
        消息派发(objc_msgSend)
#### 静态派发
##### 静态派发即直接派发基于编译期；直接调用函数地址进行调用。函数地址在编译、链接完成后就已经确定了，存放在Mach-O中
的__text代码段中；是最快最高效的一种方法派发方式；缺点:编译期已经确定了函数地址所以缺乏动态性、不能实现继承；编译器可
以对这种直接派发/静态派发方式进行更多优化，比如函数内联inline(在被调用时会直接将代码展开，以避免函数调用的开销)

#### 动态派发是基于运行时的
##### Swift 中存在两种函数表，一种是sil_vtable；一种是sil_witness_table
##### (1).函数表派发,编译阶段编译器会为每一个类创建一个vtable(key:函数名，value:函数地址；若子类override了父类的方法
key:函数名，value:子类重写的新的函数地址)，存放的是一个包含若干函数指针的数组，这些函数指针指向这个类中相对应函数的实现代码；
运行阶段调用方法时，函数表派发需要比静态派发多执行两个指令(通过读取该类的vtable和函数的指针)来进行调用

        class WGClass {
            func eat() {
                NSLog("WGClass-eat")
            }
            func sleep() {
                NSLog("WGClass-sleep")
            }
        }

        class WGSubClss : WGClass {
            override func eat() {
                NSLog("WGSubClss-eat")
            }
        }
        let cls = WGSubClss()
        cls.sleep()
        
        WGClass函数表    WGSubClss函数表
        函数名 指针地址    函数名 指针地址
        eat   0x1000     eat   0x2000 (重写)
        sleep 0x1008     sloop 0x1008 (继承)

##### (2).Witness Table Dispatch派发。证明类型实现了协议。是Swift用于协议的动态分派机制。当一个类型遵循某个协议时，编译器会
为该类生成一个Witness Table，存储该类型对协议中所有方法和属性的具体实现；当通过协议调用方法时，Swift使用Witness Table
查找具体实现: 编译器会为MyClass生成一个Witness Table，调用object.doSomething时，通过Witness Table找到具体实现并调用

        protocol MyProtocol {
            func doSomething()
        }
        class MyClass: MyProtocol {
            func doSomething() {
                print("MyClass implementation of doSomething")
            }
        }

        let object: MyProtocol = MyClass()
        object.doSomething()


##### (3).消息派发Objc_msgSend方法，和OC方法调用流程一样；是最动态但也是最慢的一种派发技术；缺点就是需要利用runtime遍历该类的整个层级
才能确定要执行哪个方法实现；优点就是在运行阶段可以动态更改使得Swizzling技术(允许我们在运行时改变方法的实现,通过交换方法选择器对应的方法实现，
来改变方法的行为)得以实现

#### 影响swift方法派发方式因素
* 声明位置(类型声明所在的作用域内 + Extension扩展声明)
* 类型: 引用类型、值类型
* 关键词: final、@objc、dynamic、@inline
* swift中类的构造器函数init和析构函数deinit都是函数表派发


![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/swiftMethod1.png)
* 值类型: 无论在声明位置定义的方法、在扩展中定义的方法、遵守协议中的方法，调用都是使用的Static派发
* 纯swift类: 声明位置定义的方法通过VTable函数表派发；扩展中定义的方法通过Static派发
* 继承自NSObject的类: 声明位置定义的方法通过VTable函数表派发；扩展中定义的方法通过Static派发
* final修饰的类、方法都是通过Static派发；static、class修饰的方法调用方式也是通过Static派发
* Swift 中的类如果要供 Objective-C 调用，必须也继承自NSObject，所以@objc、dynamic只会出现在NSObject的子类中
* @objc+dynamic组合无论是NSObject子类声明位置定义的方法、还是扩展中定义的方法都走消息发送objc_msgSend
* @objc修饰在NSObject子类声明位置定义的方法通过VTable函数表派发；修饰在NSObject子类扩展中的方法通过objc_msgSend发送
* @objc是将该方法暴露给oc使用；dynamic关键字是将方法标记为可变方法。@objc+dynamic是将方法保留给oc且还可以动态修改
* 若通过协议调用方法(无论对象是结构体、枚举、class、NSObject子类)都是通过Witness Table函数表派发
* @inline 告诉编译器可以使用直接派发

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/swiftMethod2.png)
    
#### swift方法调度汇总
#### swift函数可以声明在两个地方，一个是类型声明的作用域，一个是扩展extension中
        
                     值类型           引用类型-纯swift类         引用类型-继承自NSObject的类
        定义方法     static派发   Vtable派发(final时static派发)  Vtable派发(@objc时Vtable派发/dynamic时Vtable派发
                                                              /final时static派发/@objc+dynamic消息发送)      
        
        扩展方法     static派发         static派发                  static派发(@objc/@objc+dynamic消息发送)
        
        遵守协议方法  static派发         Vtable派发                  Vtable派发
     协议类型调用方法  witness Table派发  witness Table派发           witness Table派发
        
####  建议
1. 能用值类型地方就有值类型，不仅仅是因为其拷贝速度快，方法调度也快
2. 多使用private final 等关键字，一方面提高代码阅读性，编译器内部也对消息调度进行优化
3. 代码分类多使用拓展，拓展中的方法是静态派发（除了定义成运行时方法）
4. 遵守的协议(这里说的是Swift协议)尽量写在拓展中，如果希望被子类重写的话。建议不要使用类的多态，而是使用协议进行抽象，将需要属性和多种实现的方法抽取到协议中，拓展实现一些共用方法。这样不仅移除对父类的依赖也可以实现‘多继承’
5. OC混编时候，使用了一些OC特性的框架（例如KVO），不仅仅只需要对属性或者方法进行@objc 声明，还需要对其进行dynamic修饰才能按照预期的来
6. Swift 编写函数大部分走的是静态方法，这也就是Swift快的原因所在
7. 协议继承和类继承确保对象多态性会使用虚函数表进行动态派发
8. 继承自NSObject对象通过 @objc + dynamic 关键字让其走消息机制派发

#### swift中函数调用分为了3个步骤 https://www.jianshu.com/u/06658dd306de
1. 找到metadata
2. 确定函数地址（metadata + 偏移量）；函数地址存放在函数表sil_vtable；函数表用来存储类中的方法，存储方式类似于数组，方法连续存放在函数表中
3. 执行函数

        struct HeapObject {
            HeapMetadata const *metadata;  //8字节
            InlineRefCounts refCounts      //8字节
        }
        
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
            //不管是Class，Struct还是Enum都有自己的Descriptor TargetClassDescriptor 类型的类 VTable虚函数表就是存放在这里的
            var typeDescriptor: UnsafeMutableRawPointer 
            var iVarDestroyer: UnsafeRawPointer
        }
        
        // TargetClassDescriptor内部成员变量，发现没有发现vtable相关属性，继续从该类的初始化方法开始查找ClassContextDescriptorBuilder
        class TargetClassDescriptor {
            ContextDescriptorFlags Flags;
            TargetRelativeContextPointer<Runtime> Parent;
            TargetRelativeDirectPointer<Runtime, const char, /*nullable*/ false> Name;
            TargetRelativeDirectPointer<Runtime, MetadataResponse(...),
                                      /*Nullable*/ true> AccessFunctionPtr;
            TargetRelativeDirectPointer<Runtime, const reflection::FieldDescriptor,
                                      /*nullable*/ true> Fields;
            TargetRelativeDirectPointer<Runtime, const char> SuperclassType;
            uint32_t MetadataNegativeSizeInWords;
            uint32_t MetadataPositiveSizeInWords;
            uint32_t NumImmediateMembers;
            uint32_t NumFields;
            uint32_t FieldOffsetVectorOffset;
        }
        
        static void initClassVTable(ClassMetadata *self) {
            //获取Description地址
            const auto *description = self->getDescription();
            auto *classWords = reinterpret_cast<void **>(self);
            if (description->hasVTable()) {
                auto *vtable = description->getVTableDescriptor();
                auto vtableOffset = vtable->getVTableOffset(description);
                auto descriptors = description->getMethodDescriptors();
                //1.将本类中所有的方法存入到VTable表中
                for (unsigned i = 0, e = vtable->VTableSize; i < e; ++i) {
                  auto &methodDescription = descriptors[i];
                  swift_ptrauth_init_code_or_data(
                      &classWords[vtableOffset + i], methodDescription.Impl.get(),
                      methodDescription.Flags.getExtraDiscriminator(),
                      !methodDescription.Flags.isAsync());
                }
            }

          if (description->hasOverrideTable()) {
            auto *overrideTable = description->getOverrideTable();
            auto overrideDescriptors = description->getMethodOverrideDescriptors();
            for (unsigned i = 0, e = overrideTable->NumEntries; i < e; ++i) {
              auto &descriptor = overrideDescriptors[i];
              auto baseClassMethods = baseClass->getMethodDescriptors();
              //2.将所有父类允许重载的方法全部加到本类的vtable中
              auto baseVTable = baseClass->getVTableDescriptor();
              auto offset = (baseVTable->getVTableOffset(baseClass) +
                             (baseMethod - baseClassMethods.data()));
              swift_ptrauth_init_code_or_data(&classWords[offset],
                                              descriptor.Impl.get(),
                                              baseMethod->Flags.getExtraDiscriminator(),
                                              !baseMethod->Flags.isAsync());
            }
          }
        }
        
#### 虚函数表的内存地址，是 TargetClassDescriptor 中的最后一个成员变量，添加方法的形式是追加到数组的末尾。所以这个虚函数表是按顺序连续存储类的方法的指针
* VTable虚函数表的内存地址是通过对象底层的元数据metedata找到Descriptors，然后通过内存偏移找到虚函数表
* VTable虚函数表首先会把当前类的所有方法都放在表中，然后将重载父类的方法也放进表中
* 每个类在初始化的时候都会创建一个VTable虚函数表
* 在类的元数据中，如果存在VTable，会通过元数据描述符Descriptor获取VTable的偏移量，并将类中的方法存入VTable表中。如果存在方法重载表（Override Table），则会将基类和子类的方法也加入到VTable中‌


#### 接下来我们将swift源码通过编译器swiftc获取对应的SIL文件（swift使用的编译器为swiftc，OC使用的为Clang）
    1. 创建swift文件：WGSwiftMethodDispatch.swift
    2. 终端cd到该文件的上级目录  
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
        WGMethodDispatchStatic.init!allocator: (WGMethodDispatchStatic.Type) -> () -> 
        WGMethodDispatchStatic : @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC
        // WGMethodDispatchStatic.__deallocating_deinit
        WGMethodDispatchStatic.deinit!deallocator: @$s21WGSwiftMethodDispatch08WGMethodC6StaticCfD    
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
        WGMethodDispatchStatic.init!allocator: (WGMethodDispatchStatic.Type) -> () -> 
        WGMethodDispatchStatic : @$s21WGSwiftMethodDispatch08WGMethodC6StaticCACycfC
        
        //2. WGMethodDispatchStatic.printMethodName()
        WGMethodDispatchStatic.printMethodName: (WGMethodDispatchStatic) -> () -> 
        String : @$s21WGSwiftMethodDispatch08WGMethodC6StaticC05printB4NameSSyF   
        
        //3. WGMethodDispatchStatic.__deallocating_deinit
        WGMethodDispatchStatic.deinit!deallocator: @$s21WGSwiftMethodDispatch08WGMethodC6StaticCfD    
    }
#### 分析: **objc_method**关键字表明了方法已经转为了使用OC中的方法派发方式，即消息派发，并且方法签名中，返回类型已经变为了 NSString，vtable中也没有了**getMethodName**方法。

  
## 三. =============== Swift属性 ===============

#### swift属性中涉及到内容如下
* 存储属性
* 计算属性
* 类型属性
* 延迟属性
* 属性观察器
* 属性包装器

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/property1.png)

* enum枚举:定义计算属性(可读+可读可写) / static类型属性(var+let); 不能定义存储属性;
* struct结构体: 定义计算属性(可读+可读可写) / 存储属性(var+let) / lazy懒加载存储属性 / static类型属性(var+let)

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/property2.png)

* class类:定义计算属性(可读+可读可写) / 存储属性(var+let) / lazy懒加载存储属性 / static类型属性(var+let) / class类型属性(计算型)
* protocol协议: 可以定义属性，但不会区分存储属性还是计算属性，只是设置了属性是可读{ get }还是可读可写{ get set }

1. 存储属性占用实例的内存空间；计算属性不占用实例的内存空间，实际上计算属性本质就是个函数/方法(get/set)    
2. 计算属性必须用var声明，因为计算属性依赖于其他属性计算所得，计算属性的值是可能发生变化的    
3. 属性加上lazy就变成懒加载属性了且实例的内存空间会变大，因为加了lazy，系统会将该属性变成可选类型，在未访问时会变成nil，访问时才会赋值
lazy的本质是可选项Optional，可选项的本质是enum枚举     
4. 类型属性: 严格意义属性分为实例属性:只能通过实例访问(存储实例属性/计算实例属性)和类型属性: 只能通过类型区访问(类型存储属性/类型计算属性)
static可以定义类型属性(let+var),class只能在类中定义类型属性且类型属性属于计算型         

        enum                     struct                  class 
        计算属性(var)             计算属性(var)             计算属性(var)
        static类型属性(let+var)   存储属性(let+var)         存储属性(let+var)
                                lazy属性(var)             lazy属性(var)
                                static类型属性(let+var)    static类型属性(let+var)
                                                         class类型属性(var计算型)
                        

* 在init方法中调用set方法是不会触发属性观察器的，因为init方法还没完成初始化；如果init方法先调用了super.init方法，那么再调用set方法是可以
触发属性观察器的，因为super.init后本对象已经完成了初始化工作了

#### 4.1 存储属性
1. 存储属性是一个作为特定类和结构体实例一部分的常量或变量;类class、结构体struct可以定义存储属性，枚举不能定义存储属性
2. 存储属性要么是变量存储属性 (由 var 关键字引入)要么是常量存储属性(由 let 关键字引入)
3. 在类中有一个原则：当类实例被构造完成时，必须保证类中所有的属性都构造或者初始化完成
4. 会占用分配实例对象的内存空间    
5. 存储属性在编译的时候，编译器默认会合成get/set方式，而我们访问/赋值 存储属性的时候，实际上就是调用get/set
6. let声明的属性默认不会提供setter，并且不能被重写，因为底层有关键词final修饰

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
        
        存储属性值存放的位置
        HeapObject {
            metadata
            refCounts
            a
            b
        }

#### 4.2 计算属性
1. 类/结构体/枚举都能够定义计算属性，计算属性并不存储值而是提供 getter 来获取值或提供getter+setter来修改和获取值
2. 对于存储属性来说可以是常量let或变量var，但计算属性必须定义为变量var
3. 我们定义计算属性时候必须包含类型，因为编译器需要知道返回值是什么；不能有默认值；初始值必须在get {} 中书写
4. 不占用内存空间，本质是get/ get+set方法的属性    
           
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
* a和b虽然后面都有{ get set }，但前面修饰符有区别，a有@_hasStorage，b没有。说明a是一个可存储的值，b没有存储，只有get和set方法
* b在setter中成了一个名为 newValue 的常量，并且会把外部传进来的值赋值给 newValue，然后调用setter方法，把newValue作为参数传递给setter方法
* 计算属性根本不会有存储实例的成员变量，那也就意味着计算属性不占内存

#### 4.3 延迟属性
1. 使用 lazy 可以定义一个延迟存储属性，在第一次用到属性的时候才会进行初始化
2. lazy属性必须是变量（var修饰符），因为常量属性（let修饰符）必须在初始化之前就有值，所以常量属性不能定义为lazy
3. 如果多条线程同时第一次访问 lazy 属性，无法保证属性只被初始化 1 次
4. 定义延迟初始化的属性。这种属性不会在对象实例化时立即初始化，而是在第一次访问该属性时才进行初始化。
这种技术可以提高对象初始化的效率，并且可以减少不必要的开销
5. lazy延迟属性是线程不安全的

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
* 并且它是一个可选项。拥有可选项就意味着，其在初始的时候是有值的，只是这个值是一个nil
* lazy修饰的属性，底层默认是optional可选的，没有被访问时，默认是nil，内存中表现就是0x0
* 延迟属性必须有一个默认值 lazy var name: String?这种写法也不行编译器会报错；lazy var name: String?=nil这种写法可以
* 只有在第一次被访问时才会赋值，且是线程不安全的
* 使用lazy和不使用lazy会对实例对象的内存大小有影响，主要是因为lazy底层是可选类型optional,optional的本质是枚举，除了存储属性本身
的内存大小，还需要一个字节用于存储case

#### 4.4 类型属性
1. enum/struct/class使用关键字 static 来定义类型属性; class中可以用class定义计算型的类型属性
2. 严格来说属性可以分为实例属性和类型属性；类型属性在整个程序运行过程中，就只有1份内存（类似于全局变量），且是线程安全的
3. 类型属性必须设置初始值。因为类型属性不像实例存储属性有init那样的初始化器来初始化存储属性
4. 存储类型属性默认就是 lazy ，会在第一次使用的时候才初始化，就算被多个线程同时访问，保证只会初始化一次
5. 存储型类型属性可以是 let + var 且只能用static修饰；计算型类型属性只能是var 且可以用static或class修饰
6. 为类定义计算型类型属性时，可以改用关键字 class 来支持子类对父类的实现进行重写
7. 类型属性是线程安全的。因为类型属性底层其实就是个全局变量且在初始化过程中会有swift_once函数的调用    

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
* a变量变成了全局变量,即类型属性底层就是一个全局变量
* 在a变量的初始化方法中，发现了swift_once函数的调用，在swift_once源码中发现调用了dispatch_once_f也就是GCD的实现
* 所以在swift中单例的实现可以通过static
* 类型属性必须有一个默认的初始值，且只会被初始化一次


#### 总结
* 存储属性： 结构体/类，存储属性可以是变量var也可以是常量let;   
* 计算属性：结构体/类/枚举，计算属性只能是变量var；计算属性必须声明类型；
* 延迟属性: lazy属性必须是变量var,本质是可选项Optional，底层是final修饰的不能重写,Optional可选项的本质是枚举enum;              
* 类型属性： 结构体/类/枚举.类似一个全局变量；结构体/枚举/类可以通过static定义(var+let);⚠️类中还可以通过class定义
计算类型的类型属性            
* 计算属性不能直接设置初始值；存储属性可以直接设置初始值也可以通过初始化进行赋值；
* 计算属性不占用内容空间(通过getter/setter读写)；存储属性占用内存空间


#### 4.5 属性观察器 willSet/ didSet

1.属性观察器会用来观察属性值的变化，只能用于 var 修饰的属性，而不能用于 let 修饰的属性            
2.willSet: 属性被修改前调用，用newValue获取属性即将被赋予的新值;                    
3.didSet: 属性被修改后调用,用oldValue来获取修改前的旧值          

 
#### 结构体中 存储属性 / lazy存储属性 可以添加属性观察器      

        struct WGStruct {
            var age = 0
            //结构体中: 1.没有初始值的存储属性添加属性观察器
            var name: String  {
                willSet { NSLog("name-willSet---newValue:\(newValue)") }
                didSet { NSLog("name-didSet---oldValue:\(oldValue)") }
            }
            //结构体中: 2.有初始值的存储属性添加属性观察器
            var sex: Bool = false {
                willSet { NSLog("sex-willSet---newValue:\(newValue)") }
                didSet { NSLog("sex-didSet---oldValue:\(oldValue)") }
            }
            //结构体中: 3.lazy懒加载属性添加属性观察器
            lazy var teacher: String = ""{
                willSet { NSLog("teacher-willSet---newValue:\(newValue)") }
                didSet { NSLog("teacher-didSet---oldValue:\(oldValue)") }
            }
        }

        var str = WGStruct(name: "zhangsan")
        str.name = "123"
        str.age = 20
        str.sex = true
        str.teacher = "wang"
        NSLog("name: \(str.name) age: \(str.age) sex: \(str.sex) teacher:\(str.teacher)")
        //打印结果
        
        name-willSet---newValue:123
        name-didSet---oldValue:zhangsan
        sex-willSet---newValue:true
        sex-didSet---oldValue:false
        teacher-willSet---newValue:wang
        teacher-didSet---oldValue:
        name: 123 age: 20 sex: true teacher:wang
        
#### 类中 存储属性/ lazy存储属性 / static类型属性 可以添加属性观察器    

        class WGClass {
            var age = 0
            //类中: 1.没有初始值的存储属性添加属性观察器(类中没有初始值的存储属性一定要在初始化器中给属性赋值)
            var name: String  {
                willSet { NSLog("name-willSet---newValue:\(newValue)") }
                didSet { NSLog("name-didSet---oldValue:\(oldValue)") }
            }
            //类中: 2.有初始值的存储属性添加属性观察器
            var sex: Bool = false {
                willSet { NSLog("sex-willSet---newValue:\(newValue)") }
                didSet { NSLog("sex-didSet---oldValue:\(oldValue)") }
            }
            //类中: 3.lazy懒加载属性添加属性观察器
            lazy var teacher: String = ""{
                willSet { NSLog("teacher-willSet---newValue:\(newValue)") }
                didSet { NSLog("teacher-didSet---oldValue:\(oldValue)") }
            }
            //类中: 4.static(var)类型属性添加属性观察器
            static var score: Double = 0.0 {
                willSet { NSLog("score-willSet---newValue:\(newValue)") }
                didSet { NSLog("score-didSet---oldValue:\(oldValue)") }
            }
            init(name: String) {
                self.name = name
            }
        }
        var str = WGStruct(name: "zhangsan")
        str.name = "123"
        str.age = 20
        str.sex = true
        str.teacher = "wang"
        NSLog("name: \(str.name) age: \(str.age) sex: \(str.sex) teacher:\(str.teacher)")
        //打印结果
        name-willSet---newValue:123
        name-didSet---oldValue:zhangsan
        sex-willSet---newValue:true
        sex-didSet---oldValue:false
        teacher-willSet---newValue:wang
        teacher-didSet---oldValue:
        score-willSet---newValue:20.0
        score-didSet---oldValue:0.0
        name: 123 age: 20 sex: true teacher:wang score类属性值:20.0

#### 在继承关系中；子类继承父类的存储属性 / 继承父类的{get set}计算属性 可以添加属性观察器
* 父类的属性添加了{willSet didSet}，那么子类重写了这个属性并也添加了{ willSet didSet }
那么调用顺序是先     
1.子类的willSet             
2.父类的willSet方法        
3.父类的didSet方法       
4.子类的didSet方法                           

        class WGClass {
            //存储属性
            var age = 8 {
                willSet { NSLog("WGClass age willSet newValue: \(newValue)") }
                didSet { NSLog("WGClass age didSet oldValue: \(oldValue)") }
            }
            //计算属性-(get)
            var sex: Bool {
                return false
            }
            //计算属性-(get set)
            var name: String {
                get { return "1" }
                set { NSLog("调用了name的setter方法") }
            }
        }

        class WGSubClass : WGClass {
            //1.继承父类的存储属性
            override var age: Int {
                willSet { NSLog("WGSubClass override age willSet newValue: \(newValue)") }
                didSet { NSLog("WGSubClass override age didSet oldValue: \(oldValue)") }
            }
            //2.继承父类的可读 (get) 计算属性
            override var sex: Bool {
                return true
            }
            //3.继承父类的可读可写 (get set) 计算属性
            override var name: String {
                willSet { NSLog("WGSubClass override name willSet newValue: \(newValue)") }
                didSet { NSLog("WGSubClass override name didSet oldValue: \(oldValue)") }
            }
        }
        let sub = WGSubClass()
        sub.age = 10
        //打印结果:
        WGSubClass override age willSet newValue: 10
        WGClass age willSet newValue: 10
        WGClass age didSet oldValue: 8
        WGSubClass override age didSet oldValue: 8
        
        
        sub.name = "zhangsan"
        //打印结果:
        WGSubClass override name willSet newValue: zhangsan
        调用了name的setter方法
        WGSubClass override name didSet oldValue: 1


4.在初始化器init中设置属性值不会触发 willSet 和 didSet。在属性定义时设置初始值也不会触发 willSet 和 didSet

       class WGClass {
            //1. 初始值不会触发{ willSet didSet}
            var age: Int = 8{
                willSet { NSLog("WGClass age willSet newValue: \(newValue)") }
                didSet { NSLog("WGClass age didSet oldValue: \(oldValue)") }
            }
            //2. 初始化器中不会触发{ willSet didSet}
            init(age: Int) {
                self.age = age
            }
        }

#### 哪里可以添加属性观察器 { willSet didSet }？
* 结构体中 存储属性 / lazy存储属性 可以添加属性观察器
* 类中 存储属性 / lazy存储属性 / static类型属性var 可以添加属性观察器
* 继承关系中，子类继承 父亲的存储属性 / {get set}计算属性 可以添加属性观察器
* 计算属性不能添加属性观察器(⚠️特例：只有子类重写继承自父亲的可读可写{get set}计算属性可以添加属性观察器)




## 四. =============== Swift底层原理-内存管理之引用计数 ===============

#### swift内存管理主要通过ARC(Automatic Reference Counting)自动引用计数机制来实现；ARC 用于管理对象类型（类的实例）
的内存分配和释放
* 值类型(如enum/strut/基础数据类型)存储在栈,由编译器负责管理内存；值类型的变量超出其作用域时，内存会自动释放
* 值类型在赋值或传递参数时会进行复制copy;而对于集合类型(数组Array/字典Dictionary)的值类型采用的是写时拷贝Copy-On-Write
优化策略(只有当值类型被修改时，才会发生拷贝，主要就是为了节约内存空间)
* 引用类型存储在堆中，需要由开发人员自己管理(其实系统已经帮我们做了)
* 对于swift的内存管理来将，我们主要关注强引用Strong、弱引用weak、无主引用unowned即可
* Swift语言延续了和Objective-C语言一样的思路进行内存管理，都是采用引用计数的方式来管理实例的内存空间
* Swift对象本质是一个HeapObject结构体指针。HeapObject结构中有两个成员变量，metadata 和 refCounts
* metadata 是指向元数据对象的指针，里面存储着类的信息，比如属性信息，虚函数表等
* swift本质上存在两种refCounts引用计数  
          
        1.如果是强引用,那么就是strong RC + unowned RC + flags
        2.如果是弱引用,那么就是HeapObjectSideTableEntry    
              
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/ARCStrong.png)
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/ARCweak.png)

#### 5.1 如果是强引用或unowned无主引用，则引用计数refCounts是通过64位位域计数bits存储( 强引用stong+无主引用unowned)

        struct HeapObject {                 
            metadata(newMetadata)                       初始化默认strongExtraCount = 0 unownedCount = 1
            refCounts(InlineRefCounts::Initialized) --->RefCounts(Initialized_t):refCounts(RefCountBits(0, 1))
                            |
            typedef RefCounts<InlineRefCountBits> InlineRefCounts;
                            |
            typedef RefCountBitsT<RefCountIsInline> InlineRefCountBits;
                            |
                    class RefCountBitsT {
                        typedef typename RefCountBitsInt<refcountIsInline, sizeof(void*)>::Type
                        BitsType;
                        
                        BitsType bits;  //该属性是由RefCountBitsInt的Type属性定义的
                    }       ｜
                            ｜
                    struct RefCountBitsInt<refcountIsInline, 8> {
                            //存储的是64位原有的strong RC + unowned RC + flags
                            //一个 uint64_t 的位域信息，在这个 uint64_t 的位域信息中存储着运行生命周期的相关引用计数
                            typedef uint64_t Type;      
                            typedef int64_t SignedType;
                    }
                    
                    最终bits存储信息如下
                    第0位：标识是否是永久的
                    第1-31位：存储无主引用         unowned RC 31位
                    第32位：标识当前类是否正在析构   isDeiniting
                    第33-62位：标识强引用          strong RC 30位
                    第63位：是否使用SlowRC
         }
         数据结构大概是
         struct InlineRefCountBits {
             var strongRef: UInt32 
             var unownedRef: UInt32
         }
         
         0位  1---------31位   32位   33位----------62位    63位
               unowned RC                 strong RC
         
#### 1. swift中默认都是强引用，强引用就是通过引用计数中的bits这种位域来实现引用计数的增加、减少。引用计数的变化，
并不是直接+1，而是refercount存储的信息发生变化(第33-62位) 

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/ARCStrong1.png)

 
#### 2. 在Swift中通过 unowned 定义无主引用，unowned 不会产生强引用，实例销毁后仍然存储着实例的内存地址(类似于OC中的 
unsafe_unretained);实例销毁后访问无主引用，会产生运行时错误（野指针）;在使用unowned的时候，要确保其修饰的属性一定有值
unowned无主引用引用计数是从1开始的

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/ARCUnowned.png)


#### 5.2 如果是弱引用，则引用计数refCounts不再通过位域来存储引用计数，而是一个指针，指向HeapObjectSideTableEntr散列表
* weak修饰后的变量会变成一个可选项Optional,也就是可以将 nil 赋值给它
* 使用weak声明的变量会调用swift_weakInit方法生成一个WeakReference类；使用对象的HeapObject生成一个WeakReference类的散列表
* 散列表存储着 weak弱引用，而散列表内部引用计数相关类是继承自RefCountBitsT(通过bits位域存储strong RC + unowned RX)
* 所以散列表中存储的就是 weak RC + 继承而来的[strong RC + unowned RC]    
* unowned比weak效率更高。因为weak还需要通过操作散列表来存储引用计数；而unowned通过64位位域来存储引用计数
       
        1.使用weak声明变量，会调用swift_weakInit方法生成WeakReference类
        WeakReference *swift_weakInit(WeakReference *ref, HeapObject *value);
                                ｜
        WeakReference swift_weakInit(WeakReference *ref, HeapObject *value) {
          ref->nativeInit(value);
          return ref;
        }
        //1.1使用对象的HeapObject生成WeakReference的散列表
        void nativeInit(HeapObject *object) {
            auto side = object ? object->refCounts.formWeakReference() : nullptr;
            nativeValue.store(WeakReferenceBits(side), std::memory_order_relaxed);
        }
        
        HeapObjectSideTableEntry* RefCounts<InlineRefCountBits>::formWeakReference() {
          auto side = allocateSideTable(true);  //1.2创建散列表
          if (side)
            return side->incrementWeak();       //1.3散列表中弱引用数+1
          else
            return nullptr;
        }
        //1.2创建散列表
        HeapObjectSideTableEntry* RefCounts<InlineRefCountBits>::allocateSideTable(bool failIfDeiniting) {
            //使用HeapObject初始化一个散列表
            HeapObjectSideTableEntry *side = new HeapObjectSideTableEntry(getHeapObject());
            
            //使用散列表初始化一个RefCountBits
            auto newbits = InlineRefCountBits(side);
            
            //使用散列表里面的HeapObject的RefCounts,初始化散列表的refCounts
            side->initRefCounts(oldbits);
            return side;
        }
        //散列表
        class HeapObjectSideTableEntry {
            //(1)继承自RefCountBits,有一个64位的属性bits存储strongRC + unownedRC
            //(2)自己额外增加一个weakBits属性，记录弱引用数
            std::atomic<HeapObject*> object;  对象的HeapObject
            SideTableRefCounts refCounts;     散列表中的refCounts
            
            //通过HeapObject初始化散列表
            HeapObjectSideTableEntry(HeapObject *newObject)
                : object(newObject), refCounts()
            { }
        }
        typedef RefCounts<SideTableRefCountBits> SideTableRefCounts;
        
        class SideTableRefCountBits : public RefCountBitsT<RefCountNotInline> {
            uint32_t weakBits;
        }
        
        //1.3散列表中弱引用数+1
        HeapObjectSideTableEntry* incrementWeak() {
            if (refCounts.isDeiniting()) return nullptr;
            refCounts.incrementWeak();
            return this;
        }
        void incrementWeak() {
            auto oldbits = refCounts.load(SWIFT_MEMORY_ORDER_CONSUME);
            RefCountBits newbits;
            do {
                newbits = oldbits;
                assert(newbits.getWeakRefCount() != 0);
                newbits.incrementWeakRefCount();
              
                if (newbits.getWeakRefCount() < oldbits.getWeakRefCount()) {
                    swift_abortWeakRetainOverflow();
                }
            } while (!refCounts.compare_exchange_weak(oldbits, newbits,
                                                      std::memory_order_relaxed));
        }
        void incrementWeakRefCount() { 
            weakBits++;  //weakBits是SideTableRefCounts的新增属性，用来记录弱引用数
        }
       
         
        弱引用结构大概如下
        struct WeakReference {
            var entry: HeapObjectSideTableEntry
        }
         
        struct HeapObjectSideTableEntry {
            var object: HeapObject
            var refCounts: SideTableRefCounts
        }
         
        struct SideTableRefCounts : InlineRefCountBits {
                                    var strongref: UInt32
                                    var unownedRef: UInt32
            var weakBits: UInt32
        }
         
        struct HeapObject {
            var kind: UnsafeRawPointer
            var strongref: UInt32
            var unownedRef: UInt32
        }
         
        0-2位  3位----------61位    62-63位
                   weak RC   
                   
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/ARCWeak1.png)                           
        
#### 5.3 如何获取引用计数
#### 通过**CFGetRetainCount**函数来获取引用计数。 CFGetRetainCount会在执行前，对对象进行strong_retain操作，
在执行后，完成release_value操作。所以swift中CFGetRetainCount打印的强引用计数，会比原引用计数多1

            var cls = WGClass()
            NSLog("-------\(CFGetRetainCount(cls))----")
            //打印结果: 
            -------2----
 
#### 5.4 从上面可以分析出
* 一个实例对象在首次初始化的时候，是没有sideTable的，当我们创建一个弱引用的时候，才会创建sideTable
* weak、unowned 都能解决循环引用的问题，unowned 要比 weak 少一些性能消耗    
* 如果强引用的双方生命周期没有任何关系，使用weak；如果其中一个对象销毁，另一个对象也跟着销毁，则使用unowned；
* weak相对于unowned更兼容，更安全，而unowned性能更高；这是因为weak需要操作散列表，而unowned只需要操作64位位域信息；
在使用unowned的时候，要确保其修饰的属性一定有值
* swift中弱引用必须是可选类型，因为引用的实例被释放后，ARC会自动将其置为nil
* 散列表的创建可以分为4步操作步骤

        1.取出原来的 refCounts引用计数的信息。              
        2.判断原来的 refCounts 是否有散列表，如果有直接返回，如果没有并且正在析构直接返回nil          
        3.创建一个散列表（存放weak弱引用的sideTable）           
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
  

## 六. =============== Swift底层原理-枚举 ===============
#### 在Swift中可以通过enum 关键字来声明一个枚举；枚举是一种包含自定义类型的数据类型，它是一组有共同特性的数据的集合
* 枚举中可以定义计算属性、类型属性、实例方法、类型方法；不能定义存储属性和lazy属性
* 无原始值(没有声明枚举类型)和有原始值的枚举 占用的内容空间都是1个字节，原始值不占用枚举的内存空间
* 若设置了关联值，则不能对枚举声明类型了(即不能有原始值)，因为编译器会报错
* 如果枚举中多个成员有关联值，且最大的关联值类型大于 1 个字节（8 位）的时候，此时枚举的内存大小为：最大关联值的大小 + 1
* 原始值是在定义枚举时被预先填充的值，它的原始值始终不变；关联值是创建一个基于枚举值的常量或变量时才设置的值，枚举的关联值可以变化
* 枚举分为以下三种：       

        无原始值(没有声明枚举类型) 
        有原始值(声明了枚举类型) 
        有关联值(没有声明枚举类型且成员有关联值)


#### 6.1 无原始值: 没有指定枚举类型
* 无原始值的枚举，内部没有计算属性rawValue
* 无原始值的枚举占用的内容大小是1个字节

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
        

#### 6.2 有原始值： 指定了枚举类型(枚举类型可以是字符串、字符、任意整型值、任意浮点型值)
* 拥有原始值的枚举，内部有计算属性rawValue，通过rawValue可以获取到枚举的原始值
* 枚举的原始值特性可以将枚举值与另一个数据类型进行绑定
* 拥有原始值的枚举占用的内容大小是1个字节
* 原始值并不会存储在枚举的内存空间中，而是给枚举添加原始值时，编译器帮我们实现了**RawRepresentable协议**,
实现了init?(rawValue:）方法和计算属性rawValue
* rawValue计算属性内部通过对self参数进行switch判断，依次返回不同的原始值
* 给枚举添加原始值，不会影响枚举自身的任何结构


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


#### 6.3 关联值： Swift中枚举值可以跟其他类型关联起来存储在一起，从而来表达更复杂的案例
* 枚举的关联值和原始值本质区别是：关联值占用枚举的内存，原始值不占用枚举的内存
* 添加关联值会影响枚举自身的内存结构，关联值被存储在枚举变量中，枚举变量的大小取决于占用内存最大的那个类型
* 对于没有添加关联值的枚举，系统会默认帮我们实现**Hashable/Equatable**
* 若设置关联值，则不能再对枚举声明类型了，否则编译器会报错

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

        
#### 6.4 枚举内存分析
1. 原始值不存储在枚举内存中，不占用枚举内存空间，枚举的原始值是通过编辑器自动遵守**RawRepresentable协议**并实现了其中
的rawValue计算属性和init(rawValue:)方法，通过计算属性rawValue来获取原始值的。     
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
        

## 七. =============== Swift底层原理-闭包 ===============
#### swift中函数和闭包都属于引用类型；函数类型由形式参数类型和返回类型组成，函数类型的本质就是引用类型意味着函数本身在内存
中是通过引用访问的，而不是通过值复制。这使得函数可以作为参数传递或作为返回值。
#### 函数类型的本质在Swift中是通过TargetFunctionTypeMetadata来表示的，它继承自TargetMetadata，
TargetFunctionTypeMetadata拥有自己的Flags和ResultType，以及参数列表的存储空间  


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
#### 闭包是一个可以捕获和存储其所在上下文中的常量或者变量的函数，闭包的表现形式有三种
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
        //闭包表达式作为变量
        var closure: (Int) -> Int = { (a: Int) -> Int in
            return a + 100
        }
        //闭包表达式作为函数参数
        func func3(_ someThing: @escaping (() -> Void)) {
    
        }

#### 7.1.1闭包～捕获值
* 闭包可以在其被定义的上下文中捕获常量或变量。即使定义这些常量和变量的原作用域已经不存在，闭包仍然可以在闭包函数体内引用和修改这些值
* 闭包捕获值的本质就是：在堆上开辟一块空间、把我们的变量放到其中（这个其实就是发生了装箱操作）
* 当我们每次修改的捕获值的时候，修改的是堆区中的 value 值
* 当每次重新执⾏当前函数时候，都会重新创建内存空间
* 当闭包捕获一个常量或变量时，会捕获该常量或变量的拷贝，外部变量或常量的值发生改变也不会影响闭包内部的使用。闭包内部会在堆上申请一个
地址，并将该地址给了常量或变量，常量或变量存储在堆上。直接从堆上获取变量或常量交给闭包使用，所以闭包会开辟堆空间的内存

        func makeIncrementer() -> () -> Int {
            var runningTotal = 10
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
            }
            return incrementer
        }
        //内联函数incrementer捕获了变量runningTotal
        //申请了一个堆上的地址，并将地址给了runningTotal，将变量存储到堆上；从堆上取出变量交给闭包使用
        let fn = makeIncrementer()
        print(fn())      //11
        print(fn())      //12
        print(fn())      //13
        
        //每次调用返回的是 runningTotal += 1的结果
        print(makeIncrementer()()) //11
        print(makeIncrementer()()) //11
        print(makeIncrementer()()) //11
        
#### 7.1.2闭包～捕获全局变量
* 闭包针对全局变量，不会捕获的所以也就不会开辟堆空间，而是直接拿来用的，内部并没有进行任何堆内存开辟操作

        var runningTotal = 10
        func makeIncrementer() -> () -> Int {
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
            }
            return incrementer
        }

        let fn = makeIncrementer()
        NSLog("\(fn())")  //11
        NSLog("\(fn())")  //12
        NSLog("\(fn())")  //13
        NSLog("------")
        NSLog("\(makeIncrementer()())")  //14
        NSLog("\(makeIncrementer()())")  //15
        NSLog("\(makeIncrementer()())")  //16

#### 7.1.3闭包～捕获引用类型
* 闭包在捕获引用类型时候，其实也不需要捕获实例对象，因为它已经在堆区了，就不需要再去创建一个堆空间的实例包裹它了
* 只需要将它的地址存储到闭包的结构中，操作实例对象的引用计数+1即可
* 当闭包捕获一个引用类型的变量时，会捕获该变量的引用。即闭包内部使用的是外部变量的引用，而不是拷贝。这意味着闭包内部对
外部变量的修改会影响外部作用域中的变量


        class WGClass {
            var age = 0
        }
        func makeIncrementer() -> () -> Int {
            var runningTotal = 10
            var cls = WGClass()
            cls.age = 0
            func incrementer() -> Int {
                cls.age += 1
                return cls.age
            }
            return incrementer
        }
        
        let fn = makeIncrementer()
        NSLog("\(fn())")    //1
        NSLog("\(fn())")    //2
        NSLog("\(fn())")    //3
        
        NSLog("------")
        NSLog("\(makeIncrementer()())")  //1
        NSLog("\(makeIncrementer()())")  //1
        NSLog("\(makeIncrementer()())")  //1
        
    

#### 7.1.4闭包～捕获多个值

        //分析闭包 捕获单个值
        func makeIncrementer() -> () -> Int {
            var runningTotal = 10
            func incrementer() -> Int {
                runningTotal += 1
                return runningTotal
            }
            return incrementer
        }
        let fn = makeIncrementer()
        
        //闭包结构还原: 闭包底层就是个结构体，里面有两个成员：一个存储函数地址 一个存储捕获堆空间地址的值
        struct ClosureData<Box> {
            // 函数地址
            var ptr: UnsafeRawPointer
            // 存储捕获堆空间地址的值
            var object: UnsafePointer<Box> //捕获单个值，堆空间地址直接就是这个值所在的堆空间
        }
        struct Box<T> {
            var object: HeapObject
            // 捕获变量/常量的值
            var value: T
        }
        struct HeapObject {
            var matedata: UnsafeRawPointer
            var refcount: Int
        }
        
        
        //分析闭包 捕获多个值：
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
        
        //闭包结构还原
        struct ClosureData<MutiValue> {
            /// 函数地址
            var ptr: UnsafeRawPointer
            /// 存储捕获堆空间地址的值
            var object: UnsafePointer<MutiValue> //捕获多个值时存储的堆空间地址会变成一个可以存储很多个捕获值的结构
        }

        struct MutiValue<T1,T2> {
            var object: HeapObject
            var value: UnsafePointer<Box<T1>>
            var value1: UnsafePointer<Box<T2>>
        }

        struct Box<T> {
            var object: HeapObject
            // 捕获变量/常量的值
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
尾随闭包是一个书写在函数括号之后的闭包表达式，函数支持将其作为最后一个参数调用。在使用尾随闭包时，你不用写出它的参数标签

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
逃逸闭包常见于异步操作，比如网络请求或延时调用

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
自动闭包常用于延迟表达式的求值，这意味着直到你调用闭包，代码才会执行

        func print(_ condition: Bool, _ message: String){
            if condition {
                NSLog("debug-print: \(message)")
            }
        }
        func toDo() -> String{
            NSLog("to do")
            return "WG to do"
        }
        
        print(true, toDo())
        //打印结果: 
        to do
        debug-print: WG to do
        
        print(false, toDo())
        //打印结果: 
        to do
#### 发现条件为false,也打印了to do，如果toDo方法是个耗时操作，那么就会比较消耗性能了，为了避免这种情况应该使用自动闭包    

        func print(_ condition: Bool, _ message: ()->String ){
            if condition {
                NSLog("debug-print: \(message())")
            }
        }
        func toDo() -> String{
            NSLog("to do")
            return "WG to do"
        }
        
        //print(<#T##condition: Bool##Bool#>, <#T##message: () -> String##() -> String#>)
        
        print(true, toDo)
        //打印结果: 
        to do
        debug-print: WG to do
        
        print(false, toDo)
        //打印结果: 
        什么都不会打印
        
#### 这种方式极大的降低了资源浪费。如果我们传进的是字符串，如何处理？
#### 可以通过@autoclosure将当前的闭包声明成一个自动闭包，不接收任何参数，返回值是当前内部表达式的值。所以当传入一个String时，
其实就是将String放入一个闭包表达式中，在调用的时候返回

    func print(_ condition: Bool, _ message: @autoclosure ()->String ){
        if condition {
            NSLog("debug-print: \(message())")
        }
    }
    func toDo() -> String{
        NSLog("to do")
        return "WG to do"
    }
    
    //print(<#T##condition: Bool##Bool#>, <#T##message: String##String#>)
    print(true, "wg")
    //打印结果：
    debug-print: wg
    
    print(true, toDo())
    //打印结果：
    to do
    debug-print: wg
    
    print(false, toDo())
    //打印结果: 
    什么都不会打印


#### 总结
1.一个闭包能够从上下文中捕获已经定义的常量/变量，即使其作用域不存在了，闭包仍然能够在其函数体内引用、修改

    (1)每次修改捕获值：本质修改的是堆区中的value值
    (2)每次重新执行当前函数，会重新创建新的内存空间
2.捕获值原理：本质是在堆区开辟内存空间，并将捕获值存储到这个堆空间       
3.闭包是一个引用类型（本质是函数地址传递），底层结构为：闭包 = 函数地址 + 捕获变量的地址            
4.函数也是引用类型（本质是结构体，其中保存了函数的地址）            


## 八. =============== Swift底层原理-协议 ===============
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
* 如果协议要求未被完全满足，在编译时会报错（这句话意思就是协议中属性如果是仅可读，那么实现它的类至少是可读的，且也可以是可写的，只要满足了协议要求就行了）


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
* 协议中可以定义实例方法，也可以定义类型方法

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
* 默认情况写，协议中的方法和属性是必须要实现的，但是也可以通过以下方式实现协议可选

        protocol WGTest {
            func test1()
            func test2()
        }

        //可选协议方式一 @objc + optional
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
#### 我们知道类中的方法是通过虚函数表(Vtable)调度的；结构体中的方法是通过直接拿到函数地址进行调度的；那么协议中的方法如何调用？
如果类或结构体遵守了协议并实现了协议中的方法，那么方法如何调度的？
        
        //类实现协议中的方法
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
#### 如果实例对象的静态类型就是确定的类型(例如下面的test变量就是确定的TestClass类型)，那么这个协议方法通过类中的VTabel函数表进行调度。   
        
        //2.现在把变量test修改成协议类型(静态类型为协议类型)
        var test: BaseProtocol = TestClass()
        test.test(10)
        
#### 如果实例对象的静态类型是协议类型，这个协议方法通过witness_table中对应的协议方法，然后通过协议方法去查找遵守协议的类的VTable进行调度
可见最终还是通过witness_table找到协议中定义的方法，然后通过方法找到类中的VTable函数表进行查找

        //结构体实现协议中的方法
        protocol BaseProtocol {
            func test(_ number: Int)
        }

        struct TestStruct: BaseProtocol {
            var x: Int?
            func test(_ number: Int) {
                x = number
            }
        }
        //1.变量test是确定的类型(静态类型为结构体类型)
        var test: TestStruct = TestStruct()
        test.test(10)
        
#### 如果结构体对象的静态类型就是确定的类型(例如下面的test变量就是确定的TestStruct类型)，那么这个协议方法就是通过函数地址直接调用的

        //2.现在把变量test修改成协议类型(静态类型为协议类型)
        var test: BaseProtocol = TestStruct()
        test.test(10)
        
#### 如果实例对象的静态类型是协议类型，这个协议方法通过witness_table中对应的协议方法，然后通过协议方法去查找遵守协议的结构体
中的方法，调用方式也是通过witness_table找到协议中定义的方法，然后直接获取到函数地址直接调用
        
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



## 九. =============== Swift底层原理-反射Mirror ===============

* 反射：是指可以动态获取类型、成员信息，在运行时可以调用方法、属性等行为的特性。对于一个纯swift类来说，
并不支持直接像OC runtime那样的操作,但是swift标准库依旧提供了反射机制，用来访问成员信息，即Mirror

* 在使⽤OC开发时很少强调其反射概念，因为OC的Runtime要⽐其他语⾔中的反射强⼤的多。但是Swift是⼀⻔类型 
安全的语⾔，不⽀持我们像OC那样直接操作，它的标准库仍然提供了反射机制来让我们访问成员信息
* Mirror是Swift中的反射机制的实现，它的本质是一个结构体
##### https://www.jianshu.com/p/12efe13e3e20 
1.Mirror通过初始化方法返回一个Mirror实例          
2.这个实例对象根据传入对象的类型去对应的Metadata中找到Description          
3.在Description可以获取name也就是属性的名称          
4.通过内存偏移获取到属性值                 
5.还可以通过numFields获取属性的个数             
6.所以支持反射的类型有：类/结构体/枚举/元组/元数据/不透明类型。  

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


## 十. =============== swift构造器 ===============


#### 构造器也就是初始化方法，主要任务是保证新实例在第一次使用前完成正确的初始化，swift的初始化方法和OC初始化方法区别如下 
* OC初始化方法一定有返回值；swift初始化方法无需返回值
* OC初始化方法可以自己命名的；swift所有构造方法名都是init(以参数列表里的参数名和参数类型来分区不同的初始化方法-参数标签)
* OC中所有类都是继承于NSObject的；swift本身没继承任何类的类就叫做基类
* OC中无论你是否自定义了初始化方法，只要是类都有个叫init的初始化方法；swift中只有所有属性都有默认值且没有定义构造器，
系统才会默认给你生成个init()的构造器；一旦自定义了构造器，系统就不会给你提供这个默认的init()方法了
* 类必须要至少有一个指定构造器，可以没有便利构造器
* 便利构造器必须调用本类中的另一个构造器，最终调用到本类的指定构造器
* 便利构造器前面需要添加convenience关键字

#### 属性(特指存储属性，计算属性不需要赋值因为其内部都是通过存储属性计算的)的初值既可以在申明属性时为其设置默认值，也可以在初始化方法内为
其设置默认值,两者的效果是一样的.但是前者较好,因为申明属性和给其赋初值连在一起系统就能推断出属性的类型，而且对构造器来说也能使其更简洁清晰

        class WGA {
            let red, green, blue: Double
            //没有参数标签，调用时系统会自动补上参数标签,参数标签的名称和参数名称一致
            init(white: Double) {
                self.red = white
                self.green = white
                self.blue = white
            }
            //没有参数标签，调用时系统会自动补上参数标签,参数标签的名称和参数名称一致
            init(red: Double, green: Double, blue: Double) {
                self.red = red
                self.green = green
                self.blue = blue
            }
            //用_占位符隐藏参数标签，调用的时候就不会存在参数标签了
            init(_ red: Double, _ green: Double, _ blue: Double) {
                self.red = red
                self.green = green
                self.blue = blue
            }
        }
        
        let a1 = WGA(white: <#T##Double#>)
        let a2 = WGA(red: <#T##Double#>, green: <#T##Double#>, blue: <#T##Double#>)
        let a3 = WGA.init(<#T##red: Double##Double#>, <#T##green: Double##Double#>, <#T##blue: Double##Double#>)
        
        


1. 指定构造器: 标配，每个类至少要有一个指定构造器，可以没有便利构造器；初始化类中的所有属性
2. 便利构造器: 次要、辅助；最终调用本类中的指定构造函数；

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
2. 便利构造器必须调用同类中定义的其它构造器(可以是同类中的便利构造器，也可以是同类的指定构造器)
3. 便利构造器最后必须调用同类中的指定构造器。
4. 一个更方便记忆的方法是：
 
        (1)指定构造器必须总是向上代理
        (2)便利构造器必须总是横向代理 

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/init.jpg)
                   
#### 10.1 指定构造器和便利构造器的继承
#### swift 中的子类默认情况下不会继承父类的构造器，子类去继承父类中的构造函数有条件，遵循规则
1. 如果子类中没有任何构造函数，它会自动继承父类中所有的构造器
2. 如果子类提供了所有父类指定构造函数的实现，那么它会自动继承所有父类的便利构造函数；如果重写了部分父类指定构造器，
那么是不会自动继承便利构造器函数的

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

#### 10.2 可失败构造函数
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

## 十一. =============== swift-MemoryLayout 与class_getInstanceSize 内存地址打印分析 ===============

#### Swift中提供了一个名为 MemoryLayout 的结构体，它用于获取类型或变量在内存中所占用的字节数、对齐方式以及元素的数量等信息。
这个结构体对于了解和优化内存布局非常有用，特别是在需要与底层内存交互、进行性能优化或了解数据结构的情况下
* 为了提高性能，任何的对象都会先进行内存对齐再使用
* size: 指的是变量实际所占用的内存大小
* stride: 是经过内存对齐后创建变量需要开辟的内存空间大小
* alignment: 返回一个类型的内存对齐要求;内存对齐是计算机系统为了提高内存访问效率而采取的一种措施

        //泛型枚举 内含三个计算属性 四个静态方法
        @frozen public enum MemoryLayout<T> {
            //获取类型实际占用的内存大小
            public static var size: Int { get }
            
            //获取类型所需要分配的内存大小
            public static var stride: Int { get }
            
            //获取类型的内存对齐数
            public static var alignment: Int { get }
            
            //获取变量实际占用的内存大小
            public static func size(ofValue value: T) -> Int
            //获取创建变量所需要的分配的内存大小
            public static func stride(ofValue value: T) -> Int
            //获取变量的内存对齐数
            public static func alignment(ofValue value: T) -> Int
            
            //获取结构体中指定成员的偏移量 ⚠️只适用于结构体
            public static func offset(of key: PartialKeyPath<T>) -> Int?
        }
        
        class WGClass {
            var age = 0
            var age1 = 1
            var age2 = 2
        }
        
        var cls = WGClass()
        NSLog("WGClass类型:size----\(MemoryLayout<WGClass>.size)")
        NSLog("WGClass类型:stride----\(MemoryLayout<WGClass>.stride)")
        NSLog("WGClass类型:alignment----\(MemoryLayout<WGClass>.alignment)")
        NSLog("cls变量:size----\(MemoryLayout.size(ofValue: cls))")
        NSLog("cls变量:stride----\(MemoryLayout.stride(ofValue: cls))")
        NSLog("cls变量:alignment----\(MemoryLayout.alignment(ofValue: cls))")
        
        //打印结果
        WGClass类型:size----8
        WGClass类型:stride----8
        WGClass类型:alignment----8
        cls变量:size----8
        cls变量:stride----8
        cls变量:alignment----8
#### Why? 类对象不是至少占用16字节大小吗(8字节元数据+8字节引用计数)? 为什么打印的是8字节？
#### 实际上我们使用错了方法，MemoryLayout方法是用来查询类型的内存布局信息，注意是类型，比如Int、String、Double、struct等
要想获取类内存大小，我们应该使用class_getInstanceSize方法: 获取一个类的实例所占用的内存大小

        //MemoryLayout主要就是用来获取类型的内存情况
        NSLog("Int类型:size----\(MemoryLayout<Int>.size)")
        NSLog("Int类型:stride----\(MemoryLayout<Int>.stride)")
        NSLog("Int类型:alignment----\(MemoryLayout<Int>.alignment)")
      
        NSLog("String类型:size----\(MemoryLayout<String>.size)")
        NSLog("String类型:stride----\(MemoryLayout<String>.stride)")
        NSLog("String类型:alignment----\(MemoryLayout<String>.alignment)")
        //打印结果
        Int类型:size----8
        Int类型:stride----8
        Int类型:alignment----8
        String类型:size----16
        String类型:stride----16
        String类型:alignment----8
        
        
        //class_getInstanceSize获取一个类的实例所占用的内存大小
        //class_getInstanceSize(cls: AnyClass?)  
        //typealias AnyClass = AnyObject.Type  
        //type(of: cls): 获取实例对象cls的类
        
        NSLog("----\(class_getInstanceSize(type(of: cls)))字节")
        //打印结果
        ----40字节
        
        (lldb) po cls
        <WGClass: 0x303331ad0>     
        (lldb) x/8gx 0x303331ad0    x:打印  g:8个字节为一段 x:十六进制 (打印8段,8个字节为一段的十六进制内存地址) 
        0x303331ad0: 0x0000000104033838 0x0000000200000003
        0x303331ae0: 0x0000000000000000 0x0000000000000001
        0x303331af0: 0x0000000000000002 0x0000000000000000
        0x303331b00: 0x0000b6a21a101b00 0x000000000000008d
        
        第1个8字节: 存储元数据metaData
        第2个8字节: 存储引用计数refCounts
        第3个8字节: 存储存储属性age的值
        第4个8字节: 存储存储属性age1的值
        第5个8字节: 存储存储属性age2的值
#### 因为swift类本身占用16字节 + 三个int成员变量的内存大小24(3*8) 所以等于40个字节          

        struct WGStruct {
            var age = 0
            var age1 = 1
            var age2 = 2
        }
        var str = WGStruct()
        NSLog("WGStruct类型:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct类型:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct类型:alignment----\(MemoryLayout<WGStruct>.alignment)")
        
        NSLog("str实例:size----\(MemoryLayout.size(ofValue: str))")
        NSLog("str实例:stride----\(MemoryLayout.stride(ofValue: str))")
        NSLog("str实例:alignment----\(MemoryLayout.alignment(ofValue: str))")
        
        //打印结果: 
        WGStruct类型:size----24
        WGStruct类型:stride----24
        WGStruct类型:alignment----8
        str实例:size----24
        str实例:stride----24
        str实例:alignment----8
#### 发现MemoryLayout方法可以用来获取结构体、枚举的内存空间占用情况；而class_getInstanceSize方法是获取类的内存占用情况

        struct WGStruct {
            var age = 1
            var age1 = 3
        }
        class WGClass {
            var age = 1
            var age1 = 3
        }
        func address(of object: UnsafeRawPointer) {
            let addr = Int(bitPattern: object)
            print(String(format: "%p", addr))
        }
        
        var str = WGStruct()
        var cls = WGClass()
        
        NSLog("WGStruct类型:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct类型:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct类型:alignment----\(MemoryLayout<WGStruct>.alignment)")
        //打印结果:
        WGStruct类型:size----16
        WGStruct类型:stride----16
        WGStruct类型:alignment----8
        
        
#### 11.1 如何打印class类对象的变量、struct变量的内存地址？      

        struct WGStruct {
            var age = 1
            var age1 = 3
        }
        class WGClass {
            var age = 1
            var age1 = 3
        }
        func address(of object: UnsafeRawPointer) {
            let addr = Int(bitPattern: object)
            print(String(format: "%p", addr))
        }

        var cls = WGClass()
        NSLog("方式一: 类实例cls地址/指针: \(Unmanaged.passUnretained(cls).toOpaque())")
        NSLog("方式二: 类实例cls地址/指针: \(ObjectIdentifier(cls))")
        
        var str = WGStruct()
        withUnsafePointer(to: &str) { point in
            NSLog("11111结构体变量str地址: \(point)")
        }
        address(of: &str)
        
        NSLog("WGStruct类型:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct类型:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct类型:alignment----\(MemoryLayout<WGStruct>.alignment)")
        NSLog("WGClass类实例占用内存大小:\(class_getInstanceSize(type(of: cls)))")
        
        //打印结果:
        0x16bceea28
        方式一: 类实例cls地址/指针: 0x0000000300615d00
        方式二: 类实例cls地址/指针: ObjectIdentifier(0x0000000300615d00)
        11111结构体变量str地址: 0x000000016bceea28
        WGStruct类型:size----16
        WGStruct类型:stride----16
        WGStruct类型:alignment----8
        WGClass类实例占用内存大小:32
        
        //WGClass类内存信息 占32个字节
        (lldb) po cls
        <WGClass: 0x300615d00>
        (lldb) x/8gx 0x300615d00
        0x300615d00: 0x0000000105c3f8a0 0x0000000000000003   //元数据指针:8字节 + 引用计数:8字节
        0x300615d10: 0x0000000000000001 0x0000000000000003   //属性age=1的值:8字节 + 属性age1=3的值:8字节
        0x300615d20: 0x01000001edb5f8e1 0x0000000000013680
        0x300615d30: 0x0000000109534000 0x00000001ef3ce3d8
    
        //WGStruct结构体内存信息 占16个字节
        (lldb) po str
        ▿ WGStruct
          - age : 1
          - age1 : 3
        (lldb) x/8gx 0x000000016bceea28
        0x16bceea28: 0x0000000000000001 0x0000000000000003  //属性age=1的值:8字节 + 属性age1=3的值:8字节
        0x16bceea38: 0x0000000300615d00 0x300000000000004a
        0x16bceea48: 0x0000000303478900 0x0000000300615d00
        0x16bceea58: 0x3000000000000038 0x0000000303478900
* 获取打印类对象变量的地址采用两种方式   
 
        1. ObjectIdentifier(x: AnyObject)
        2. Unmanaged.passUnretained(cls).toOpaque()
* 获取打印结构体类型变量的地址采用两种方式：推荐使用第一种方式

        1.withUnsafePointer(to: &str) { point in
            NSLog("结构体变量str地址: \(point)")
        }
        2.通过定义方法来获取
        func address(of object: UnsafeRawPointer) {
            let addr = Int(bitPattern: object)
            print(String(format: "%p", addr))
        }
#### 11.2 分析enum枚举内存信息

        enum WGEnum {
            case A
            case B
        }
        enum WGEnum1 : String {
            case A
            case B
        }

        enum WGEnum2 {
            case A(name: String)  //16字节
            case B(sex: Bool)     //1字节
        }
        
        enum WGEnum3 {
            case A
        }

        var en = WGEnum.A
        var en1 = WGEnum1.A
        var en2 = WGEnum2.A(name: "1")
        withUnsafePointer(to: &en) { point in
            NSLog("WGEnum无原始值变量地址:\(point)")
        }
        withUnsafePointer(to: &en1) { point in
            NSLog("WGEnum1有原始值变量地址:\(point)")
        }
        withUnsafePointer(to: &en2) { point in
            NSLog("WGEnum2有关联值变量地址:\(point)")
        }
        NSLog("WGEnum无原始值类型:size----\(MemoryLayout<WGEnum>.size)")
        NSLog("WGEnum无原始值类型:stride----\(MemoryLayout<WGEnum>.stride)")
        NSLog("WGEnum无原始值类型:alignment----\(MemoryLayout<WGEnum>.alignment)")
        
        NSLog("WGEnum1有原始值类型:size----\(MemoryLayout<WGEnum1>.size)")
        NSLog("WGEnum1有原始值类型:stride----\(MemoryLayout<WGEnum1>.stride)")
        NSLog("WGEnum1有原始值类型:alignment----\(MemoryLayout<WGEnum1>.alignment)")
        
        NSLog("WGEnum2有关联值类型:size----\(MemoryLayout<WGEnum2>.size)")
        NSLog("WGEnum2有关联值类型:stride----\(MemoryLayout<WGEnum2>.stride)")
        NSLog("WGEnum2有关联值类型:alignment----\(MemoryLayout<WGEnum2>.alignment)")
        
        NSLog("WGEnum3:size----\(MemoryLayout<WGEnum3>.size)")
        NSLog("WGEnum3:stride----\(MemoryLayout<WGEnum3>.stride)")
        NSLog("WGEnum3:alignment----\(MemoryLayout<WGEnum3>.alignment)")

        WGEnum无原始值类型:size----1
        WGEnum无原始值类型:stride----1
        WGEnum无原始值类型:alignment----1
        WGEnum1有原始值类型:size----1
        WGEnum1有原始值类型:stride----1
        WGEnum1有原始值类型:alignment----1
        WGEnum2有关联值类型:size----17
        WGEnum2有关联值类型:stride----24
        WGEnum2有关联值类型:alignment----8
        WGEnum3:size----0
        WGEnum3:stride----1
        WGEnum3:alignment----1
        
        WGEnum无原始值变量地址:0x000000016bbf6a97
        WGEnum1有原始值变量地址:0x000000016bbf6a96
        WGEnum2有关联值变量地址:0x000000016bbf6a80
* enum枚举原始值不占用枚举的内存空间
* enum枚举的关联值占用枚举的内存空间(内存大小 = 枚举成员中关联值占用内存最大的 + 1字节 条件是最大关联值内存 > 1个字节)
* 获取enum枚举变量内存地址用方法 withUnsafePointer(to: &st)
* 获取enum枚举变量内存大小用方法 MemoryLayout 中的size/stride/alignment

#### 11.3 分析Struct结构体内存信息     

        struct WGStruct {
            var age = 1
            var age1 = 3
            var age2 = 8
        }
        var st = WGStruct()
        withUnsafePointer(to: &st) { point in
            NSLog("WGStruct变量地址:\(point)")
        }
        NSLog("WGStruct:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct:alignment----\(MemoryLayout<WGStruct>.alignment)")
        
        //打印结果: 
        WGStruct变量地址:0x000000016b0eaa80
        WGStruct:size----24
        WGStruct:stride----24
        WGStruct:alignment----8
        
        (lldb) x/8gx 0x000000016b0eaa80
        0x16b0eaa80: 0x0000000000000001 0x0000000000000003  //age=1 age1 = 3
        0x16b0eaa90: 0x0000000000000008 0x0000000301811ef0  //age3 = 8
        0x16b0eaaa0: 0x0000000000000000 0x00000001094767c0
        0x16b0eaab0: 0x0000000000000000 0x0000000000000001
* 结构体内存大小是由各个成员变量内存相加组成的
* 成员变量的值存储在结构体变量的地址中
* 为了节省内存空间，将成员变量占用内存大的成员写在最前面，利用内存对齐法则可以控制变量内存大小(控制分配内存大小stride才是目标)
* 获取结构体变量内存地址用方法 withUnsafePointer(to: &st)
* 获取结构体变量内存大小用方法 MemoryLayout 中的size/stride/alignment

        struct WGStruct {
            var sex: Bool = false  //1字节 内存对齐原则分配8字节
            var name = ""          //16字节
            var love = true        //1字节 内存对齐原则分配8字节 8字节
        }
        var st = WGStruct()
        NSLog("WGStruct:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct:alignment----\(MemoryLayout<WGStruct>.alignment)")
        // 打印结果: 
        WGStruct:size----25
        WGStruct:stride----32
        WGStruct:alignment----8
        
        调整下成员位置
        struct WGStruct {
            var name = ""          //16字节
            var sex: Bool = false  //1字节 内存对齐原则分配8字节，只用一位来存储
            var love = true        //1字节 
        }
        var st = WGStruct()
        NSLog("WGStruct:size----\(MemoryLayout<WGStruct>.size)")
        NSLog("WGStruct:stride----\(MemoryLayout<WGStruct>.stride)")
        NSLog("WGStruct:alignment----\(MemoryLayout<WGStruct>.alignment)")
        // 打印结果: 
        WGStruct:size----18
        WGStruct:stride----24
        WGStruct:alignment----8
        
#### 11.4 分析Class类内存信息

        class WGClass {
            var age = 1
            var age1 = 3
            var age2 = 8
        }
        var cls = WGClass()
        NSLog("WGClass变量地址:\(Unmanaged.passUnretained(cls).toOpaque())")
        NSLog("WGClass变量地址:\(ObjectIdentifier(cls))")
        NSLog("WGClass:size----\(class_getInstanceSize(type(of: cls)))")

        //打印结果:
        WGClass变量地址:0x0000000300a13b10
        WGClass变量地址:ObjectIdentifier(0x0000000300a13b10)
        WGClass:size----40

        (lldb) x/8gx 0x0000000300a13b10
        0x300a13b10: 0x00000001064638e0 0x0000000000000003  //元数据指针  引用计数
        0x300a13b20: 0x0000000000000001 0x0000000000000003  //age=1的值  age1=3的值
        0x300a13b30: 0x0000000000000008 0x0000000000000000  //age2=3的值
        0x300a13b40: 0x01000001ffcef6a9 0x0000000000000000
   
* 获取swift中类class的变量的内存地址用方法 Unmanaged.passUnretained / ObjectIdentifier(cls)
* 获取swift中类class的变量的内存大小用方法 class_getInstanceSize
* ⚠️swift中类的成员变量的值是存储在类变量的内存空间的，而不是存储在元数据中的
