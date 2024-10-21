### Block系统性总结

### 1. block本质及底层结构
#### 1.1 block本质也是个OC对象,它内部也有isa指针.block是封装了函数调用以及函数环境的OC对象
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            void (^block)(void) = ^{
                NSLog(@"123123");
            };
            block();
        }
        return 0;
    }
#### 通过xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m 生成C++文件
    int main(int argc, const char * argv[]) {
        /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
            void (*block)(void) = ((void (*)())&__main_block_impl_0(  
            (void *)__main_block_func_0,   
            &__main_block_desc_0_DATA));
            ((void (*)(__block_impl *))((__block_impl *)block)->  
            FuncPtr)((__block_impl *)block);
        }
        return 0;
    }
    
    简化后(取出强制转化的代码)
    int main(int argc, const char * argv[]) {
        { __AtAutoreleasePool __autoreleasepool; 
            //定义block变量: 将函数传递两个参数,然后将函数返回值的地址赋值给void (*block)(void)
            void (*block)(void) = &__main_block_impl_0(
            __main_block_func_0, &__main_block_desc_0_DATA));
            //执行block内部代码
            block->FuncPtr)(block);
        }
        return 0;
    }
        
#### 1.2__main_block_impl_0函数内部结构,结构体名称和方法名称一样,这种写法是C++语言的语法,这种方法叫做**构造函数**,同时这个方法没有写返回值,其实类似于OC中的init方法,该函数的返回值就是__main_block_impl_0结构体对象本身
    struct __main_block_impl_0 {  
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        //C++构造函数,返回值就是这个结构体(__main_block_impl_0)对象本身,  
        这里有三个参数,但外面传递进来的只有2个参数,其实这就是C++语言特性:可以设置默认值,类似于swift
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
        
    struct __block_impl {
      void *isa;
      int Flags;
      int Reserved;
      void *FuncPtr;
    };
#### 从上面分析中我们可以知道下面的代码中,通过函数__main_block_impl_0返回的就是这个结构体(__main_block_impl_0)对象本身,然后将这个结构体的地址赋值给了block, 所以block底层本质其实就是个结构体对象
        void (*block)(void) = &__main_block_impl_0(
        __main_block_func_0, 
        &__main_block_desc_0_DATA));
        
#### __main_block_impl_0函数参数分析
        参数1: __main_block_func_0,封装了block执行逻辑的函数,简单就是将block中的任务封装到了__main_block_func_0这个函数中
        static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
            NSLog((NSString *)&  
            __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_5ad538_mi_0);
        }
        
        参数2: __main_block_desc_0_DATA, 存放block额外信息的结构体
        static struct __main_block_desc_0 {
          size_t reserved;     //保留字段,默认是0
          size_t Block_size;   //结构体__main_block_impl_0所占的内存大小,其实就是block所占内存大小
        } __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};

#### 1.3 block底层结构总结
    void (^block)(void) = ^{
        NSLog(@"123123");
    };
    
    //1. 底层是__main_block_impl_0结构体,里面至少保存了两个成员变量
    struct __main_block_impl_0 {
        struct __block_impl impl;           //保存了block内代码/任务的执行    
        struct __main_block_desc_0* Desc;   //block的描述信息
        //构造函数这里先省略
    };
        
    //2. 保存了block内代码/任务的执行 
    struct __block_impl {
      void *isa;
      int Flags;
      int Reserved;
      void *FuncPtr;   //指向将来执行block内函数的地址
    };
    
    //3. block的描述信息
    static struct __main_block_desc_0 {
      size_t reserved;
      size_t Block_size;
    }
#### 1.4 block执行过程分析
    //定义block变量: 将函数传递两个参数,然后将函数返回值的地址赋值给void (*block)(void)
    void (*block)(void) = &__main_block_impl_0(
    __main_block_func_0, &__main_block_desc_0_DATA));
    
    //执行block内部代码
    block->FuncPtr)(block);
#### 从上面我们知道block指向的是结构体__main_block_impl_0,但是__main_block_impl_0结构体中并没有FuncPtr成员变量,这里其实是做了强制类型转化,为什么可以转化?因为__main_block_impl_0结构体的地址其实也是它内部第一个成员变量的地址,所以也就是__block_impl结构体的地址,这样就可以找到block函数实现的地址FuncPtr,然后进行函数调用

### 2. block变量的捕获
#### 变量分为局部变量(auto自动变量+static静态变量)和全局变量,默认是auto自动变量,自动变量离开了作用域就会销毁
#### 2.1 block捕获局部变量-auto自动变量
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            //auto自动变量,离开了作用域就会销毁
            int age = 10;
            void (^block)(void) = ^{
                NSLog(@"my age is: %d",age);
            };
            age = 20;
            block();
        }
        return 0;
    }
    
    打印结果: my age is: 10
        
#### 简化后C++代码
    int age = 10;
    void (*block)(void) = &__main_block_impl_0(
    __main_block_func_0, &__main_block_desc_0_DATA, age));
    age = 20;
    block->FuncPtr(block);
    
    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int age = __cself->age; // bound by copy
        NSLog((NSString *)  
        &__NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_7ea761_mi_0,
        age);
    }
        
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        //block底层结构中多了一个成员变量
        int age;   
        //参数中age(_age)是C++语法,表示将_age的值赋值给age,即赋值给block的成员变量age
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
        int _age, int flags=0) : age(_age) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 分析,block捕获自动变量时,是底层自动生成了和外部自动变量类型/名称一样的变量,用来保存外部自动变量的值,是值捕获

#### 2.2 block捕获局部变量-static静态局部变量
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            int age = 10;
            static int height = 100;
            void (^block)(void) = ^{
                NSLog(@"my age is: %d, my height is: %d",age,height);
            };
            age = 20;
            height = 200;
            block();
        }
        return 0;
    }
    
    打印结果: my age is: 10, my height is: 200
        
#### 简化后C++代码
     int age = 10;
     static int height = 100;
     void (*block)(void) = &__main_block_impl_0(__main_block_func_0, 
     &__main_block_desc_0_DATA, age, &height));  //将height的地址传递给这个函数
     age = 20;
     height = 200;
     block->FuncPtr(block);
        
    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
        int age = __cself->age; // bound by copy
        int *height = __cself->height; // bound by copy
        NSLog((NSString *)&  
        __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_999b2c_mi_0,
        age,(*height));
    }
        
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        //因为block底层生成了对应的成员变量,所以block对局部变量都会捕获,无论是自动变量还是静态变量
        int age;
        int *height;  
        //age(_age):将_age的值赋值给age; height(_height):将外部传建立的_height赋值给height
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,  
        int _age, int *_height, int flags=0) : age(_age), height(_height) {  
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 分析,block捕获static静态变量时,是底层自动生成了和外部静态变量名称一样的变量指针,用来保存外部自动变量的地址,也就是block中生成的变量地址和外部静态变量的地址是一样的,所以外部改变静态变量的值,block内部的值也跟着改变,是指针捕获

#### 思考: 为什么block捕获auto自定变量是**值传递**,而捕获static静态变量是**指针传递**? 因为对于自动变量,出了作用域就会被销毁,所以block要在访问时,先保存它的值,来避免访问已经销毁的自动变量而发生错误.而对于static变量的值,static变量即便离开了作用域,它仍然存在于内存中,直接通过指针就可以随时访问到它最新的值


#### 2.3 block捕获全局变量(全局变量+全局静态变量)
    int age = 10;            //全局变量
    static int height = 100; //全局静态变量
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            void (^block)(void) = ^{
                NSLog(@"my age is: %d, my height is: %d",age,height);
            };
            age = 20;
            height = 200;
            block();
        }
        return 0;
    }

    打印结果: my age is: 20, my height is: 200
        
#### 简化后C++代码
    void (*block)(void) = &__main_block_impl_0(__main_block_func_0, 
    &__main_block_desc_0_DATA));
    age = 20;
    height = 200;
    block->FuncPtr(block);

    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
        NSLog((NSString *)&  
        __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_9a7948_mi_0,
        age,height); //直接访问外部的全局变量即可,不需要捕获
    }

    int age = 10;
    static int height = 100;
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        //这里并没有生成对应的成员变量,所以block对全局变量(全局变量+全局静态变量)是不会捕获的
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };

#### 分析,block对全局变量是不会捕获的,因为全局变量是一直存在于内存中的,直接访问即可. 为什么全局变量不需要捕获? 因为全局变量在什么地方都可以访问,所以block不需要捕获
#### 思考? 为什么局部变量需要捕获? 主要还是因为局部变量作用域的问题,局部变量是跨函数访问,定义的地方和访问的地方不是同一个函数,所以需要捕获


#### 2.4 案例
#### 下面block中是否会捕获self?
    //WGPerson.h文件
    @interface WGPerson : NSObject
    -(void)test;
    @end

    //WGPerson.m文件
    @implementation WGPerson
    -(void)test {
        void (^block)(void) = ^{
            NSLog(@"-----%@",self);
        };
        block();
    }
    @end
        
#### 简化后的C++代码
    // test()方法转化后,可以发现调用test方法,实际传递了两个参数:  
    self对象本身,还有就是方法名称,函数参数也是局部变量,既然是局部变量,那么就都会被block捕获
    static void _I_WGPerson_test(WGPerson * self, SEL _cmd) {
        //将self作为参数再传递给block底层构造方法,
        void (*block)(void) = &__WGPerson__test_block_impl_0(
        __WGPerson__test_block_func_0, &__WGPerson__test_block_desc_0_DATA, 
        self, 570425344));
        block->FuncPtr(block);
    }
        
    struct __WGPerson__test_block_impl_0 {
        struct __block_impl impl;
        struct __WGPerson__test_block_desc_0* Desc;
        //生成对应的成员变量
        WGPerson *self;  
        //self(_self)接收外部传递进来的_self参数,然后赋值给self
        __WGPerson__test_block_impl_0(void *fp, 
        struct __WGPerson__test_block_desc_0 *desc, 
        WGPerson *_self, int flags=0) : self(_self) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        } 
    };
#### 分析,调用对象的方法,底层实际是传递了两个参数: 一个是对象本身self,一个是方法SEL,既然是参数,那么就是局部变量,只要是局部变量,那么就一定会被block捕获. 如果在案例test方法的block中访问WGPerson的成员变量,那么实际block上捕获的是WGPerson对象self本身,然后通过self再去访问它的成员变量



#### 总结
#### 为了保证block内部能够正常访问外部的变量,block有变量捕获机制
                 变量类型            捕获到block内部        访问方式
    局部变量      auto               捕获                  值传递
                static              捕获                  指针传递
    全局变量      全局变量            不捕获                 直接访问

### 3. block类型
#### 3.1 block有3中类型,可以通过调用**class**方法或isa指针查看具体类型,最终都是继承自NSBlock类型
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
        //类型一->继承关系: __NSGlobalBlock__:__NSGlobalBlock:NSBlock:NSObject:(null)
            void (^block)(void) = ^{
                NSLog(@"hello world");
            };
            NSLog(@"%@",[block class]);     //block类对象
            NSLog(@"%@",[[block class] superclass]);  //block类对象的父类
            //block类对象的父类的父类
            NSLog(@"%@",[[[block class] superclass] superclass]);  
            NSLog(@"%@",[[[[block class] superclass] superclass] superclass]);  
            NSLog(@"%@",[[[[[block class] superclass] superclass] superclass] superclass]); 
        }
        return 0;
    }

    打印结果: __NSGlobalBlock__
            __NSGlobalBlock
            NSBlock
            NSObject
            (null)
            
    struct __block_impl {
      void *isa;
      int Flags;
      int Reserved;
      void *FuncPtr;
    };
#### 分析,从结果打印可知,block本质就是一个OC对象,最终是继承自NSBlock类型, 基类就是NSObject, 那么就可以明白之前研究的block底层结构中的**isa**指针就是从NSObject中继承来的, 同理我们可以打印其他block类型
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
        //类型二->继承关系:__NSMallocBlock__:__NSMallocBlock:NSBlock:NSObject:(null)
            int age = 10;
            void (^block)(void) = ^{
                NSLog(@"hello world---%d",age);
            };
            block();
        }
        return 0;
    }
        
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
        //类型三->继承关系:  __NSStackBlock__:__NSStackBlock:NSBlock:NSObject:(null)
            int age = 10;
            NSLog(@"--%@---%@---%@",[^{
                NSLog(@"----%d",age);
            } class],  
            [[^{} class] superclass],[[[^{} class] superclass] superclass]);
        }
        return 0;
    }
    打印结果: --__NSStackBlock__---__NSGlobalBlock---NSBlock

#### 分析,OS中block类型分为三种__NSGlobalBlock__/__NSMallocBlock__/__NSStackBlock__

#### 3.2 编译后的block类型和真实打印block类型的差异
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            //__NSGlobalBlock__
            void (^block1)(void) = ^{
                NSLog(@"hello world");
            };
            //__NSStackBlock__
            int age = 10;
            void (^block2)(void) = ^{
                NSLog(@"hello world---%d",age);
            };
            //__NSStackBlock__
            NSLog(@"%@ %@ %@",[block1 class],[block2 class],[^{
                NSLog(@"%d",age);
            } class]);
        }
        return 0;
    }
        
#### 简化为C++代码后
    //block1
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        __main_block_impl_0(void *fp, 
        struct __main_block_desc_0 *desc, int flags=0) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
    //block2
    struct __main_block_impl_1 {
        struct __block_impl impl;
        struct __main_block_desc_1* Desc;
        int age;
        __main_block_impl_1(void *fp, 
        struct __main_block_desc_1 *desc, int _age, int flags=0) : age(_age) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 分析,我们可以看出编译后的block的**isa**都指向了**&_NSConcreteStackBlock**类型,这个和我们运行打印的结果是不一样的, 为什么? 我们一切以Runtime运行时为准,我们通过**clang**生成的C++代码并不是我们OC真正生成的代码,会有一些差异化的改变,只是可以作为参考,因为**LLVM**编译器从某个版本开始,不在生成C++代码,而是生成了一种中间文件,这种中间文件和我们**clang**出来的C++文件还是有所差别的,但是差别不大,(clang是属于LLVM编译器种的一部分)

#### 3.3 block类型总结
    应用程序的内存分配:
        程序区域(.text区): 程序代码
        数据区域(.data区): 全局变量/static变量
        堆区: alloc/malloc出来的对象,动态分配内存,需要我们程序员自己申请和管理内存
        栈区: 局部变量,函数参数等
    
    __NSGlobalBlock__(NSConcreteGlobalBlock): 数据区
    __NSMallocBlock__(_NSConcreteMallocBlock): 堆区 
    __NSStackBlock__(_NSConcreteStackBlock): 栈区
        
#### 3.4 block类型区别
    int height = 100;
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            void (^block1)(void) = ^{
                NSLog(@"hello world---");
            };
            NSLog(@"block1----%@",[block1 class]);

            static int age = 10;
            void (^block2)(void) = ^{
                NSLog(@"my age is: %d",age);
            };
            NSLog(@"block2----%@",[block2 class]);
            
            void (^block3)(void) = ^{
                NSLog(@"my height is: %d",height);
            };
            NSLog(@"block3----%@",[block3 class]);
        }
        return 0;
    }
        
    打印结果: block1----__NSGlobalBlock__
            block2----__NSGlobalBlock__
            block3----__NSGlobalBlock__
                
#### 分析,没有访问auto自动变量的都是NSGlobalBlock类型的, 存放在数据段中. 为什么访问了static静态变量/全局变量的block是NSGlobalBlock类型? 推测可能是因为这些变量存储在数据段中,离开作用域不会销毁的原因
    int age = 10;
    void (^block)(void) = ^{
        NSLog(@"my age is: %d",age);
    };
    block();
    NSLog(@"%@",[block class]);
    
    //在MRC(手动管理内存)环境下
    打印结果: my age is: 10
            __NSStackBlock__

    //在ARC(自动管理内存)环境下
    打印结果: my age is: 10
            __NSMallocBlock__
#### 分析,访问了auto变量的block在ARC环境下就是__NSMallocBlock__类型,在MRC环境下就是__NSStackBlock__类型,为什么ARC和MRC环境下,block类型会不一致? 原因就是栈(NSStackBlock)类型block会随时销毁的,我们控制不了,在ARC自动管理内存中,ARC底层已经帮我们做了事来保证block不会被销毁,所以将栈(NSStackBlock)类型的block **变成了**  堆(NSMallocBlock)类型的block,即将栈block做了一次copy变成了堆block
    
#### 3.5 block类型区分总结
             block类型                          环境
    全局block:__NSGlobalBlock__(数据区)  没有访问auto变量(不访问变量/访问static变量/访问全局变量)
    栈block:__NSStackBlock__(栈区)      访问了auto变量(在Block内部使用局部变量或者OC属性，并且赋值给强引用或者Copy修饰的变量)
    堆block:__NSMallocBlock__(堆区)     __NSStackBlock__调用了copy(与 MallocBlock一样，可以在内部使用局部变量或者OC属性。但是不能赋值给强引用或者Copy修饰的变)

#### 每种block调用copy后的结果
             block类型                  副本源的配置存储域     copy复制效果
    全局block:__NSGlobalBlock             程序的数据区域      什么也不做
    栈block:__NSStackBlock__(栈区)             栈           从栈复制到堆
    堆block:__NSMallocBlock__(堆区)            堆           引用计数增加  
        
### 4 block的copy操作
#### 在ARC环境下,编译器会根据情况自动将栈上的block复制到堆上,什么情况下会发生?
1. block作为函数返回值时
2. 将block赋值给__strong指针时(对象默认创建的都是强指针,只是省略了__strong关键词)
3. block作为Cocoa API中方法名含有usingBlock的方法参数时
4. block作为GCD API的方法参数时

### 5 block捕获-对象类型的auto变量
    //WGPerson.m文件
    @implementation WGPerson
    -(void)dealloc {
        NSLog(@"%s",__func__);
    }
    @end

    typedef void (^WGBlock)(void);
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            {
                WGPerson *person = [[WGPerson alloc]init];
                person.age = 10;
            }
            打断点: NSLog(@"-----");  
        }
        return 0;
    }
    
    打印结果: -[WGPerson dealloc]
#### 分析, 当出了{}大括号后,WGPerson对象就销毁了,因为{}大括号中的WGPerson对象是局部变量,离开作用域就会销毁,这个很好理解,接下来再分析

    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            WGBlock block;
            {
                WGPerson *person = [[WGPerson alloc]init];
                person.age = 10;
                block = ^{
                    NSLog(@"------%d",person.age);
                };
            }
            打断点: NSLog(@"-----");
        }
        return 0;
    }
    
    打印结果: ------10
#### 分析,发现WGPerson对象出了{}大括号后并没有销毁,因为没有打印信息: -[WGPerson dealloc],为什么? 因为block内部访问了person.age,即访问了person对象,那么会对person对象进行强引用, 只有block销毁了person对象才会销毁, 这里的block类型其实就是堆block,因为它被__strong指针引用着(WGBlock block;默认情况下就是__strong,只是省略了而已)

#### 转为C++代码
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        WGPerson *person;   //这里自动生成了成员变量来保存外部的person对象的指针
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
        WGPerson *_person, int flags=0) : person(_person) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
        
#### 上面的验证都是在ARC环境下,block类型是堆block,因为block有强指针(__strong)引用着,接下来我们看下如果在MRC环境下有什么变化, 在Build Settings中将Objective-C Automatic Reference Counting 设置为NO
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            WGBlock block;
            {
                WGPerson *person = [[WGPerson alloc]init];
                person.age = 10;
                block = ^{
                    NSLog(@"------%d",person.age);
                };
                [person release];  //因为是MRC环境,所以person要进行一次release               
            }
            打断点:NSLog(@"-----");
        }
        return 0;
    }
    打印结果: -[WGPerson dealloc]
#### 分析,为什么在ARC环境下,person对象没有销毁,而在MRC环境下就销毁了? 原因是因为在MRC环境下,这里的block类型属于栈block,而栈上的block对person没有进行强引用, 如果此时对block进行一次copy操作,block类型变成堆block,那么person对象就不会销毁了,因为堆block是可以保住外部auto对象的命的,这个已经验证过了
#### 总结: 从上面案例分析中,得出结论: 无论在MRC还是ARC环境下,栈上的block对外部的auto对象是不会强引用的
    
#### 5.1 __weak修饰的auto对象类型
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            WGBlock block;
            {
                WGPerson *person = [[WGPerson alloc]init]; 
                person.age = 10;
                __weak WGPerson *weakPerson = person;
                block = ^{
                    NSLog(@"------%d",weakPerson.age);
                };
            }
            打断点:NSLog(@"-----");
        }
        return 0;
        }

    打印结果: -[WGPerson dealloc]
    
#### 通过 xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m 转为C++代码,这里会发生如下错误
    cannot create __weak reference because the current deployment target does  
    not support weak references
    __attribute__((objc_ownership(weak))) WGPerson *weakPerson = person;
    1 error generated.
    弱引用技术是需要运行时来支持的,解决方案
    xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc  
    -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m
    
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        WGPerson *__weak weakPerson;   //此时变成了弱引用
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
        WGPerson *__weak _weakPerson, int flags=0) : weakPerson(_weakPerson) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 分析,用__weak修饰符来修饰auto对象,那么堆上的block对person对象就是个弱引用,所以person对象离开了作用域就销毁了

#### 5.2 block访问对象类型的auto变量,底层结果有哪些变化
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        //默认是WGPerson * person,如果clang使用了-fobjc-runtime,就会生成这种类型  
        WGPerson *__strong person,都是强引用,意思是一样的
        WGPerson *__strong person;  
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
        WGPerson *__strong _person, int flags=0) : person(_person) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
    
    static struct __main_block_desc_0 {
        size_t reserved;
        size_t Block_size;
        //之前访问非对象类型的auto变量时,没有下面两个方法,如果访问的是对象类型的auto变量,那么就会多出来这两个方法
        void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
        void (*dispose)(struct __main_block_impl_0*);
    } __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), 
    __main_block_copy_0, __main_block_dispose_0};
        
    copy指针指向了__main_block_copy_0函数,dispose指针指向了__main_block_dispose_0函数
        
    //当block进行copy时,就会调用下面的函数
    static void __main_block_copy_0(struct __main_block_impl_0*dst, 
    struct __main_block_impl_0*src) {
    //该函数会根据传进去的person对象是强引用还是弱引用,来对person对象进行对应的强引用或弱引用
    //如果外面person对象是强引用修饰(默认就是强引用,省略了__strong),那么block就对person对象是强引用
    //如果外面person对象是弱引用修饰(用__weak修饰),那么block就对person对象是弱引用
    //该函数内部也会处理引用计数的问题,如果是强引,那么就会对person的引用计数+1,  
    在_Block_object_dispose函数中进行对应的-1操作
      _Block_object_assign((void*)&dst->person, (void*)src->person, 
      3/*BLOCK_FIELD_IS_OBJECT*/);
    }
    
    //当block释放时,就会调用这个函数
    static void __main_block_dispose_0(struct __main_block_impl_0*src) {
        //该函数会自动释放引用的auto变量,类似于release            
        _Block_object_dispose((void*)src->person, 3/*BLOCK_FIELD_IS_OBJECT*/);
    }

#### 5.3 总结, 当block内部访问了对象类型的auto变量时
* 如果block是在栈上,肯定不会对auto变量产生强引用(不管是在ARC还是MRC环境下)
* 如果block被拷贝copy到堆上, 会自动调用block内部的copy函数, copy函数会调用_Block_object_assign函数,_Block_object_assign函数会根据**auto**变量的修饰符(__storng、__weak、__unsafe_unretained)来做出相应的操作,类似retaion(形成强引用、弱引用),__storng就会强引用auto变量,__weak/__unsafe_unretained就会弱引用auto变量
* 如果block从堆上移除,会调用block内部的dispose函数,dispose函数会调用_Block_object_dispose函数,_Block_object_dispose函数会自动释放引用的auto变量,类似于release
* 为什么block底层会多出来两个函数(copy函数和dispose函数)? 因为访问的是对象类型的auto变量,而对象类型的auto变量是需要对其进行内存管理的

         block内部函数                      调用时机
           copy函数                  栈上的block复制到堆上时
          dispose函数                 堆上的block被废弃时
          
#### 5.4 案例分析
    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
    }
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
    }
    @end
    
    打印结果: -[Person dealloc]---
            -[Person dealloc]---
            -[Person dealloc]---
            ...
#### 分析,每次点击屏幕,都会创建一个新的person对象,当离开touchesBegan方法后,person对象就会销毁
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 
        (3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"----%@",person);
        });
        NSLog(@"%s",__func__);
    }
    打印结果: 23:18:51.727756+0800 -[WGMainObjcVC touchesBegan:withEvent:]
            23:18:54.728141+0800  ----<Person: 0x600003b44670>
            23:18:54.728433+0800  -[Person dealloc]---
#### 分析,GCD中的block作为参数时,block类型是堆block,因为block内部访问了person对象,所以会对person对象进行强引用,所以直到3秒后,执行完NSLog(@"----%@",person);,block才会销毁,当block销毁的时候,会对引用的person对象进行release操作,随之person对象被销毁

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
        //下面两种写法是一样的,只不过第一种写法可以省略掉类型,用typeof(person)来表示,  
        person是什么类型,这里就是什么类型
        __weak typeof(person) weakPerson = person;
        //__weak Person *weakPerson = person;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 
        (3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"----%@",weakPerson);
        });
        NSLog(@"%s",__func__);
    }

    打印结果: 23:24:47.911207+0800 -[WGMainObjcVC touchesBegan:withEvent:]
            23:24:47.911415+0800  -[Person dealloc]---
            23:24:50.911296+0800 ----(null)
#### 分析,person对象先销毁了,因为此时person对象是弱引用,所以block不会对person对象进行强引用,执行完NSLog(@"%s",__func__);方法后,person对象就直接销毁了,销毁后的3秒,打印了----(null)信息,说明此时访问的person对象是一个已经被销毁的对象

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2.0 * NSEC_PER_SEC)), 
            dispatch_get_main_queue(), ^{
                NSLog(@"----%@",person);
            });
        });
        NSLog(@"%s",__func__);
    }
    
    打印结果: 23:30:04.904533+0800 -[WGMainObjcVC touchesBegan:withEvent:]
            23:30:07.904964+0800 ----<Person: 0x60000021c690>
            23:30:07.905330+0800  -[Person dealloc]---

#### 分析, block强引用了person对象,所以执行完第一个block后,在执行第二个block,所以person对象在3秒后释放
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
        __weak Person *weakPerson = person;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.0 * NSEC_PER_SEC)), 
        dispatch_get_main_queue(), ^{
            NSLog(@"1----%@",weakPerson);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2.0 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
                NSLog(@"2----%@",person);
            });
        });
        NSLog(@"%s",__func__);
    }
    
    打印结果: 23:33:21.958500+0800 -[WGMainObjcVC touchesBegan:withEvent:]
            23:33:22.958846+0800  1----<Person: 0x6000024c9830>
            23:33:25.123819+0800  2----<Person: 0x6000024c9830>
            23:33:25.124175+0800  -[Person dealloc]---
#### 分析,在第一个block内,block访问的是一个弱引用类型的person对象,为什么执行完第一个block,person对象没有立即销毁哪? 因为编译器是看整体的block内有没有强引用去引用,如果有强引用,就等强引用结束后才会去释放,而不是根据弱引用来决定的

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        Person *person = [[Person alloc]init];
        __weak Person *weakPerson = person;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.0 * NSEC_PER_SEC)), 
        dispatch_get_main_queue(), ^{
            NSLog(@"1----%@",person);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2.0 * NSEC_PER_SEC)), 
            dispatch_get_main_queue(), ^{
                NSLog(@"2----%@",weakPerson);
            });
        });
        NSLog(@"%s",__func__);
    }

    打印结果: 23:39:17.005876+0800  -[WGMainObjcVC touchesBegan:withEvent:]
            23:39:18.005954+0800  1----<Person: 0x600000e450d0>
            23:39:18.006142+0800  -[Person dealloc]---
            23:39:20.186553+0800  2----(null)
#### 分析,因为编译器是根据block内的强引用来决定什么时候释放对象的, 所以第一个block内访问的是强引用的person对象,所以执行完第一个block代码后,person对象就销毁了,直到2秒后,执行了第2个block,此时访问的person的对象已经销毁了,所以打印的是2----(null)
#### 总结,在GCD中,不管GCD中嵌套了多少个block, 考察对象释放时机,就主要根据强引用类型的对象所在的block什么时候执行完就可以了

### 6 __block修饰符
#### 6.1 __block修改变量
#### 如果我们需要更改外面age变量的值,是无法修改的,那么为什么不能修改?
    typedef void (^WGBlock)(void);

    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            int age = 10;
            WGBlock block = ^ {
                NSLog(@"my age is %d", age);
            };
            block();
        }
        return 0;
    }
        
    转为C++后, 可以看到这个是两个不同的函数, 在__main_block_func_0函数中是无法对main函数中的age变量进行修改值的,
    __main_block_func_0函数只能修改block内部的age变量值,而修改block内部变量值并不会影响外部变量的值
    int main(int argc, const char * argv[]) {
        /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
            int age = 10;
            WGBlock block = ((void (*)())&__main_block_impl_0(
            (void *)__main_block_func_0, &__main_block_desc_0_DATA, age));
            
            ((void (*)(__block_impl *))((__block_impl *)block)->  
            FuncPtr)((__block_impl *)block);
        }
        return 0;
    }
        
    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
        int age = __cself->age; // bound by copy
        NSLog((NSString *)&  
        __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_25a4d8_mi_0,
        age);
    }
        
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        int age;
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
        int _age, int flags=0) : age(_age) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags; 
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 如果我们想在block内部修改外部变量的值,有以下几种方式
1. 将变量变为static变量(全局变量也可以,全局变量不会被block捕获,在任何地方都可以被修改),缺点就是static变量和全局变量会一直存在于内存中,不会销毁,因为这些变量是放在全局区的

        typedef void (^WGBlock)(void);
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                static int age = 10;
                WGBlock block = ^ {
                    age = 20;
                    NSLog(@"my age is %d", age);
                };
                block();
            }
            return 0;
        }
        转为C++后代码 在main函数中,将静态变量age的地址传递给了函数__main_block_impl_0
        int main(int argc, const char * argv[]) {
            /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
                static int age = 10;
                WGBlock block = ((void (*)())&__main_block_impl_0(
                (void *)__main_block_func_0, &__main_block_desc_0_DATA, &age));
                
                ((void (*)(__block_impl *))((__block_impl *)block)->  
                FuncPtr)((__block_impl *)block);
            }
            return 0;
        }
        
        //在block内部会生成对应的变量指针,来保存外部传进来的变量的地址
        struct __main_block_impl_0 {
            struct __block_impl impl;
            struct __main_block_desc_0* Desc;
            int *age;
            __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, 
            int *_age, int flags=0) : age(_age) {
                impl.isa = &_NSConcreteStackBlock;
                impl.Flags = flags;
                impl.FuncPtr = fp;
                Desc = desc;
            }
        };
        
        //通过外部传递进来的变量地址对其进行修改值,虽然修改的是block内部变量的值,但是这个变量的地址  
        和外部变量的地址是一样的,所以外部变量就会被修改了
        static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
            int *age = __cself->age; // bound by copy
            (*age) = 20;
            NSLog((NSString *)&  
            __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_c7c690_mi_0,
            (*age));
        }
2. 添加__block修饰符

        typedef void (^WGBlock)(void);
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                __block int age = 10;
                WGBlock block = ^ {
                    age = 20;
                    NSLog(@"my age is %d", age);
                };
                block();
            }
            return 0;
        }
#### 给auto变量添加__block修饰符后,就可以更改auto变量的值了,但是并不会影响变量的作用域,它仍然是个auto变量,出了作用域就会被销毁. 那么__block底层是如何实现的哪?

#### 6.2 __block本质
1. __block可以用于解决block内部无法修改auto变量值的问题
2. __block不能修改全局变量、静态变量(static)
3. 编译器会将__block修饰的变量包装成一个对象 
#### 接着上面的例子,来分析下它的C++代码

    int main(int argc, const char * argv[]) {
        /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        __attribute__((__blocks__(byref))) __Block_byref_age_0 age =   
        {(void*)0,(__Block_byref_age_0 *)&age, 0, sizeof(__Block_byref_age_0), 10};
            
        WGBlock block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, 
        &__main_block_desc_0_DATA, (__Block_byref_age_0 *)&age, 570425344));
             
        ((void (*)(__block_impl *))((__block_impl *)block)->  
        FuncPtr)((__block_impl *)block);
        
        //上面代码可以简化成
        //__Block_byref_age_0 age = {0, &age, 0, sizeof(__Block_byref_age_0), 10};
        WGBlock block = &__main_block_impl_0(__main_block_func_0,
        &__main_block_desc_0_DATA, &age, 570425344));
        
        block->FuncPtr(block);
      }
        return 0;
    }
        
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        __Block_byref_age_0 *age; // by ref
        __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_age_0 *_age, int flags=0) : age(_age->__forwarding) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;   
        }
    };
    
    //对下面一一赋值
    //__Block_byref_age_0 age = {0, &age, 0, sizeof(__Block_byref_age_0), 10};
    struct __Block_byref_age_0 {
        void *__isa;    //这里有个isa指针,所以可以理解成一个对象
        __Block_byref_age_0 *__forwarding;  //指向这个结构体本身的地址
        int __flags;
        int __size; //结构体专用的内存大小
        int age;    //变量的值
    };
        
    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
        __Block_byref_age_0 *age = __cself->age; // bound by ref
        //通过age拿到__forwarding,然后再通过__forwarding拿到age,然后对其进行修改值
        (age->__forwarding->age) = 20;
        NSLog((NSString *)&  
        __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_46c985_mi_0,  
        (age->__forwarding->age));
    }
#### 总结,编译器会将__block修饰的变量包装成一个对象(底层就是个结构体),Block底层内部会有个指针指向包装成的结构体,然后通过指针修改结构体中的age变量进行修改

    typedef void (^WGBlock)(void);
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            __block int age = 10;
            __block NSObject *obj = [[NSObject alloc]init];
            WGBlock block = ^ {
                obj = nil;
                age = 20;
                NSLog(@"my age is %d", age);
            };
            block();
        }
        return 0;
    }
        
#### __block无论是修饰auto变量还是对象类型的变量,底层都会包装成一个对象,只是修饰对象类型时,包装成对象的结构体中会多出来copy/dispose方法,主要就是为了进行内存管理用的
    struct __Block_byref_age_0 {
        void *__isa;
        __Block_byref_age_0 *__forwarding;
        int __flags;
        int __size;
        int age;
    };
    
    struct __Block_byref_obj_1 {
        void *__isa;
        __Block_byref_obj_1 *__forwarding;
        int __flags;
        int __size;
        void (*__Block_byref_id_object_copy)(void*, void*);
        void (*__Block_byref_id_object_dispose)(void*);
        NSObject *obj;
    };

#### 如果我们修改可变数组中的元素个数,是不需要添加__block修饰符的,因为我们只是用arr这个地址,而并不是对其进行赋值操作,只有对其进行赋值操作才需要添加__block修饰符. 能不加__block就不加,因为加__block会生成新的对象
    typedef void (^WGBlock)(void);
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            NSMutableArray *arr = [NSMutableArray array];
            WGBlock block = ^ {
                [arr addObject:@"123"];
            };
            block();
        }
        return 0;
    }

#### 6.2.1 __block底层细节
    typedef void (^WGBlock)(void);
    int main(int argc, const char * argv[]) {
        @autoreleasepool {
            __block int age = 10;
            WGBlock block = ^ {
                age = 20;
            };
            block();
            NSLog(@"%p",&age);
        }
        return 0;
    }
#### 分析,我们现在访问age地址,其实访问的是__Block_byref_age_0结构体中变量age(int age;)的地址,而不是block底层结构体__main_block_impl_0中的成员age(__Block_byref_age_0 *age;),为什么打印的地址不是block结构体中的成员变量age? 可能是苹果想屏蔽__block内部的实现细节,就像KVO一样
    struct __Block_byref_age_0 {
        void *__isa;
        __Block_byref_age_0 *__forwarding;
        int __flags;
        int __size;
        int age;
    };
    
    struct __main_block_impl_0 {
        struct __block_impl impl;
        struct __main_block_desc_0* Desc;
        __Block_byref_age_0 *age; // by ref
        ...
    }
        
#### 6.2.2 __block的__forwarding指针
#### 为什么我们拿到age的指针后,不直接去访问age指针指向的结构体中的age变量,而是通过__forwarding指针再去获取age变量? 
    static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
        __Block_byref_age_0 *age = __cself->age; // bound by ref
        //通过age拿到__forwarding,然后再通过__forwarding拿到age,然后对其进行修改值
        (age->__forwarding->age) = 20;
        NSLog((NSString *)&  
    __NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_46c985_mi_0,  
        (age->__forwarding->age));
    }
#### block在栈上时,__forwarding指针指向的是它自己,如果block拷贝到了堆上,那么栈上的__forwarding指针会指向堆上的block对象,堆上的__forwarding指针指向的是堆上block的自身,这样不论是访问栈上的__forwarding指针还是堆上的__forwarding指针,都可以找到堆上的变量

#### 6.3 __block内存管理
1. 当block在栈上时,并不会对__block修饰的变量产生强引用
2. 当block被拷贝到堆上时
* 1 会调用block内部的copy函数
* 2 copy函数内部会调用_Block_object_assign函数
* 3 _Block_object_assign函数会对__block变量形成强引用(retain)

        typedef void (^WGBlock)(void);
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                __block int age = 10;
                WGBlock block = ^ {
                    age = 20;
                };
                block();
            }
            return 0;
        }
            
        int main(int argc, const char * argv[]) {
            /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

            __attribute__((__blocks__(byref))) __Block_byref_age_0 age = 
                {(void*)0,(__Block_byref_age_0 *)&age, 0, 
                sizeof(__Block_byref_age_0), 10};
                
                WGBlock block = ((void (*)())&__main_block_impl_0(
                (void *)__main_block_func_0, &__main_block_desc_0_DATA, 
                (__Block_byref_age_0 *)&age, 570425344));
                
                ((void (*)(__block_impl *))((__block_impl *)block)->  
                FuncPtr)((__block_impl *)block);
            }
            return 0;
        }
            
        struct __main_block_impl_0 {
            struct __block_impl impl;
            struct __main_block_desc_0* Desc;
            __Block_byref_age_0 *age; // by ref
            __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,  
            __Block_byref_age_0 *_age, int flags=0) : age(_age->__forwarding) {
                impl.isa = &_NSConcreteStackBlock;
                impl.Flags = flags;
                impl.FuncPtr = fp;
                Desc = desc;
            }
        };
        
        //block内部存在copy和dispose函数
        static struct __main_block_desc_0 {
          size_t reserved;
          size_t Block_size;
          void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
          void (*dispose)(struct __main_block_impl_0*);
        } __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0),  
        __main_block_copy_0, __main_block_dispose_0};
            
        static void __main_block_copy_0(struct __main_block_impl_0*dst, 
        struct __main_block_impl_0*src) {
        
            _Block_object_assign((void*)&dst->age,   
            (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);
        }
        
        static void __main_block_dispose_0(struct __main_block_impl_0*src) {
            _Block_object_dispose((void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);
        }
            
3. 当block从堆上移除时
* 1 会调用block内部的dispose函数
* 2 dispose函数内部会调用_Block_object_dispose函数
* 3 _Block_object_dispose函数会自动释放引用的__block变量(release)

        typedef void (^WGBlock)(void);
        int main(int argc, const char * argv[]) {
            @autoreleasepool {
                NSObject *objc = [[NSObject alloc]init];
                __block int age = 10;
                WGBlock block = ^ {
                    NSLog(@"age: %d",age);
                    NSLog(@"objc: %p",objc);
                };
                block();
            }
            return 0;
        }
        
        struct __main_block_impl_0 {
            struct __block_impl impl;
            struct __main_block_desc_0* Desc;
            NSObject *__strong objc;     //强引用 
            __Block_byref_age_0 *age; // by ref
            __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,   
            NSObject *__strong _objc,__Block_byref_age_0 *_age,int flags=0) : objc(_objc),  
            age(_age->__forwarding) {
                impl.isa = &_NSConcreteStackBlock;
                impl.Flags = flags;
                impl.FuncPtr = fp;
                Desc = desc;
            }
        };
        
        static void __main_block_copy_0(struct __main_block_impl_0*dst,
        struct __main_block_impl_0*src) {
        //会对__block修饰的age变量包装成的对象-强引用
        _Block_object_assign((void*)&dst->age, (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/); 
        //会对objc变量-强引用  如果是__weak NSObject *weakSelf = objc;那么就对objc变量进行的是弱引用
        _Block_object_assign((void*)&dst->objc, (void*)src->objc, 3/*BLOCK_FIELD_IS_OBJECT*/);
        }
#### 总结: block访问auto类型的对象时,如果对象是强引用修饰(默认的都是Strong),那么block就对外部的auto对象是强引用;如果对象是弱引用(用__weak修饰),那么block对auto对象就是弱引用; 如果block访问的是__block修饰的对象,那么block对修饰的对象就是强引用


#### 6.4 对象类型的auto变量和__block修饰的变量的内存管理
1. 当block在栈上时,对它们都不会产生强引用
2. 当block拷贝到堆上时,都会通过copy函数来处理它们

        __block变量age: 对age就是强引用
        _Block_object_assign((void*)&dst->age, (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/); 
        对象类型的auto变量person: 若person对象是Strong修饰,block对person就是强引用;  
        若person对象是__weak修饰,则是弱引用
        _Block_object_assign((void*)&dst->person, (void*)src->objc, 3/*BLOCK_FIELD_IS_OBJECT*/);
3. 当block从堆上移除时,都会通过dispose函数来释放它们

        __block变量age: 
        _Block_object_dispose((void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);
        对象类型的auto变量person:
        _Block_object_dispose((void*)src->person, 3/*BLOCK_FIELD_IS_BYREF*/);
4. __block int age = 20,不能再用__weak来修饰了,因为__weak是用来修饰对象类型的 


#### 6.5 __block修饰的对象类型
    typedef void (^WGBlock) (void);

    @implementation WGMainObjcVC
    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        __block Person *person = [[Person alloc]init];
        WGBlock block = ^{
            NSLog(@"---%p",person);
        };
        block();
    }
        
    xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc  
    -fobjc-runtime=ios-8.0.0 WGMainObjcVC.m
    转为C++代码如下

    struct __Block_byref_person_0 {
        void *__isa;
        __Block_byref_person_0 *__forwarding;
        int __flags;
        int __size;
        void (*__Block_byref_id_object_copy)(void*, void*);
        void (*__Block_byref_id_object_dispose)(void*);
        Person *__strong person;
    };

    struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
        struct __block_impl impl;
        struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
        __Block_byref_person_0 *person; // by ref
        __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, 
        struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, 
        __Block_byref_person_0 *_person, 
        int flags=0) : person(_person->__forwarding) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### WGBlock内有个person指针,指向了__Block_byref_person_0结构体(是个强指针即强引用),__Block_byref_person_0结构体中有个person指针(Person *__strong person;),这个指针指向了我们alloc出来的person对象(强引用还是弱引用根据外部person对象是strong修饰还是__weak修饰的)

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        Person *person = [[Person alloc]init];
        //若是用__weak修饰的弱引用
        __block __weak Person *weakPerson = person;  
        WGBlock block = ^{
            NSLog(@"---%p",weakPerson);
        };
        block();
    }
    
    struct __Block_byref_weakPerson_0 {
        void *__isa;
        __Block_byref_weakPerson_0 *__forwarding;
        int __flags;
        int __size;
        void (*__Block_byref_id_object_copy)(void*, void*);
        void (*__Block_byref_id_object_dispose)(void*);
        Person *__weak weakPerson;  //这里显示的就是弱引用
    };

    struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
        struct __block_impl impl;
        struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
        __Block_byref_weakPerson_0 *weakPerson; // by ref  
        __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, 
        struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc,
        __Block_byref_weakPerson_0 *_weakPerson, 
        int flags=0) : weakPerson(_weakPerson->__forwarding) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
#### 如果外部是弱引用,那么block中的weakPerson指针指向的是__Block_byref_weakPerson_0结构体,这里都是强引用;而__Block_byref_weakPerson_0结构体中有weakPerson指针(Person *__weak weakPerson;),它对我们alloc出来的person对象是弱引用

#### 总结
1. 当__block变量在栈上时,不会对指向的对象产生强引用
2. 当__block变量被拷贝到堆上时
* 会调用__block变量内部的copy函数
* copy函数内部会调用_Block_object_assign函数
* _Block_object_assign函数会根据所指向对象的修饰符(__strong、__weak、__unsafe_unretained)做出相应的操作,形成强引用(retain)或者弱引用(注意⚠️这里仅限在ARC时会retain,MRC时不会retain)
3. 如果__block变量从堆上移除
* 会调用__block变量内部的dispose函数
* dispose函数内部会调用_Block_object_dispose函数
* _Block_object_dispose函数会自动释放指向的对象(release)



#### 7 block循环引用
#### 7.1 循环引用会导致内存泄漏,导致该释放的对象无法释放

    typedef void(^WGBlock) (void);

    @interface Person : NSObject
    //copy、strong都可以保证将block拷贝到堆上,但建议使用copy,这样无论是ARC还是MRC,这个写法都是一致的
    @property(nonatomic, copy) WGBlock block;
    @property(nonatomic, assign) int age;
    @end
    
    @implementation Person
    -(void)dealloc {
        NSLog(@"%s---",__func__);
    }
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        Person *person = [[Person alloc]init];
        person.age = 18;
        person.block = ^{
            NSLog(@"----%d",20);
        };
        NSLog(@"111111111");
    }
    
    打印结果: 111111111
            -[Person dealloc]---
#### 因为block没有访问任何外部变量,所以执行完viewDidLoad方法后,person对象就销毁了

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor whiteColor];
        Person *person = [[Person alloc]init];
        person.age = 18;
        person.block = ^{
            NSLog(@"age is %d",person.age);
        };
        NSLog(@"111111111");
    }
    
    打印结果: 111111111
#### block内访问了person对象的age属性.person对象无法释放.因为person对象内持有block,block内又持有person对象,相互引用,导致循环引用,具体如下

    struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
        struct __block_impl impl;
        struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
        Person *__strong person;  //block底层对象中有个person指针
        __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, 
        struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, 
        Person *__strong _person, int flags=0) : person(_person) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
        }
    };
    2.block(person):block内访问了person对象,这个person对象指向了1
                                        |
                                        |
    person ----------->  1.MJPerson(内有_block成员):_block指向了2
#### 循环引用的本质就是你引用我,我引用你,相互引用,导致无法释放

#### 7.2 循环引用的解决方法
#### 7.2.1 在ARC环境下
1. __weak修饰(弱引用): 指向的对象销毁时,会自动让指针置为nil

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            Person *person = [[Person alloc]init];
            person.age = 18;
            //下面两种方法都可以
            __weak typeof(person) weakPerson = person;
            //__weak Person *weakPerson = person;
            person.block = ^{
                NSLog(@"age is %d",weakPerson.age);
            };
            NSLog(@"111111111");
        }
        
        打印结果: 111111111
                -[Person dealloc]---
                    
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
            struct __block_impl impl;
            struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
            Person *__weak weakPerson;  //弱引用来打破循环引用
            __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, 
            struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, 
            Person *__weak _weakPerson, int flags=0) : weakPerson(_weakPerson) {
                impl.isa = &_NSConcreteStackBlock;
                impl.Flags = flags;
                impl.FuncPtr = fp;
                Desc = desc;
            }
        };
#### 通过__weak弱指针来引用对象,这样循环引用就不存在了. Person中持有block,block中持有的person对象是弱引用,这样就打破了循环引用

2. __unsafe_unretained修饰(弱引用): 指向的对象销毁时,指针存储的地址值不变

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            Person *person = [[Person alloc]init];
            person.age = 18;
            __unsafe_unretained typeof(person) weakPerson = person;
            person.block = ^{
                NSLog(@"age is %d",weakPerson.age);
            };
            NSLog(@"111111111");
        }
        
        打印结果: 111111111
                -[Person dealloc]---
3. __block(必须调用block并在block内对访问的变量在不需要时置为nil)

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            __block Person *person = [[Person alloc]init];
            person.age = 18;
            person.block = ^{
                NSLog(@"age is %d",person.age);
                person = nil;
            };
            person.block();
            NSLog(@"111111111");
        }
        打印结果: age is 18
                -[Person dealloc]---
                111111111
          
        //__block包装成的对象
        struct __Block_byref_person_0 {  
            void *__isa;
            __Block_byref_person_0 *__forwarding;
            int __flags;
            int __size;
            void (*__Block_byref_id_object_copy)(void*, void*);
            void (*__Block_byref_id_object_dispose)(void*);
            Person *__strong person;
        };
        
        //block对象
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
            struct __block_impl impl;
            struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
            __Block_byref_person_0 *person; // by ref
            __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, 
            struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, 
        __Block_byref_person_0 *_person, int flags=0) : person(_person->__forwarding) {
                impl.isa = &_NSConcreteStackBlock;
                impl.Flags = flags;
                impl.FuncPtr = fp;
                Desc = desc;
            }
        };
                
#### 这里有三个对象,Person对象、block对象、__block包装成的对象, 首先我们知道person对象会对我们的__block包装成的对象形成强引用,而Person对象持有block对象,block对象内又持有__block包装成的对象,__block包装成的对象内部又持有并且是强引用了person对象,导致三个对象之间形成了闭环的循环引用,而现在我们主动将person对象置为nil,其实就是将__block包装成的对象内部的person指针置为nil,这样就打破了闭环的循环引用
#### 7.2.2 在MRC环境下
#### 在Xcode中设置为MRC环境(Build Setting ->automatic Reference Counting -> NO),需要注意的是在MRC环境是,是没有__weak这种弱引用的概念的,即MRC环境下不支持__weak.
1.  __unsafe_unretained

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            __unsafe_unretained Person *person = [[Person alloc]init];
            person.age = 18;
            person.block = [^{  //如果不加__unsafe_unretained,在block内会对person进行一次retain
                NSLog(@"age is %d",person.age);
            } copy];
            [person release];
            NSLog(@"111111111");
        }
        
        打印结果: -[Person dealloc]---
                111111111
2. __block

       - (void)viewDidLoad {
           [super viewDidLoad];
           self.view.backgroundColor = [UIColor whiteColor];
           __block Person *person = [[Person alloc]init];
           person.age = 18;
           person.block = [^{
               NSLog(@"age is %d",person.age);
           } copy];
           [person release];
           NSLog(@"111111111");
       }
       
       打印结果: -[Person dealloc]---
                    111111111

#### ⚠️在MRC环境下,__block包装成的对象不会对其内部的person对象形成强引用,仅限在MRC环境下


#### 8.面试题
#### 1. block的原理是怎样的,本质是什么
#### 封装了函数调用及其调用环境的OC对象
#### 2. __block的作用是什么? 有什么使用注意点?
#### __block会将修饰的变量包装成一个对象,可以解决block内无法修改auto变量值的问题,可以通过包装成对象的指针来访问auto变量,进而进行修改;注意点就是内存管理的问题(详细可以看上面的__block内存管理的总结)
#### 3. block的属性修饰符为什么是copy?使用block有哪些使用注意?
#### block一旦没有进行copy操作,就不会在堆上,我们希望在堆上的原因是我们希望能够控制block的销毁时机;使用注意点就是要注意循环引用的问题
#### 4. block在修改NSMutableArray,需不需要添加__block?
#### 不需要,因为我们知道访问的是数组的指针, 而不是修改,所以不需要添加__block


