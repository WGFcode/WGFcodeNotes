
#### 1.方法调用三种方式
1. [testObject testMethod];
2. [self perform(<#T##aSelector: Selector!##Selector!#>, with: <#T##Any!#>)]
3.  1) 通过方法调用者创建方法签名,
     2) 然后通过方法签名生成NSInvocation对象
     3) 设置方法调用者，方法选择器，方法参数
     4) 执行并获取返回值
     
            方法一
            [self eat];
            方法二
            [self performSelector:@selector(eat)];
            方法三
            [self loadMethod];

            -(void)loadMethod {
                //1.通过方法调用者创建方法签名
                NSMethodSignature *sign = [[self class] instanceMethodSignatureForSelector:@selector(eat)];
                //2.通过方法签名生成NSInvocation
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
                //3.设置方法调用者和方法选择器
                invocation.target = self;
                invocation.selector = @selector(eat);
                //4.有参数的话设置参数 设置的参数必须从2开始；因为0和1 已经被self ,_cmd 给占用了
            //    NSString *foodName = @"面条";
            //    [invocation setArgument:&foodName atIndex:2];
                //5.执行
                [invocation invoke];
                //6.判断方法返回是否有返回值
                NSUInteger signLength = sign.methodReturnLength; //方法签名返回值长度
                id returnValue;
                if (signLength == 0) {
                    //NSLog(@"该方法没有返回值");
                }else {
                    //这里默认所有返回值均为OC对象
                    if (strcmp(sign.methodReturnType, "@") == 0) {
                        [invocation getReturnValue:&returnValue];
                    }
                }
            }

            -(void)eat {
                NSLog(@"被调用了");
            }
