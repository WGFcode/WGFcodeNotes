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
#### 分析:为什么局部变量需要捕获？因为考虑作用域的问题，需要跨函数访问局部变量，所以需要捕获；Block内访问self是否会捕获?会捕获，self被当成调用Block的参数，参数是局部变量，所以会捕获；

### 1.4 Block类型

