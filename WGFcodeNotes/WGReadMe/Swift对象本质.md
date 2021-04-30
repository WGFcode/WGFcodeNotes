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
        HeapMetadata const *__ptrauth_objc_isa_pointer metadata;  //指向元数据的指针-8字节(可以理解为OC中类对象和元类对象)
        SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;                        //引用计数-8字节
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
        StoredPointer Kind;  //kind属性，就是之前传入的Inprocess，主要用于区分是哪种类型的元数据
        // 若kind > 0x7FF(LastEnumeratedMetadataKind) 则kind为MetadataKind::Class，否则返回MetadataKind(kind)
        MetadataKind getKind() const {
            return getEnumeratedMetadataKind(Kind);
        }
        // 通过去匹配kind，返回值是TargetClassMetadata类型，如果有则获取它的类对象，若类型不是class,则返回nil
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


### 2. swift方法调用
#### swift中方法调用主要分两类
1. 直接调用: 直接调用函数地址
2. 查找调用: 函数都按照顺序存储在vtable中，需要偏移
#### 2.1 swift中方法调用情况分析
* extension扩展中的方法。swift中，extension中方法是不能被继承的，并不在vtable中，调用方式是直接调用;
* final关键字。final修饰的方法和属性,也不会写入vtable中，子类不可重写，只可以调用，调用方式是直接调用;
* dynamic关键字。标记为dynamic的变量/函数会隐式的加上@objc关键字，它会使用OC的runtime机制,Swift 为了追求性能，Swift 类型的成员或者方法在编译时就已经决定，而运行时便不再需要经过一次查找,想要实现OC的方法交换或者kvo都需要要添加dynamic关键字











        声明位置        @Objc    dynamic    调用方式
        Struct          否        否        直接调用
        Class           否        否       V-Table 调用
        Extension       否        否        直接调用
        Extension       是        否      objc_msgSend
        Class           是        是      objc_msgSend










