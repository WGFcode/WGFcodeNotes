## Runtime
### 面试题
1. 讲一下OC的消息机制
* OC中的方法调用其实都是转成了objc_msgSend函数的调用,给receiver(方法调用者)发送一条消息(selector方法名)
* objc_msgSend底层有3大阶段: 消息发送阶段(在当前类、父类中查找)、动态方法解析、消息转发阶段
2. 消息转发机制流程
* 讲解清楚调用的方法和顺序即可
3. 什么是Runtime? 平时项目中有用过么?
* OC是一门动态性比较强的编程语言,允许很多操作推迟到程序运行时再调用
* OC动态性就是由Runtime来支撑和实现的,Runtime是一套C语言的API,封装了很多动态性相关的函数
* 平台编写的OC代码,底层都是转换成了Runtime API进行调用
* 利用关联对象(AssociatedObject)给分类添加属性
* 遍历类的所有成员变量(修改textField的占位文字颜色、字典转模型、自动归档解档)
* 交换方法实现(交换系统的方法)
* 利用消息转发机制解决方法找不到的异常问题
* Runtime API中只要你用到的方法都可以大体说一下
* 场景【OC消息机制/方法交换(可以在不修改原有方法的情况下，给系统方法添加额外的功能)/动态修改类和对象的行为/字典转模型(通过runtime获取类的属性、方法、成员变量等)】
4. @dynamic作用
* 告诉编译器不用自动生成getter/setter的实现，不要自动生成对应的成员变量,等到运行时再添加方法实现

### RunTime源码阅读可以通过全局搜索 WGRunTimeSourceCode 源码阅读 来快速查阅
#### Objective-C是一门动态性比较强的编程语言,跟C、C++等语言有着很大的不同;C/C++语言流程是:编写代码->编译链接->运行,而OC可以做到在程序运行的过程中可以修改之前编译的东西.Objective-C的动态性是由RunTime API来支撑的,Runtime顾名思义就是运行时,RunTime API提供的接口基本都是C语言的,源码由C/C++/汇编语言编写
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/runtime.png)

### 1. isa详解
#### 之前的学习中我们知道如下结论,在arm64架构之前,isa就是一个普通的指针,存储着Class、Meta_Class对象的内存地址,而从arm64位架构开始,对isa进行了优化,变成了一个共用体(union)结构,还使用位域来存储更多的信息
    实例对象                               
    instance &ISA_MASK                              
      isa------------>类对象                   
    其他成员变量        class   &ISA_MASK  
                       isa---------------->元类对象  &ISA_MASK
                    superclass             isa-------------->基元类对象(isa----->它本身)    
                属性/对象方法/协议/成员变量    superclass
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
        isa_t isa;  //联合体+位域的方式存储信息的
    }
    
    union isa_t {  //共用体
        Class cls;
        uintptr_t bits;  //存放所有的数据
        struct {  //利用了位域技术,这个结构体纯粹就是为了增加可读性,其它没什么作用
            //占1位 最低的地址(0b0000 0000 最后一位代表这个值)
            uintptr_t nonpointer        : 1;  
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
9. extra_rc: 里面存储的值是引用计数器减1，最多存储2^19-1个引用计数

    
#### isa优化后,除了存放class、Meta-class的地址,还存放更多的其他信息, 通过上面的源代码,我们知道有33位存储的是class、Meta-class的地址,所以isa现在需要按位与&才能得到class、Meta-class的真实地址


#### 1.1.1 引用计数存储在什么地方
#### arm64架构后，iOS中引用计数存储在优化过的isa指针中，isa采用的是共用体结构存储更多的对象信息，其中有两个成员存储引用计数
一个是extra_rc，一个是全局哈希表Sidetable中，引用计数首先存储在extra_rc，他的值是引用计数值-1，如果extra_rc不够存储了，才开始存储哈希表Sidetable中
* extra_rc存放的是可能是对象部分或全部引用计数值减1，因为extra_rc如果存不下的话，会将部分引用计数存储在Sidetable中
* has_sidetable_rc为一个标志位，值为1时代表 extra_rc的19位内存已经不能存放下对象的retainCount , 需要把一部分retainCount存放地另外的地方
#### 如果extra_rc溢出了，那么会将**extra_rc的最大值+1**减少一半，然后将减掉的一半存储在Sidetable中，为什么是减少一半？？？？？
#### 因为每次操作SideTable都需要进行一次上锁/解锁，而且还要经过几次哈希运算才能处理对象的引用计数，效率比较低。而且，考虑到release操作，也不能在溢出时把值全部存在SideTable中。因此，为了尽可能多的去操作extra_rc，每当extra_rc溢出时，就各存一半，这样下次进来就还是直接操作extra_rc，会更高效

#### SideTables散列表
#### SideTables可以理解成一个类型为StripedMap静态全局对象，内部以数组(哈希表)的形式存储了64个SideTable

        static StripedMap<SideTable>& SideTables() {
            return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
        }

        //MARK: StripedMap底层结构 可以存放64个SideTable
        class StripedMap {
            enum { StripeCount = 64 };    //ios设备  StripeCount = 64字节
        }
        struct SideTable {
            spinlock_t slock;           //自旋锁：用于上锁/解锁SideTable
            RefcountMap refcnts;        //OC对象引用计数Map（key为对象，value为引用计数）-引用计数表
            weak_table_t weak_table;    //OC对象弱引用Map-弱引用表
        }
        
    
        //weak_table 是一个哈希表的结构, 根据 weak 指针指向的对象的地址计算哈希值, 哈希值相同的对象按照下标 +1 的形式向后查找可用位置, 
        是典型的闭散列算法. 最大哈希偏移值即是所有对象中计算出的哈希值和实际插入位置的最大偏移量, 在查找时可以作为循环的上限.
        //通过对象的地址，可以找到weak_table_t结构中的weak_entry_t
        //weak_entry_t 中保存了所有指向这个对象的 weak 指针.
        //⚠️弱引用表底层结构
        struct weak_table_t {
            weak_entry_t *weak_entries;         //hash数组(动态数组)
            size_t    num_entries;              //hash数组中元素的个数
            uintptr_t mask;                     //hash数组长度-1，而不是元素的个数，一般是做位运算定义的值
            uintptr_t max_hash_displacement;    //hash冲突的最大次数(最大哈希偏移值)
        };
        
         /* union联合体特点
         1.联合体中可以定义多个成员，联合体的大小由最大的成员大小决定
         2.联合体的成员公用一个内存，一次只能使用一个成员
         3.对某一个成员赋值，会覆盖其他成员的值
         4.存储效率更高，可读性更强，可以提高代码的可读性，可以使用位运算提高数据的存储效率
         */
        //弱引用实体,一个对象对应一个weak_entry_t,保存对象的弱引用;保存弱应用的是个联合体,当弱引用小于等于4个的时候,直接用inline_referrers数组保存
        大于四个时用referrers动态数组
        struct weak_entry_t { //对应关系是[referent weak指针的数组]
            DisguisedPtr<objc_object> referent;   //被弱引用的对象
            union { //联合体（共用体）共用体的所有成员占用同一段内存
                struct {
                    weak_referrer_t *referrers;  //指向 referent 对象的weak指针数组。动态数组保存弱引用的指针
                    uintptr_t        out_of_line_ness : 2;     //这里标记是否超过内联边界, 下面会提到
                    uintptr_t        num_refs : PTR_MINUS_2;   //数组中已占用的大小
                    uintptr_t        mask;          //数组下标最大值(数组大小 - 1)
                    uintptr_t        max_hash_displacement;  //最大哈希偏移值
                };
                struct {
                    //这是一个取名叫内联引用的数组，WEAK_INLINE_COUNT宏定义值为4 初始化时默认使用的数组
                    weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];  //静态数组
                };
            };
            //当指向这个对象的 weak 指针不超过 4 个, 则直接使用数组 inline_referrers, 省去了哈希操作的步骤, 如果 weak 指针个数超过了4个, 就要使用第一个结构体中的动态数组weak_referrer_t *referrers
            bool out_of_line() {
                return (out_of_line_ness == REFERRERS_OUT_OF_LINE);
            }

            weak_entry_t& operator=(const weak_entry_t& other) {
                memcpy(this, &other, sizeof(other));
                return *this;
            }

            weak_entry_t(objc_object *newReferent, objc_object **newReferrer)
                : referent(newReferent)
            { //构造方法，里面初始化了静态数组
                inline_referrers[0] = newReferrer;
                for (int i = 1; i < WEAK_INLINE_COUNT; i++) {
                    inline_referrers[i] = nil;
                }
            }
        };
        
#### 自旋锁：忙等状态、比较消耗CPU资源、不能递归调用、如果短时间内可以获取到资源，则使用自旋锁比互斥锁效率要高，因为少了互斥锁中的线程调度等操作
自旋锁比较适用于锁使用者保持锁时间比较短的情况。正是由于自旋锁使用者一般保持锁时间非常短,因此选择自旋而不是睡眠是非常必要的，自旋锁的效率远高于互斥锁。

#### Runtime维护了一个全局的SideTables表，SideTables就是个哈希表，其实就是个数组，里面存放了SideTable结构,SideTables数组中元素的最大数量是64个，
通过对象可以找到对应SideTable，进而可以找到对应的弱引用表、对应的引用计数表

#### 通过对象地址在Runtime维护的全局SideTables哈希表中(SideTables[this])找到对应的SideTable({slock自旋锁/refcnts引用计数表/weak_table弱引用表})，
进而找到弱引用表(以对象为key的哈希表)，弱引用表里面其实是个数组，每个对象对应着一个weak_entry_t，即弱引用表中是以对象为key，以weak_entry_t为value的
weak_entry_t里面拥有数组用来存储弱引用的地址，如果引用个数小于4则用inline_referrers数组存储，如果大于4个则使用动态数组进行存储



    全局SideTables哈希表                Sidetable              weak_table                  weak_entries       weak_entry_t
                                      slock自旋锁          weak_entries(hash数组)         [weak_entry_t]--->  referent 弱引用对象地址
    [Sidetable]  SideTables[对象地址] refcnts引用计数表      num_entries(hash数组中元素的个数) [weak_entry_t]     []数组存放weak指针地址的数组
    [Sidetable]----------------->   weak_table弱引用表 ----> mask (hash数组长度-1)          [weak_entry_t]
      ......                           
    [Sidetable]
    [Sidetable]
            
















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
            method_array_t methods;       //方法列表(分类+类)、二维数组、可读可写
            property_array_t properties;  //属性列表(分类+类)、二维数组、可读可写
            protocol_array_t protocols;   //属性协议(分类+类)、二维数组、可读可写
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
    // @代表第一个参数id,0表示这个参数从哪里开始,
    // 8代表参数:(SEL)开始的字节数  16代表参数i开始的字节数 20代表f开始的字节数
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
        struct bucket_t *_buckets;  //数组,其实就是个散列表,里面存放的是bucket_t，即[bucket_t]
        mask_t _mask;               //散列表长度-1(数组元素个数-1)
        mask_t _occupied;           //已经缓存的方法数量
    }
    为什么_mask的长度是散列表长度-1? 因为如果等于散列表长度,而@selector(test)&_mask的值要小于等于  
    散列表的下标而最大的下标是散列表长度-1
    
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
4. 将方法添加到缓存列表第1⃣️步

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
6. 如果仍然没有找到,并且也没有做其它处理,就走动态方法解析和消息转发渠道
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
         退出       (3)从receive Class的class_rw_t中查找方法---找到--->调用方法结束查询
                                      |                     并将方法缓存到receive的cache中
                                      |
                                   没有找到
                    (4)从superClass的cache中查找方法---找到--->调用方法结束查询
                                      |               并将方法缓存到receive的cache中
                                      |
                                    没有找到
                  (5)从superClass的class_rw_t中查找方法---找到--->调用方法结束查询
                                      |                   并将方法缓存到receive的cache中
                                      |
                                    没有找到
                     (6)上层是否还有superClass---否--->动态方法解析阶段
                                      |
                                      |
                                      是
                                继续(4)步骤
                                    
1. 如何从class_rw_t中查找方法: 已经排序的,二分查找(折半查找);没有排序的,遍历查找
2. receive通过isa指针找到receiveClass
3. receiveClass通过superclass指针找到superClass
                                      
### 3.2 动态方法解析阶段
#### 如果自己类和父类都没有找到方法,那么就会进入动态方法解析阶段
                是否曾经有动态解析---> 是 ---> 消息转发
                        | 否
        调用+(BOOL)resolveInstanceMethod:(SEL)sel
        或者+(BOOL)resolveClassMethod:(SEL)sel来动态解析方法
                        |
                  标记为已经动态解析
                        |
                      消息发送
1. 开发者可以实现以下方法,来动态添加方法实现:

        +resolveInstanceMethod  添加对象方法的实现
        +resolveClassMethod     添加类方法的实现
2. 动态解析过后,会重新走**消息发送**的流程,“从receiverClass的cache中查找方法”这一步开始执行，因为动态方法解析阶段是给对象添加方法，方法在类对象或元类对象中
#### 案例1: 对象方法
    @interface Person : NSObject
    -(void)test;
    @end

    #import "Person.h"
    #import <objc/runtime.h>
    @implementation Person
    /*
     typedef struct objc_method *Method;
     objc_method其实等价于method_t结构体
     struct method_t {
                SEL name;
                const char *types;
                IMP imp;
     };
     */
    -(void)otherTest{
        NSLog(@"---%s---",__func__);
    }
    //对象方法
    +(BOOL)resolveInstanceMethod:(SEL)sel {
        if (sel == @selector(test)) {
            //动态添加test对象方法的实现
            //1. 获取其它方法:传self,因为是在类方法中,所以self代表类对象,而对象方法是添加到类对象中的
            Method otherMethod = class_getInstanceMethod(self, @selector(otherTest));
            //2.方法添加到什么上面? 肯定是添加到类对象中,而这个方法就是在类方法中,所以self就代表类对象
            class_addMethod(self,
                            sel,  
                            method_getImplementation(otherMethod),
                            method_getTypeEncoding(otherMethod)
                            );
            //3.返回YES代表有动态添加方法,其实返回YES/NO都没关系,因为系统拿到这个返回值也不会做事情,只是打印
            return YES;
        }
        return [super resolveInstanceMethod:sel];
    }
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *person = [[Person alloc]init];
        [person test];
    }
    打印结果: ----[Person otherTest]---
#### 案例2: 类方法
    @interface Person : NSObject
    +(void)test;
    @end

    #import "Person.h"
    #import <objc/runtime.h>

    @implementation Person
    +(void)otherTest{
        NSLog(@"---%s---",__func__);
    }
    //类方法
    +(BOOL)resolveClassMethod:(SEL)sel {
        if (sel == @selector(test)) {
            //获取类方法
            Method otherMethod = class_getClassMethod(self, @selector(otherTest));
            //将类方法添加到元类对象中, 类(self)的object_getClass就是元类对象
            class_addMethod(object_getClass(self),
                            sel,
                            method_getImplementation(otherMethod),
                            method_getTypeEncoding(otherMethod)
                            );
            return YES;
        }
        return [super resolveClassMethod:sel];
    }

    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        [Person test];
    }
    打印结果: ---+[Person otherTest]---

#### 分析,当在类和父类中都没有找到方法时(**消息发送阶段**),就会走**动态方法解析阶段**,如果在**动态方法解析阶段**也没有实现方法+resolveInstanceMethod
或+resolveClassMethod方法,那么就会继续走**消息发送阶段**,并且会将这次的动态解析阶段标记为已经动态解析,显然这次的动态解析阶段什么也没有做,走完**消息发送阶段**后,发现仍然没有找到方法,那么就会来到**动态解析阶段**,发现已经动态解析过了,那么就会走**消息转发阶段**,如果实现了动态解析方法resolveInstanceMethod或resolveClassMethod方法,那么只要在对应动态方法解析的方法中添加方法的实现即可,然后标记为已动态解析,然后方法就会继续走**消息发送阶段**了,为什么又走消息发送阶段?因为在动态解析阶段已经在类对象或元类对象中添加了方法实现,所以才会继续走**消息发送阶段**

#### 注意⚠️：**动态解析阶段**添加的方法实现有如下要求：方法返回值类型可以不一样，方法参数名称可以不一样，但是方法参数的类型和参数的个数要一致并且要对应上


### 3.3 消息转发阶段
#### **消息发送阶段**和**动态解析阶段**都找不到方法或没有处理,就会进入**消息转发阶段**

    (1)调用forwardingTargetForSelector方法---返回值不为nil--->(2)objc_megSend(返回值,SEL)
                            |
                            |  返回值为nil
            调用methodSignatureForSelector:方法---返回值为nil--->调用doesNotRecognizeSelector:方法
             [作用是返回一个有用有效的方法签名]
                            |
                            | 返回值不为nil
            再给最后一次机会去调用forwardInvocation:方法,来处理        
                            
#### 实例方法消息转发

    @interface Person : NSObject
    -(void)test;
    @end

    #import "Person.h"
    #import "Student.h"
    @implementation Person
    //1.方法一,消息转发:将消息转发给别人,将方法交给一个指定的对象去实现
    -(id)forwardingTargetForSelector:(SEL)aSelector {
        if (aSelector == @selector(test)) {
            //底层实际上是这么处理的:objc_msgSend([[Student alloc]init], aSelector)
            return [[Student alloc]init];
        }
        return 0;
    }
    
    ⚠️：这里Student对象中的方法有如下要求：方法名必须和调用的方法名要一致，方法参数类型要一致,参数名称可以不一致；  
    方法返回值类型可以不一致

    //2.如果方法一没有实现(相当于返回nil),或者返回值为nil,就继续调用下面这个方法
    - (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
        //返回一个方法签名: 方法签名(返回值类型、参数类型)
        if (aSelector == @selector(test)) {
            //"v16@0:8": 代表-(void)test的方法签名
            return [NSMethodSignature signatureWithObjCTypes:"v16@0:8"];
            //方法签名也可以这样写,前提是知道要实现的对象,并且对象有这个方法(知道一下就可以了)
            //return [[[Student alloc]init] methodSignatureForSelector:aSelector];
            return 
        }
        return [super methodSignatureForSelector:aSelector];
    }

    //3.返回完方法签名后,会调用下面的方法,如果方法签名中返回nil,那么就不会调用下面这个方法
    //NSInvocation封装了一个方法调用,包括:方法调用者、方法名、方法参数
    -(void)forwardInvocation:(NSInvocation *)anInvocation {
        //方法调用者:anInvocation.target
        //方法名:anInvocation.selector
        //方法参数: [anInvocation getArgument:NULL atIndex:0]
        //(1)可以指定一个对象来执行
        //anInvocation.target = [[Student alloc]init];
        //[anInvocation invoke];
        //上面的会报错,所以尽量用下面的方法来调用
        [anInvocation invokeWithTarget:[[Student alloc]init]];
    }
    @end

#### 详细刨析,如果我们仅仅是为了像案例中的一样,指定一个方法接收者,那么完全不用这么麻烦,直接在**动态方法解析阶段**直接指定一个方法接收者即可,为什么还要这么麻烦的进行**消息转发阶段**那? 因为在消息转发阶段我们可以随意编写我们希望实现的方法内容
        #import "Person.h"
        @implementation Person

        /// 返回一个方法签名
        - (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
            if (aSelector == @selector(test)) {
                return [NSMethodSignature signatureWithObjCTypes:"v16@0:8"];
            }
            return [super methodSignatureForSelector:aSelector];
        }

        /// 这里可以尽情的实现方法调用
        -(void)forwardInvocation:(NSInvocation *)anInvocation {
            //这里可以随便处理,如打印一个信息,或者什么都不写都可以
            NSLog(@"我要尽情的处理");
        }
        @end
#### 假如我们要调用的是方法-(void)test:(int)age;,我们想让参数+10,

    @implementation Person
    /// 返回一个方法签名
    - (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
        if (aSelector == @selector(test:)) {
            return [NSMethodSignature signatureWithObjCTypes:"v20@0:8i16"];
        }
        return [super methodSignatureForSelector:aSelector];
    }

    /// 这里可以尽情的实现方法调用
    -(void)forwardInvocation:(NSInvocation *)anInvocation {
        //参数顺序: receiver、selector、other arguments
        int age;
        [anInvocation getArgument:&age atIndex:2];
        //anInvocation还可以获取方法返回值: getReturnValue
        NSLog(@"---%d",age+10);
    }
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *person = [[Person alloc]init];
        [person test:10];
    }
    打印结果:  ---20
#### 类方法消息转发

    @interface Student : NSObject
    +(void)test;
    @end

    @implementation Student
    +(void)test {
        NSLog(@"---%s",__func__);
    }
    @end

    @interface Person : NSObject
    +(void)test;
    @end

    @implementation Person
    //如果消息转发的是类方法,那么这个方法应该也是类方法,所以方法用+号,但是一般我们直接敲方法出来的都是  
    实例方法,因为编译器对于类方法没有提示,所以我们需要根据方法类型来决定是用+还是-
    
    +(id)forwardingTargetForSelector:(SEL)aSelector {
        if (aSelector == @selector(test)) {
            //因为转发的是类方法,所以消息的接收者应该是类对象
            return [Student class];
        }
        return [super forwardingTargetForSelector:aSelector];
    }
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        [Person test];
    }
    
    打印结果: ---+[Student test]


    @implementation Person
    //如果消息转发的是类方法,那么这个方法应该也是类方法,所以方法用+号,但是一般我们直接敲方法出来的都是实例方法,  
    因为编译器对于类方法没有提示,所以我们需要根据方法类型来决定是用+还是-
    //+(id)forwardingTargetForSelector:(SEL)aSelector {
    //    if (aSelector == @selector(test)) {
    //        //因为转发的是类方法,所以消息的接收者应该是类对象
    //        return [Student class];
    //    }
    //    return [super forwardingTargetForSelector:aSelector];
    //}

    /// 如果上面的方法返回为nil或者没有处理,就会继续执行下面的方法, 记得也是类方法(+)
    + (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
        if (aSelector == @selector(test)) {
            return [NSMethodSignature signatureWithObjCTypes:"v@:"];
        }
        return [super methodSignatureForSelector:aSelector];
    }
    // 这里也是个类方法
    +(void)forwardInvocation:(NSInvocation *)anInvocation {
        NSLog(@"123123123");
    }
    @end
        
    打印结果: 123123123
#### 整个消息传递流程可以通过RunTime源码中objc-runtime-new.h文件中的_class_lookupMethodAndLoadCache3为入口进行查看

### 大总结
* OC方法调用，首先通过对象的isa指针找到对应的类对象，然后在类对象的方法缓存列表cache_t中查找方法
* 查询缓存列表cache_t方法过程是这样的，首先通过@selector(name)方法名作为key，然后通过和散列表的长度-1进行哈希算法(key & mask)获取到散列表的下标index，然后取出对应下标index的元素bucket_t(key,imp),然后将外部的@selector(name)的地址值与bucket_t元素中的key进行对比,如果相同则返回对应元素的imp,进行方法调用;如果两个key的值不相同,则对下标进行index-1操作,继续对比.如果index减少到了0仍然没有找到IMP,则会让index==mask(数组长度-1)继续进行对比,若找到了对应的IMP,则直接调用,若仍然没有找到,即继续去类对象的class_rw_t中的方法列表中去查找
*  在class_rw_t的方法列表中如果找到了对应的方法实现IMP,则直接调用,并将方法填充到缓存方法列表中
* 若在class_rw_t的方法列表中仍然没有找到,则通过isa找到superClass,通过superClass找到对象的父类,在父类的方法缓存列表中继续去查找,如果找到了则直接调用,并且将该方法写到方法接收者(当前类的子类)类对象的方法缓存列表中;若没有找到,则继续查找class_rw_t中的方法列表,若找到直接调用,并将方法填充到方法接收者(当前类的子类)类对象的方法缓存列表中;
* 若所有的父类一层一层都没有找到,则消息发送阶段结束,开始进入动态方法解析阶段
* 在动态方法解析阶段,若实现了+resolveInstanceMethod
或-resolveClassMethod方法,并且返回值不为nil,即动态添加了方法,则将此标记为已动态解析过,然后继续走消息发送流程; 消息发送流程若找到直接调用,若没有找到,又会走到动态解析阶段,此时判断标记,发现已经动态解析过了,则直接进入方法转发阶段;若根本没有实现上面的两个方法中的一个或者返回值为nil,即动态方法解析阶段什么也没有处理,则会进入方法转发阶段
* 在方法转发阶段,若实现(+-)forwardingTargetForSelector了方法,并且返回值不为nil,则直接进行方法转发;若返回值为nil,即在这一步没有进行处理,则会去判断methodSignatureForSelector方法是否返回了方法签名,若返回的方法签名为nil,则直接报经典的错误:unrecognized selector sent to instance; 若返回的方法签名不为nil,则会继续执行forwardInvocation方法,在这个方法里面可以随便处理,即便不处理也不会有问题,只要方法签名返回有效即可


### 4 @dynamic、@synthesize关键词
    @interface Person : NSObject
    /*
     写上这么一个属性,编译器会自动帮我们
     1.生成对应的getter/setter方法的声明
     -(void)setAge:(int)age;
     -(int)age;
     2._age成员变量
     {
        int _age;
     }
     3. getter/setter方法的实现
     -(void)setAge:(int)age {
         _age = age;
     }
     -(int)age {
         return _age;
     }
     */
    @property(nonatomic, assign)int age;
    @end
        
    @implementation Person
    /*
     1.@synthesize关键词是很早之前的写法,现在已经不需要再写这个关键词了,Xcode默认已经实现了,只要写  
     上属性@property,就会自动生成成员变量和getter/setter方法的实现
     2.@synthesize age = _age; 为age属性生成_age的成员变量,并且自动生成getter/setter方法的实现,  
     这里可以指定成员变量的名称,例如也可以这样写@synthesize age = _age1111;
     */
    @synthesize age = _age;

    /*
    如果我们不希望Xcode自动帮我们生成属性的getter/setter方法的实现和对应的成员变量,可以这么写@dynamic age;
    提醒编译器不要自动生成getter/setter的实现、不要自动生成对应的成员变量
    外部仍然可以调用setAge方法,因为@dynamic并不影响属性的getter/setter方法的声明
     */
    @dynamic age;
    
    @end
### 5 super关键词
#### 案例代码
    @interface Student : Person
    @end
    
    @implementation Student
    -(instancetype)init {
        if (self = [super init]) {
            NSLog(@"[self class] = %@",[self class]);           //Student
            NSLog(@"[self superclass] = %@",[self superclass]); //Person
            NSLog(@"------------------------------");
            NSLog(@"[super class] = %@",[super class]);         //Student
            NSLog(@"[super superclass] = %@",[super superclass]);//Person
        }
        return self;
    }
    @end

    @interface Person : NSObject
    @end

    @implementation Person
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        Student *student = [[Student alloc]init];
    }
    
    打印结果: [self class] = Student
            [self superclass] = Person
            ------------------------------
            [super class] = Student
            [super superclass] = Person

#### 分析: 对于[self class]、[self superclass]我们很容易理解,打印结果就是Student、Person,但是[super class]、[super class],按照我们常规的理解,应该打印的是Person、NSObject,但结果很意外,跟我们常规理解的不一致,为什么?接下来我们通过事例来验证

#### 在Person类中写上方法run,然后子类Student重写run方法,然后通过xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc Student.m命令生成对应的C++文件(cpp文件)
    @interface Person : NSObject
    -(void)run;
    @end
    @implementation Person
    -(void)run {
        NSLog(@"----%s",__func__);
    }
    @end

    @implementation Student
    -(void)run {
        [super run];
    }
    @end
    
    C++代码
    static void _I_Student_run(Student * self, SEL _cmd) {
        ((void (*)(__rw_objc_super *, SEL))(void *)objc_msgSendSuper)((__rw_objc_super){  
        (id)self,
        (id)class_getSuperclass(objc_getClass("Student"))},
        sel_registerName("run"));
    }
    
    C++代码简化版 __rw_objc_super、objc_msgSendSuper在Runtime源码中可以找到
    static void _I_Student_run(Student * self, SEL _cmd) {
        objc_msgSendSuper((__rw_objc_super){
        (id)self, 
        (id)class_getSuperclass(objc_getClass("Student")) //Student的父类Person类
        }, sel_registerName("run"));
    }
    
    struct __rw_objc_super { 
        struct objc_object *object; 
        struct objc_object *superClass; 
        __rw_objc_super(struct objc_object *o,struct objc_object *s):object(o),superClass(s){} 
    };
    
    //objc_super data structure, including the instance of the class that is to receive the
    //message and the superclass at which to start searching for the method implementation.
    //翻译过来就是objc_super是一个结构体,包含了一个消息接收者和消息接收者的父类,这个父类就是查找方法开始的地方
    //简单说: 就是调用 [super 方法名],查看方法是从该类的父类开始查找的
    objc_msgSendSuper(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)
        OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0, 2.0);
    
    struct objc_super {
        id receiver;        //消息接收者
        Class super_class;  //消息接收者的父类, 查找方法从这个类开始搜索
    };
    
    class、superclass在Runtime中的源码
    - (Class)class {
        return object_getClass(self);
    }
    - (Class)superclass {
        return [self class]->superclass;
    }
    
#### 通过以上代码分析我们知道,在Student对象中调用[super class],消息接收者仍然是Student对象,而查找方法是从Student对象的父类Person中开始查找的,我们都知道class方法是在NSObject中的,所以最终查找到NSObject类中,而根据class方法的底层结果我们知道,class方法返回的内容和self(即消息接收者)有关,而消息接收者是Student对象,所以[super class]的结果就是Student,而[super superclass]的结果就是Person
    -(instancetype)init {
         if (self = [super init]) {
            //下面的底层结构是: objc_msgSend(self,@selector(class))
             NSLog(@"[self class] = %@",[self class]);           //Student
             NSLog(@"[self superclass] = %@",[self superclass]); //Person
             NSLog(@"------------------------------");
             //下面的底层结构是: objc_msgSendSuper({self,[Person Class]},@selecot(class))
             NSLog(@"[super class] = %@",[super class]);         //Student
             NSLog(@"[super superclass] = %@",[super superclass]);//Person
         }
         return self;
     }
 #### 总结: [super message]的底层实现是: 1.消息接收者仍然是子类对象 2.从父类开始查找方法的实现

### 6 isMemberOfClass、isKindOfClass
#### 首先我们通过Runtime源码中的NSObject.mm文件可以看到关于这两个方法的底层实现代码如下
    类方法：类的类对象(元类)是否等于指定的类对象(元类对象)【类的元类是否等于指定的元类对象】
    + (BOOL)isMemberOfClass:(Class)cls {
        return object_getClass((id)self) == cls;
    }
    //实例方法：对象的类是否等于指定的类对象
    - (BOOL)isMemberOfClass:(Class)cls {
        return [self class] == cls;
    }
    //类方法：类的类对象(元类)是否等于指定的类对象(元类)或者是指定的类对象(元类)的子类
    //【类的元类是否等于指定的元类对象或者是指定元类对象的子类】
    + (BOOL)isKindOfClass:(Class)cls {
        for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
            if (tcls == cls) return YES;
        }
        return NO;
    }
    //对象方法：对象的类对象是否是指定的类对象或者是指定的类对象的子类
    - (BOOL)isKindOfClass:(Class)cls {
        for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
            if (tcls == cls) return YES;
        }
        return NO;
    }
    
    Person *per = [[Person alloc]init];
    NSLog(@"%d",[NSObject isKindOfClass:[NSObject class]]);     //1
    NSLog(@"%d",[NSObject isMemberOfClass:[NSObject class]]);   //0
    NSLog(@"-----");
    NSLog(@"%d",[per isKindOfClass:[Person class]]);            //1
    NSLog(@"%d",[per isMemberOfClass:[Person class]]);          //1
    NSLog(@"-----");
    NSLog(@"%d",[per isKindOfClass:[NSObject class]]);          //1
    NSLog(@"%d",[per isMemberOfClass:[NSObject class]]);        //0
    
    打印结果： 1
             0
             -----
             1
             1
             -----
             1
             0

#### 两个方法都有对应的类方法和实例方法，结合底层源码总结如下
* 如果是类方法
1. isMemberOfClass: 类的类对象(元类对象)是否是指定的元类对象
2. isKindOfClass: 类的类对象(元类对象)是否是指定的元类对象或者是指定的元类对象的子类
3. 2中有个特例：NSObject的元类对象的superClass指向的是NSObject类对象
* 如果是对象方法
1. isMemberOfClass: 对象的类对象是否是指定的类对象
2. isKindOfClass: 对象的类对象是否是指定的类对象或者指定的类对象的子类

### 7. 查看OC源码方式
#### LLVM编译器会将: OC----->中间代码----->汇编----->机器代码,即OC在变成机器代码之前,会被LLVM编译器转换为中间代码(Intermediate Representation)
1. 通过xcrun -sdk iphones clang -arch arm64 -rewrite-objc WGPerson.m将指定的OC文件转为cpp文件(c++语法)
2. 通过Xcode打断点方式启动项目:Xcode顶部菜单栏Debug->Debug Workflow->Always Show Disassembly查看指定断点下OC代码的汇编代码
3. 可以不启动项目情况下查看汇编代码:Xcode顶部菜单栏Produce->Perform Action->Assemble "WGPerson.m",可以将WGPerson.m生成汇编代码
4. 可以使用clang -emit-llvm -S WGPerson.m,将指定OC文件生成中间代码,通过查看中间代码来解读源码
#### 生成中间代码后的语法分析
    @->代表全局变量   %->局部变量   i32->32位4字节的整数   align->对齐
    load->读出      store->写入   label->代码标签       call->调用函数
    icmp->两个整数值比较,返回布尔值
    br->选择分支,根据条件来转向label,不根据条件跳转的话类似goto
    alloca->在当前执行的函数的堆栈帧中分配内容,当该函数返回其调用者时,将自动释放内容
    详细语法可参考:https://llvm.org/docs/LangRef.html
#### ⚠️cpp文件(C语言)和我们OC代码更接近,更容易理解,其实底层转化的都应该是汇编代码,但汇编代码不容易看懂,所以我们通常情况下查看cpp文件即可

### 8.Runtime在项目中的应用
#### 平时我们在项目中用到Runtime的地方通常就是用Runtime提供的API,下面列举常用的函数
### 8.1 类
    1.动态创建一个类(参数:父类、类名、额外的内存空间)
    Class objc_allocateClassPair(Class superclass, const char * name, size_t extraBytes)
    2. 注册一个类(要在类注册之前添加成员变量,因为注册类就相当于添加了类的结构,如果类结构确定了,成员变量就无法添加了)
    Void objc_registerClassPair(Class __unsafe_unretained cls)
    3. 销毁一个类
    Void objc_disposeClassPair(Class cls)
    4. 获取isa指向的Class
    Class object_getClass(id  obj)
    5. 设置isa指向的Class
    Class object_setClass(id obj, Class cls)
    6. 判断一个OC对象是否为Class
    Bool object_isClass(id  obj)
    7. 判断一个Class是否为元类
    Bool class_isMetaClass(Class cls)
    8. 获取父类
    Class class_getSuperclass(Class cls)
    
#### 事例代码
    @interface Person : NSObject
    -(void)run;
    @end
    @implementation Person
    -(void)run {
        NSLog(@"----%s",__func__);
    }
    @end
    
    @interface Car : NSObject
    -(void)run;
    @end
    @implementation Car
    -(void)run {
        NSLog(@"----%s",__func__);
    }
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        //1. 动态创建一个类(Pair是一对的意思,创建的是一个父类对象和类对象)
        //(父类,类名,额外的内存大小)
        Class newClass = objc_allocateClassPair([NSObject class], "Dog", 0);
        //2. 注册这个类
        objc_registerClassPair(newClass);
        // 创建一个Dog对象
        id dog = [[newClass alloc]init];
        
        Person *person = [[Person alloc]init];
        [person run];
        //4. 获取isa指向的Class(类对象,类对象,元类对象)
        NSLog(@"%p---%p---%p",  
        object_getClass(person),[Person class],object_getClass([Person class]));
        //4. 打印结果:0x107422d78---0x107422d78---0x107422d50
        
        //5. 将person对象的isa指针设置为指向Car类对象;可以实现中途让对象调用其它类的同名的方法
        object_setClass(person, [Car class]);
        [person run];
        //5. 打印结果:-----[Car run]
        
        //6. 判断一个OC对象是否为Class(元类对象也是特殊的类对象)
        NSLog(@"%d---%d---%d",object_isClass(person),  
        object_isClass([person class]),object_isClass(object_getClass([Person class])));
        //6. 打印结果:0---1---1

        //7. 判断一个Class是否为元类(参数必须传Class类型)
        NSLog(@"%d---%d",class_isMetaClass([person class]),  
        class_isMetaClass(object_getClass([Person class])));
        //7. 打印结果:0---1
        
        //8.获取父类(参数必须传Class类型)特例:NSObject元类对象的superClass指向NSOject类对象
        NSLog(@"---%@---%@---%@",class_getSuperclass([person class]),  
              class_getSuperclass([Person class]),
              class_getSuperclass(object_getClass([Person class])));
        //8. 打印结果: ---NSObject---NSObject---NSObject
    }
    
    void run(id self,SEL _cmd) {
        NSLog(@"%@---%@",self, NSStringFromSelector(_cmd));
    }
    - (void)viewDidLoad {
        [super viewDidLoad];
        //1. 动态创建一个类(Pair是一对的意思,创建的是一个父类对象和类对象)
        //(父类,类名,额外的内存大小一般写0即可)
        Class newClass = objc_allocateClassPair([NSObject class], "Dog", 0);
        //添加成员变量(类对象、成员变量名称、成员变量占用字节数、内存对其子节一般写1、成员变量类型的编码@encode)
        //成员变量添加一定要在注册类之前
        class_addIvar(newClass, "_age", 4, 1, @encode(int));
        class_addIvar(newClass, "_weight", 4, 1, @encode(int));
        //添加方法
        class_addMethod(newClass, @selector(run), (IMP)run, "v@:");
        
        //2. 注册这个类(一旦注册完相当于类对象、元类对象的结构就创建好了)
        objc_registerClassPair(newClass);
        
        // 创建一个Dog对象
        id dog = [[newClass alloc]init];
        //这里因为没有对应的getter/setter方法,所以只能通过KVC去设置访问
        [dog setValue:@100 forKey:@"_age"];
        [dog setValue:@200 forKey:@"_weight"];
        NSLog(@"%@---%@",[dog valueForKey:@"_age"],[dog valueForKey:@"_weight"]);
        //打印结果: 100---200
        
        //调用方法
        [dog run];
        //打印结果: <Dog: 0x600000ccc650>---run
        
        //3. 销毁不需要的类
        objc_disposeClassPair(newClass);
    }

### 8.2 成员变量
    1. 获取一个实例变量
    Ivar class_getInstanceVariable(Class cls, const char * name)
    2. 拷贝实例变量列表(最后需要用free释放)
    Ivar * class_copyIvarList(Class cls, unsigned int * outCount)
    3. 设置和获取成员变量的值
    Void object_setIvar(id obj, Ivar ivar, id value)
    id object_getIvar(id obj, Ivar ivar)
    4. 动态添加成员变量(已经注册的类是不能动态添加成员变量的)
    Bool class_addIvar(Class cls,const char * name,size_t size,uint8_t alignment,const char * types)
    5. 获取成员变量的相关信息
    const char *ivar_getName(Ivar v)
    const char *ivar_getTypeEncoding(Ivar v)
        
#### 事例代码
    @interface Person : NSObject
    @property(nonatomic, assign)int age;
    @property(nonatomic, copy)NSString *nameStr;
    @end
    
    @implementation Person
    @end
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        //1. 获取一个实例/成员变量的描述信息
        Ivar ageIvar = class_getInstanceVariable([Person class], "_age");
        NSLog(@"---%s---%s",ivar_getName(ageIvar),ivar_getTypeEncoding(ageIvar));
        //打印结果:---_age---i
        
        //2. 设置和获取成员变量的值
        Person *person = [[Person alloc]init];
        object_setIvar(person, ageIvar, @10);
        NSLog(@"---%d",person.age);
        //打印结果: ----459048901 结果出乎意料了,因为我们的_age成员变量类型是int,  
        但是我们传递的是NSNumber类型,所以这样会出问题,但可以这样设置,首先将int类型转为(void *)指针,  
        指针变量就是存储值的,然后将指针转为id,再通过桥接即可
        object_setIvar(person, ageIvar, (__brigde id)(void *)10);
        
        //正常情况下:
        Ivar nameIvar = class_getInstanceVariable([Person class], "_nameStr");
        object_setIvar(person, nameIvar, @"123");   //设置值
        NSLog(@"---%@---%@",person.nameStr,object_getIvar(person, nameIvar)); //获取值
        //打印结果:---123---123
    }
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        //1. 拷贝实例变量列表
        unsigned int count;  //成员变量的数量
        //C语言中:ivars其实就是个数组,指针可以当成数组来用的
        Ivar *ivars = class_copyIvarList([Person class], &count);
        for (int i = 0; i < count; i++) {
            //取出i位置的成员变量
            Ivar iva = ivars[i];
            NSLog(@"---%s---%s",ivar_getName(iva),ivar_getTypeEncoding(iva));
        }
        //打印结果:---_age---i
                 ---_nameStr---@"NSString"
        //2. Runtime中用copy、create创建的都需要用free去销毁
        free(ivars);
    }
#### 总结:一般用法是我们可以通过获取(窥探)系统类或第三方库的成员变量,通过KVC来快速设置它的属性信息,如:[textField setValue:[UIColor redColor] forKeyPath:@"_placeholderLabel.textColor"];

#### 我们还可以利用Runtime进行字典转模型的封装,创建一个NSObject的分类去实现,下面只是简单的提供了思路,真正需要封装考虑的东西还有很多(继承关系、数组属性等等)
    @interface Person : NSObject
    @property(nonatomic, assign)int age;
    @property(nonatomic, copy)NSString *nameStr;
    @property(nonatomic, assign)int weight;
    @end

    @implementation Person
    @end

    @interface NSObject (WGJson)
    +(instancetype)WG_objectWithJson:(NSDictionary *)json;
    @end

    @implementation NSObject (WGJson)
    +(instancetype)WG_objectWithJson:(NSDictionary *)json {
        id obj = [[self alloc]init];
        unsigned int count;  //成员变量的数量
        Ivar *ivars = class_copyIvarList(self, &count);
        for (int i = 0; i < count; i++) {
            //取出i位置的成员变量
            Ivar iva = ivars[i];
            //C语言的成员变量字符串
            const char *charName = ivar_getName(iva);
            //C语言字符串转为OC语言
            NSMutableString *name = [NSMutableString stringWithUTF8String:charName];
            //将成员变量的_去除
            [name deleteCharactersInRange:NSMakeRange(0, 1)];
            //设置值
            [obj setValue:json[name] forKey:name];
        }
        return obj;
    }
    @end

### 8.3 属性
    1. 获取一个属性
    objc_property_t class_getProperty(Class cls, const char * name)
    2. 拷贝属性列表(最后需要调用free释放)
    objc_property_t * class_copyPropertyList(Class cls, unsigned int * outCount)
    3. 动态添加属性
    Bool class_addProperty(Class cls, const char *name,  
    const objc_property_attribute_t *attributes, unsigned int attributeCount)
    4. 动态替换属性
    Void class_replaceProperty(Class cls, const char *name,  
    const objc_property_attribute_t *attributes, unsigned int attributeCount)
    5. 获取属性的一些信息
    const char * property_getName(objc_property_t property);
    const char * property_getAttributes(objc_property_t property)

### 8.4 方法
    1. 获得一个实例方法、类方法
    Method class_getInstanceMethod(Class cls, SEL name)
    Method class_getClassMethod(Class cls, SEL name)
    2. 方法实现相关操作
    IMP class_getMethodImplementation(Class cls, SEL name)
    IMP method_setImplementation(Method m, IMP imp)
    Void method_exchangeImplementations(Method m1, Method m2)
    3. 拷贝方法列表(最后需要调用free释放)
    Method *class_copyMethodList(Class cls, unsigned int *outCount)
    4. 动态添加方法
    BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types)
    5. 动态替换方法
    IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
    6. 获取方法的相关信息(带copy的需要调用free去释放)
    SEL method_getName(Method m)
    IMP method_getImplementation(Method m)
    const char *method_getTypeEncoding(Method m)
    unsigned int method_getNumberOfArguments(Method m)
    char *method_copyReturnType(Method m)
    char *method_copyArgumentType(Method m, unsigned int index)
    7. 选择器相关
    const char *sel_getName(SEL sel)
    SEL sel_registerName(const char *str)
    8. 用block作为方法实现
    IMP imp_implementationWithBlock(id block)
    id imp_getBlock(IMP anImp)
    BOOL imp_removeBlock(IMP anImp)
#### 事例代码
    @interface Person : NSObject
    -(void)run;
    -(void)test;
    @end

    @implementation Person
    -(void)run {
        NSLog(@"---%s",__func__);
    }
    -(void)test {
        NSLog(@"---%s",__func__);
    }
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *person = [[Person alloc]init];
        //1. 替换方法(若替换对象方法,则第一个参数传递类对象,若是类方法,则传递元类对象)
        class_replaceMethod([Person class], @selector(run), (IMP)myRun, "v@:");
        [person run];
        //打印结果:---my Run
        
        //2. 用block作为方法实现
        class_replaceMethod([Person class], @selector(run), imp_implementationWithBlock(^{
            NSLog(@"this is block task");
        }), "v@:");
        [person run];
        //打印结果: this is block task
    }
    
    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *person = [[Person alloc]init];
        //1.交换方法
        Method runMethod = class_getInstanceMethod([Person class], @selector(run));
        Method testMethod = class_getInstanceMethod([Person class], @selector(test));
        //交换的实际上是class_rw_t中method中的IMP,是不会去交换cache缓存列表中的method中的IMP的,因为这个方法
        //一旦调用,就会清空cache缓存中的方法列表
        method_exchangeImplementations(runMethod, testMethod);
        //此时调用run方法调用的应该是test方法
        [person run];
        //打印结果: ----[Person test]
    }
#### 实际上上面交换自己类中的方法是无意义的,通常我们都是交换其它类的方法实现,
#### 案例1: 例如我们拦截项目中所有按钮的点击事件(拦截其实就是hook方法)
#### 我们知道按钮的点击事件首先调用的方法都是UIControl中的- (void)sendAction:(SEL)action to:(nullable id)target forEvent:(nullable UIEvent *)event;然后再去执行按钮的具体点击事件,所以我们只需要拦截到这个方法即可

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        
        UIButton *btn1 = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 80, 40)];
        btn1.backgroundColor = [UIColor redColor];
        [btn1 addTarget:self action:@selector(clickRedBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btn2 = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 80, 40)];
        btn2.backgroundColor = [UIColor yellowColor];
        [btn2 addTarget:self action:@selector(clickYeallowBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btn3 = [[UIButton alloc]initWithFrame:CGRectMake(100, 300, 80, 40)];
        btn3.backgroundColor = [UIColor blueColor];
        [btn3 addTarget:self action:@selector(clickBlueBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn1];
        [self.view addSubview:btn2];
        [self.view addSubview:btn3];
    }

    -(void)clickRedBtn:(UIButton *)sender {
        NSLog(@"点击了红色按钮");
    }
    -(void)clickYeallowBtn:(UIButton *)sender {
        NSLog(@"点击了黄色按钮");
    }
    -(void)clickBlueBtn:(UIButton *)sender {
        NSLog(@"点击了蓝色按钮");
    }
    @end
    
    //想拦截按钮的点击事件,就要创建UIControl的分类,来拦截到  
    方法-(void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
    
    @interface UIControl (WGHookMethod)
    @end
    
    #import "UIControl+WGHookMethod.h"
    #import <objc/runtime.h>

    @implementation UIControl (WGHookMethod)
    +(void)load {
        //系统方法
        Method method1 = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
        //自定义方法
        Method method2 = class_getInstanceMethod(self, @selector(WG_sendAction:to:forEvent:));
        //交换方法
        method_exchangeImplementations(method1, method2);
    }
    -(void)WG_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
        //拦截到按钮的点击事件后,可以做自己想做的事情,但注意,一旦拦截到按钮点击事件后,按钮本身添加的事件就不会再次响应了
        NSLog(@"self:%@---target:%@---selectorName:%@",self, target, NSStringFromSelector(action));
        //如果我们在拦截到按钮事件后,处理完自己想处理的事,仍然想让按钮继续处理它的事件,那么可以这么做
        //去调用WG_sendAction:to:forEvent:)方法即可,本来应该调用系统方法sendAction:to:forEvent:),  
        但是因为已经方法交换了,所以调用WG_sendAction:to:forEvent:)方法最终才能去执行  
        系统方法sendAction:to:forEvent:),
        [self WG_sendAction:action to:target forEvent:event];
    }
    @end

#### 案例2: 拦截数组添加元素的方法,来避免crash
#### 我们知道数组中添加元素,如果添加的元素为nil,那么程序就会crash,如下
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        NSString *name = nil;
        NSMutableArray *muArr = [NSMutableArray array];
        [muArr addObject:@"123"];
        [muArr addObject:name];
    }
    程序crash: *** Terminating app due to uncaught exception 'NSInvalidArgumentException',  
    reason: '*** -[__NSArrayM insertObject:atIndex:]: object cannot be nil'
#### 从上面报错信息我们可以知道addObject方法底层调用的是insertObject:atIndex:方法,所以我们创建NSMutableArray的分类来拦截到这个方法,然后去判断添加的元素是否为nil,如果为nil就不要再调用添加的方法了,这样就可以避免程序crash
    @interface NSMutableArray (WGHookMutableArray)
    @end

    #import "NSMutableArray+WGHookMutableArray.h"
    #import <objc/runtime.h>

    @implementation NSMutableArray (WGHookMutableArray)
    +(void)load {
        //这里不能填写self,因为NSString、NSArray、NSDictionary属于类簇,类簇的真实类型是其它类型
        //Method method1 = class_getInstanceMethod(self, @selector(insertObject:atIndex:));
        
        Class cls = NSClassFromString(@"__NSArrayM");
        Method method1 = class_getInstanceMethod(cls, @selector(insertObject:atIndex:));
        Method method2 = class_getInstanceMethod(cls, @selector(WG_insertObject:atIndex:));
        method_exchangeImplementations(method1, method2);
    }
    -(void)WG_insertObject:(id)anObject atIndex:(NSUInteger)index {
        if (anObject == nil) { //如果添加的元素为nil,直接返回,不需要再去调用添加的方法了
            return;
        }
        //如果不为nil,则可以继续进行添加元素的方法
        [self WG_insertObject:anObject atIndex:index];
    }
    @end

#### 案例3: 拦截字典添加元素的方法,来避免crash
#### 字典中如果key为nil,则程序会crash
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        NSString *obj = nil;
        NSMutableDictionary *muDic = [NSMutableDictionary dictionary];
        //下面代码等价于 [muDic setObject:@"zhangSan" forKey:@"name"];
        muDic[@"name"] = @"zhangSan";
        muDic[obj] = @"ceShi";
    }
    程序crash: *** Terminating app due to uncaught exception 'NSInvalidArgumentException',  
    reason: '*** -[__NSDictionaryM setObject:forKeyedSubscript:]: key cannot be nil'
#### 从上面报错信息我们可以知道setObject:forKey:;方法底层调用的是setObject:forKeyedSubscript:方法,所以我们创建NSMutableDictionary的分类来拦截到这个方法,然后去判断元素Key是否为nil,如果为nil就不要再调用添加的方法了,这样就可以避免程序crash
    @interface NSMutableDictionary (WGHookMutableDictionary)
    @end
    
    #import "NSMutableDictionary+WGHookMutableDictionary.h"
    #import <objc/runtime.h>

    @implementation NSMutableDictionary (WGHookMutableDictionary)
    +(void)load {
        Class cls = NSClassFromString(@"__NSDictionaryM");
        Method method1 = class_getInstanceMethod(cls, @selector(setObject:forKeyedSubscript:));
        Method method2 = class_getInstanceMethod(cls, @selector(WG_setObject:forKeyedSubscript:));
        method_exchangeImplementations(method1, method2);
    }
    -(void)WG_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
        if (key == nil) {
            return;
        }
        [self WG_setObject:obj forKeyedSubscript:key];
    }
    @end
#### ⚠️需要注意的是NSDictionary中有很多其它的类对象名称,所以后续一定要注意区分交换方法的方法是归属可变类型还是不可变类型,因为可变/不可变类型的类对象名称是不一样的


## RunTime
#### 我们知道OC是动态性的编程语言，所谓的动态性就是将程序的一些决定性工作从编译期推迟到运行时。由于OC的运行时特性，所以OC不仅需要依赖编辑器还需要依赖运行时环境，在运行时系统中动态的创建类和对象、消息传递和转发等。而RunTime就是OC语言面向对象和动态机制的基石，RunTime是一套比较底层的纯C语言的API。高级编程语言想成为可执行文件，必须先编译为汇编语言再汇编为机器语言，而OC语言不能直接编译为汇编语言，而是先编译为C语言，然后再编辑为汇编语言和机器语言，而OC到C语言的过渡就是RunTime来完成的。

### 如何查看OC的底层代码？
#### 我们使用**clang**来查看OC的源码实现，**clang**是由Apple主导编写，基于LLVM的C/C++/Objective-C编译器.LLVM 设计思想分为前端/优化器/后端，这里的前端实际上指的就是**clang**，整个流程可以简单概括为**clang**对代码进行处理形成中间层作为输出，LLVM把CLang的输出作为输入生成机器码。接下来我们重点介绍使用**clang**编译器来将OC代码编译为C语言代码，并生成一个.cpp的C++文件
* cd 到当前文件项目的需要转化的文件目录下 
* clang -rewrite-objc WGTestModel.m 
* 在需要转化的文件目录下，会生成对应的WGTestModel.cpp文件

### 一.源码分析
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
#### 打开生成的WGTestModel.cpp文件，全局查找到WGTestModel对应的地方，以下是摘取的cpp文件的内容和RunTime源码中

#### 1.每个对象本质就是个结构体(objc_objec),结构体中包含了isa指针,该指针指向了对象所属的类

    typedef struct objc_object WGTestModel;  
    struct objc_object {
        Class _Nonnull isa;         指向自己所属的类
    };
#### 2. 通过对象的isa指针找到对象所属的类,该类也是个结构体(objc_class),并且继承自结构体objc_object,所以类也是个对象;既然是继承自objc_object,那么在类的结构体objc_class中也包含了isa指针,而这个isa指针又指向了类对象自身的元类,类对象和元类对象的类型都是Class;类对象和元类对象在内存中本质都是objc_class结构体

* 什么是元类?
元类就是类对象所属的类,元类用于描述类对象本身所具有的特征，而在元类的 methodLists 中，保存了类的方法链表，即所谓的[类方法]

        typedef struct objc_class *Class;
        struct objc_class : objc_object {
        // Class ISA;
        Class superclass;        指向当前类的父类
        cache_t cache;           用于方法缓存来加速方法的调用
        class_data_bits_t bits;  存储类的方法、属性、遵循的协议等信息的地方,可以理解为一个指针
        class_rw_t *data() {     存储方法、属性、协议列表等信息；rw可读可写
            return bits.data();
        }
        ...
        }
    
        通过class_data_bits_t和FAST_DATA_MASK找到class_rw_t
        class_rw_t* data() {
            return (class_rw_t *)(bits & FAST_DATA_MASK);
        }
    
        //存储方法、属性、协议列表等信息(如果是[类对象]这里的方法指的是[实例方法];  
        如果是[元类对象]这里的方法指的是[类方法])
        struct class_rw_t {
            const class_ro_t *ro;   存储了当前类在编译期就已经确定的属性、方法以及遵循的协议
            //下面三个都是二维数组,这三个二位数组中的数据有一部分是从class_ro_t中合并过来的
            method_array_t methods;        方法列表
            property_array_t properties;   属性列表
            protocol_array_t protocols;    协议列表
            ...
            这里是没有成员变量信息的,成员变量的信息是编译期就已经确定并添加到 class_ro_t 中去，并且只读
        }
    
        //存储了当前类在编译期就已经确定的属性、方法以及遵循的协议
        //class_ro_t意思是readonly,在编译阶段就已经确定了，不可以修改
        struct class_ro_t {         
            const char * name;                  类名(不能修改)
            uint32_t instanceSize;              对象所占用的内存大小
            method_list_t * baseMethodList;     方法列表
            protocol_list_t * baseProtocols;    协议列表
            const ivar_list_t * ivars;          成员变量列表(不能修改)
            property_list_t *baseProperties;    属性列表
            const uint8_t * weakIvarLayout;     weak 成员变量内存布局
            const uint8_t * ivarLayout;         (不能修改)
            ...
            ivarLayout:成员变量ivar内存布局，是放在我们的io里面的，并且是const不允许修改的，也就是说明，  
            我们的成员变量布局，在编译阶段就确定了，内存布局已经确定了，在运行时是不可以修改了，  
            这就说明了，为什么运行时不能往类中动态添加成员变量。
        };
        
        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_name;
        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_age;
#### OC中声明的属性，系统会自动为其生成一个带下划线的成员变量，所以我们在声明成员变量的时候规范性的以_XXX的格式进行声明    

#### 总结: 初始化一个类的过程
* 在编译期将类中已经确定的信息(属性/成员变量/方法/协议)添加到class_ro_t结构体中,这里面信息在运行时是不会改变的
* 递归初始化类的父类和元类
* 运行时会动态创建class_rw_t结构体,
* 将class_ro_t中的信息(属性/方法/协议)添加到class_rw_t结构体对应的数组中,注意成员变量仍然在class_ro_t中
* 将分类中的信息(属性/方法/协议)添加到class_rw_t结构体对应的数组中
* 在运行期,不能动态的在类中添加成员变量/弱引用成员变量/修改类名
* 为什么在运行时可以动态添加属性/方法/协议,而不能添加成员变量到类中?因为**rw**中引用了**ro**,**ro**中的属性/方法/协议添加到了我们**rw**对应的数组中,所以为动态添加提供了可能;而成员变量在**ro**中并没有添加到**rw**中,所以不能动态添加
* runtime 虽然提供了动态添加成员变量的方法 class_addIvar() ，但官方文档明确说明必须在alloc和register之间调用,程序在编译时,就已经生成了成员变量布局,程序启动后就没有机会再添加成员变量
* 我们的类实例是需要一块内存空间的，他有isa指针指向，如果我们在运行时允许动态修改成员变量的布局，那么创建出来的类实例就属于无效的了，能够被任意修改，但是属性和方法是我们 objc_class 可以管理的，增删改都不影响我们实例内存布局。

#### 3. 接下来我们解读cache_t结构体
    实际上cache_t结构体内部本质是一个散列表(哈希表),用来缓存调用过的方法,进而提高访问方法的速度
    struct cache_t {
        struct bucket_t *_buckets;     //缓存方法的散列表(也可称为数组)
        mask_t _mask;                  //总槽位-1(实际就是散列表总长度-1)
        mask_t _occupied;              //实际已经使用的槽位(已经占用的散列表长度)
        
        public:
        struct bucket_t *buckets();    //_buckets对外的一个获取函数
        mask_t mask();                 //获取缓存容量_mask
        mask_t occupied();             //获取已经占用的缓存个数_occupied
        void incrementOccupied();      //增加缓存，_occupied自++
        //设置一个新的_buckets
        void setBucketsAndMask(struct bucket_t *newBuckets, mask_t newMask);  
        void initializeToEmpty();      //初始化cache并设置为空

        mask_t capacity();             //获取_buckets的容量
            思考:为什么需要mask()+1? 扩容算法需要：expand()中的扩容算法基本逻辑 
            (最小分配的容量是4，当容量存满3/4时，进行扩容，扩容当前容量的两倍)；  
            这样最小容量4的 1/4就是1，这就是mask() + 1的原因。
            mask_t cache_t::capacity() {
                //当mask()=0时,返回0;当mask()>0时,返回mask()+1
                return mask() ? mask()+1 : 0; 
            }

        bool isConstantEmptyCache();    //判断_buckets是否为空
        bool canBeFreed();

        static size_t bytesForCapacity(uint32_t cap);
        static struct bucket_t * endMarker(struct bucket_t *b, uint32_t cap);

        void expand();  //扩容
        void reallocate(mask_t oldCapacity, mask_t newCapacity);   //重新分配
        //通过 cache_key_t 查找receiver中的 bucket_t *
        struct bucket_t * find(cache_key_t key, id receiver);

        static void bad_cache(id receiver, SEL sel, Class isa) __attribute__((noreturn));
    }
        
    bucket_t * cache_t::find(cache_key_t k, id receiver){
        assert(k != 0);
        bucket_t *b = buckets();
        mask_t m = mask();
        mask_t begin = cache_hash(k, m);    //找到对应的下标
        mask_t i = begin;
        do {
            if (b[i].key() == 0  ||  b[i].key() == k) {
                return &b[i];
            }
        } while ((i = cache_next(i, m)) != begin); //哈希表会有碰撞问题
        // hack
        Class cls = (Class)((uintptr_t)this - offsetof(objc_class, cache));
        cache_t::bad_cache(receiver, (SEL)k, cls);
    }

    //发生映射的关系是: key&mask=index,index一定是<=mask的;key就是方法名称,mask就是总槽位-1
    //散列表(又叫哈希表)的实现原理是f(key)=index,通过一个函数直接找到对应的index
    static inline mask_t cache_hash(cache_key_t key, mask_t mask) {
        return (mask_t)(key & mask);  //取余法计算索引
    }
    
    struct bucket_t {
        private:
            cache_key_t _key;    //指方法的名字:@selector()
            IMP _imp;            //函数地址
        public:
            inline cache_key_t key() const { return _key; }
            inline IMP imp() const { return (IMP)_imp; }
            inline void setKey(cache_key_t newKey) { _key = newKey; }
            inline void setImp(IMP newImp) { _imp = newImp; }
            void set(cache_key_t newKey, IMP newImp);
    };
        
* 问题1: 为什么需要cache_t?,我们知道对象调用方法的过程是这样的
1. 通过obj的isa指针找到obj的类对象Class -> 通过bits找到class_rw_t中的method_array_t方法列表,然后进行循环遍历,如果找到就调用,没有找到继续下一步
2. objc的Class对象 -> superclass父类 ->  method_array_t方法列表,循环遍历,如果找到就调用,没有找到继续找父类
3. 一直递归这样找obj的父类,如果一直到obj的根父类NSObjct -> isa -> NSObject的Class对象 -> method_array_t方法列表,如果这里仍然没有找到,就走各种判断,然后抛出异常
4. 每次调用方法都要进行这么耗时的查找流程,所以cache_t方法缓存列表出现了
5. cache_t底层是通过哈希表来实现读取的,调用过的方法会直接从cache_t缓存中获取,大大提高查找速度

        
* 问题2: 哈希表会出现碰撞问题(@selector(test)&_mask 和 @selector(test1)&_mask 的index相同时)
        当出现碰撞问题的时候,索引会查找下一个,当(i-1)=0时,因为有&mask,所以索引i = 0又回到了散列表头部,
        这样就会把散列表头尾连接起来形成一个环
        
        //例如第一次找到的下标是3，如果下标3没找到对应的IMP，那么就继续找下标为2的元素、下标为1的元素、小标为0的元素，如果下标为0仍然没有找到，就直接找到散列表的最后一位进行查找，即下标为散列表长度-1，继续进行查找
        //⚠️遍历散列表时寻找方法是按照下标递减(index-1)进行寻找的
        static inline mask_t cache_next(mask_t i, mask_t mask) {
            return i ? i-1 : mask;
        }
        
* 问题3: 当实际占用的槽位_occupied和_mask相等时,即_buckets数组有4个元素,而_occupied和_mask值都是3的时候,
        当再次添加一个缓存方法时,槽位的总量会变大为原来的 2倍(_mask*2=6) 进行扩容;
        在扩容的同时,会将哈希表里原来缓存的内容进行清空;扩容的策略就是当当前的哈希表中使用的空间占总空间的3/4时,会扩容当前使用空间的2倍
        
        void cache_t::expand(){
            cacheUpdateLock.assertLocked();
            uint32_t oldCapacity = capacity(); //获取原来的_buckets容量
            //计算新_buckets的容量;INIT_CACHE_SIZE=4,
            //如果oldCapacity==0,则使用最小容量4; 如果oldCapacity>0,则扩容两倍
            uint32_t newCapacity = oldCapacity ? oldCapacity*2 : INIT_CACHE_SIZE;
            if ((uint32_t)(mask_t)newCapacity != newCapacity) {
                // mask overflow - can't grow further
                // fixme this wastes one bit of mask
                newCapacity = oldCapacity;
            }
            reallocate(oldCapacity, newCapacity); //重新分配
        }
        
        void cache_t::reallocate(mask_t oldCapacity, mask_t newCapacity) {
            bool freeOld = canBeFreed();
            //拿到原有buckets
            bucket_t *oldBuckets = buckets();
            //创建一个新的buckets
            bucket_t *newBuckets = allocateBuckets(newCapacity);
            assert(newCapacity > 0);
            assert((uintptr_t)(mask_t)(newCapacity-1) == newCapacity-1);
            //设置新的buckets 和 mask（capacity - 1）
            setBucketsAndMask(newBuckets, newCapacity - 1);
            //抹掉原有buckets的数据
            if (freeOld) {
                cache_collect_free(oldBuckets, oldCapacity);
                cache_collect(false);
            }
        }
* 🤔思考:当扩容的时候,为什么要创建新的哈希表buckets,来抹掉旧的buckets数据,而不是在旧的buckets基础上进行扩容?
        1.减少对方法快速查找流程的影响：调用objc_msgSend时会触发方法快速查找，
        如果进行扩容需要做一些读写操作，对快速查找影响比较大。
        2.对性能要求比较高：开辟新的buckets空间并抹掉原有buckets的消耗比在原有buckets上进行扩展更加高效
        
* 问题4: 当子类没有实现方法的时候,会调用父类的方法,会将父类方法加入到子类自己的cache里

* 问题5: 什么时候缓存到cache中

        objc_msgSend第一次发送消息会触发方法查找，找到方法后会调用cache_fill()方法把方法缓存到cache中
        
        cache_fill核心代码
        void cache_fill(Class cls, SEL sel, IMP imp, id receiver) {
            mutex_locker_t lock(cacheUpdateLock);  //lock-线程锁,保证线程安全
            cache_fill_nolock(cls, sel, imp, receiver);  //填充cache
        }
        
        static void cache_fill_nolock(Class cls, SEL sel, IMP imp, id receiver) {

            //如果能找到缓存就直接返回，确保没有其它线程把方法加入到cache中
            if (cache_getImp(cls, sel)) return;
            
           
            cache_t *cache = getCache(cls);       //获取cls的cache
            cache_key_t key = getKey(sel);        //换算出sel的key

            mask_t newOccupied = cache->occupied() + 1;  //加上即将加入缓存的占用数
            mask_t capacity = cache->capacity();         //拿到当前buckets的容量
            if (cache->isConstantEmptyCache()) {         //当cache为空时，则重新分配空间；
                //当 capacity == 0时 ，使用最小的缓存空间 INIT_CACHE_SIZE = 4
                cache->reallocate(capacity, capacity ?: INIT_CACHE_SIZE);
            } else if (newOccupied <= capacity / 4 * 3) {  
                //使用的空间newOccupied<=3/4, 不需要扩容
            } else {
                //使用的空间 newOccupied > 3/4, 对cache进行扩容
                cache->expand();
            }
            //find 使用hash找到可用的bucket指针
            bucket_t *bucket = cache->find(key, receiver);
            //判断 bucket 是否可用，如果可用对齐occupied +1
            if (bucket->key() == 0) cache->incrementOccupied();
            //把缓存方法放到bucket中
            bucket->set(key, imp);
        }

* 问题6: 当调用方法的时候,先从方法缓存cache_t列表中查找**imp**,如果找到就调用,没有就走普通流程,找到后就缓存到cache_t中

#### 4. objc_class中其它的成员
        方法
        struct method_t {
            SEL name;              //函数名
            const char *types;     //包含了函数返回值、参数编码的字符串
            IMP imp;               //指向函数的指针(函数地址)
        };
        属性
        struct property_t {
            const char *name;
            const char *attributes;
        };


### 二,Runtime特性之方法调用和消息转发
#### OC中所有方法的调用都是通过Runtime实现的,Runtime进行方法发送本质上是发送消息,通过objc_msgSend()函数进行消息发送
