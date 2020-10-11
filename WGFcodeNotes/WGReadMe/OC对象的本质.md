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
#### 结论: 综上分析 NSObject中定义的类在C/C++中是被转成结构体对象的
        @interface NSObject <NSObject> {            struct NSObject_IMPL {
            Class isa;                      --->         Class isa;
        }                                           };    


#### 2. 一个OC对象占用多少个内存空间?
#### 我们知道一个NSObject对象占用8个字节的内存空间,这8个字节存放的是NSObject对象的isa指针,那么如果是下面的对象哪? 
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
#### 3.2 通过LLDB指令,首先打断点,Xcode的控制台上会出现(lldb), 然后通过print XXX来查看内存,一般我们使用: p/x (long)对象 来查看内存地址,这个命令后续可以来验证实例对象的isa指针--->类对象, 类对象isa指针--->元类对象,但是这个验证过程中需要⚠️注意, 从64bit开始,isa需要进行一次位运算才能计算处真实的地址,即实例对象的isa指针地址 & ISA_MASK 等于真实的isa指针,类对象和元类对象的isa地址同理需要进行一次位运算才能计算出
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
        
        
#### 4. 更复杂的OC对象占用的内存大小
#### 假如Person继承自NSObject, Student又继承自Person,那么Person和Student对象各占有多少内存空间?
        @interface Person()
        {
            int _age;
        }
        @end

        @interface Student()
        {
            int _weight;
        }
        @end

#### 通过上面的学习我们知道上面的C/C++代码是这样的

        struct NSObject_IMPL {
            Class isa;
        };

        struct Person_IMPL {
            struct NSObject_IMPL NSObject_IVARS;
            int _age;
        };

        struct Student_IMPL {
            struct Person_IMPL Person_IVARS;
            int _weight;
        };

#### 首先我们计算Person对象的内存大小,Person对象的结构体中有isa指针和age成员变量,isa指针占用8个字节,age成员变量占4个字节,但是因为存在内存对其原则,我们知道Person_IMPL结构体的内存对齐大小为8个字节,所以Person对象占用16个字节的大小(isa占8个字节,age成员变量虽然占4个字节,但是因为内存对齐,所以系统会分配8个字节); 再看Student对象,因为Person_IMPL结构体专用16个字节,而weight成员变量占4个字节由于内存对齐,所以可以刚好放进Person_IMPL结构体中没有被填充的4个字节的内存空间中,所以Student对象也占16个字节.


#### 5. OC对象分类,分为三类: 实例对象,类对象,元类对象
1. 实例对象: 通过类alloc出来的对象,每次通过alloc都会产生新的实例对象.实例对象在内存中存储的信息包括**isa指针**、**成员变量的值**, 

        NSObject *obj1 = [[NSObject alloc]init];
        NSObject *obj2 = [[NSObject alloc]init];
        
#### 上面的方式就是创建了两个不同的实例对象obj1、obj2,分别占据着两块不同的内存
        
2. 类对象

        //获取类对象方式
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
#### class对象(类对象)在内存中存放的信息: **isa指针**、**superClass**、**属性信息**、**对象方法信息**、**协议信息**、**成员变量信息(成员变量名称类型都是固定的,所以只需要一份存放在类对象中,而成员变量的值是存放在实例对象中的)**
3. 元类对象

        //获取元类对象---元类对象和类对象都是Class类型
        //通过RunTime的object_getClass将类对象传递进去
        Class objcMetaClass = object_getClass([NSObject class]);
        //为了验证元类对象和类对象不是同一个对象
        Class objClass = [NSObject class];
        NSLog(@"objcMetaClass:%p---\nobjClass:%p---\n",objcMetaClass, objClass);

        打印结果: objcMetaClass:0x7fff89e06698---
                objClass:0x7fff89e066c0---
#### 从上面打印结果我们可以知道,元类meta-class对象和类class对象是不同的对象; 每个类在内存中有且仅有一个元类meta-class对象; 元类meta-class对象和类class对象的内存结构是一样的,但是用途不一样,在内存中存储的信息: **isa指针**、**superClass**、**类方法信息**等等

#### 这里需要⚠️注意,下面的代码,无论通过[NSObject class] class多少次class方法,获取到的对象仍然是类对象,而不是元类对象
        //获取类对象
        Class objClass = [NSObject class];
        //获取元类对象
        Class objcMetaClass = object_getClass([NSObject class]);
        //通过类的class方法获取到类对象,再通过类对象的class方法获取对象
        Class cls1 = [[NSObject class] class];
        Class cls2 = [[[NSObject class] class] class];
        NSLog(@"objcMetaClass:%p---\nobjClass:%p---\ncls1:%p---\ncls2:%p---\n",objcMetaClass, objClass,cls1,cls2);
        
        打印结果: bjcMetaClass:0x7fff89e06698---
                objClass:0x7fff89e066c0---
                cls1:0x7fff89e066c0---
                cls2:0x7fff89e066c0---

#### 6. isa指针
      实例对象                   类对象                    元类对象
      instance                  class                    meta-class
      isa                       isa                      isa
      成员变量值                  superclass               superclass
                                属性、对象方法、协议、       类方法
                                成员变量(名称类型)
      实例对象isa指针-->类对象     类对象isa指针-->元类对象    元类对象isa指针-->基类(NSObject)的meta-class
                                                        基类(NSObject)的meta-class的isa指针指向它本身

#### 当调用**对象方法**时,通过**instance**的**isa指针**找到**class**,最后找到**对象方法**的实现进行调用; 当调用**类方法**时,通过**class**的**isa指针**找到**meta-class**,最后找到**类方法**的实现进行调用


#### 7. superclass
#### 从上面学习中我们知道superclass只存在于类class对象和元类meta-class对象中,我们通过如下例子来说明
#### 7.1 superclass存在于类class对象中
       @interface Student : Person               @interface Person : NSObject

       Student类对象                      Person类对象                    NSObject类对象
       isa指针                            isa指针                        isa指针
       superclass                        superclass                     superclass
       属性/对象方法                       属性/对象方法                    属性/对象方法
       成员变量/协议                       成员变量/协议                    成员变量/协议
       superclass指针-->Person类对象       superclass-->NSObject类对象     superclass-->nil
       -(void)studentMethod              -(void)personMethod            -(void)init
       //+(void)studentClassMethod         -(void)personClassMethod       +(void)load
       
       Student *stu = [[Student alloc]init];
       [stu studentMethod];
#### 上面方法调用过程: 通过stu的isa指针找到stu的类对象,然后在类对象中找到studentMethod方法进行调用
         [stu personMethod];
#### 当调用父类Person的对象方法时: 通过stu的isa指针找到stu的类对象,然后在通过stu类对象中的superclass找到Person类对象,在Person类对象中找到personMethod方法进行调用
         [stu init];
#### 当调用NSObject的init方法时: 通过stu的isa指针找到stu的类对象,然后通过stu类对象中superclass找到Person类对象,再通过Person类对象superclass找到NSObject的类对象,然后在NSObject类对象中找到实例方法init进行调用

#### 总结: 类对象中的superclass指向父类对象的类对象; 父类对象的类对象中的superclass指向基类(NSObject)的类对象; 基类的类对象中的superclass指向nil; 所以类对象中的superclass作用一般就是为了方法查找和调用

#### 7.2 superclass存在于元类meta-class对象中
        @interface Student : Person               @interface Person : NSObject

        Student元类对象                     Person元类对象                    NSObject元类对象  
        isa指针                            isa指针                        isa指针
        superclass                        superclass                     superclass
        类方法                             类方法                          类方法 
        superclass指针-->Person元类对象      superclass-->NSObject元类对象     superclass-->nil
        +(void)studentClassMethod         +(void)personClassMethod       +(void)load

       [Student studentClassMethod];
#### 上面方法调用过程: 通过Student的isa指针找到Student的元类对象,然后在Student元类对象中找到studentClassMethod方法进行调用
         [Student personClassMethod];
#### 当调用父类Person的类方法时: 通过Student的isa指针找到Student的元类对象,然后在通过Student的元类对象中的superclass找到Person元类对象,在Person元类对象中找到personClassMethod方法进行调用
         [Student load];
#### 当调用NSObject的load方法时: 通过Student的isa指针找到Student的元类对象,然后通过Student元类对象中superclass找到Person元类对象,再通过Person元类对象中的superclass找到NSObject的元类对象,然后在NSObject元类对象中找到类方法load进行调用

#### 总结: 元类对象中的superclass指向父元类对象,父元类对象中的superclass指向根(NSObject)元类对象,⚠️注意根元类(NSObject)对象的superclass比较特殊, 它是指向基类(NSObject)的类对象


#### 8. isa和superclass总结
1. instance对象的isa指针--->class对象
2. class对象的isa指针--->meta-class对象
3. meta-class对象的isa指针--->基类(NSObject)的meta-class对象
4. ⚠️特殊:基类(NSObject)的meta-class对象的isa指针--->它本身

5. superclass只存在于class对象和meta-class对象中
6. class对象的superclass--->父类的class对象
7. 父类的class对象的superclass--->基类(NSObject)的class对象
8. ⚠️特殊:基类(NSObject)的class对象的superclass--->nil

9. meta-class对象的superclass---> 父类的meta-class对象
10. 父类的meta-class对象中的superclass---> 基类(NSObject)的meta-class对象
11. ⚠️特殊:基类(NSObject)的meta-class对象中的superclass---> 基类(NSObject)的class对象 

#### 9 面试题
#### 9.1  一个NSObject对象占用多少个内存空间?
* 实际上分配了16个字节的存储空间给NSObject对象
* 真正有使用的空间是: 一个指针变量所占用的大小(64bit,占8个字节; 32bit,占4个字节)
* NSObject对象本质是一个结构体,结构体中存放的是isa指针,OC中一个指针占用内存空间就是4/8字节

        // 使用malloc_size 需要导入#import <malloc/malloc.h>头文件
        //malloc_size 系统分配的内存空间大小
        //class_getInstanceSize: 真正使用的内存空间大小(可以理解成正在使用的成员变量所使用的空间)
        //⚠️这两个方法底层实现可以通过RunTime源码可以查找到,后续可以自己看一下
        
        NSObject *objc = [[NSObject alloc]init];
        NSLog(@"%zd-----%zd",class_getInstanceSize([NSObject class]), malloc_size((__bridge const void *)(objc)));
        
        打印结果: 8-----16


#### 9.2  OC的类信息存放在哪里?
* 成员变量的具体值存放在instance实例对象中
* 对象方法、属性、协议、成员变量信息(名称/类型等)存放在类class对象中
* 类方法信息存放在元类meta-class对象中

#### 9.3 对象的isa指针指向哪里?
* instance实例对象的isa指向类class对象
* 类class对象isa指针指向元类meta-class对象中
* 元类meta-class对象的isa指针指向基类的元类meta-class对象中
* 基类的元类meta-class对象的isa指针指向它本身


#### 10 窥探class类对象、meta-class元类对象底层结构
#### 我们知道类对象、元类对象的类型都是**Class类型**,通过在Xcode中点击**Class**进去,我们可以看到Class是一个objc_class结构体, 所以类对象和元类对象底层结构就是结构体objc_class
    typedef struct objc_class *Class;
    
#### 接下来我们来通过RunTime源码(objc源码)来窥探objc_class结构体,
        struct objc_object {
        private:
            isa_t isa;
            ...其他信息...
        }
    
        //为什么结构体可以继承? 因为这是C++语言的结构体,C++语言结构体是可以继承的
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
        
        其实上面的内容相当于下面的结构体
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
#### 通过源码我们可以总结:struct objc_class结构体中有四个成员变量
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
        
        //通过 bits & FAST_DATA_MASK 可以获取到 class_rw_t结构体
        struct class_rw_t {
            uint32_t flags;
            uint32_t version;
            const class_ro_t *ro;
            method_array_t methods;        //方法列表
            property_array_t properties;   //属性列表
            protocol_array_t protocols;    //协议列表
        }
        //class_rw_t结构体中存放着class_ro_t结构体
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
