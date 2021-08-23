
#### 1.方法调用四种种方式
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
4. 创建个数组，并将对象放到数组中，然后调用KVC中的valueForKey:方法，将方法作为Key传递进去，这样就可以给对象发送消息了，即实现了方法调用
#### 2. 递归写算法1到100的和；时间复杂度是多少？递归缺点？不用递归能实现吗？时间复杂度能否降低到O(1)
    /*
    递归方法时间复杂度：O(n),
    递归缺点就是效率低：
    递归是函数调用，每次函数调用都需要在内存栈中分配空间来保存参数、返回地址以及临时变量，而往栈中压入数据和弹出数据都
    需要时间调用栈可能会溢出，每一次函数调用会在内存栈中分配空间，每个进程的栈的容量是有限的，当调用的层次太多时，
    就会超出栈的容量，从而导致栈溢出
    */
    private func getSum(value: Int) -> Int {
        guard value > 0 else {
            return 0
        }
        return value + getSum(value: value-1)
    }
    //非递归方法 时间复杂度O(n)
    private func getSum1(value: Int) -> Int {
        guard value > 0 else {
            return 0
        }
        var resultTotal = 0
        for i in 1...value {
            resultTotal += i
        }
        return resultTotal
    }
    //不用递归的方式：时间复杂度O(1)
    private func getSum2(value: Int) -> Int {
        guard value > 0 else {
            return 0
        }
        return (1+value)*value/2
    }
#### 3.property的作用是什么，有哪些关键词，分别是什么含义？
##### 用property可以直接调用属性，不需要我们再写set/get方法，系统已经帮我们实现了，@property的实质就是生成 _var +set +get方法(成员变量+set/get方法，添加实例变量有个前提，就是对象还没有同名的成员变量；如果我们同时自定义了属性的set和get方法，那么就不会再生成实例变量了)；property有两个对应的词，@synthesize和@dynamic
1. @synthesize：(1)ARC下很少使用了，因为都会生成set/get方法；在 MRC 下只有@synthesize name这样，编译器才会自动合成name的set/get存取方法;(2)如果不喜欢生成的实例变量名称，可以@synthesize  newName = name,即给实例变量起个别名，但是name的存取方法不会改变的。但一般不建议这么用
2. @dynamic：(1)告诉编译器,属性的setter/getter方法由用户自己实现，编辑器不再自动生成，即便我们没有手动实现，编辑阶段也不会报错，因为编辑器认为我们运行过程中会实现，但是如果我们确实没有实现并且调用了，那么运行就会报错“-[XXX setStr:]: unrecognized selector sent to instance 0x10040af10”;(2)如果我们子类中声明(重写)了和父类相同的属性名，编辑器就会警告，因为它不知道该在父类还是子类中实现set/get方法，如果在子类的.m文件中@dynamic name；那么系统就不会再为子类生成set/get方法了，这样就可以明确了
3. 如果@synthesize和@dynamic都没写，那么默认的就是@syntheszie var = _var;

#### 4. NSString、NSArray、NSDictionary应该如何选关键词？
#### 首先我们先看下面有关NSString的例子
    //.h文件
    @interface WGMainObjcVC : UIViewController
    @property(nonatomic, strong) NSString *nameStrong;
    @property(nonatomic, copy) NSString *nameCopy;
    @end
    //.m文件
    - (void)viewDidLoad {
        [super viewDidLoad];
        NSString *str = @"iphone";
        str = @"sdfasdfasdfasdf";
        self.nameCopy = str;
        self.nameStrong = str;
        str = @"123";
        NSLog(@"str:%@-地址:%p---nameStrong:%@-地址:%p---nameCopy:%@-地址:%p", 
        str, str, _nameStrong, _nameStrong, _nameCopy, _nameCopy);
    }
    当源字符串(str)是不可变的NSString类型，打印结果
    str:123-地址:0x109253658---nameStrong:sdfasdfasdfasdf-地址:0x109253638---
    nameCopy:sdfasdfasdfasdf-地址:0x109253638
        
    总结: copy或strong修饰的属性的内存地址都是一样的，都是指向了str的内存地址，而str的引用计数此时
    就是3，copy或strong修饰的属性并没有拷贝一份，所以nameCopy和nameStrong会随着str的改变而改变，即都进行了浅拷贝
    
    NSMutableString *str = [NSMutableString stringWithString:@"iphone"];
    self.nameCopy = str;
    self.nameStrong = str;
    [str appendString:@"X"];
    NSLog(@"str:%@-地址:%p---nameStrong:%@-地址:%p---nameCopy:%@-地址:%p",
    str, str, _nameStrong, _nameStrong, _nameCopy, _nameCopy);
    
    当源字符串(str)是可变的NSMutableString类型，打印结果
    str:iphoneX-地址:0x600003b1c900---nameStrong:iphoneX-地址:0x600003b1c900---
    
    nameCopy:iphone-地址:0x961fde0267f16d72
    总结：strong修饰的属性地址和源字符串的地址一样，即修饰的属性只是使str的引用计数+1，而内存地址依旧指向源字符串，
    所以会随着str的改变而改变(进行了浅拷贝)；
    
    而copy修饰的属性是（进行了深拷贝并生成了一个新的对象，nameCopy就指向了这个新对象）直接拷贝了一份str的内容，
    两者内存地址是不一样的，所以即便str改变了，copy修饰的属性也不会改变
        
#### 总结，综上所属，一般我们声明NSString类型属性的时候，如果不希望属性中途被改变(因为来源可能是NSMutableString)，那么选择copy可以进行深拷贝；如果我们确定来源是不可变的NSString类型，那么使用Strong或者copy都可以，但是，但是推荐使用Strong,因为copy修饰的NSString在进行set操作时，底层进行了这样的判断if ([str isMemberOfClass: [NSString class]])，如果来源是可变的，就进行一次深拷贝，如果是不可变的就和strong修饰一样，进行一次浅拷贝，如果项目中用的比较多的话，可能会影响性能；深拷贝就是拷贝的内容，浅拷贝就是拷贝的地址

        @interface WGMainObjcVC : UIViewController

        @property(nonatomic, strong) NSArray *arrStrong;
        @property(nonatomic, copy) NSArray *arrCopy;

        @end

        NSArray *arr = @[@"12",@"sdfa"];
        self.arrStrong = arr;
        self.arrCopy = arr;
        NSLog(@"arr:%@-地址:%p\narrStrong:%@-地址:%p\narrCopy:%@-地址:%p",
        arr, arr, _arrStrong, _arrStrong, _arrCopy, _arrCopy);

        打印结果：
        arr:(12, sdfa)-地址:0x600003177020
        arrStrong:(12, sdfa)-地址:0x600003177020
        arrCopy:(12,sdfa)-地址:0x600003177020
         
        分析：当源数组是不可变数据时，copy和strong修饰的属性的地址都指向了arr,其实就是都进行了浅拷贝，即指针拷贝
      
        NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@"12",@"sdfa"]];
        self.arrStrong = arr;
        self.arrCopy = arr;
        [arr addObject:@"000"];
        NSLog(@"arr:%@-地址:%p\narrStrong:%@-地址:%p\narrCopy:%@-地址:%p",
        arr, arr, _arrStrong, _arrStrong, _arrCopy, _arrCopy);
        
        打印结果:
        arr:(12,sdfa,000)-地址:0x600001018d50
        arrStrong:(12,sdfa,000)-地址:0x600001018d50
        arrCopy:(12,sdfa)-地址:0x600001eb6560
        
#### 分析：当源数组是NSMutableArr时，使用Strong进行的是浅拷贝，即进行内容地址的拷贝，所以Strong修饰的属性的地址和str是一样的，会随着str值的改变而改变；而copy修饰的属性进行的是深拷贝，即进行的是内容的拷贝，即将拷贝的内容赋值给了新的对象，所以它不会随着str值改变而改变；声明NSArray时，如果不希望它中途被改变，并且来源可能是NSMutableArray时，要使用copy来修饰，进行一次深拷贝，即拷贝源的内容，而地址是用新的内存地址，这样数组内容就不会随源数组的改变而改变了；如果确定源数组是不可变的NSArray类型，那么使用copy和strong效果是一样的，都进行了一次浅拷贝，即内存地址都是一样的，但建议使用strong，因为copy修饰的NSArray在进行set时多了一层判断，if ([str isMemberOfClass: [NSArray class]])，比较消耗性能；如果来源是可变的，那么使用copy修饰的话就会进行一次深拷贝
* 1.copy修饰NSArray:如果源数组是不可变的，则内存地址和源数组内存地址是一样的，即进行的是浅拷贝，会随着源数据的改变而改变；如果源数组是可变的，则进行的是深拷贝，即将源数组的内容拷贝一份，赋值给新的内存地址，不会随着源数据的改变而改变
* 2.Strong修饰的NSArray，无论源数据是可变的还是不可变的，进行的都是浅拷贝，即内存地址和源数据的内存地址是一样的
        
#### 需要注意的就是下面的情况，如果源数组是可变的NSMutableArray类型，那么使用Copy，确实进行了深拷贝，但是目标数组中的元素的内存地址和源数组中元素的内容地址仍然是一样的，如果改变了源数组中元素的内容，目标数组中的值也是会被改变的

    WGTestModel *mode1 = [[WGTestModel alloc]init];
    mode1.name = @"zhangsan";
    mode1.age = 18;
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:mode1, @"8888", nil];
    self.arrStrong = arr;
    self.arrCopy = arr;
    NSLog(@"arr:%@-地址:%p\narrStrong:%@-地址:%p\narrCopy:%@-地址:%p",
    arr, arr, _arrStrong, _arrStrong, _arrCopy, _arrCopy);

    打印结果:arr:( "<WGTestModel: 0x600003091320>", 8888 )-地址:0x600003e44900
                arrStrong:("<WGTestModel: 0x600003091320>",8888)-地址:0x600003e44900
                arrCopy:("<WGTestModel: 0x600003091320>",8888)-地址:0x600003091340
    分析: 从打印结果中可以看出arrCopy的内存地址和源数组的内容地址确实不一样，即进行了深拷贝，但是它里面元素的内容地址
    源数组中元素的内存地址是一样的，那么我们修改源数组中元素的内容，那么目标数组arrCopy中的元素是也会改变的
    
    WGTestModel *mode1 = [[WGTestModel alloc]init];
    mode1.name = @"zhangsan";
    mode1.age = 18;
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:mode1, @"8888", nil];
    self.arrStrong = arr;
    self.arrCopy = arr;
    //修改源数组arr中元素mode1中的内容
    mode1.name = @"lisi";
    mode1.age = 20;
    NSLog(@"arr:%@-地址:%p\narrStrong:%@-地址:%p\narrCopy:%@-地址:%p-元素内容:name:%@-age:%d",
    arr, arr, _arrStrong, _arrStrong, _arrCopy, _arrCopy,mode1.name,mode1.age);
        
    打印结果
    arr:("<WGTestModel: 0x60000324e3c0>",8888)-地址:0x600003c99dd0
    arrStrong:("<WGTestModel: 0x60000324e3c0>",8888)-地址:0x600003c99dd0
    arrCopy:("<WGTestModel: 0x60000324e3c0>",8888)-地址:0x60000324e3e0-元素内容:name:lisi-age:20

    分析：可以发现如果改变源数组中元素的内容，那么copy修饰的数组虽然进行了深拷贝，但是它里面元素的内容也会随着改变，那么如何避免那？
#### 想要避免上面情况，就需要将数组元素中的模型类实现NSCopying和NSMutableCopying协议
        //.h文件
        @interface WGTestModel : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) int age;
        @end

        //.m文件
        @interface WGTestModel()<NSCopying, NSMutableCopying>
        @end
        @implementation WGTestModel

        -(id)copyWithZone:(NSZone *)zone {
            WGTestModel *model = [[[self class] allocWithZone:zone] init];
            model.name = [self.name copyWithZone:zone];
            model.age = self.age;
            return model;
        }
        -(id)mutableCopyWithZone:(NSZone *)zone {
            return [self copyWithZone:zone];
        }
        @end

        WGTestModel *mode1 = [[WGTestModel alloc]init];
        mode1.name = @"zhangsan";
        mode1.age = 18;
        NSMutableArray *arr = [NSMutableArray array];
        NSMutableArray *tempArr = [NSMutableArray arrayWithObjects:mode1, nil];
        for (WGTestModel *model in tempArr) {
            [arr addObject:[model copy]];
        }
        self.arrStrong = arr;
        self.arrCopy = arr;
        //修改源数组arr中元素mode1中的内容
        mode1.name = @"lisi";
        mode1.age = 20;

        NSLog(@"arr:%@-地址:%p\narrStrong:%@-地址:%p\narrCopy:%@-地址:%p-元素内容:%@",
        arr, arr, _arrStrong, _arrStrong, _arrCopy, _arrCopy,((WGTestModel *)_arrCopy[0]).name);
              
        打印结果:
        arr:("<WGTestModel: 0x600003e5e1c0>")-地址:0x6000030134e0
        arrStrong:("<WGTestModel: 0x600003e5e1c0>")-地址:0x6000030134e0
        arrCopy:("<WGTestModel: 0x600003e5e1c0>")-地址:0x600003c40620-元素内容:zhangsan
#### 同理对于NSDictionary也是一样的

#### 5. copy和muteCopy有什么区别，深复制和浅复制是什么意思，如何实现深复制？
#### 首先我们要知道copy特点：修改源对象(副本对象)的属性和行为，不会影响副本对象(源对象)。一个对象可以通过copy或者muteCopy来创建一个副本对象
    NSString *str1 = @"123";
    NSString *strCopy = [str1 copy];
    NSString *strMutaCopy = [str1 mutableCopy];
    NSLog(@"str1:%@-%p\nstrCopy:%@-%p\nstrMutaCopy:%@-%p",
    str1,str1, strCopy, strCopy, strMutaCopy, strMutaCopy);
    
    打印结果: str1:123-0x1060fa618
            strCopy:123-0x1060fa618
            strMutaCopy:123-0x600000817000

    总结:copy进行的是浅拷贝，拷贝的是str1的地址；mutableCopy进行的是深拷贝，拷贝的是str1的内容到另一个新的内容地址中

#### 因为copy进行的是浅拷贝，那么修改str1的值，按理说strCopy值也会随着改变，因为浅拷贝拷贝的是内存地址，那么我们验证一下
    NSString *str1 = @"123";
    NSLog(@"str1:%@-%p",str1, str1);
    NSString *strCopy = [str1 copy];
    NSString *strMutaCopy = [str1 mutableCopy];
    str1 = @"666";  
    NSLog(@"str1:%@-%p\nstrCopy:%@-%p\nstrMutaCopy:%@-%p",
    str1,str1, strCopy, strCopy, strMutaCopy, strMutaCopy);
    
    打印结果: str1:123-0x100b59618
            str1:666-0x100b59658
            strCopy:123-0x100b59618
            strMutaCopy:123-0x600000d0fb40
    我们会发现当改变源对象str1的时候，strCopy的值并没有改变,并且对str1重新赋值的时候，str1又进行了浅拷贝，
    即str1的内存地址改变了；这种情况就得用使用copy的特点来解释了，修改源对象或者副本对象，并不会改变副本对象或者源对象；
#### copy是浅拷贝，即不同的指针(str1和strCopy)指向了同一个地址，那么为什么修改str1的内容，strCopy却没有变化，不是指向了同一个地址吗？并且修改str1后，str1的内存地址就也改变了？首先当执行[str1 copy]时，str1和strCopy都是不可变的，指向了同一个内存空间中的@“123”，为了性能优化，系统没必要提供新的内存空间，只生成另一个指针，指向同一块内容空间就行；当str1 = @"666"重新给str1赋值时，因为之前的内容不可变，还有互不影响的原则，所以系统会重新开辟一个内存空间


#### 问题2: 数组拷贝
    NSArray *arr = @[@"123"];
    NSArray *arrCopy = [arr copy];
    NSMutableArray *arrMutaCopy = [arr mutableCopy];
    NSLog(@"arr:%@-%p\narrCopy:%@-%p\narrMutaCopy:%@-%p",
    arr,arr, arrCopy, arrCopy,arrMutaCopy,arrMutaCopy);
    打印结果: arr:(123)-0x600001efa800
            arrCopy:(123)-0x600001efa800
            arrMutaCopy:(123)-0x6000012aa070
            
    分析：copy进行的是浅拷贝，因为内存地址和源数组内存地址一样；mutableCopy进行的深拷贝，拷贝了内容后重新赋值给新的内存地址
     
    NSArray *arr = @[@"123"];
    NSLog(@"arr:%@-%p",arr,arr);
    NSArray *arrCopy = [arr copy];
    NSMutableArray *arrMutaCopy = [arr mutableCopy];
    arr = @[@"666"];
    NSLog(@"arr:%@-%p\narrCopy:%@-%p\narrMutaCopy:%@-%p",
    arr,arr, arrCopy, arrCopy,arrMutaCopy,arrMutaCopy);
    
    打印结果:arr:(123)-0x60000015ead0
           arr:(666)-0x60000015eb00
           arrCopy:(123)-0x60000015ead0
           arrMutaCopy:(123)-0x600000df8030
    分析:当修改arr后，arrCopy的值并没有随着arr的改变而改变，遵循copy的特点，源数据改变并不能改变目标数据；
    而改变arr值后arr的地址改变了，因为之前的arr和copy指针指向了同一个内存地址，并且都是不可变的，那么系统为了性能，
    就重新开辟新的内存空间来存放新设置的值

#### 浅拷贝，不拷贝对象本身，仅仅是拷贝指向对象的指针。深拷贝，是直接拷贝整个对象内存到另一块内存中。 有什么看法？浅拷贝，不拷贝对象本身，仅仅是拷贝指向对象的指针。不够严谨，在一些特殊情况下，还是会拷贝整个对象内存到另一块内存中。
#### 总结：
1. 用copy修饰的 或者赋值的 变量肯定是不可变的。
2. 用copy赋值，要看源对象是否是可变的，来决定拷贝指针，还是也拷贝对象到另一块内存空间
3. 对象之间mutableCopy赋值，肯定会拷贝整个对象内存到另一块内存中，即进行了深拷贝
4. 对象之间赋值之后，再改变，遵循互不影响的原则

#### 6. 用runtime做过什么事情？runtime中的方法交换是如何实现的？
#### 7. 讲一下对KVC合KVO的了解，KVC是否会调用setter方法？
#### 8. __block有什么作用
#### 1.对于自动变量的值，在Block内是无法修改的，因为Block使用外部变量的时候，是在Block内创建了一个新的变量来接收这个外部变量的值，而对于static变量，在Block内是可以被修改的，因为在Block内存储的是static变量的指针，Block内是可以通过指针来修改静态变量的。而__block的作用就是允许在Block内修改外部自动变量的值，__block会把Block外部变量的地址从栈区放到堆区，这样在Block内就可以修改外部变量的值了；
#### 2. __block本身无法解决循环引用问题，但是我们可以手动在Block中将obj=nil置空来解决循环引用问题
#### 9. 说一下对GCD的了解，它有那些方法，分别是做什么用的？
#### GCD主要是用来处理多线程任务的，涉及到队列任务的概念，队列分为串行队列/并发队列/主队列/全局队列，而主队列是系统创建的串行队列，全局队列是系统创建的并发队列，任务又分为同步任务/异步任务，通过队列和任务的组合，将创建的任务放到队列里面来执行任务的；GCD中会涉及到GCD组DispatchGroup的概念，组就是将多个任务放在组中，实现异步调用的。
1. GCD组notify方法：当GCD组中所有的任务都完成后，才通知后续的任务执行，一般用于任务间依赖，例如任务C的完成依赖于任务A任务B的完成，该方法不会阻塞当前线程
2. GCD组wait方法：如果我们想控制组内任务的执行顺序，就可以使用该方法来实现，例如任务A-wait()-任务B-wait...该方法会阻塞当前线程
3. GCD中的信号量来显示任务间依赖，signal方法使信号量+1，wait(信号量为0时，阻塞wait后的任务执行，直到信号量值大于0)
4. 如果GCD中组的任务嵌套了异步任务，那么可以通过使用GCD组中的enter和leave方法来控制异步任务的完成，从而来真正控制组内任务的同步

#### 10. 对二叉树是否了解？

#### 11. ARC和MRC的区别，iOS是如何管理引用计数的，什么情况下引用计数加1什么情况引用计数减一？
#### 12. 在MRC下执行[object autorelease]会发生什么，autorelease是如何实现的？
#### 13. OC如何实现多继承？
#### 14. 对设计模式有什么了解，讲一下其中一种是如何使用的。
#### 15. 有没有哪个开源库让你用的很舒服，讲一下让你舒服的地方。
#### 16. 一张100*100，RGBA的png图像解压之后占多大内存空间。
#### 17. 题目：给定一个个数字arr，判断数组arr中是否所有的数字都只出现过一次。有没有办法进行优化?
#### 18. 给定一个Int型数组，用里面的元素组成一个最大数，因为数字可能非常大，用字符串输出。例如：输入: [3,30,34,5,9]，输出: 9534330

#### 19. 项目中有这么一个方法func findfile(dir: String suffix: String) -> [String] ，可以通过输入文件夹目录，和后缀检索出所需的文件。例如需要在某个文件中检索txt文件或者mp4文件，那就传入dir和suffix就行了。现在又有一些需求，例如需要检索utf8格式的txt或者h264编码的mp4，也会有一些例如查找最近一周更新过的文件这样的需求，你如何优化这个类，让它满足这些情况？


#### 20. 如果子视图超出父视图范围，那么点击子视图和父视图重叠位置时，哪个视图会响应事件？如果点击子视图超出父视图位置，会响应事件吗？如果不能响应事件如何做？如果我们希望点击父视图的区域时响应父视图事件，点击子视图时，响应子视图事件，怎么做？

#### 问题1：点击子视图和父视图重叠的位置时，子视图能响应事件而父视图不能，因为点击屏幕,首先调用RunLoop的source1(基于端口的系统事件)来唤醒RunLoop，然后RunLoop会将事件交给source0来处理，source0会把点击时生成的UIEvent事件交给UIApplication,然后通过UIWindow->VC的View->...>bigsupView->subView进行寻找最佳响应者，在找的过程中，找到bigsupView时，判断点击点在bigsupView上，然后继续找到subView，发现点击点subView上，所以事件就交给subView来处理了，所以subView能响应事件，而bigsupView不能响应事件,
#### 问题2：点击子视图超出父视图的位置时，子视图和父视图都不影响事件，因为在响应链中寻找最佳响应者时，找到bigsupView时，判断点击点不在bigsupView上，直接就返回了不再向下一级的subView寻找了，所以子视图和父视图都不会响应事件
#### 问题3: 如果点击超出父视图的子视图区域，想让子视图响应事件的话，就两种解决方式
1. 方式一：自定义bigsupView，并在bigsupView的类中重写系统的方法- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event，并设置为YES，该方法作用就是当响应链中找到父视图WGBigView时，判断点击点是否在WGBigView上，设置为YES，就表示点击点在父视图上，然后才会继续去subView中找，这样子视图就可以响应事件了

        public class WGBigView : UIView {
           //方式一：
           public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
               return true
           }
        }
   
   2. 方式二: 继续方案一种的demo,在父视图WGBigView中重写系统方法- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;在这个方法中遍历父视图WGBigView的子视图，如果点击点在子视图的范围内，就返回这个子视图作为最佳响应者，这样子视图就可以响应事件了
   
          public class WGBigView : UIView {
              //方法二：
              public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
                    let view = super.hitTest(point, with: event)
                    if view == nil { //如果WGBigView的父视图没有找到最佳响应者，就遍历WGBigView的子视图
                        for sub in self.subviews {
                            //将当前点击的点从当前视图的坐标系中换算到sub的坐标系中
                            let point = sub.convert(point, from: self)
                            //判断点击点是否在sub的范围之内，如果在就返回这个子视图作为最佳响应者
                            if sub.bounds.contains(point) {
                                return sub
                            }
                        }
                    }
                    return view
                }
            }
#### 问题4，简单描述就是父视图范围在子视图范围内包含着，然后点击父视图范围响应父视图，点击父视图其他范围但是这个范围还在子视图中时，响应子视图事件。方案就是重写WGBigView类中的系统方法hitTest，然后先判断点击位置是否在父视图范围，如果在直接返回，如果不在再去遍历子视图

            public class WGBigView : UIView {
                public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
                    //首先判断点是否在self上，如果在就响应事件，如果不在就继续下面的判断
                     if self.bounds.contains(point) {
                         return self
                     }
                     for sub in self.subviews {
                         let subPoint = sub.convert(point, from: self)
                         if sub.bounds.contains(subPoint) {
                             return sub
                         }
                     }
                    return nil
                }
            }
#### 21. swift中class和struct区别
1. class是引用类型; struct是值类型
2. 在初始化时，struct可直接把属性放在默认的构造器函数中进行赋值，而class则不能
3. 对class或者struct进行赋值(=)时，struct会拷贝一份完整的数据内容给新的变量(开辟了新的内存空间)，改变旧变量并不会影响新变量的内容；而class进行赋值(=)时，并不会拷贝一份完整的数据内容给新的变量，只是增加了原变量内存地址的引用(就是多个变量指向了同一块内存地址，并不会开辟新的内存空间)
4. class中的方法可以修改属性的值，而struct中的方法如果要修改属性的值，需要在方法前添加mutating关键字
5. class可以继承； struct不可继承
6. struct比class更**轻量级**，struct内存分配在**栈空间**; class内存分配在**堆空间**

#### 21.1 struct作为数据模型的注意点：
* 优点:
1. 安全性：Struct是用值类型传递的，它们没有引用计数。
2. 不存在内存泄露: 没有引用数，所以不会因为循环引用导致内存泄漏
3. 速度快:值类型通常以栈的形式分配内存空间的
4. 线程安全: 值类型是自动线程安全的,无论从哪个线程去访问你的Struct，都非常简单。
* 缺点:
1. 混合开发(OC+swift)时，OC代码中无法调用Swift的Struct,因为在OC中调用swift代码，需要swift中对象继承自NSObject
2. 不能继承
3. NSUserDefaults: Struct不能被序列化成NSData对象。
#### 建议:如果模型较小，并且无需继承、无需储存到NSUserDefault或者无需Objective-C使用时，建议使用 Struct。
#### 21.2 为什么访问struct会比class快？
1. 栈内存空间是在程序启动时，系统事先分配的，使用过程中系统不干预；在编译时分配空间
2. 堆是用的时候才向系统申请的，用完了需要交还；申请和交还的过程开销就大了；在运行时分配空间
3. 堆在分配和释放时都要调用函数（MALLOC,FREE)，分配时会到堆空间去寻找足够大小的空间，都需要花费一定时间，而栈却不需要这些
4. 访问堆的一个具体单元，需要两次访问内存，第一次得取得指针，第二次才是真正得数据，而栈只需访问一次。

































