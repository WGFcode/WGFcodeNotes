##  Block
#### Block是封装函数实现及上下文环境的匿名函数,

### 1.Block基本语法
### 1.1 Block声明及定义
        返回值类型 (^Block名称)(参数类型) = ^返回值类型(参数类型 参数名) {}
        return_type (^blockName)(var_type) = ^return_type (var_type varName) { ... };
        1.有参数有返回值
        NSString* (^WGCustomBlock)(NSString *) = ^(NSString *name){
            NSLog(@"名称是:%@",name);
            return [NSString stringWithFormat:@"%@",name];
        };
        NSString *name = WGCustomBlock(@"张三");
        NSLog(@"%@",name);
        
        打印结果: 名称是:张三
                 张三
        
        2.有多个参数有返回值
        NSString* (^WGCustomBlock)(NSString *, int) = ^(NSString *name, int age) {
            NSLog(@"name:%@-age:%d",name,age);
            return [NSString stringWithFormat:@"%@-%d",name,age];
        };
        NSString *info = WGCustomBlock(@"张三",18);
        NSLog(@"%@",info);
        
        打印结果: name:张三-age:18
                 张三-18

        3.有参数无返回值
        void (^WGCustomBlock)(NSString *) = ^(NSString *name) {
            NSLog(@"我的名字叫:%@",name);
        };
        WGCustomBlock(@"张三");
        
        打印结果:我的名字叫:张三
        
        4.无参数有返回值
        NSString *(^WGCustomBlock)(void) = ^(void) {
            NSLog(@"我是张三");
            return @"张三";
        };
        也可简写成
        NSString *(^WGCustomBlock)(void) = ^{
            NSLog(@"我是张三");
            return @"张三";
        };
        NSString *name = WGCustomBlock();
        NSLog(@"%@",name);
        
        
        打印结果: 我是张三
                 张三
        
        //5 无参数无返回值
        void(^WGCustomBlock)(void) = ^(void) {
            NSLog(@"我是张三");
        };
        可简写成
        void(^WGCustomBlock)(void) = ^{
            NSLog(@"我是张三");
        };
        WGCustomBlock();
        
        打印结果: 我是张三

        6.Block实现时，等号右边就是一个匿名Block，它没有blockName，称之为匿名Block
        ^return_type (var_type varName) {
        };
### 1.2 typedef给Block起别名
        //1.Block作为属性
        //typedef简化Block生命
        typedef return_type (^blockName)(var_type varName);
      /*在swift中有可选类型和非可选类型(?和!),在OC中没有这个区分,所以在混编的时候,swift编译器并不知道它是可选还是非可选,为了解决这个问题,引入了两个关键字
         _Nullable: 表示对象可以是NULL或nil
         _Nonnull: 表示对象不应该为空
         如果不明确是否可选,那么编译器会一直警告
         */
        typedef NSString * _Nonnull (^WGCustomBlock)(NSString *name);
        typedef void(^WGCustomBlock1)(NSString *name, int age);
        typedef void(^WGCustomBlock2)(void);

        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, copy) WGCustomBlock cusBlock;
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //类似给属性赋值
            self.cusBlock = ^NSString * _Nonnull(NSString * _Nonnull name) {
                NSLog(@"我的名字是:%@",name);
                return name;
            };
        }
        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            NSString *name = self.cusBlock(@"张三");
            NSLog(@"%@",name);
        }
        @end
        
        打印结果:我的名字是:张三
                张三
                
        //2.Block作为方法的参数
        typedef void (^WGCustomBlock)(NSString *name);        
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            [self getName:^(NSString * _Nonnull name) {
                NSLog(@"我的名字是:%@",name);
            }];
        }
        -(void)getName:(WGCustomBlock)block {
            block(@"张三");
        }
        打印结果:  我的名字是:张三
        
        //3.Block作为方法的返回值
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            NSString *(^WGCustomBlock)(NSString *) = [self function:@"王"];
            NSString *name = WGCustomBlock(@"小二");
            NSLog(@"我的名字是:%@",name);
        }
        - (NSString *(^)(NSString *))function:(NSString *)firstName {
            return ^NSString *(NSString *lastName) {
                return [firstName stringByAppendingString:lastName];
            };
        }
        打印结果: 我的名字是:王小二
### 1.3 Block捕获值
#### 1.3.1捕获局部变量
        - (void)viewDidLoad {
            [super viewDidLoad];
            int age = 18;
            NSString *name = @"张三";
            void(^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,我的年龄是:%d",name,age);
            };
            age = 30;
            name = @"李四";
            WGCustomBlock();
        }

        打印结果: 我的名字是:张三,我的年龄是:18
#### 分析:创建Block的时候，block已经将局部变量(无论是基本数据类型还是对象类型)的值捕获到，block内部会专门新增一个成员来存储auto变量的值，block运行时会访问这个新增的成员；block外改变age和name的值，也不会影响到block内捕获的auto变量值；为什么Block对auto变量的捕获是值捕获？因为auto类型的局部变量出了作用域就会被销毁，它所占用的内存地址也会被销毁，如果Block不保存这个局部变量值，当运行Block的时候，这个局部变量可能已经不存在了；

#### 1.3.2 捕获静态局部变量
        - (void)viewDidLoad {
            [super viewDidLoad];
            static int age = 18;
            static NSString *name = @"张三";
            void(^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,我的年龄是:%d",name,age);
            };
            age = 30;
            name = @"李四";
            WGCustomBlock();
        }
        
        打印结果: 我的名字是:李四,我的年龄是:30
#### 分析: Block捕获局部静态变量捕获的是静态变量的地址；static静态局部变量虽然出了作用域也不能访问，但是它的内存是一直存在的，不会被销毁，所以Block只要在运行的时候能够访问到它就可以了，所以针对这种变量Block采用的是指针传递

#### 1.3.3 捕获成员变量
        @interface WGMainObjcVC()
        {
            NSString *_name;
            int _age;
        }
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            _age = 18;
            _name = @"张三";
            void(^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,我的年龄是:%d",self->_name,self->_age);
            };
            _age = 30;
            _name = @"李四";
            WGCustomBlock();
        }

        打印结果: 我的名字是:李四,我的年龄是:30
#### 分析：Block访问成员变量是会捕获成员变量的 ，成员变量实质是调用了self->成员变量，其实成员变量捕获是捕获到了self，所以理解成可以被Block捕获；捕获的成员变量都是指针传递的；通过类中的方法底层实现可以看到，每个方法的前两个参数都是self和方法名，那么self也就是一个参数，肯定是一个局部变量，所以在Block实现中使用 self是会被捕获的；

#### 1.3.4 捕获全局的静态变量
        static int age = 18;
        NSString *name = @"张三";

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            age = 21;
            name = @"李四";
            void(^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,我的年龄是:%d",name,age);
            };
            age = 30;
            name = @"王五";
            WGCustomBlock();
        }
        
        打印结果: 我的名字是:王五,我的年龄是:30
#### 分析: Block不需要对全局变量(全局变量或全局静态变量)进行捕获，都是直接使用其值；因为全局变量既不会被销毁又可以随处访问，所以block根本不用去捕获它就可以随时随地访问到它的值。

#### 总结: Block对自动变量捕获的是自动变量的值，而对static的局部静态变量捕获的是静态变量的指针地址；为什么Block对static局部静态变量捕获的是指针？因为static变量一直保存在内存中，所以指针访问即可

#### 1.3.5 Block对外部变量的捕获机制
                 auto     捕获到Block内   值传递      
        局部变量                                     局部变量存储在栈里面,系统会自动释放
                 static   捕获到Block内   指针传递

        全局变量            不需要捕获      直接访问    全局变量存储在静态区中 程序启动时就会分配存储空间 直到程序结束才会释放
        成员变量            需要捕获        指针传递    存储在堆中(当前对象对应的堆存储空间中)
#### 分析:为什么局部变量需要捕获？因为考虑作用域的问题，需要跨函数访问局部变量，所以需要捕获；
### 1.4 Block类型
#### Block类型取决于isa指针，可以通过断点打印isa所指向的类型
        - (void)viewDidLoad {
            [super viewDidLoad];
            
            void (^WGCustomBlock1)(void) = ^{
                NSLog(@"我叫张三");
            };
            NSString *name = @"张三";
            void(^WGCustomBlock2)(void) = ^{
                NSLog(@"我的名字是:%@",name);
            };
            NSLog(@"%@--%@--%@",[WGCustomBlock1 class],[WGCustomBlock2 class],[^{
                NSLog(@"我的名字是:%@",name);
            }class]);
            NSLog(@"WGCustomBlock1类型\n:%@\n:%@\n:%@\n:%@\n:%@",[WGCustomBlock1 class],[[WGCustomBlock1 class] superclass],[[[WGCustomBlock1 class] superclass] superclass],[[[[WGCustomBlock1 class] superclass] superclass] superclass],[[[[[WGCustomBlock1 class] superclass] superclass] superclass] superclass]);
        }
        
        打印结果: __NSGlobalBlock__--__NSMallocBlock__--__NSStackBlock__
                WGCustomBlock1类型
                :__NSGlobalBlock__
                :__NSGlobalBlock
                :NSBlock
                :NSObject
                :(null)

#### 分析:从打印结果可以看出:Block实质也是个对象类型最终继承自NSObject；Block主要分为以下三种类型
* __NSGlobalBlock__ 全局Block: 存在数据区；
* __NSStackBlock__  栈Block: 存在栈区,超出作用域就会被销毁；
* __NSMallocBlock__ 堆Block: 存在堆区；【__NSStackBlock__ copy】就是堆区Block
* 系统自动分配栈区内存，自动销毁，先入后出；动态分配堆区内存，需要程序员自己申请，程序员自己管理

#### 如何判断一个Block所处的存储位置?
* 没有访问外界变量的Block都是全局Block,存储在数据区;
* 在MRC下访问外界变量的Block默认存储在栈中;
* 在ARC下访问外界变量的Block默认存储在堆中(实际在栈中,ARC情况下自动拷贝到堆区),

#### 在ARC下,为什么访问外界变量的Block自动从栈区拷贝到堆区?
* 栈上的Block,如果其所属的变量作用域结束,该Block就会被销毁/废弃,当然Block中的__block变量也会跟着销毁;为了解决栈区在其变量作用域结束后被销毁的问题,我们需要把Block复制到堆区来延长它的生命周期;将Block从栈区复制(copy)到堆区比较耗费CPU资源,所以在栈区也能够使用就尽量不要复制了


#### Block copy操作
#### 不同类型的Block执行copy操作后的效果如下
                             副本源的存储域      复制效果
        __NSGlobalBlock__       数据区          什么也不做
        __NSStackBlock__         栈           从栈复制到堆上
        __NSMallocBlock__        堆           引用计数增加
* Block在堆中copy会造成引用计数增加,这和对象是一样的;虽然在栈上的Block也是以对象的身份存在的,但是栈区没有引用计数,栈区内存是由编译器自动分配释放,所以不需要引用计数


### 1.4.1 Block引用问题
1. 当Block内部访问了对象类型的auto变量时，是否会强引用？
* 如果block在栈空间，不管外部变量是强引用还是弱引用，block都会弱引用访问对象；
* 如果block在堆空间，如果外部强引用，block内部也是强引用；如果外部弱引用，block内部也是弱引用
2. ARC环境下，编译器会自动将栈上Block复制到堆上的情况
* block作为函数返回值时
* 将block赋值给__strong指针时
* block作为Cocoa API中方法名含有usingBlock的方法参数时
* block作为GCD API的方法参数时

### 2. __block修饰符
#### Block能否修改外部变量的值？
* auto变量的值，在Block内是无法修改的，因为Block使用的时候是内部创建了一个变量来保存外部auto变量的值；Block只有修改内部自己变量的权限，无法修改外部auto变量的值
* static静态局部变量，在Block内是可以修改的，因为Block内部存储的是static修饰的变量的指针，Block内可以直接修改指针指向的变量值
* 全局变量，无论在哪里都可以修改，所以在Block中也可以修改

#### 如果我们想在Block中修改auto变量的值，那么就可以使用__block来修饰auto变量，__block主要作用
* __block可以用于解决Block内部无法修改auto变量值的问题
* __block不能修饰全局变量、静态变量（static）
* 编译器会将__block变量包装成一个对象

#### Block可以向NSMutableArray添加元素吗？
        NSMutableArray *arr = [NSMutableArray array];
        void (^WGCustomBlock1)(void) = ^{
            [arr addObject:@"123"];
            [arr addObject:@"111"];
        };
        [arr addObject:@"000"];
        WGCustomBlock1();
        NSLog(@"arr:%@",arr);
        
        打印结果: arr:(
                    000,
                    123,
                    111
                 )
#### 分析：Block中可以对NSMutableArray数组添加元素，因为操作的是NSMutableArray的变量，而不是通过指针改变；如果在Block内执行arr=nil,就会报错(Variable is not assignable (missing __block type specifier)),不能改变外部变量，如果想执行成功，需要将arr添加__block修饰符（__block NSMutableArray *arr = [NSMutableArray array];）

### 2.1 __block内存管理
#### 当block在栈上时，并不会对__block变量产生强引用
1. Block的属性修饰符为什么用copy?
* Block如果没有进行copy操作，默认是在栈上的，栈内存释放是由系统控制的，Block只有在堆上，程序员才可以对block做内存管理等操作，可以控制block的生命周期
2. 当Block被copy到堆时，对__block修饰的变量做了什么？
* 会调用Block内部的copy函数
* copy函数内部会调用_Block_object_assign函数
* _Block_object_assign函数会对__block修饰的变量形成强引用(retain)；对于外部对象 assign函数根据外部如何引用而引用
3. 当Block从堆中移除时，对__block修饰的变量做了什么？
* 会调用Block内部的dispose函数
* dispose函数内部会调用_Block_object_dispose函数
* _Block_object_dispose函数会自动释放引用的__block修饰的变量(release)
4. __block修饰的对象类型在Block上如何操作的？
* 当__block变量在栈上时，不会对指向的对象产生强引用
* 当__block变量被copy到堆时,会调用__block变量内部的copy函数;copy函数内部会调用_Block_object_assign函数;_Block_object_assign函数会根据所指向对象的修饰符(__strong、__weak、__unsafe_unretained)做出相应的操作，形成强引用或者弱引用
* 如果__block变量从堆上移除,会调用__block变量内部的dispose函数;dispose函数内部会调用_Block_object_dispose函数;_Block_object_dispose函数会自动释放指向的对象

### 2.2 __block变量与__forwarding
#### 我们知道在copy操作之后,__block变量也会被拷贝到堆中,那么访问该变量访问的是栈上的还是堆上的?
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/block2.jpeg)
* 通过__forwarding无论在Block内还是Block外访问__block修饰的变量,也不管该变量在堆上还是栈上,都能顺利的访问同一个__block修饰的变量



### 3. Block循环引用
#### 在ARC环境下解决循环引用有三种方式
* __weak: 弱引用，不持有对象，对象释放时会将对象置nil。
* __unsafe_unretained: 弱引用，不持有对象，对象释放时不会将对象置nil。
* __block: 必须把引用对象置位nil，并且要调用该block
        //.h文件
        typedef void (^WGCustomBlock)(NSString *name);

        @interface WGAnimal : NSObject
        @property(nonatomic, copy) WGCustomBlock block1;
        @property(nonatomic, assign) int age;
        @end

        @interface WGMainObjcVC : UIViewController
        @end

        //.m文件
        @implementation WGAnimal
        @end

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            WGAnimal *animal = [[WGAnimal alloc]init];
            animal.block1 = ^(NSString * _Nonnull name) {
                //warn: Capturing 'animal' strongly in this block is likely to lead to a retain cycle
                NSLog(@"动物的年龄是:%d",animal.age);
            };
        }
        @end
#### 分析: block1是animal对象的一个属性，所以animal对象强引用了block1,block1内又强引用了animal对象，这就造成了循环引用
        //方式一:使用__weak来解决循环引用
        WGAnimal *animal = [[WGAnimal alloc]init];
        //通过typeof为要引用的animal对象起个别名animalWeak
        __weak typeof(animal)animalWeak = animal;
        animal.block1 = ^(NSString * _Nonnull name) {
            NSLog(@"动物的年龄是:%d",animalWeak.age);
        };
        
        //方式二:使用__unsafe_unretained来解决循环引用,在这里会引起crash
        __unsafe_unretained WGAnimal *animal = [[WGAnimal alloc]init];
        animal.block1 = ^(NSString * _Nonnull name) {
            NSLog(@"动物的年龄是:%d",animal.age);
        };
        
        //方式三 使用__block来解决循环引用,这种方式必须调用Block,否则对象就不会置为nil,内存泄漏会一直存在
        __block WGAnimal *animal = [[WGAnimal alloc]init];
        animal.block1 = ^(NSString * _Nonnull name) {
            NSLog(@"动物的年龄是:%d，名字是:%@",animal.age,name);
            //必须置为nil
            animal = nil;
        };
        animal.block1(@"狗");

#### MRC环境下解决循环引用有二种方式
* __unsafe_unretained
* __block

#### 3.1 不会造成循环引用的情况
* 大部分GCD方法，因为self并没有对GCD中的Block进行持有，没有形成循环引用；目前还没碰到使用GCD导致循环引用的场景；除非self对GCD中的block持有才有可能造成循环引用
* block并不是属性值，而是临时变量,self对block并没有持有

        - (void)viewDidLoad {
            [super viewDidLoad];
            
            void (^WGCustomBlock)(NSString *) = ^(NSString *name){
                NSLog(@"我的名字是:%@,所在的类是:%@",name,[self class]);
            };
            WGCustomBlock(@"张三");
        }
        打印结果: 我的名字是:张三,所在的类是:WGMainObjcVC

### 4.总结
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/block.jpeg)



### 5.Block源码分析
### 5.1 使用clang编译器将Objective-C代码编译成C语言代码, 并生成在一个.cpp的 C++文件中，通过这个文件我们可以查看Block的底层代码实现
* 项目中创建一个.m文件，然后在.m文件中使用Block
* 在终端cd到包含.m文件的目录，然后执行clang -rewrite-objc XXX.m，在.m文件的同级目录中会生成XXX.cpp文件
* 如果出现main.m:9:9: fatal error: 'UIKit/UIKit.h' file not found错误，可使用命令:clang -x objective-c -rewrite-objc -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk XXX.m,如果在目录中生成了XXX.cpp文件即证明编辑成功了
* 上面的命令太长了，可以使用alias来为上面的命令起个别名来替换这个命令
1. 在终端输入 vim ~/.bash_profile
2. 在vim界面输入i进入编辑状态并且键入alias wgrewriteoc='clang -x objective-c -rewrite-objc -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
3. 点击esc退出编辑，然后输入:wq保存并退出Vim界面
4. 输入命令source ~/.bash_profile保证刚才的编辑生效
5. cd到包含XXX.m的文件夹，然后输入命令 wgrewriteoc XXX.m即可在XXX.m的同级目录生成.cpp文件

### 5.2 .cpp文件分析
### 5.2.1 我们将下面WGMainObjcVC.m文件转为WGMainObjcVC.cpp文件
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            //1无参数无返回值的Block
            void (^WGCustomBlock1)(void) = ^{
                NSLog(@"我叫张三");
            };
            WGCustomBlock1();
        }
        @end
        
#### 转为.cpp文件后的WGCustomBlock1底层代码如下
        //定义Block
        void (*WGCustomBlock1)(void) = ((void (*)())&__WGMainObjcVC__viewDidLoad_block_impl_0((void *)__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA));
        //调用Block
        ((void (*)(__block_impl *))((__block_impl *)WGCustomBlock1)->FuncPtr)((__block_impl *)WGCustomBlock1);
        
        把强制类型去掉简化后的代码
        //定义Block
        void (*WGCustomBlock1)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA);
        //调用Block
        WGCustomBlock1->FuncPtr(WGCustomBlock1);
        
### 5.2.2 分析Block定义
        void (*WGCustomBlock1)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA);
        
#### 我们可以猜测定义过程是：调用__WGMainObjcVC__viewDidLoad_block_impl_0函数，里面传递了两个参数__WGMainObjcVC__viewDidLoad_block_func_0和__WGMainObjcVC__viewDidLoad_block_desc_0_DATA，然后得到这个函数的返回值，将函数返回值的地址赋值给WGCustomBlock1这个指针

#### 接下来我们来看下上面的方法__WGMainObjcVC__viewDidLoad_block_impl_0的详细信息，会发现实际上Block就是个结构体对象

        这是一个C++的结构体，包含了一个和结构体名称一样的函数，函数名和结构体名称一样，这是C++结构体的特性
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          //C++结构体中包含的函数称为构造函数，相当于OC的init方法，init方法返回的是对象本身，那么C++的构造函数返回的也是这个结构体本身
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, int flags=0) {
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
        
        static struct __WGMainObjcVC__viewDidLoad_block_desc_0 {
          size_t reserved;
          size_t Block_size;
        } __WGMainObjcVC__viewDidLoad_block_desc_0_DATA = { 0, sizeof(struct __WGMainObjcVC__viewDidLoad_block_impl_0)};

#### 在这里我们就可以判定__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA)这个结构体函数返回的就是__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体对象，然后将结构体对象的指针赋值给了WGCustomBlock1指针，即WGCustomBlock1这个Block指向的就是初始化后的__WGMainObjcVC__viewDidLoad_block_impl_0结构体对象。

#### 接下来分析下上面方法的参数
    //第一个参数  __WGMainObjcVC__viewDidLoad_block_func_0
    static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_246f66_mi_0);
    }
* 这个函数其实就是把WGCustomBlock1中要执行的代码封装到这个函数内部了，因为这个函数里面就一行代码，并且有NSLog函数对应我们的NSLog(@"我叫张三");将这个函数指针传递给构造函数__WGMainObjcVC__viewDidLoad_block_impl_0的第一个参数，然后用这个函数指针来初始化__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体中的第一个结构体impl中的成员变量FuncPtr，也就是说FuncPtr这个指针指向的就是__WGMainObjcVC__viewDidLoad_block_func_0这个函数

        //第二个参数 __WGMainObjcVC__viewDidLoad_block_desc_0_DATA
        static struct __WGMainObjcVC__viewDidLoad_block_desc_0 {
            size_t reserved;
            size_t Block_size;
        } __WGMainObjcVC__viewDidLoad_block_desc_0_DATA = { 0, sizeof(struct __WGMainObjcVC__viewDidLoad_block_impl_0)};
* 在这个结构体中，0赋值给了reserved，sizeof(struct __WGMainObjcVC__viewDidLoad_block_impl_0)赋值给了Block_size；可以看出这个结构体存放是的__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体的信息
#### Block定义过程总结如下:
        void (*WGCustomBlock1)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA);
* 创建一个函数__WGMainObjcVC__viewDidLoad_block_func_0，作用就是将我们block中要执行的代码封装到这个函数内部，方便调用，将这个函数传递给构造函数__WGMainObjcVC__viewDidLoad_block_impl_0，用来初始化结构体__WGMainObjcVC__viewDidLoad_block_impl_0的第一个成员变量impl的成员变量FuncPtr，这个结构体就拥有了block中那个代码块的地址
* 创建一个__WGMainObjcVC__viewDidLoad_block_desc_0结构体，主要用来保存__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体的专用的存储空间大小的信息
*  __WGMainObjcVC__viewDidLoad_block_impl_0这个构造函数执行完成后返回的是__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体，将这个结构体的指针地址赋值给Block指针

### 5.2.3 分析Block调用
       原生版:调用Block
       ((void (*)(__block_impl *))((__block_impl *)WGCustomBlock1)->FuncPtr)((__block_impl *)WGCustomBlock1);
       简化版:调用Block
       WGCustomBlock1->FuncPtr(WGCustomBlock1);
* 我们已经知道了WGCustomBlock1这个Block的指针指向的是__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体,那么调用的顺序是不是就是 WGCustomBlock1->impl->FuncPtr？ 答案是不是的，原因是简化版前WGCustomBlock1前面是(__block_impl *)这种类型，而WGCustomBlock1这个指针指向的是__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体的首地址，而这个结构体的第一个成员是struct __block_impl impl;所以impl的首地址和__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体的首地址是一样的，因此指向__WGMainObjcVC__viewDidLoad_block_impl_0的首地址的指针也可以被转化为指向impl的首地址指针，FuncPtr这个指针在构造函数中是被初始化为指向__WGMainObjcVC__viewDidLoad_block_func_0这个函数的地址。因此通过block->FuncPtr调用也就获取了__WGMainObjcVC__viewDidLoad_block_func_0这个函数的地址，然后对__WGMainObjcVC__viewDidLoad_block_func_0进行调用，也就是执行block中的代码了。这中间block又被当做参数传进了__WGMainObjcVC__viewDidLoad_block_func_0这个函数

### 5.3 Block捕获auto自定变量(局部变量)源码分析
        - (void)viewDidLoad {
            [super viewDidLoad];
            int age = 18;
            NSString *name = @"张三";
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,年龄是:%d",name,age);
            };
            age = 30;
            name = @"李四";
            WGCustomBlock();
        }
        @end
        
        打印结果: 我的名字是:张三,年龄是:18
#### 我们在调用WGCustomBlock前，已经改变了name和age的值，为什么没有打印“我的名字是:李四,年龄是:30”这样的信息?,接下来看下cpp文件的内容
        简化后的代码
        int age = 18;
        NSString *name = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_e3cc9b_mi_0;
        //将age,name的值传递给__WGMainObjcVC__viewDidLoad_block_impl_0这个函数
        void (*WGCustomBlock)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA, name, age, 570425344));
        age = 30;
        name = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_e3cc9b_mi_2;
        WGCustomBlock->FuncPtr)WGCustomBlock;
        
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          //这是新加入的成员变量name和age
          NSString *name;
          int age;
          //将传递进来的name和age的值赋给对应的成员变量name,age
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, NSString *_name, int _age, int flags=0) : name(_name), age(_age) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
          }
        };
        
        //通过传入__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体来获取其成员变量的值
        static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
        NSString *name = __cself->name;   
        int age = __cself->age; 
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_e3cc9b_mi_1,name,age);
        }
#### 发现__WGMainObjcVC__viewDidLoad_block_impl_0构造函数中多了两个参数，将name,age作为参数传递给这个构造函数,为了给这个结构体内新生成的成员变量name，age赋值，由于这个过程是值传递，所以在外部改变name,age的值后，结构体中的成员变量值并不会被修改了；所以Block对auto局部变量的捕获是将局部变量的值赋值给Block结构体中新创建的成员变量，外部再修改局部变量的值也无法更改Block结构体内的成员变量的值

### 5.4 Block捕获static静态变量源码分析
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            static int age = 18;
            static NSString *name = @"张三";
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,年龄是:%d",name,age);
            };
            age = 30;
            name = @"李四";
            WGCustomBlock();
        }
        @end

        打印结果: 我的名字是:李四,年龄是:30
#### 对于static修饰的变量，我们发现外部修改了age和name值之后，WGCustomBlock内的值也跟着改变了，为什么？
        简化后的代码
        static int age = 18;
        static NSString *name = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_b8acf2_mi_0;
        //将age，name的指针地址传递__WGMainObjcVC__viewDidLoad_block_impl_0这个函数
        void (*WGCustomBlock)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA, &name, &age, 570425344));
        age = 30;
        name = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_b8acf2_mi_2;
        WGCustomBlock->FuncPtr)WGCustomBlock;


        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          //多了两个指针类型的成员变量
          NSString **name;
          int *age;
          //将传递进来的name和age的指针地址给对应的指针类型的成员变量name,age
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, NSString **_name, int *_age, int flags=0) : name(_name), age(_age) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
          }
        };
        
        //通过传入__WGMainObjcVC__viewDidLoad_block_impl_0这个结构体来获取其成员变量的指针地址
        static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
        NSString **name = __cself->name;
        int *age = __cself->age; 
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_b8acf2_mi_1,(*name),(*age));
        }
####  Block捕获static修饰的变量时，会在block结构体内创建一个指针类型的变量来接收这个局部变量的地址，因为是指针传递，所以Block能通过这个static修饰的变量的地址指针来获取到最新的值，即外部改变变量值的时候，在Block内都可以接收到这个最新的值

### 5.5 Block捕获全局变量源码分析
        int age = 18;
        static NSString *name = @"张三";

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,年龄是:%d",name,age);
            };
            age = 30;
            name = @"李四";
            WGCustomBlock();
        }
        @end
        
        打印结果: 我的名字是:李四,年龄是:30
#### Block内可以获取到全局变量最新的值
        简化后的代码
        //并没将全局变量作为参数传递到这个构造函数中
        void (*WGCustomBlock)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA));
        age = 30;
        name = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_2a8f5a_mi_2;
        WGCustomBlock->FuncPtr)WGCustomBlock;
        
        //这个结构体中也没有新增成员变量
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, int flags=0) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
          }
        };
        //这里直接调用全局变量，
        static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
         NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_2a8f5a_mi_1,name,age);
        }
        
#### 从源码看可以看出，全局变量name，age并没有作为参数传递给__WGMainObjcVC__viewDidLoad_block_impl_0这个构造函数，所以得出结论:Block对全局变量是不会捕获的


### 5.6 Block捕获self源码分析
        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"所在的对象是:%@",self);
            };
            WGCustomBlock();
        }
        @end

        打印结果: 所在的对象是:<WGMainObjcVC: 0x7fd380e058b0>
#### Block对self是否会捕获？
        简化后代码
        //self作为参数传递到这个构造函数中了，所以self就是个局部变量了
        void (*WGCustomBlock)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA, self, 570425344));
        WGCustomBlock->FuncPtr)WGCustomBlock;
        
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          //新增加了个成员变量
          WGMainObjcVC *self;
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, WGMainObjcVC *_self, int flags=0) : self(_self) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
          }
        };
        
        //通过__WGMainObjcVC__viewDidLoad_block_impl_0结构体获取到成员变量的值
        static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
        WGMainObjcVC *self = __cself->self;
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_7ddc39_mi_0,self);
        }
#### 可以看到Block捕获到self了.因为在Block中调用self的时候，self作为参数传递到了Block结构体中(这个self就是个局部变量)，并且赋值给了结构体中新增加的成员变量，

### 5.7 Block捕获成员变量源码分析
        @interface WGMainObjcVC()
        {
            NSString *_name;
            int _age;
        }
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            _name = @"张三";
            _age = 18;
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"我的名字是:%@,我的年龄是:%d",self->_name,self->_age);
            };
            _name = @"李四";
            _age = 30;
            WGCustomBlock();
        }

        @end

        打印结果:  我的名字是:李四,我的年龄是:30
#### Block是否会捕获到成员变量?
        //简化后代码
        (*(NSString **)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_name)) = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_31d681_mi_0;
        (*(int *)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_age)) = 18;
        
        //成员变量并没有作为参数传递给这个构造函数，而是将self作为你参数传递进去了
        void (*WGCustomBlock)(void) = &__WGMainObjcVC__viewDidLoad_block_impl_0(__WGMainObjcVC__viewDidLoad_block_func_0, &__WGMainObjcVC__viewDidLoad_block_desc_0_DATA, self, 570425344));
        
        (*(NSString **)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_name)) = (NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_31d681_mi_2;
        (*(int *)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_age)) = 30;
        
        WGCustomBlock->FuncPtr)WGCustomBlock;

        
        struct __WGMainObjcVC__viewDidLoad_block_impl_0 {
          struct __block_impl impl;
          struct __WGMainObjcVC__viewDidLoad_block_desc_0* Desc;
          //新增加了个成员变量用来保存外部传进来的参数self
          WGMainObjcVC *self; 
          __WGMainObjcVC__viewDidLoad_block_impl_0(void *fp, struct __WGMainObjcVC__viewDidLoad_block_desc_0 *desc, WGMainObjcVC *_self, int flags=0) : self(_self) {
            impl.isa = &_NSConcreteStackBlock;
            impl.Flags = flags;
            impl.FuncPtr = fp;
            Desc = desc;
          }
        };
        
        //通过__WGMainObjcVC__viewDidLoad_block_impl_0结构体获取到成员变量self
        static void __WGMainObjcVC__viewDidLoad_block_func_0(struct __WGMainObjcVC__viewDidLoad_block_impl_0 *__cself) {
        WGMainObjcVC *self = __cself->self;
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGMainObjcVC_31d681_mi_1,(*(NSString **)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_name)),(*(int *)((char *)self + OBJC_IVAR_$_WGMainObjcVC$_age)));
        }
#### 分析发现，Block内访问成员变量的时候，并不会在结构体中创建新的成员变量来保存这些传递进来的变量，而是将当前对象self做为参数传递到Block结构体中，所以Block对成员变量的捕获，实际上捕获的是self；所以Block内可以获取到最新的成员变量的值也是靠捕获self来获取的

### 6 Block捕获对象类型
        //.h文件
        @interface WGAnimal : NSObject
        @property(nonatomic, strong) NSString *name;
        @end

        @interface WGMainObjcVC : UIViewController
        @end

        //.m文件
        @implementation WGAnimal
        @end

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            WGAnimal *a1 = [[WGAnimal alloc]init];
            a1.name = @"张三";
            WGAnimal *a2 = [[WGAnimal alloc]init];

            NSLog(@"111111a1:%@---a2:%@",a1,a2);
            void (^WGCustomBlock)(void) = ^{
                NSLog(@"对象a1：%@,名称是:%@",a1,a1.name);
            };
            
            a1 = a2;
            a1.name = @"李四";
            NSLog(@"222222a1:%@---a2:%@",a1,a2);
            WGCustomBlock();
        }
        @end
        
        打印结果:111111a1:<WGAnimal: 0x6000024496a0>---a2:<WGAnimal: 0x6000024496b0>
                222222a1:<WGAnimal: 0x6000024496b0>---a2:<WGAnimal: 0x6000024496b0>
                对象a1：<WGAnimal: 0x6000024496a0>,名称是:张三
#### 分析: a1和a2对象都是局部变量，所以在WGCustomBlock中，捕获到的是对象a1的值，即便在Block外a1对象的地址被更换为对象a2的值，也不会改变WGCustomBlock中对象a1的值；因为捕获到的是a1的值，所以对象a1的属性name的值也是值捕获；
