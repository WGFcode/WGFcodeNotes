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
* __NSGlobalBlock__ 全局Block: 存在数据区；没有访问auto变量的Block都是全局Block
* __NSStackBlock__  栈Block: 存在栈区；访问了auto变量的Block都是栈区Block
* __NSMallocBlock__ 堆Block: 存在堆区；【__NSStackBlock__ copy】就是堆区Block
* 系统自动分配栈区内存，自动销毁，先入后出；动态分配堆区内存，需要程序员自己申请，程序员自己管理


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
        
        //方式三 使用__block来解决循环引用
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
