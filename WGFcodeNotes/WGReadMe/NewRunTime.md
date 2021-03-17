## Runtime
### 面试题
1. 将一下OC的消息机制
* OC中的方法调用其实都是转成了objc_msgSend函数的调用,给receiver(方法调用者)发送一条消息(selector方法名)
* objc_msgSend底层有3大阶段: 消息发送阶段(在当前类、父类中查找)、动态方法解析、消息转发阶段
2. 消息转发机制流程
* 讲解清楚调用的方法和顺序即可
3. 什么是Runtime? 平时项目中有用过么?
4. @dynamic作用
* 告诉编译器不用自动生成getter/setter的实现,等到运行时再添加方法实现



### RunTime源码阅读可以通过全局搜索 WGRunTimeSourceCode 源码阅读 来快速查阅
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
        +resolveClassMethod   添加类方法的实现
2. 动态解析过后,会重新走**消息发送**的流程,“从receiverClass的cache中查找方法”这一步开始执行
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

#### 分析,当在类和父类中都没有找到方法时(**消息发送阶段**),就会走**动态解析阶段**,如果在**动态解析阶段**也没有实现方法+resolveInstanceMethod
或+resolveClassMethod方法,那么就会继续走**消息发送阶段**,并且会将这次的动态解析阶段标记为已经动态解析,显然这次的动态解析阶段什么也没有做,走完**消息发送阶段**后,发现仍然没有找到方法,那么就会来到**动态解析阶段**,发现已经动态解析过了,那么就会走**消息转发阶段**,如果实现了动态解析方法resolveInstanceMethod或resolveClassMethod方法,那么只要在对应动态方法解析的方法中添加方法的实现即可,然后标记为已动态解析,然后方法就会继续走**消息发送阶段**了,为什么又走消息发送阶段?因为在动态解析阶段已经在类对象中添加了方法实现,所以才会继续走**消息发送阶段**

#### 注意⚠️：**动态解析阶段**添加的方法实现有如下要求：方法返回值类型可以不一样，方法参数名称可以不一样，但是方法参数的类型和参数的个数要一致并且要对应上


### 3.3 消息转发阶段
#### **消息发送阶段**和**动态解析阶段**都找不到方法或没有处理,就会进入**消息转发阶段**

    (1)调用forwardingTargetForSelector方法---返回值为nil--->(2)objc_megSend(返回值,SEL)
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
    ///1.方法一,消息转发:将消息转发给别人,将方法交给一个指定的对象去实现
    -(id)forwardingTargetForSelector:(SEL)aSelector {
        if (aSelector == @selector(test)) {
            //底层实际上是这么处理的:objc_msgSend([[Student alloc]init], aSelector)
            return [[Student alloc]init];
        }
        return 0;
    }
    
    ⚠️：这里Student对象中的方法有如下要求：方法名必须和调用的方法名要一致，方法参数类型要一致,参数名称可以不一致；方法返回值类型可以不一致

    /// 2.如果方法一没有实现(相当于返回nil),或者返回值为nil,就继续调用下面这个方法
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

#### 详细刨析,如果我们仅仅是为了像案例中的一样,指定一个方法接收者,那么完全不用这么麻烦,直接在**动态方法解析阶段**直接指定一个方法接收者即可,为什么还要这么麻烦的进行**消息转发阶段**那?
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
        //如果消息转发的是类方法,那么这个方法应该也是类方法,所以方法用+号,但是一般我们直接敲方法出来的都是实例方法,因为编译器对于类方法没有提示,所以我们需要根据方法类型来决定是用+还是-
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
         2.@synthesize age = _age; 为age属性生成_age的成员变量,并且自动生成getter/setter方法的实现,这里可以指定成员变量的
         名称,例如也可以这样写@synthesize age = _age1111;
         */
        @synthesize age = _age;

        /*
         如果我们不希望Xcode自动帮我们生成属性的getter/setter方法的实现,可以这么写@dynamic age;
         提醒编译器不要自动生成getter/setter的实现,不要自动生成成员变量
         外部仍然可以调用setAge方法,因为@dynamic并步影响属性的getter/setter方法的声明
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
        ((void (*)(__rw_objc_super *, SEL))(void *)objc_msgSendSuper)((__rw_objc_super){(id)self, (id)class_getSuperclass(objc_getClass("Student"))}, sel_registerName("run"));
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
        __rw_objc_super(struct objc_object *o, struct objc_object *s) : object(o), superClass(s) {} 
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

### 6 消息转发机制用途,
#### 利用消息转发机制,可以实现项目中永远不会出现因为unrecognized selector sent to instance而crash闪退

