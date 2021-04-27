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















### 1.3 swift对象和OC对象区别
1. OC中的实例对象本质是结构体，通过底层的objc_object模版创建，类是继承自objc_class
2. Swift中的实例对象本质是结构体，类型是HeapObject，比OC多了一个refCounts
3. OC中的方法列表存储在objc_class结构体(class_rw_t)的methodList中
4. Swift中的方法存储在metadata元数据中
5. OC中的ARC是存储在全局的sidetable中
6. Swift中的引用计数是对象内部由一个refCounts属性存储













