### Block系统性总结


#### 1. block本质及底层结构
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
                void (*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
                ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
            }
            return 0;
        }
        
        简化后(取出强制转化的代码)
        int main(int argc, const char * argv[]) {
            { __AtAutoreleasePool __autoreleasepool; 
                //定义block变量: 将函数传递两个参数,然后将函数返回值的地址赋值给void (*block)(void)
                void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
                //执行block内部代码
                block->FuncPtr)(block);
            }
            return 0;
        }
        
#### 1.2__main_block_impl_0函数内部结构,结构体名称和方法名称一样,这种写法是C++语言的语法,这种方法叫做**构造函数**,同时这个方法没有写返回值,其实类似于OC中的init方法,该函数的返回值就是__main_block_impl_0结构体对象本身
        struct __main_block_impl_0 {  
            struct __block_impl impl;
            struct __main_block_desc_0* Desc;
            //C++构造函数,返回值就是这个结构体(__main_block_impl_0)对象本身, 这里有三个参数,但外面传递进来的只有2个参数,其实这就是C++语言特性:可以设置默认值,类似于swift
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
        void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
        
#### __main_block_impl_0函数参数分析
        参数1: __main_block_func_0,封装了block执行逻辑的函数,简单就是将block中的任务封装到了__main_block_func_0这个函数中
        static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
            NSLog((NSString *)&__NSConstantStringImpl__var_folders_wc_tkbgc_ts0pv3lyd2n4wsdc6h0000gn_T_main_5ad538_mi_0);
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
        void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
        
        //执行block内部代码
        block->FuncPtr)(block);
#### 从上面我们知道block指向的是结构体__main_block_impl_0,但是__main_block_impl_0结构体中并没有FuncPtr成员变量,这里其实是做了强制类型转化,为什么可以转化?因为__main_block_impl_0结构体的地址其实也是它内部第一个成员变量的地址,所以也就是__block_impl结构体的地址,这样就可以找到block函数实现的地址FuncPtr,然后进行函数调用











#### 面试题
#### 1. block的原理是怎样的,本质是什么
#### 2. __block的作用是什么? 有什么使用注意点?
#### 3. block的属性修饰符为什么是copy?使用block有哪些使用注意?
#### 4. block在修改NSMutableArray,需不需要添加__block?


