## RunTime
#### 我们知道OC是动态性的编程语言，所谓的动态性就是将程序的一些决定性工作从编译期推迟到运行时。由于OC的运行时特性，所以OC不仅需要依赖编辑器还需要依赖运行时环境，在运行时系统中动态的创建类和对象、消息传递和转发等。而RunTime就是OC语言面向对象和动态机制的基石，RunTime是一套比较底层的纯C语言的API。高级编程语言想成为可执行文件，必须先编译为汇编语言再汇编为机器语言，而OC语言不能直接编译为汇编语言，而是先编译为C语言，然后再编辑为汇编语言和机器语言，而OC到C语言的过渡就是RunTime来完成的。

### 如何查看OC的底层代码？
#### 我们使用**clang**来查看OC的源码实现，**clang**是由Apple主导编写，基于LLVM的C/C++/Objective-C编译器.LLVM 设计思想分为前端/优化器/后端，这里的前端实际上指的就是**clang**，整个流程可以简单概括为**clang**对代码进行处理形成中间层作为输出，LLVM把CLang的输出作为输入生成机器码。接下来我们重点介绍使用**clang**编译器来将OC代码编译为C语言代码，并生成一个.cpp的C++文件
* cd 到当前文件项目的需要转化的文件目录下 
* clang -rewrite-objc WGTestModel.m 
* 在需要转化的文件目录下，会生成对应的WGTestModel.cpp文件

### 1.源码分析
        //.h文件
        @interface WGTestModel : NSObject

        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) int age;

        +(void)run;
        -(void)eat;
        -(void)sleepWithTime:(NSTimeInterval)time;

        @end

        //.m文件
        @interface WGTestModel()
        {
            NSString *_parents;
            BOOL _isSex;
        }

        @end

        @implementation WGTestModel

        +(void)run {
            NSLog(@"开始跑步了");
        }
        -(void)eat {
            NSLog(@"开始吃饭了");
        }
        -(void)sleepWithTime:(NSTimeInterval)time {
            NSLog(@"我睡了%f分钟了",time);
        }
        -(void)love {
            NSLog(@"我喜欢你");
        }

        @end
#### 打开生成的WGTestModel.cpp文件，全局查找到WGTestModel对应的地方，以下是摘取的cpp文件的内容
    typedef struct objc_object WGTestModel;  
    struct objc_object {
        Class _Nonnull isa;         指向自己所属的类
    };
    
    通过对象的isa指针找到对应的类
    typedef struct objc_class *Class;
    struct objc_class : objc_object {
        // Class ISA;
        Class superclass;           指向当前类的父类
        cache_t cache;              用于方法缓存来加速方法的调用
        class_data_bits_t bits;     存储类的方法、属性、遵循的协议等信息的地方
        class_rw_t *data() {        存储方法、属性、协议列表等信息；rw可读可写
            return bits.data();
        }
        ...
    }
    
    通过class_data_bits_t和FAST_DATA_MASK找到class_rw_t
    class_rw_t* data() {
        return (class_rw_t *)(bits & FAST_DATA_MASK);
    }
    
    存储方法、属性、协议列表等信息
    struct class_rw_t {
        const class_ro_t *ro;        存储了当前类在编译期就已经确定的属性、方法以及遵循的协议
        //下面三个都是二维数组,这三个二位数组中的数据有一部分是从class_ro_t中合并过来的
        method_array_t methods;      方法列表(类对象存放对象方法，元类对象存放类方法)
        property_array_t properties; 属性列表
        protocol_array_t protocols;  协议列表
        ...
    }
    
    在编译期就已经确定的内容，主要用来存储成员变量
    struct class_ro_t {
        uint32_t instanceSize;            实例对象所占用的内存大小
        method_list_t * baseMethodList;   方法列表
        protocol_list_t * baseProtocols;  协议列表
        const ivar_list_t * ivars;        成员变量列表
        property_list_t *baseProperties;  属性列表
    };
    
1. WGTestModel是个结构体对象：每个OC对象都是个结构体对象，在结构体中有一个isa指针，这个指针指向自己所属的类即WGTestModel类；类被定义为结构体objc_class，objc_class结构体继承自objc_object，所以类也是对象;

        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_name;
        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_age;
##### OC中声明的属性，系统会自动为其生成一个带下划线的成员变量，所以我们在声明成员变量的时候规范性的以_XXX的格式进行声明    

