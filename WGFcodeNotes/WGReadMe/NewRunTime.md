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
    
### 2. 源码解读(简化)
#### 2.1 Class结构
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


#### 2.2 method_t结构
#### method_t是对方法/函数的封装
    struct method_t {
        SEL name;            //函数名(方法名)
        const char *types;   //编码(返回值类型、参数类型)
        IMP imp;             //指向函数的指针(函数地址)
    }
* IMP代表函数的具体实现
* SEL代表方法/函数名,一般叫做选择器,底层结构跟char *类似
1. 可以通过@selector()和sel_registerName()获得
2. 可以通过sel_getName()和NSStringFromSelector()转成字符串
3. 不同类中相同名字的方法,所对应的方法选择器是相同的
* types包含了函数返回值、参数编码的字符串

#### Type Encoding: iOS中提供了一个叫做@encode的指令,可以将具体的类型表示成字符串编码. 可以在苹果官网上搜索Type Encoding找到对应的表

        - (void)viewDidLoad {
            [super viewDidLoad];
            NSLog(@"-----%s",@encode(int));
            NSLog(@"-----%s",@encode(id));
            NSLog(@"-----%s",@encode(SEL));
        }
        打印结果: -----i
                -----@
                -----:
    
    //这个方法的types是(i24@0:8i16f20)
    // i: 返回值类型  @是第一个参数id类型就是消息接收者  :是SEL  i表示int类型 f表示float类型
    // 24代表所有参数的字节数(id-8字节 SEL-8字节 int-4字节 float-4字节)
    // @代表第一个参数id,0表示这个参数从哪里开始,8代表参数:(SEL)开始的字节数  16代表参数i开始的字节数 20代表f开始的字节数
    -(int)test:(int)age height:(float)height;

#### 2.3 cache_t方法缓存结构
#### Class内部结构中有个方法缓存(cache_t),用**散列表**(也叫哈希表)来缓存曾经调用过的方法,可以提高方法的查找速度
    struct objc_class {
        Class isa;
        Class superclass;
        cache_t cache;          //方法缓存
        class_data_bits_t bits; //用于获取具体的类信息
    }
    
    struct cache_t {
        struct bucket_t *_buckets;  //数组,其实就是个散列表,里面存放的是bucket_t
        mask_t _mask;               //散列表长度-1(数组元素个数-1)
        mask_t _occupied;           //已经缓存的方法数量
    }
    为什么_mask的长度是散列表长度-1? 因为如果等于散列表长度,而@selector(test)&_mask的值要小于等于散列表的下标
    而最大的下标是散列表长度-1
    
    struct bucket_t {               //散列表
        cache_key_t _key;           //SEL作为Key
        IMP _imp;                   //函数的内存地址
    }
#### 再次调用[person test]方法时,先通过isa找到cache_t cache,然后在方法缓存中对比_key,如果_key相同,那么就返回函数地址imp,直接调用即可
    例如: [person test]    //_key = @selector(test)  _imp = test的地址

#### 2.3.1 cache_t方法缓存的存取过程: 散列表核心(f(key)==index)
    数组下标index  元素    
       0        NULL
       1        NULL
       2        NULL
       3        bucket_t(_key,_imp)
       4        ......
#### 将方法放入缓存的过程: 
1. 首先通过@selector(test) & _mask获取到数组下标index,然后将方法放入对应的下标中,其它没有元素的下标都是NULL,这种方式就是牺牲了内存空间,而换来了查找的高效率,即空间换时间   
2. 如果发现& _mask后获取到的下标index中已经有元素,会将下标index-1进行存放,如果index-1也有元素了,继续让index-1,如果index减到0了,仍然没有地方村,那么就让下标等于_mask,继续进行找NULL地方存放
3. 如果仍然没有找到NULL位置来存放,那么就进行扩容,扩容的容量是之前散列表长度的2倍,如果发生扩容,会将之前的散列表中的缓存内容全部清空,重新设置新的_mask
    
        数组下标index  元素    
           0        bucket_t(_key,_imp)
           1        bucket_t(_key,_imp)
           2        bucket_t(_key,_imp)
           3        bucket_t(_key,_imp)
           4        ......
#### 从方法缓存列表中查找方法过程: 
1. 首先通过@selector(test) & _mask获取到数组下标,然后找到对应的下标元素,对比@selector(test)和元素中的_key是否相同,若相同,则取出对应的_imp,进行方法调用; 若不相同,则下标index-1,继续去判断index-1下标中的元素的_key是否相同,若仍然不相同,则继续让下标index-1去找; 若减到0了仍不相同,则让index等于_mask,即去找散列表中的最后一位元素继续进行对比

#### 注意: 在arm64架构下index是-1进行操作的,如果是X86/arm/i386架构,则是i+1进行操作的

#### 2.3.2 查找方法过程
1. 首先通过isa指针找到方法缓存,如果方法缓存有就调用
2. 若方法缓存中没有,则继续通过bits & FAST_DATA_MASK找到结构体class_rw_t,在结构体class_rw_t中的方法列表methods中继续查找,找到了就调用,并将该方法写入到方法缓存列表中
3. 若方法列表中没有,则通过superClass找到父类的类对象,在父类的类对象的方法缓存中查找,若找到则调用,并且会将父类的类对象中的方法缓存列表中的方法写入到自己类的方法缓存列表中
4. 若父类的方法缓存列表中没有,则继续找父类的类对象的结构体class_rw_t中的方法列表,若找到则调用,并且会将这个方法写入到自己类的方法缓存列表中
5. 若在父类的方法列表中仍然没有,则继续通过superClass找到父类的父类的类对象继续查找,依次类推
6. 如果仍然没有找到,并且也没有做其它处理,就走消息转发和动态方法解析渠道
7. 如果这些都没有处理,则会报经典的错误: unrecognized selector sent to instance


### 3 objc_msgSend函数
#### OC中的方法调用,其实都是转换为objc_msgSend函数的调用,objc_msgSend(消息接收者,消息名称);objc_msgSend的执行流程可以分为三大阶段
1. 消息发送阶段
2. 动态方法解析
3. 消息转发

        //对象方法
        Person *person = [[Person alloc]init];
        [person test];
        等价于
        objc_msgSend(person,sel_registerName("test"))
        
        //类方法
        [Person initialize];
        等价于
        objc_msgSend([Person class],sel_registerName("initialize"))

### 3.1 消息发送阶段
                                                
    (1)receiver是否为nil---否--->(2)从receive Class的cache中查找方法---找到--->调用方法结束查询
         是                         没有找到
         退出         (3)从receive Class的class_rw_t中查找方法---找到--->调用方法结束查询
                                      |                           并将方法缓存到receive的cache中
                                      |
                                   没有找到
                         (4)从superClass的cache中查找方法---找到--->调用方法结束查询
                                      |                       并将方法缓存到receive的cache中
                                      |
                                    没有找到
                        (5)从superClass的class_rw_t中查找方法---找到--->调用方法结束查询
                                      |                           并将方法缓存到receive的cache中
                                      |
                                    没有找到
                            (6)上层是否还有superClass---否--->动态方法解析阶段
                                      |
                                      |
                                      是
                                继续(4)步骤
                                    
1. 如何从class_rw_t中查找方法: 已经排序的,二分查找;没有排序的,遍历查找
2. receive通过isa指针找到receiveClass
3. receiveClass通过superclass指针找到superClass
                                      
                                      

### 3.2 动态方法解析阶段

### 3.3 消息转发阶段



















