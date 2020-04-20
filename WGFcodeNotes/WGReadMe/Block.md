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
