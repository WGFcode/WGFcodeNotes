## Runtime
#### Objective-C是一门动态性比较强的编程语言,跟C、C++等语言有着很大的不同;C/C++语言流程是:编写代码->编译链接->运行,而OC可以办到在程序运行的过程中可以修改之前编译的东西.Objective-C的动态性是由RunTime API来支撑的,Runtime顾名思义就是运行时,RunTime API提供的接口基本都是C语言的,源码由C/C++/汇编语言编写


### 1. isa详解
#### 之前的学习中我们知道如下结论,在arm64架构之前,isa就是一个普通的指针,存储着Class、Meta_Class对象的内存地址,而从arm64位架构开始,对isa进行了优化,变成了一个共用体(union)结构,还使用位域来存储更多的信息
    实例对象                               
    instance  &ISA_MASK                              
      isa--------------->类对象                   
    其他成员变量           class      &ISA_MASK  
    superclass            isa--------------------->元类对象  &ISA_MASK
                        superclass                  isa----------------->基元类对象(isa----->它本身)    
                   属性/对象方法/协议/成员变量         superclass
                                                    类方法
    # if __arm64__
    #   define ISA_MASK   0x0000000ffffffff8ULL
    # elif __x86_64__
    #   define ISA_MASK   0x00007ffffffffff8ULL
    # endif
    MASK: 掩码,一般用来按位与(&)运算的
    按位 & 可以用来取出特定的位

#### 1.1 isa优化后的内部源码刨析(简化)
    struct objc_object {
        isa_t isa;
    }
    
    union isa_t {  //共用体
        Class cls;
        uintptr_t bits;  //存放所有的数据
        struct {  //利用了位域技术,这个结构体纯粹就是为了增加可读性,其它没什么作用
            uintptr_t nonpointer        : 1;  //占1位 最低的地址(0b0000 0000 最后一位代表这个值)
            uintptr_t has_assoc         : 1;  
            uintptr_t has_cxx_dtor      : 1;
            uintptr_t shiftcls          : 33; //代表类/元类对象的地址
            uintptr_t magic             : 6;
            uintptr_t weakly_referenced : 1;
            uintptr_t deallocating      : 1;
            uintptr_t has_sidetable_rc  : 1;
            uintptr_t extra_rc          : 19;
        };
        //结构体中位的总和是64位,即8个字节,虽然优化后存储了大量的信息,但是利用共用体和位域技术可以共用一块内存
    }
1.  nonpointer
* 若是0: 代表普通的指针,存储着class、Meta-class对象的内存地址,即没有经过优化的isa指针
* 若是1: 代表优化过,使用位域存储更多的信息
2. has_assoc: 是否设置过关联对象,如果没有,释放时更快
3. has_cxx_dtor: 是否有C++的析构函数(.cxx_destruct),如果没有,释放时更快
4. shiftcls: 存储着Class、Meta-Class对象的内存地址信息
5. magic: 用于在调试时分辨对象是否未完成初始化
6. weakly_referenced: 是否有被弱引用指向过,如果没有,释放时会更快
7. deallocating: 对象是否正在释放
8. has_sidetable_rc:
* 引用计数器是否过大无法存储在isa中,如果是1,那么引用计数器就存储在一个叫SideTable的类的属性中
9. extra_rc: 里面存储的值是引用计数器减1

    
#### isa优化后,除了存放class、Meta-class的地址,还存放更多的其他信息, 通过上面的源代码,我们知道有33位存储的是class、Meta-class的地址,所以isa现在需要按位与&才能得到class、Meta-class的真实地址

#### 1.2 扩展知识: 
    #define WGTallMask (1<<0)       1向左移动0位   0000 0001   <<0   0000 0001
    #define WGRichMask (1<<1)       1向左移动1位   0000 0001   <<1   0000 0010
    #define WGHandsomeMask (1<<2)   1向左移动2位   0000 0001   <<2   0000 0100

    //结构体是支持位域技术的;下面的结构体只占1个字节,拿出来三位用来存储对应的值,
    struce {
        char tall : 1;     //只占一位(不用关心char类型,只看后面的1)   
        char rich : 1;     //只占一位
        char handsome : 1; //只占一位
        //0b0000 0000 最后一位代表tall,倒数第二位代表rich,倒数第三位代表handsome
    } _tallRichHandsome
    
#### 什么是共用体union?
    结构体中的成员是独立存在,每个成员占4个字节      共用体:大家共用一块内存空间 
    struct Date {                            union Data {
        int year;  //4个字节                      int year;  //4个字节  
        int month; //4个字节                      int month; //4个字节
        int day;   //4个字节                      int day;   //4个字节
    }                                        }
        
    ---------0x0000                          ---------0x0000
       year  -->4个字节                       存year|month|day -->4个字节
    ---------0x0004                          ---------0x0004
       month--->4个字节
    ---------0x0008
       day----->4个字节
    ---------0x000c
    
### 2.  Class结构-源码解读(简化)
        struct objc_class {
            Class isa;
            Class superclass;
            cache_t cache;          //方法缓存
            class_data_bits_t bits; //用于获取具体的类信息
        }
        
        #define FAST_DATA_MASK          0x00007ffffffffff8UL
        bits & FAST_DATA_MASK ------> class_rw_t
        
        struct class_rw_t {
            uint32_t flags;
            uint32_t version;
            const class_ro_t *ro;
            method_array_t methods;       //方法列表(类+分类)、二维数组、可读可写
            property_array_t properties;  //属性列表(类+分类)、二维数组、可读可写
            protocol_array_t protocols;   //属性协议(类+分类)、二维数组、可读可写
            Class firstSubclass;
            Class nextSiblingClass;
            char *demangledName;
        }
        
#### 例如:二维数组的方法列表method_array_t methods 
        元素1             元素2           元素3           元素4           元素... 
        method_list_t    method_list_t   method_list_t  method_list_t   ...
        
        method_list_t一维数组
         元素1        元素2       元素3       元素4     元素... 
        method_t    method_t   method_t   method_t    ...
        
        struct method_t {
            SEL name;
            const char *types;
            IMP imp;
        }
#### class_rw_t里面的methods、properties、protocols是二维数组,是可读可写的,包含了类的初始内容、分类的内容,为什么要设计成二维数组? 原因就是可以动态往里面添加或删除方法,那么设计成一维数组不是一样可以吗?原因就是分类的方法都是独立的,不同的分类可能存放在数组的不同位置上,而一维数组操作不太方便; 
#### 类的所有方法、协议、属性、成员变量等一开始都是放在class_ro_t结构体中的,程序运行起来后,会将分类的信息和类原来的信息(class_ro_t)进行合并在一起,存放到class_rw_t结构体中
        //编译期已经确定的内容
        struct class_ro_t {
            uint32_t flags;
            uint32_t instanceStart;
            uint32_t instanceSize;  //instance对象占用的内存空间
        #ifdef __LP64__
            uint32_t reserved;
        #endif
            const uint8_t * ivarLayout;
            const char * name;      //类名
            method_list_t * baseMethodList;   //一维数组
            protocol_list_t * baseProtocols;  //一维数组
            const ivar_list_t * ivars;        //成员变量列表-一维数组
            const uint8_t * weakIvarLayout;
            property_list_t *baseProperties;  //一维数组
        }
#### 例如 方法列表一维数组method_list_t * baseMethodList
        method_list_t一维数组
         元素1        元素2       元素3       元素4     元素... 
        method_t    method_t   method_t   method_t    ...

        struct method_t {
            SEL name;
            const char *types;
            IMP imp;
        }
#### class_ro_t里面的baseMethodList、baseProtocols、ivars、baseProperties是一维数组,是只读的,包含了类的初始内容


























