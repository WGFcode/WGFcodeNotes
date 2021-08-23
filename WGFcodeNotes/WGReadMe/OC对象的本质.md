## OC对象的本质

#### 1. 开发中编写的OC代码,底层其实都是C/C++代码,OC的面向对象都是基于C/C++的数据结构实现的,那么OC中的类、对象是基于C/C++的什么数据结构实现的那?答案是结构体
    Objective-C  -->  C/C++  -->  汇编语言  --> 机器语言

#### 如何证明OC中的类、对象是基于C/C++中的结构体来实现的那? 我们就需要将OC的代码转为类、对象是基于C/C++的语言
    xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc WGMain.m -o WGMain.cpp
    //创建WGMain.m文件
    #import <Foundation/Foundation.h>
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            NSObject *objc = [[NSObject alloc]init];
        }
        return 0;
    }
        
#### 在WGMain.cpp文件中我们发现了如下结构
        
        struct NSObject_IMPL {
            Class isa;
        };
        
#### 我们进入NSObject的系统声明中,发现NSObject中只有一个成员变量就是isa
    @interface NSObject <NSObject> {
        Class isa;
    }
    typedef struct object_class *Class;   //是个指针
#### 结论: 综上分析 NSObject中定义的类在C/C++中是被转成结构体对象
    @interface NSObject <NSObject> {            struct NSObject_IMPL {
        Class isa;                      --->         Class isa;
    }                                           };    

#### 2. 一个OC对象占用多少个内存空间?
        //.m文件
        @interface Person()
        {
            NSString *_name;
            int _age;
        }
        @end

        @implementation Person
        @end
        
#### 转为C/C++后的代码
        struct Person_IMPL {
            struct NSObject_IMPL NSObject_IVARS;
            int _weight;
            int _age;
        };
        struct NSObject_IMPL {
            Class isa;
        };
#### 其实上面的代码等同于下面的代码
        struct Person_IMPL {
            Class isa;    //8个字节
            int _weight;  //4个字节
            int _age;     //4个字节
        };
        
#### 接下来我们看下Person对象和NSObject对象占用的内存空间
        #import <objc/runtime.h>
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            NSLog(@"NSObject对象占用内存: %zd----Person对象占用内存: %zd",
                  class_getInstanceSize([NSObject class]),
                  class_getInstanceSize([Person class])
                  );
        }
        @end
        
        打印结果: NSObject对象占用内存: 8----Person对象占用内存: 16
#### 结论:OC对象分配的内存空间存放的是isa指针和成员变量, 而NSObject对象存放的只有一个isa指针,即分配8个字节的空间,而OC对象的内存空间是isa指针(8个字节存放isa指针)内存大小+成员变量分配的内存大小
        
        
#### 3. 实时查看内存数据
#### 3.1 方式一: 通过打断点, 然后找到要查看的对象的内存地址,然后通过Xcode -> Debug -> Debug Workflow -> View Memory -> 输入要查看的对象的内存分配情况
#### 3.2 通过LLDB指令,首先打断点,Xcode的控制台上会出现(lldb), 然后通过print XXX来查看内存,一般我们使用: p/x (long)对象 来查看内存地址,这个命令后续可以来验证实例对象的isa指针--->类对象, 类对象isa指针--->元类对象 等于真实的isa指针,类对象和元类对象的isa地址同理需要进行一次位运算才能计算出
    常用LLDB指令
    print 或者 p: 打印
    po: 打印对象
    读取内存: 
    1.memory read 内存地址
    2.memory read/数量格式字节数 内存地址
    3.x/数量格式字节数 内存地址
    格式: x是16进制、f是浮点、d是十进制
    字节大小: b(byte)1字节、h(half word)2个字节、w(word)4个字节、g(ginat work)8个字节
    修改内存中的值
    memory write 内存地址 数值

#### 4. OC对象分类,分为三类: 实例对象,类对象,元类对象
1. 实例对象: 通过类alloc出来的对象,每次通过alloc都会产生新的实例对象.实例对象在内存中存储的信息包括**isa指针**、**成员变量的值**, 

        NSObject *obj1 = [[NSObject alloc]init];
        NSObject *obj2 = [[NSObject alloc]init];
        
#### 上面的方式就是创建了两个不同的实例对象obj1、obj2,分别占据着两块不同的内存, 如果证明实例对象中存放成员变量的值?
        //Person.h文件
        @interface Person : NSObject
        {
            @public
            int _age;
        }
        @end
        //main.m文件
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                Person *objcP = [[Person alloc]init];
                objcP->_age = 4;
            }
            return 0;
        }
#### 将main.m文件转为main.cpp文件可以发现，Person实例对象中确实存在成员变量，但是如何证明存放的是值那？，我们可以通过在对成员变量赋值的地方断点，然后通过Xcode -> Debug -> Debug Workflow -> View Memory -> 输入要查看的对象(objcP)的内存分配情况,测试结果是显示的地址值为如下：
    struct Person_IMPL {
        struct NSObject_IMPL NSObject_IVARS;
        int age;
    };
    
    struct NSObject_IMPL {
        Class isa;
    };
    
    //测试案例中objcP对象的地址，可以发现前8个字节保存的是isa指针，后8个字节保存的就是成员变量age的值
    8D 13 00 00 01 80 1D 00 04 00 00 00 00 00
        
2. 类对象。获取类对象方式如下：

        //方式一: 通过调用实例对象的class方法
        Class objClass1 = [obj1 class];
        Class objClass2 = [obj2 class];
        
        //方式二: 通过调用类的class方法
        Class objClass3 = [NSObject class];
        
        //方式三: 通过RunTime的object_getClass将实例对象传递进去
        Class objClass4 = object_getClass(obj1);
        Class objClass5 = object_getClass(obj2);
        
        NSLog(@"objClass1:%p---\nobjClass2:%p---\nobjClass3:%p---\nobjClass4:%p---\nobjClass5:%p---\n",  
        objClass1, objClass2, objClass3, objClass4, objClass5);
        
        打印结果: objClass1:0x7fff89e066c0---
                objClass2:0x7fff89e066c0---
                objClass3:0x7fff89e066c0---
                objClass4:0x7fff89e066c0---
                objClass5:0x7fff89e066c0---
#### objClass1~objClass5都是NSObject的类对象; 它们是同一个对象,每个类在内存中有些仅有一个class对象(类对象)

    Person *objcP1 = [[Person alloc]init];
    Person *objcP2 = [[Person alloc]init];
    //获取Person的类对象
    //方式一
    Class objcClassP1 = [objcP1 class];
    Class objcClassP2 = [objcP2 class];
    //方式二
    Class objcClassP3 = [Person class];
    //方式三
    Class objcClassP4 = object_getClass(objcP1);
    Class objcClassP5 = object_getClass(objcP2);

    NSLog(@"\nobjcP1:%p\nobjcP2:%p\nobjcClassP1:%p\nobjcClassP2:%p\nobjcClassP3:%p\nobjcClassP4:%p  
    \nobjcClassP5:%p\n",objcP1,objcP2,objcClassP1,objcClassP2,objcClassP3,objcClassP4,objcClassP5);

    打印结果: objcP1:0x10051e090
            objcP2:0x100524100
            objcClassP1:0x100001398
            objcClassP2:0x100001398
            objcClassP3:0x100001398
            objcClassP4:0x100001398
            objcClassP5:0x100001398
#### 创建两个不同的Person对象实例，获取到的它们的类对象是一样的，再次证明了每个类在内存中只有一个类对象，但是可以创建多个实例对象              
                

#### class对象(类对象)在内存中存放的信息: **isa指针**、**superClass**、**属性信息**、**对象方法信息**、**协议信息**、**成员变量信息**(成员变量名称类型都是固定的,所以只需要一份存放在类对象中,而成员变量的值是存放在实例对象中的)**
3. 元类对象。元类对象和类对象都是Class类型

        //获取元类对象
        Person *objcP1 = [[Person alloc]init];
        Person *objcP2 = [[Person alloc]init];
        Class objcClassP1 = [Person class];
        //唯一的获取方式：通过RunTime方法将【类对象】传给方法object_getClass
        Class objcMetaClass1 = object_getClass([Person class]);
        Class objcMetaClass2 = object_getClass([objcP1 class]);
        Class objcMetaClass3 = object_getClass([objcP2 class]);
        NSLog(@"\nobjcClassP1:%p\nobjcMetaClass1:%p\nobjcMetaClass2:%p\nobjcMetaClass3:%p\n",  
        objcMetaClass1,objcMetaClass2,objcMetaClass3);
        
        打印结果: objcClassP1:0x100001398
                objcMetaClass1:0x100001370
                objcMetaClass2:0x100001370
                objcMetaClass3:0x100001370
#### 从打印结果得知：一个类的元类对象meta-class只有一个，每个类在内存中有且仅有一个元类对象,并且元类对象meta-class和类对象class是不同的对象。元类meta-class对象和类class对象的内存结构是一样的,但是用途不一样,元类在内存中存储的信息: **isa指针**、**superClass**、**类方法信息**等等

#### ⚠️注意，下面的案例,即便通过调用多次class方法，获取到的仍然是类对象，而不是元类对象
    //元类对象
    Class objcMetaClass = object_getClass([NSObject class]);
    //类对象
    Class objcClass1 = [NSObject class];
    Class objcClass2 = [[NSObject class] class];
    Class objcClass3 = [[[NSObject class] class] class];
    
    NSLog(@"\nNSObject元类对象信息:%p\nNSObject类对象信息:\nobjcClass1:%p\nobjcClass2:%p  
    \nobjcClass3:%p\n",objcMetaClass,objcClass1, objcClass2, objcClass3);

    //元类对象
    Class personMetaClass = object_getClass([Person class]);
    //类对象
    Class personClass1 = [Person class];
    Class personClass2 = [[Person class] class];
    Class personClass3 = [[[Person class] class] class];
    NSLog(@"\nPerson元类对象信息: %p\n Person类对象信息:\n personClass1:%p \n personClass2:%p  
    \n personClass3:%p \n",personMetaClass, personClass1, personClass2, personClass3);
    
    打印结果：NSObject类对象信息: 0x7fffae2bd0f0 
            NSObject类对象信息: objcClass1:0x7fffae2bd140 
                              objcClass2:0x7fffae2bd140 
                              objcClass3:0x7fffae2bd140 

    Person元类对象信息: 0x100001388
    Person类对象信息: personClass1:0x1000013b0 
                        personClass2:0x1000013b0 
                        personClass3:0x1000013b0

#### 5. isa指针
      实例对象                类对象                  元类对象
      instance               class                meta-class
      isa                     isa                   isa
      成员变量值              superclass             superclass
                            属性、对象方法、协议、      类方法
                            成员变量(名称类型)
    实例对象isa指针-->类对象    类对象isa指针-->元类对象  元类对象isa指针-->基类(NSObject)的meta-class  
                                                    基类(NSObject)的meta-class的isa指针指向它本身


#### 接下来我们来证明实例对象的isa指针指向类对象；类对象的isa指针指向元类对象；元类对象的isa指针指向基类的元类对象；基类的元类对象的isa指针指向它自身, 这里有个注意点：从64bit开始,isa需要进行一次位运算才能计算处真实的地址,即实例对象的isa指针地址 & ISA_MASK

        # if __arm64__
        #define ISA_MASK   0x0000000ffffffff8ULL
        #elif __x86_64__
        #define ISA_MASK   0x00007ffffffffff8ULL

        Person *objcP = [[Person alloc]init];
        Class objcClassP = [Person class];

#### 接下来通过Xcode断点，在控制台打印实例对象、类对象，元类对象、基类的元类对象、isa指针信息来验证
    (lldb) p/x (long)objcP->isa          
    (long) $5 = 0x001d8001000013a5   //打印实例对象的isa指针地址：0x001d8001000013a5
    (lldb) p/x (long)objcClassP
    (long) $6 = 0x00000001000013a0   //打印类对象的地址：0x00000001000013a0
    (lldb) p/x (long)objcP->isa & 0x00007ffffffffff8ULL
    (unsigned long long) $7 = 0x00000001000013a0  //打印实例对象的isa的真实地址:0x00000001000013a0
    (lldb) 
* 分析1：验证了：实例对象instance的isa指针指向了类对象class

#### 下面是**Class类型**的底层结构，但是这种结构我们无法像上面一样打印isa指针地址，所以只能通过自定义结构体，然后进行转化，然后再打印对象的isa地址
    typedef struct objc_class *Class;
    struct objc_class {
        Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
    }

    struct WG_objc_class {
        Class isa;
    };

    int main(int argc, const char * argv[]) {
        @autoreleasepool {
        Class objcClassP = [Person class];
        struct WG_objc_class *objcClassPPP=(__bridge struct WG_objc_class *)(objcClassP);
        Class objcMetaClassP = object_getClass(objcClassP);
    }
    
    p/x (long)objcClassPPP->isa         
    (long) $0 = 0x001d800100001361     //打印类对象中的isa指针的地址
    (lldb) p/x (long)objcMetaClassP   
    (long) $1 = 0x0000000100001360     //打印元类对象的地址
    (lldb) p/x (long)objcClassPPP->isa & 0x00007ffffffffff8ULL
    (unsigned long long) $2 = 0x0000000100001360   //打印类对象中isa指针的真实地址
* 分析2：验证了：类对象class中的isa指针指向了元类对象meta-class

        Class objcMetaRoot = object_getClass([NSObject class]);
        Class objcMetaClassP = object_getClass([Person class]);
        struct WG_objc_class *objcMetaClassPPP=(__bridge struct WG_objc_class *)(objcMetaClassP);
        
        (lldb) p/x (long)objcMetaClassPPP->isa
        (long) $0 = 0x001dffffae2bd0f1        //打印元类对象中isa指针的地址    
        (lldb) p/x (long)objcMetaRoot  
        (long) $1 = 0x00007fffae2bd0f0        //打印基类的元类对象的地址
        (lldb) p/x (long)objcMetaClassPPP->isa & 0x00007ffffffffff8ULL
        (unsigned long long) $2 = 0x00007fffae2bd0f0  //打印元类对象中isa指针的真实地址     
* 分析3：验证了：元类对象meta-class中的isa指针指向了基类的元类对象
        
        Class objcMetaClassR = object_getClass([NSObject class]);
        struct WG_objc_class *objcMetaClassRRR=(__bridge struct WG_objc_class *)(objcMetaClassR);

        (lldb) p/x (long)objcMetaClassRRR->isa
        (long) $0 = 0x001dffffae2bd0f1       //打印基类的元类对象中的isa指针的地址
        (lldb) p/x (long)objcMetaClassR
        (long) $1 = 0x00007fffae2bd0f0       //打印基类的元类对象的地址
        (lldb) p/x (long)objcMetaClassRRR->isa & 0x00007ffffffffff8ULL
        (unsigned long long) $2 = 0x00007fffae2bd0f0   //打印基类的元类对象中的isa指针的真实地址
        (lldb) 
* 分析4：验证了：基类的元类对象meta-class中的isa指针指向了它自身

#### 当调用**对象方法**时,通过**instance**的**isa指针**找到**class**,最后找到**对象方法**的实现进行调用; 当调用**类方法**时,通过**class**的**isa指针**找到**meta-class**,最后找到**类方法**的实现进行调用,isa作用其实就是寻找类的信息(寻找属性、协议、方法、成员变量)


#### 6. superclass
#### 从上面学习中我们知道superclass只存在于类class对象和元类meta-class对象中,我们通过如下例子来说明
#### 6.1 superclass存在于类class对象中
       @interface Student : Person   @interface Person : NSObject

       Student类对象                 Person类对象               NSObject类对象
       isa指针                       isa指针                      isa指针
       superclass                   superclass                 superclass
       属性/对象方法                  属性/对象方法                属性/对象方法
       成员变量/协议                  成员变量/协议               成员变量/协议
    superclass指针-->Person类对象   superclass-->NSObject类对象  superclass-->nil
    -(void)studentMethod         -(void)personMethod          -(void)init
       
       Student *stu = [[Student alloc]init];
       [stu studentMethod];
#### 上面方法调用过程: 通过stu的isa指针找到stu的类对象,然后在类对象中找到实例方法studentMethod进行调用
         [stu personMethod];
#### 当调用父类Person的对象方法时: 通过stu的isa指针找到stu的类对象,然后在通过stu的类对象中的superclass找到Person的类对象,在Person类对象中找到实例方法personMethod进行调用
         [stu init];
#### 当调用NSObject的init方法时: 通过stu的isa指针找到stu的类对象,然后通过stu类对象中superclass找到Person的类对象,再通过Person的类对象中的superclass找到NSObject的类对象,然后在NSObject的类对象中找到实例方法init进行调用

#### 总结: 类对象中的superclass指向父类对象的类对象; 父类对象的类对象中的superclass指向基类(NSObject)的类对象; 基类的类对象中的superclass指向nil; 所以类对象中的superclass作用一般就是为了实例方法的查找和调用

#### 6.2 superclass存在于元类meta-class对象中
    @interface Student : Person   @interface Person : NSObject

    Student元类对象                 Person元类对象              NSObject元类对象  
    isa指针                         isa指针                       isa指针
    superclass                    superclass                    superclass
    类方法                          类方法                         类方法 
    superclass指针-->Person元类对象  superclass-->NSObject元类对象 superclass-->nil
    +(void)studentClassMethod     +(void)personClassMethod      +(void)load

    [Student studentClassMethod];
    
#### 上面方法调用过程: 通过Student类对象中的的isa指针找到Student的元类对象,然后在Student的元类对象中找到类方法studentClassMethod方法进行调用
         [Student personClassMethod];
#### 当调用父类Person的类方法时: 通过Student类对象中的isa指针找到Student的元类对象,然后在通过Student的元类对象中的superclass找到Person类的元类对象,在Person元类对象中找到类方法personClassMethod进行调用
         [Student load];
#### 当调用NSObject的类方法load时: 通过Student类对象中的isa指针找到Student的元类对象,然后通过Student元类对象中superclass找到Person元类对象,再通过Person元类对象中的superclass找到NSObject的元类对象,然后再通过NSObject元类对象找到类方法load进行调用

#### 总结: 元类对象中的superclass指向父元类对象,父元类对象中的superclass指向根(NSObject)元类对象,⚠️注意根元类(NSObject)对象的superclass比较特殊, 它是指向基类(NSObject)的类对象


#### 7. isa和superclass总结
1. 实例instance对象的isa指针--->类class对象
2. 类class对象的isa指针--->元类meta-class对象
3. 元类meta-class对象的isa指针--->基元类(NSObject)meta-class对象
4. ⚠️特殊:基元类(NSObject)meta-class对象的isa指针--->它本身

5. superclass只存在于类class对象和元类meta-class对象中
6. 类class对象的superclass--->父类的类class对象
7. 父类的类class对象的superclass--->基类(NSObject)的类class对象
8. ⚠️特殊:基类(NSObject)的类class对象的superclass--->nil

9. 元类meta-class对象的superclass---> 父类的元类meta-class对象
10. 父类的元类meta-class对象中的superclass---> 基类(NSObject)的元类meta-class对象
11. ⚠️特殊:基类(NSObject)的元类meta-class对象中的superclass---> 基类(NSObject)的类class对象 

#### 8 面试题
#### 8.1  一个NSObject对象占用多少个内存空间?
* 实际上分配了16个字节的存储空间给NSObject对象
* 真正有使用的空间是: 一个指针变量所占用的大小(64bit,占8个字节; 32bit,占4个字节)
* NSObject对象本质是一个结构体,结构体中存放的是isa指针,OC中一个指针占用内存空间就是4/8字节

        验证方式一：
        //使用malloc_size 需要导入#import <malloc/malloc.h>头文件
        NSObject *objc = [[NSObject alloc]init];
        NSLog(@"实际占用内存:%zd-----系统分配内存:%zd",
        class_getInstanceSize([NSObject class]),
        malloc_size((__bridge const void *)(objc)));
        
        打印结果: 实际占用内存:8-----系统分配内存:16
        
        //1.真正使用的内存空间大小(可以理解成正在使用的成员变量所使用的空间),Runtime源码如下
        size_t class_getInstanceSize(Class cls) {
            if (!cls) return 0;
            return cls->alignedInstanceSize();
        }
        
        //类成员变量所占内存 Class's ivar size rounded up to a pointer-size boundary.
        uint32_t alignedInstanceSize() {
            return word_align(unalignedInstanceSize());
        }
        
        // May be unaligned depending on class's ivars.
        uint32_t unalignedInstanceSize() {
            assert(isRealized());
            return data()->ro->instanceSize;  //成员变量大小
        }
        
        //2. malloc_size 系统分配的内存空间大小，Runtime源码查找如下
        //_objc_rootAllocWithZone--->class_createInstance--->  
        _class_createInstanceFromZone--->instanceSize
        
        size_t instanceSize(size_t extraBytes) {
            size_t size = alignedInstanceSize() + extraBytes;
            // CF requires all objects be at least 16 bytes.
            if (size < 16) size = 16;
            return size;
        }
        如果内存小于16个字节，系统默认就分配16个字节的内存
        
#### 8.2 一个自定义类占用内存
* 案例1

        //.h文件
        @interface Person : NSObject
        @property(nonatomic, assign) int heigth;
        @end
        //.m文件
        @implementation Person
        @end
        
        Person *p = [[Person alloc]init];
        NSLog(@"实际占用内存:%zd",class_getInstanceSize([Person class]));
        NSLog(@"系统分配内存:%zd",malloc_size((__bridge const void *)(p)));
        
        打印结果：实际占用内存:16
                系统分配内存:16
#### 分析，对象实际占用的内存是这个对象中成员变量的内存大小，@property属性系统会自动生成_heigth成员变量，所以Person对象中成员变量有**isa**、**_heigth**两个成员变量，isa占用8个字节，根据内存对齐原则，虽然int heigth占4个字节，但是内存对齐是8个字节，所以_heigth成员变量也占用8个字节，所以Person对象实际占用16个字节，系统分配16个字节
* 案例2

        //.h文件
        @interface Person : NSObject
        @property(nonatomic, assign) int heigth;
        @end
        //.m文件
        @interface Person()
        {
            int _age;
        }
        @end
        
        @implementation Person
        @end
        
        Person *p = [[Person alloc]init];
        NSLog(@"实际占用内存:%zd",class_getInstanceSize([Person class]));
        NSLog(@"系统分配内存:%zd",malloc_size((__bridge const void *)(p)));
        
        打印结果： 实际占用内存:16
                 系统分配内存:16
#### 分析：现在Person对象中有3个成员变量：isa、_height、_age,isa占8个字节，_height和_age都是占4个字节，根据内存对齐，所以Person对象实际占用16字节内存，系统分配16个字节
* 案例3

        //.h文件
        @interface Person : NSObject
        @property(nonatomic, assign) int heigth;
        @end
        
        //.m文件
        @interface Person()
        {
            int _age;
            NSString *_name;
        }
        @end

        @implementation Person
        @end
        
        Person *p = [[Person alloc]init];
        NSLog(@"实际占用内存:%zd",class_getInstanceSize([Person class]));
        NSLog(@"系统分配内存:%zd",malloc_size((__bridge const void *)(p)));
        
        打印结果： 实际占用内存:32
                 系统分配内存:32
####  分析：OC对象底层结构体中成员变量的顺序是1.isa、2.成员变量、3.声明@property时，系统自动生成的属性，
* isa: 8字节
* _age: 4个字节,因为接下来是字符串占用8字节，内存对齐为8字节，所以_age要分配8个字节
* _name: 8个字节
* @property时系统自动生成的属性_heigth,4个字节，但是内存对齐，所以_heigth要分配8个字节
#### 所以Person对象实际占用8+8+8+8=32个字节，系统分配肯定是16的整数倍，所以为32个字节

#### 如果我们将_age和_name的顺序换一下
        @interface Person()
        {
            NSString *_name;
            int _age;
        }
        @end
        
        Person *p = [[Person alloc]init];
        NSLog(@"实际占用内存:%zd",class_getInstanceSize([Person class]));
        NSLog(@"系统分配内存:%zd",malloc_size((__bridge const void *)(p)));
        
        打印结果： 实际占用内存:24
                 系统分配内存:32
#### 分析： 顺序更换后，Person对象结构体中成员变量的顺序如下
* isa: 8字节
* _name: 8个字节
* _age: 4个字节，因为内存对齐，所以分配8个字节
* @property时系统生成的属性_heigth,4个字节，但是内存对齐，所以_heigth占用_age分配的8个字节中的剩余4个未用的字节
#### 所以Person对象实际占用8+8+8=24个字节，系统分配肯定是16的整数倍但是要大于实际分配的字节数(24)，所以为32个字节



* 案例4 Student继承Person

        //Person.m文件
        @interface Person()
        {
            NSString *_name;
            int _Height;   
        }
        @property(nonatomic, assign) BOOL personSex;
        @end

        //Student.m文件
        @interface Student()
        {
            int _studentHeight;  
        }
        @property(nonatomic, strong) NSString *studentName;
        @end

        Person *p = [[Person alloc]init];
        Student *stu = [[Student alloc]init];
        NSLog(@"Person实际占用内存:%zd,系统分配给Person内存:%zd\n  
        Student实际占用内存:%zd,系统分配给Student内存:%zd\n",
        
        class_getInstanceSize([Person class]),
        malloc_size((__bridge const void *)(p)),
        class_getInstanceSize([Student class]),
        malloc_size((__bridge const void *)(stu)));

        打印结果: Person实际占用内存:24,系统分配给Person内存:32
                Student实际占用内存:40,系统分配给Student内存:48
#### 分析：Person对象中的成员变量有(按顺序排列):
* isa: 占8个字节
* _name: 占8个字节
* _Height: 占4个字节，因为内存对齐，系统分配了8个字节
* @property时，系统生成的成员变量_personSex,占1个字节，刚好放在上一个成员变量_Height未被使用完的内存空间中
* 所以Person对象实际占用的内存就是 8 + 8 + 8 = 24个字节，系统分配了32个字节

#### 分析：Student对象中的成员变量有(按顺序排列): 如果类有继承，那么子类底层结构体中成员变量的顺序是先写继承自父类的成员变量，再写本类中的成员变量
* isa: 占8个字节
* 从Person类中继承来的成员变量有(按顺序排列):
* _name: 占8个字节
* _Height: 占4个字节，因为内存对齐，系统分配了8个字节
* @property时，系统生成的成员变量_personSex,占1个字节，刚好放在上一个成员变量_Height未被使用完的内存空间中
* _studentHeight: 占8个字节
* @property时，系统生成的成员变量_studentName,占8个字节
* 所以Student对象实际分配的内存是 (Student自身成员变量内存)8 + 8 + 8 + (Student继承Person的成员变量内存) 8 + 8 = 40个字节，而系统分配了48个字节


#### 注意：一般项目开发中，为了避免对象占用太大的内存，我们一般将占用内存大的成员变量写在最前面，这样就可以使用内存对齐来填补，进而减少对象占用内存空间


#### 8.3  OC的类信息存放在哪里?
* 成员变量的具体值存放在instance实例对象中
* 对象方法、属性、协议、成员变量信息(名称/类型等)存放在类class对象中
* 类方法信息存放在元类meta-class对象中

#### 8.4 对象的isa指针指向哪里?
* instance实例对象的isa指向类class对象
* 类class对象isa指针指向元类meta-class对象
* 元类meta-class对象的isa指针指向基类的元类meta-class对象
* 基类的元类meta-class对象的isa指针指向它本身


#### 9 窥探class类对象、meta-class元类对象底层结构
#### 我们知道类对象、元类对象的类型都是**Class类型**,通过在Xcode中点击**Class**进去,我们可以看到Class是一个objc_class结构体, 所以类对象和元类对象底层结构就是结构体objc_class
    typedef struct objc_class *Class;
    
#### 接下来我们来通过RunTime源码(objc源码)来窥探objc_class结构体,
    struct objc_object {
    private:
        isa_t isa;
        ...其他信息...
    }

    为什么结构体可以继承? 因为这是C++语言的结构体,C++语言结构体是可以继承的,这也是和OC语言的区别
    struct objc_class : objc_object {
        // Class ISA;
        Class superclass;
        cache_t cache;             // formerly cache pointer and vtable
        class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags

        class_rw_t *data() { 
            return bits.data();
        }
            ...其他信息...
    }
        
#### 其实上面的内容相当于下面的结构体
        struct objc_class {
            isa_t isa;
            Class superclass;
            cache_t cache;             
            class_data_bits_t bits;    
            class_rw_t *data() { 
                return bits.data();
            }
                ...其他信息...
        }
#### 通过源码我们可以总结:struct objc_class结构体中有四个成员变量，即类对象中有四个成员变量，分别是isa、superclass、cache、bits,由于类对象和元类对象结构体是一样的，所以元类对象中也有这四个成员变量，只是类信息没有的话，元类对象中对应的成员变量为空，即没有值罢了
        struct objc_class {
            isa_t isa;
            Class superclass;
            cache_t cache;            //方法缓存       
            class_data_bits_t bits;   //用于获取具体的类信息
            class_rw_t *data() { 
                return bits.data();
            }
            ...其他信息...
        }
        
        通过 bits & FAST_DATA_MASK 可以获取到 class_rw_t结构体
        struct class_rw_t {
            uint32_t flags;
            uint32_t version;
            const class_ro_t *ro;
            method_array_t methods;        //方法列表
            property_array_t properties;   //属性列表
            protocol_array_t protocols;    //协议列表
        }
        
        class_rw_t结构体中存放着class_ro_t结构体
        struct class_ro_t {
            uint32_t flags;
            uint32_t instanceStart;
            uint32_t instanceSize;        //实例对象占用的内存空间
        #ifdef __LP64__
            uint32_t reserved;
        #endif
            const uint8_t * ivarLayout;
            const char * name;            //类名称
            method_list_t * baseMethodList;
            protocol_list_t * baseProtocols;
            const ivar_list_t * ivars;    //成员变量列表
            const uint8_t * weakIvarLayout;
            property_list_t *baseProperties;
        }

#### 总结: 类对象底层结构体是objc_class，在这个结构体中主要有四个成员变量[isa、superclass、方法缓存列表cache、用于获取具体的类信息的bits], 通过bits结构体我们可获取到可读可写的结构体class_rw_t，在这个结构体中的成员主要有[方法列表、属性列表、协议列表、可读不可写的结构体class_ro_t]，而结构体class_ro_t中的成员变量主要有[成员变量列表]等信息

    objc_class结构体                         
      isa                                                         
    superclass                         
    cache方法缓存列表                    
         & FAST_DATA_MASK          
    bits ---------------->class_rw_t结构体                  
                          class_ro_t --------->class_ro_t结构体
                          methods方法列表       instanceSize实例对象占用的内存空间
                          properties属性列表    ivars成员变量列表        
                          protocols协议列表

#### 10 自我总结
#### iOS中成员变量如果写在.m文件中，那么就是私有的，只能在.m文件内访问，权限就是private，子类是无法访问的,并且在.m文件中访问不能通过**实例对象.XXX**的形式访问,而是直接XXX访问即可；如果成员变量写在.h文件中，默认的权限是@protected，在子类中是可以访问这个成员变量的，但是需要通过**self->XXX**的形式访问，如果想在除了子类的其他地方使用，需要修改权限，添加@public即可






































