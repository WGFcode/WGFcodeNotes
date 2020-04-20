##  Block
#### Block是封装函数实现及上下文环境的匿名函数,

### 1.Block概述
        Block声明及定义
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
