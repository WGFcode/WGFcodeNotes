## KVO键值观察
#### KVO(Key-Value Observing)键值观察,就是对对象的属性添加观察，当属性值变化的时候，通过观察者对象实现的KVO接口方法来自动的通知观察者,KVO是基于KVC实现的;在swift中KVO的接口都定义在NSObject的扩展中，在OC中所有的KVO接口都定义在@interface NSObject(NSKeyValueObserving)类别中，也就是所有的NSObject对象都可以实现KVO

### KVO使用过程注意点
* 添加了一个观察者，就必须在合适的时机移除观察者，否则会造成内存泄露；
* 如果在添加观察者方法中，拼写错了属性，则KVO是不会触发的
* KVO只能监听属性，不能监听成员变量，因为KVO的底层实现原理是通过监听属性的setter方法
* 如果观察者已经被移除了，那么当属性发生变化的时候，就不在触发监听方法了；
* 如果观察者已经被移除了，当再次调用移除观察者的方法removeObserver的时候，程序会crash(errorInfo: because it is not registered as an observer.)，所以使用过程中一定要注意
* KVO是同步的
* KVO是基于runtime机制实现的，运用了一个isa-swizzling技术。isa-swizzling就是类型混合指针机制, 将2个对象的isa指针互相调换, 就是俗称的黑魔法
* KVO的通过重写setter方法来触发通知机制的，如果你直接赋值给实例变量而不是使用属性赋值的话，是不会触发KVO的(self.XXX换成_XXX是无效的，因为self.XXX赋值时调用了setter方法)。但是使用KVC来给实例变量赋值，会触发KVO,因为对一个实例变量调用KVC的时候，KVC内部会主动调用对象的willChangeValueForKey:和didChangeValueForKey: 这两个方法,所以会触发KVO操作
* 对于集合属性(NSArray/NSSet不包括NSDictionary)的KVO，只有在对集合赋值的时候才会触发KVO，改变集合中元素的个数是不会触发KVO的；如果想集合元素个数改变时(增删改)，也能触发KVO，那么有两种方式:
1. 就是自定义一个类，将集合作为自定义类的属性，然后在需要监听的类中引用这个自定义类，为这个引用的属性添加观察方法，利用KVC(mutableArrayValueForKeyPath)获取到自定义类中的集合对象，然后进行增删改操作就可以触发KVO的监听方法了
2. 在使用集合对象的类中，什么都不需要做，只需要在集合对象发生变化的时候，在变化前后添加willChangeValueForKey和didChangeValueForKey方法，就可以手动触发KVO；如果集合在多个地方被频繁的改变，每个改变的地方都要写上面两个方法，会使代码很臃肿，所以推荐第一种方法

## OC 
#### KVO主要接口方法在NSKeyValueObserving和NSKeyValueObserverRegistration两个NSObject的类别中；NSKeyValueObserving提供监听到观察者属性变化的接口；NSKeyValueObserverRegistration提供添加和移除观察者的接口

        @interface NSObject(NSKeyValueObserving)
        监听到属性变化开始处理
        - (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;
        @end

        @interface NSObject(NSKeyValueObserverRegistration)
        添加观察者
        - (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
        删除观察者
        - (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;
        - (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
        @end
#### 各个参数含义
* observer: 添加的观察者对象，也就是KVO通知的订阅者。当监听的属性发生变化时就会通知该对象,该对象必须实现observeValueForKeyPath:方法,否则当监听的属性发生变化的时候,发现没有相应的接收方法时,程序会crash;
* keyPath: 要被监听的属性,也就是被观察者,注意这里不能为nil,否则程序会crash;通常我们使用的是与属性同名的字符串,但是为了避免出现拼写错误,我们可以使用NSStringFromSelector(@selector(属性名))来规避拼写错误,这个方法实际上就是将属性的getter方法转成了字符串
* options: KVO的配置参数,用于指明通知发出的时机和响应方法observeValueForKeyPath:的change字典中包含哪些值
* context: 可选的参数,可以传值也可以传nil，这个参数会被传递监听方法中，用来区分不同的通知;如果你想用来区分通知,推荐使用[声明一个静态变量,其保持它自己的地址,这个变量没什么意义,但能起到区分通知的作用],可以拥有区分多个观察者观察同一个属性的时候，甚至也可以用于传递值
* change: 字典类型，保存了监听属性的变更信息，信息内容受options:NSKeyValueObservingOptions枚举的影响
#### NSKeyValueObservingOptions枚举包含下列4个选项
* NSKeyValueObservingOptionNew：change字典中包含属性改变后的新值
* NSKeyValueObservingOptionOld： change字典中包含属性改变前的旧值
* NSKeyValueObservingOptionInitial：注册通知方法发出后立即就会立刻触发KVO通知，即触发observeValueForKeyPath方法
* NSKeyValueObservingOptionPrior：分2次调用。在值改变之前和值改变之后
#### 如何从change字典中获取对应的值,这里有5个常量作为change字典的键Key来获取对应的值
* NSString *const NSKeyValueChangeKindKey; 变更的类型,值为NSKeyValueChange的枚举,一般都是返回的都是1(NSKeyValueChangeSetting),如果监听的属性是个集合类型,当集合发生插入，删除，替换时就会返回对应的值

        enum {
           NSKeyValueChangeSetting = 1,
           NSKeyValueChangeInsertion = 2,
           NSKeyValueChangeRemoval = 3,
           NSKeyValueChangeReplacement = 4
        };
        typedef NSUInteger NSKeyValueChange;

* NSString *const NSKeyValueChangeNewKey;  被监听属性改变后的新值;如果监听的属性是个集合,并且NSKeyValueChangeKindKey不为1(NSKeyValueChangeSetting)时,返回的是个数组,包含了插入，替换后的新值,删除操作不会返回新值的;
* NSString *const NSKeyValueChangeOldKey;  被监听属性改变前的旧值;如果监听的属性是个集合,并且NSKeyValueChangeKindKey不为1(NSKeyValueChangeSetting)时,返回的是个数组,包含了删除，替换前的旧值,插入操作不会返回旧值;
* NSString *const NSKeyValueChangeIndexesKey;  如果NSKeyValueChangeKindKey的值为NSKeyValueChangeInsertion, NSKeyValueChangeRemoval, 或者 NSKeyValueChangeReplacement，这个键的值是一个NSIndexSet对象，包含了增加，移除或者替换对象的index;
* NSString *const NSKeyValueChangeNotificationIsPriorKey; change字典中就会带有这个key，值为NSNumber类型的YES.

### 1.监听其自定义属性(字符串)
    //.m文件中
    @interface WGMainObjcVC ()
    @property(nonatomic, strong) NSString *name;
    @end

    @implementation WGMainObjcVC

    - (void)viewDidLoad {
        [super viewDidLoad];
        self.view.backgroundColor = [UIColor redColor];
        self.name = @"lisi";
        //两种写法都可以，但推荐第二种写法,这样可以有效避免拼写错误
        //[self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(name)) options:NSKeyValueObservingOptionNew context:nil];
        NSLog(@"结束了");
    }

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        self.name = @"zhangsan";
    }

    -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
        NSString *newName = [change objectForKey:NSKeyValueChangeNewKey];
        NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\ncontext:%@\nnewName:%@\n",keyPath,object,change,context,newName);
    }
    
    //适当的时机移除观察者(一般在对象销毁的时候)
    -(void)viewWillDisappear:(BOOL)animated {
        [super viewWillDisappear:animated];
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(name))];
        [self removeObserver:self forKeyPath:@"name"];
    }
    @end

    打印结果: keyPath:name
            object:<WGMainObjcVC: 0x7ff90ec0a130>
            change:{
                kind = 1;
                new = zhangsan;
            }
            context:(null)
            newName:zhangsan
            结束了
#### 分析: KVO的实现步骤就是添加观察者，实现监听属性变化的方法，然后在适当的时机移除观察者；通过打印信息(“结束了 ”)我们可以知道KVO是同步的;在监听属性变化的方法中，change字典中必然会有kind这个键，其含义就是监听属性变化的类型(设置/插入/删除/替换)，一般情况下是NSKeyValueChangeSetting类型，其值为1。change字典中其他值的内容取决于添加观察方法时候option的选项，下面是对应设置option下change字典中包含的其他值

    options:NSKeyValueObservingOptionNew
    NSString *newName = [change objectForKey:NSKeyValueChangeNewKey];
    change:{
        kind = 1;
        new = zhangsan;
    }
    
    options:NSKeyValueObservingOptionOld
    NSString *oldName = [change objectForKey:NSKeyValueChangeOldKey];
    change:{
        kind = 1;
        old = lisi;
    }
    oldName:lisi
    
    当添加观察者方法执行完成后，监听的方法就会立即被执行；当属性发生变化的时候
    监听的方法就会再次被触发执行，但是在监听方法中是取不到属性变化前或者变化后的值的，因为change字典中只有一个键值kind=1
    options:NSKeyValueObservingOptionInitial
    change:{
        kind = 1;
    }

    会触发两次监听方法，值改变前调用一次observeValueForKeyPath，当属性值改变后会再调用一次,这里面依然无法获取到改变前后的属性值
    options:NSKeyValueObservingOptionPrior
    改变前调用一次，change中多了一个以NSKeyValueChangeNotificationIsPriorKey为key，Bool类型为value的键值对
    NSNumber *number = [change objectForKey:NSKeyValueChangeNotificationIsPriorKey];
    change:{
        kind = 1;
        notificationIsPrior = 1;
    }
    //改变后又触发了一次
    change:{
        kind = 1;
    }
#### 分析: 从中可以发现，如果单独设置option的选项，那么只有NSKeyValueObservingOptionNew和NSKeyValueObservingOptionOld能够从监听方法的change中分别获取到属性改变后的新值和改变前的旧值，而NSKeyValueObservingOptionInitial和NSKeyValueObservingOptionPrior选项是获取不到属性变化前后值的，只是提供给我们KVO触发的时机，前者添加注册后立即触发；后者属性变化前会调用一次变化后会再调用一次。option选项可以根据具体的业务场景需求通过 | 进行多选项的组合。

### 1.1 如何区别不同的通知
####  在添加观察者和监听方法中都有**content**字典，当有多个观察者的时候，用来进行分类处理
        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, strong) NSString *name;
        @end

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //NSArray *contentNSArray = @[@"100",@"200"];
            //NSDictionary *contextNSDictionary = @{@"teacher": @"zhanglaoshi", @"student": @"xiaoming"};
            下面三种方法都可以
            //方法一
            NSString *contextNSString = @"abcdefg";
            [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(contextNSString)];
            //方法二
            [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(contextNSString)];
            //方法三
            [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: @"abcdefg"];
            self.name = @"zhangsan";
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSLog(@"context is:%@",context);
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"name"];
        }

        @end

        打印结果:context is:abcdefg
                context is:(
                    100,
                    200
                )
                context is:{
                    student = xiaoming;
                    teacher = zhanglaoshi;
                }
#### 分析: 这个方法就是为了证明context参数可以传递字符串、数组、字典等等类型，如果我们需要在添加注册方法的时候传递给监听方法一些参数，就可以用这个参数传递一些参数值进去；同时也可以在监听方法中判断content内容来进行分类处理


### 1.2 键依赖
#### 如果一个属性的改变是依赖于其他属性的改变而变化的，那么就需要添加键依赖来实现其他属性变化的时候也能监听到监听属性的改变,如果不添加依赖键，监听的属性变化的时候，是不会触发监听方法的；
        //.h文件
        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, strong) NSString *parents;
        @end

        //.m文件
        @interface WGMainObjcVC()
        @property(nonatomic, strong) NSString *fatherName;
        @property(nonatomic, strong) NSString *motherName;
        @end

        @implementation WGMainObjcVC
        //父母=父亲+母亲
        -(NSString *)parents {
            return [NSString stringWithFormat:@"父亲:%@-母亲:%@",self.fatherName, self.motherName];
        }

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            self.motherName = @"小龙女";
            self.fatherName = @"令狐冲";
            [self addObserver:self forKeyPath:NSStringFromSelector(@selector(parents)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            self.fatherName = @"岳不群";
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            self.fatherName = @"杨过";
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSString *newParents = [change objectForKey:NSKeyValueChangeNewKey];
            NSString *oldParents  = [change objectForKey:NSKeyValueChangeOldKey];
            NSLog(@"\nnewParents:%@\noldParents:%@",newParents,oldParents);
        }

        //下面两种都可以设置依赖键，都是系统提供的类方法，任选其一
        //设置依赖键 方式一
        +(NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
            NSSet *set = [super keyPathsForValuesAffectingValueForKey:key];
            if ([key isEqualToString:@"parents"]) {
                set = [set setByAddingObjectsFromArray:@[@"fatherName",@"motherName"]];
            }
            return set;
        }
        //设置依赖键 方式二
        +(NSSet<NSString *> *)keyPathsForValuesAffectingParents {
            return [NSSet setWithArray:@[@"fatherName",@"motherName"]];
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"parents"];
        }

        @end
#### 分析:父母parents是有父亲father和母亲mother组成的，我们对parents添加监听，当然直接对parents进行赋值操作也会触发监听方法；那么如果father或者mother发生变化的时候，parent也得改变，进而通知监听方法，这就需要添加监听属性parent的依赖键来实现


### 2.KVO 监听集合属性（数组）方法一
#### 一般监听的都是控制器中的数组，如果数组是不可变的，并且数组的改变都是通过类似赋值的操作(self.arr = @[@"1",@"2"]类似这种)，那么KVO是可以监听到的，这种方式其实和一般属性赋值没有什么差别；如果真正的想监听数组的变化，即数组进行了增删改查操作，那么如何监听？其实KVO是不能直接监听控制器中的数组元素变化的，如果想监听，必须把数组定义在模型中(自定义一个类)，然后控制器持有这个模型对象，通过这个模型对象来实现监听

        //将监听的数组放在一个模型中
        @interface WGCustomModel : NSObject
        @property(nonatomic, strong) NSMutableArray *mutableArr;
        @end

        @interface WGMainObjcVC : UIViewController
        //控制器持有这个存放数组的模型属性
        @property(nonatomic, strong) WGCustomModel *model;
        @end

        @implementation WGCustomModel
        //懒加载
        - (NSMutableArray *)mutableArr {
            if (_mutableArr == nil) {
                _mutableArr = [[NSMutableArray alloc]init];
            }
            return _mutableArr;
        }
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //添加监听方法 
            self.model = [[WGCustomModel alloc]init];
            [self.model addObserver:self forKeyPath:@"mutableArr" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

            UIButton *addBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 120, 100, 30)];
            addBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:addBtn];
            [addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
            UIButton *deleteBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 160, 100, 30)];
            deleteBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:deleteBtn];
            [deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
            UIButton *replaceBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 30)];
            replaceBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:replaceBtn];
            [replaceBtn addTarget:self action:@selector(clickReplaceBtn) forControlEvents:UIControlEventTouchUpInside];
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [[self.model mutableArrayValueForKeyPath:@"mutableArr"] addObject:@"100"];
        }
        -(void)clickAddBtn {
            //首先通过mutableArrayValueForKeyPath方法获取model中的可变数组，然后再添加元素
            [[self.model mutableArrayValueForKeyPath:@"mutableArr"] addObject:@"200"];
        }
        -(void)clickDeleteBtn {
            [[self.model mutableArrayValueForKeyPath:@"mutableArr"] removeLastObject];
        }
        -(void)clickReplaceBtn {
            [[self.model mutableArrayValueForKeyPath:@"mutableArr"] replaceObjectAtIndex:0 withObject:@"888"];
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSArray *newArr = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *oldArr = [change objectForKey:NSKeyValueChangeOldKey];
            //监听的集合中改变元素的索引值
            NSIndexSet *indexSex  = [change objectForKey:NSKeyValueChangeIndexesKey];
           NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\ncontext:%@\nnewArr:%@\noldArr:%@\n",keyPath,object,change,context,newArr,oldArr);
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"mutableArr"];
        }
        @end
#### 当点击屏幕的时候，数组中会添加元素字符串100，并且kind=2(属性变化类型属于NSKeyValueChangeInsertion-插入)；即使option选项中设置了NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew，但是并没有打印旧值，只会打印新值；change字典中多了个键NSKeyValueChangeIndexesKey，这是一个索引，用于标识集合中改变元素的下标，打印结果如下
         keyPath:mutableArr
         object:<WGCustomModel: 0x600001c040b0>
         change:{
             indexes = "<_NSCachedIndexSet: 0x600001e405a0>[number of indexes: 1 (in 1 ranges), indexes: (0)]";
             kind = 2;
             new =     (
                 100
             );
         }
         context:(null)
         newArr:(
             100
         )
         oldArr:(null)
#### 当点击添加按钮时，向数组中添加元素，标识属性变化类型的kind键值为NSKeyValueChangeInsertion-插入；change字典中不包含旧值；打印结果如下
         keyPath:mutableArr
         object:<WGCustomModel: 0x600001c040b0>
         change:{
             indexes = "<_NSCachedIndexSet: 0x600001e40420>[number of indexes: 1 (in 1 ranges), indexes: (1)]";
             kind = 2;
             new =     (
                 200
             );
         }
         context:(null)
         newArr:(
             200
         )
         oldArr:(null)
#### 当点击删除按钮时，删除数组中最后一个元素，标识属性变化类型的kind键值为NSKeyValueChangeRemoval-删除，此时change字典中包含旧值不包含新值；打印结果如下
        keyPath:mutableArr
        object:<WGCustomModel: 0x6000032d8190>
        change:{
            indexes = "<_NSCachedIndexSet: 0x6000030a4ea0>[number of indexes: 1 (in 1 ranges), indexes: (1)]";
            kind = 3;
            old =     (
                200
            );
        }
        context:(null)
        newArr:(null)
        oldArr:(
            200
        )
#### 当点击替换按钮时，用字符串888替换数组中第一个元素，标识属性变化类型的kind键值为NSKeyValueChangeReplacement-替换，此时change字典中既包含旧值也包含新值；打印结果如下
        keyPath:mutableArr
        object:<WGCustomModel: 0x6000032d8190>
        change:{
            indexes = "<_NSCachedIndexSet: 0x6000030a4d00>[number of indexes: 1 (in 1 ranges), indexes: (0)]";
            kind = 4;
            new =     (
                888
            );
            old =     (
                100
            );
        }
        context:(null)
        newArr:(
            888
        )
        oldArr:(
            100
        )
#### 总结：KVO监听数组元素变化的时候，不能直接将数组作为观察者的属性，而是需要将数组封装在一个类中，然后观察者持有这个类，然后添加观察方法，监听的属性就是封装的类中声明的数组属性(这里的数组肯定是可变数组，否则无法进行增删改查)；对数组进行增删改查操作时，必须通过mutableArrayValueForKeyPath方法获取封装类中的数组属性，然后再进行addObject等操作，其实这种方式实现KVO监听集合(容器)类，是依赖于KVC的(mutableArrayValueForKeyPath这个方法就是KVC实现的)

### 3.KVO 监听集合属性（数组）方法二
#### 如果我们不将数组封装在一个数据类中，那么我们如何监听数组元素的变化那，其实我们可以利用KVO的底层实现原理来实现，KVO原理是生成一个监听对象的派生类，然后重写对象属性的setter方法，并且在setter方法中添加willChangeValueForKey和didChangeValueForKey方法，那么我们也可以在数组变化的时候添加这两个方法，来通知对象，监听的属性(数组)已经发生改变了

        @interface WGMainObjcVC()
        //直接在控制器中声明一个可变数组的属性
        @property(nonatomic, strong) NSMutableArray *mutableArr;
        @end

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            //属性初始化
            self.mutableArr = [NSMutableArray array];
            //添加观察
            [self addObserver:self forKeyPath:@"mutableArr" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

            UIButton *addBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 120, 100, 30)];
            addBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:addBtn];
            [addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
            UIButton *deleteBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 160, 100, 30)];
            deleteBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:deleteBtn];
            [deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
            UIButton *replaceBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 30)];
            replaceBtn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:replaceBtn];
            [replaceBtn addTarget:self action:@selector(clickReplaceBtn) forControlEvents:UIControlEventTouchUpInside];
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            ////在数组属性发生变化的方法添加willChangeValueForKey 和 didChangeValueForKey方法
            [self willChangeValueForKey:@"mutableArr"];
            [self.mutableArr addObject:@"100"];
            [self didChangeValueForKey:@"mutableArr"];
        }
        -(void)clickAddBtn {
            [self willChangeValueForKey:@"mutableArr"];
            [self.mutableArr addObject:@"200"];
            [self didChangeValueForKey:@"mutableArr"];
        }
        -(void)clickDeleteBtn {
            [self willChangeValueForKey:@"mutableArr"];
            [self.mutableArr removeLastObject];
            [self didChangeValueForKey:@"mutableArr"];
        }
        -(void)clickReplaceBtn {
            [self willChangeValueForKey:@"mutableArr"];
            [self.mutableArr replaceObjectAtIndex:0 withObject:@"888"];
            [self didChangeValueForKey:@"mutableArr"];
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSArray *newArr = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *oldArr = [change objectForKey:NSKeyValueChangeOldKey];
            NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\ncontext:%@\nnewArr:%@\noldArr:%@\n",keyPath,object,change,context,newArr,oldArr);
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"mutableArr"];
        }
        @end
#### 当点击屏幕的时候，向数组中添加元素字符串100，发现change字典中没有了标识元素改变的索引；标识属性改变类型的键值全部是1(kind=1)；change字典中包含新值和旧值；打印结果如下:
        keyPath:mutableArr
        object:<WGMainObjcVC: 0x7face5803880>
        change:{
            kind = 1;
            new =     (
                100
            );
            old =     (
                100
            );
        }
        context:(null)
        newArr:(
            100
        )
        oldArr:(
            100
        )
#### 当点击添加按钮的时候，向数组中添加元素字符串200。打印结果如下
        keyPath:mutableArr
        object:<WGMainObjcVC: 0x7face5803880>
        change:{
            kind = 1;
            new =     (
                100,
                200
            );
            old =     (
                100,
                200
            );
        }
        context:(null)
        newArr:(
            100,
            200
        )
        oldArr:(
            100,
            200
        )
#### 当点击删除按钮的时候，删除数组中最后一个元素。change字典中同样包含新值和旧值，这里的值是数组执行完操作后剩余的元素；打印结果如下:
        keyPath:mutableArr
        object:<WGMainObjcVC: 0x7face5803880>
        change:{
            kind = 1;
            new =     (
                100
            );
            old =     (
                100
            );
        }
        context:(null)
        newArr:(
            100
        )
        oldArr:(
            100
        )
#### 当点击替换按钮时，用字符串888替换数组第一个元素，打印结果如下:
        keyPath:mutableArr
        object:<WGMainObjcVC: 0x7face5803880>
        change:{
            kind = 1;
            new =     (
                888
            );
            old =     (
                888
            );
        }
        context:(null)
        newArr:(
            888
        )
        oldArr:(
            888
        )
#### 总结: 通过在数组改变的地方添加willChangeValueForKey和didChangeValueForKey方法实现KVO监听集合变化时，change字典中不再包含数组元素变化的类型(插入/删除/替换)，而是kind被统一标识为1(设置)类型，并且也不再包含集合元素改变的索引值(下标)；change字典中在数组元素改变的时候，始终可以获取到新值和旧值，并且新值和旧值的内容是一样的，因为他们都表示数组中现有元素的内容

### 4.KVO实现原理
#### 我们知道在给属性赋值的时候，调用的是属性的setter方法，KVO监听属性的过程其实也是调用了属性的setter方法，那么为什么KVO会触发通知方法，而没有添加观察者的时候，给属性赋值并不会触发通知？带着疑问我们进行下面的验证
        //.h文件
        @interface WGAnimal : NSObject
        @property(nonatomic, strong) NSString *animalName;
        @end

        @interface WGMainObjcVC : UIViewController
        @end

        //.m文件
        @implementation WGAnimal
        @end

        @implementation WGMainObjcVC

        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            WGAnimal *animal1 = [[WGAnimal alloc]init];
            WGAnimal *animal2 = [[WGAnimal alloc]init];
            NSLog(@"\n添加观察者前\nanimal1对象:%@\nanimal1类对象:%@\nanimal1的类名称:%s   \nanimal2对象:%@\nanimal2类对象:%@\nanimal2的类名称:%s",
                  animal1,[animal1 class],object_getClassName(animal1),
                  animal2,[animal2 class],object_getClassName(animal2));
            //我们给animal1对象添加观察者
            [animal1 addObserver:self forKeyPath:@"animalName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            NSLog(@"\n添加观察者后\nanimal1对象:%@\nanimal1类对象:%@\nanimal1的类名称:%s\n animal2对象:%@\nanimal2类对象:%@\nanimal2的类名称:%s",
                  animal1,[animal1 class],object_getClassName(animal1),
                  animal2,[animal2 class],object_getClassName(animal2));
            animal1.animalName = @"dog";
            animal2.animalName = @"cat";
            NSLog(@"执行完成了");
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSArray *newValue = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *oldValue = [change objectForKey:NSKeyValueChangeOldKey];
            NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\n context:%@\nnewValue:%@\noldValue:%@\n",
              keyPath,object,change,context,newValue,oldValue);
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"animalName"];
        }
        @end

        打印结果:
        添加观察者前
                animal1对象:<WGAnimal: 0x600003e182b0>
                animal1类对象:WGAnimal
                animal1的类名称:WGAnimal   
                animal2对象:<WGAnimal: 0x600003e182c0>
                animal2类对象:WGAnimal
                animal2的类名称:WGAnimal
        添加观察者后
                animal1对象:<WGAnimal: 0x600003e182b0>
                animal1类对象:WGAnimal
                animal1的类名称:NSKVONotifying_WGAnimal
                animal2对象:<WGAnimal: 0x600003e182c0>
                animal2类对象:WGAnimal
                animal2的类名称:WGAnimal
        keyPath:animalName
        object:<WGAnimal: 0x600003e182b0>
        change:{
            kind = 1;
            new = dog;
            old = "<null>";
        }
        context:(null)
        newValue:dog
        oldValue:<null>
        执行完成了
#### 分析：我们给animal1对象的属性animalName添加KVO监听，animal2对象没有添加KVO监听，在添加KVO监听方法前，animal1对象的isa指针指向的是它的类对象WGAnimal；在添加KVO监听方法后，animal1对象的isa指针指向了系统生成的派生类NSKVONotifying_WGAnimal,其实它是WGAnimal类的子类，所以我们知道了添加KVO方法后，系统会为监听属性的对象类自动生成一个它的子类(派生类)，这个过程是通过对象的isa指针，然后将isa指针指向这个派生类。为什么系统会为我们生成一个派生类，它的作用又是什么？

#### 首先我们来了解一下IMP是什么？官网文档(A pointer to the start of a method implementation)它是指向方法实现开始的指针，即指向方法实现的指针，那么同一个方法它的IMP地址是不变的。我们来获取添加KVO前后对监听属性的setter方法的IMP指针

        WGAnimal *animal1 = [[WGAnimal alloc]init];
        WGAnimal *animal2 = [[WGAnimal alloc]init];
        //我们获取属性animalName的setter方法的方法实现开始指针IMP
        IMP animalIMP1 = [animal1 methodForSelector:@selector(setAnimalName:)];
        IMP animalIMP2 = [animal2 methodForSelector:@selector(setAnimalName:)];
        NSLog(@"添加KVO前");
        //我们给animal1对象添加观察者
        [animal1 addObserver:self forKeyPath:@"animalName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        animalIMP1 = [animal1 methodForSelector:@selector(setAnimalName:)];
        animalIMP2 = [animal2 methodForSelector:@selector(setAnimalName:)];
        NSLog(@"添加KVO后");
        animal1.animalName = @"dog";
        animal2.animalName = @"cat";
        NSLog(@"执行完成了");

        通过断点打印结果：添加KVO前
        (lldb) print animalIMP1
        (IMP) $0 = 0x000000010878c950 (WGFcodeNotes`-[WGAnimal setAnimalName:] at WGMainObjcVC.h:15)
        (lldb) print animalIMP2
        (IMP) $1 = 0x000000010878c950 (WGFcodeNotes`-[WGAnimal setAnimalName:] at WGMainObjcVC.h:15)
         添加KVO后
        (lldb) print animalIMP1
        (IMP) $2 = 0x00007fff25721c7a (Foundation`_NSSetObjectValueAndNotify)
        (lldb) print animalIMP2
        (IMP) $3 = 0x000000010878c950 (WGFcodeNotes`-[WGAnimal setAnimalName:] at WGMainObjcVC.h:15)
        (lldb) 
#### 分析：我们会发现animal1对象添加KVO后，它并没有去调用监听属性的setter方法，而是调用了Foundation框架下的_NSSetObjectValueAndNotify函数，由此可知添加KVO后，系统修改了监听属性的方法实现；而没有添加KVO的animal2对象，属性改变仍然调用的是属性的setter方法；我们结合系统生成的派生类NSKVONotifying_WGAnimal和_NSSetObjectValueAndNotify函数这两点来研究下派生类里面的东西

        WGAnimal *animal1 = [[WGAnimal alloc]init];
        WGAnimal *animal2 = [[WGAnimal alloc]init];

        //我们给animal1对象添加观察者
        [animal1 addObserver:self forKeyPath:@"animalName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        //这里需要引入头文件#import <objc/message.h>
        NSArray *methodArr = [self getAnimalMethodList: animal1];
        NSArray *propertyArr = [self getAnimalProperty:animal1];
        NSLog(@"派生类中方法列表:%@\n派生类中的属性列表:%@",methodArr,propertyArr);
        animal1.animalName = @"dog";
        animal2.animalName = @"cat";
        
        //获取派生类中的方法列表
        -(NSArray *)getAnimalMethodList:(WGAnimal *)animal {
            NSMutableArray *arr = [NSMutableArray array];
            //获取派生类中方法列表中的所有方法
            unsigned int count = 0;
            Method *methods = class_copyMethodList(object_getClass(animal), &count);
            for (int i = 0; i < count; i++) {
                Method method = methods[i];
                SEL sel = method_getName(method);
                NSString *methodName = NSStringFromSelector(sel);
                [arr addObject:methodName];
            }
            return arr;
        }
        //获取派生类中的属性列表
        -(NSArray *)getAnimalProperty:(WGAnimal *)animal {
            NSMutableArray *arr = [NSMutableArray array];
            //获取派生类中方法列表中的所有方法
            unsigned int count = 0;
            objc_property_t *propertyList = class_copyPropertyList(object_getClass(animal), &count);
            for (int i = 0; i < count; i++) {
                //c语言的属性名称
                const char *propertyNameC = property_getName(propertyList[i]);
                NSString *propertyName = [NSString stringWithUTF8String:propertyNameC];
                [arr addObject:propertyName];
            }
            return arr;
        }

        打印结果:派生类中方法列表:(
                "setAnimalName:",
                class,
                dealloc,
                "_isKVOA"
                )
                派生类中的属性列表:(
                )
#### 分析:派生类NSKVONotifying_WGAnimal中重写了属性animalName的setter方法，并且也重写了class、dealloc和_isKVOA方法，由此我们知道了animal1对象添加KVO后，runtime动态生成了一个派生类NSKVONotifying_WGAnimal，并在派生类中重写监听属性的setter方法，在setter方法中一定做了什么才会触发observeValueForKeyPath的监听方法；同时我们也发现派生类中没有其他属性的生成，只是重写了方法； 

#### _NSSetObjectValueAndNotify函数内部实现是什么？我们知道对象添加KVO后，runtime动态的生成了对象的派生类，并且重写了监听属性的setter方法，如果只是重写了setter方法，那么如何通知到监听方法(observeValueForKeyPath)属性发生了变化？这就是_NSSetObjectValueAndNotify函数的作用了
* 首先在重写的监听属性的setter方法中，调用了_NSSetObjectValueAndNotify函数
* _NSSetObjectValueAndNotify函数首先调用了willChangeValueForKey
*  然后调用派生类(NSKVONotifying_WGAnimal)的父类(WGAnimal)的setter方法给监听的属性赋值
* 再然后调用didChangeValueForKey方法
* 最后调用observe的observeValueForKeyPath方法去告诉监听者属性发生了变化

#### 接下来我们验证上面的结论,在WGAnimal类中重写监听属性animalName的setter方法，并且重写willChangeValueForKey和didChangeValueForKey方法,在属性发生变化后，通过断点来验证执行顺序

        @implementation WGAnimal
        //重写监听属性的setter方法
        -(void)setAnimalName:(NSString *)animalName {
            NSLog(@"开始调用setter方法");
            _animalName = animalName;
            NSLog(@"结束调用setter方法");
        }

        -(void)willChangeValueForKey:(NSString *)key {
            NSLog(@"开始执行willChangeValueForKey");
            [super willChangeValueForKey:key];
            NSLog(@"结束执行willChangeValueForKey");
        }

        -(void)didChangeValueForKey:(NSString *)key {
            NSLog(@"开始执行didChangeValueForKey");
            [super didChangeValueForKey:key];
            NSLog(@"结束执行didChangeValueForKey");
        }
        @end

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSLog(@"监听到属性变化了");
        }

        打印结果: 开始执行willChangeValueForKey
                结束执行willChangeValueForKey
                开始调用setter方法
                结束调用setter方法
                开始执行didChangeValueForKey
                监听到属性变化了
                结束执行didChangeValueForKey
#### 分析: 通过打印结果印证了我们的结论

#### 总结KVO实现的底层原理:当对一个对象的属性添加监听的时候，runtime会动态的为这个对象生成一个它的派生类(这个对象类的子类)，并且系统将对象的isa指针指向了这个派生类，这个派生类会重写【1.监听属性的setter方法；2.class方法；3.dealloc方法；4._isKVOA方法】这四个方法
* setter方法：内部调用的是Foundation框架下的C函数(这里调用的是_NSSetObjectValueAndNotify方法，其实还有好多函数形如_NSSetXXXValueAndNotify，XXX需要根据属性的类型来决定)，这个函数内部实现是:
1. 首先调用willChangeValueForKey:
2. 调用父类(派生类的父类就是对象的类)的setter方法，进行赋值
3. 调用didChangeValueForKey:方法，而这个方法内部又会去调用监听方法observeValueForKeyPath，从而实现属性的监听
* class方法：如果不重写这个方法，当调用class方法的时候返回的就是runtime动态生成的派生类(NSKVONotifying_WGAnimal),重写这个方法后，返回的就是原本的类(WGAnimal),重写的目的就是隐藏KVO的具体实现细节，或者说是为了避免派生类的信息被暴露
* dealloc方法：做一些KVO释放内存的工作
* _isKVOA方法：这是个私有方法，暂不讨论研究


### 5. 禁用KVO
#### 如果我们不想一些类实现KVO，可以在这些类中重写automaticallyNotifiesObserversForKey方法并返回NO来实现
        @interface WGAnimal : NSObject
        @property(nonatomic, strong) NSString *animalName;
        @end

        @implementation WGAnimal

        +(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
            return NO;
        }
        @end
#### 如果想实现指定的属性(animalName)不能被监听，而其他属性可以监听
        @interface WGAnimal : NSObject
        @property(nonatomic, strong) NSString *animalName;
        @property(nonatomic, assign) NSInteger *age;
        @end

        @implementation WGAnimal

        +(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
            if ([key isEqualToString:@"animalName"]) {
                return NO;
            }
            return [super automaticallyNotifiesObserversForKey:key];
        }
        @end

### 6. 手动KVO
#### 有时候在项目中我们需要手动触发KVO机制，这样我们就可以灵活的加上自己的判断。比如我们监听动物年龄的变化，实际业务中我们可能只需要监听年龄在10-20岁的动物，如果是其他年龄区间，就不要再触发监听方法observeValueForKeyPath了。手动监听KVO的步骤如下:
* 重写监听属性的setter方法
* 在setter方法中，我们需要在赋值操作前手动调用willChangeValueForKey方法，在赋值操作后再手动调用didChangeValueForKey方法
* 在类中重写automaticallyNotifiesObserversForKey方法，来限制该属性的监听，必须限制，否则监听方法会被触发两次;或者重写automaticallyNotifiesObserversOfAge方法，这个方法是创建属性的时候，系统为我们自动生成的，直接在这个方法中返回NO即可
        //在.h文件中
        @interface WGAnimal : NSObject
        @property(nonatomic, assign) int age;
        @end

        @interface WGMainObjcVC : UIViewController
        @property(nonatomic, strong) WGAnimal *animal;
        @end

        //在.m文件中
        @implementation WGAnimal
        -(void)setAge:(int)age {
            //年龄在【10-20】之间才触发监听方法
            if (age >= 10 && age <= 20) {
                [self willChangeValueForKey:@"age"];
                _age = age;
                [self didChangeValueForKey:@"age"];
            }else {
                _age = age;
            }
        }
        //下面方法任选其一，告诉KVO当属性age变化的时候，不需要KVO自动监听了，而是我们手动开启监听属性的变化
        +(BOOL)automaticallyNotifiesObserversOfAge {
            return NO;
        }
        +(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
            if ([key isEqualToString:@"age"]) {
                return NO;
            }
            return [super automaticallyNotifiesObserversForKey: key];
        }

        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor redColor];
            self.animal = [[WGAnimal alloc]init];
            [self.animal addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 120, 100, 30)];
            btn.backgroundColor = [UIColor yellowColor];
            [self.view addSubview:btn];
            [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
        }

        -(void)clickBtn{
            NSLog(@"点击了按钮");
            self.animal.age = 14;
        }

        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            NSLog(@"点击了屏幕");
            self.animal.age = 21;
        }

        -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
            NSLog(@"监听到属性变化了");
            NSArray *newValue = [change objectForKey:NSKeyValueChangeNewKey];
            NSArray *oldValue = [change objectForKey:NSKeyValueChangeOldKey];
            NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\n context:%@\nnewValue:%@\noldValue:%@\n",
              keyPath,object,change,context,newValue,oldValue);
        }

        -(void)viewWillDisappear:(BOOL)animated {
            [super viewWillDisappear:animated];
            [self removeObserver:self forKeyPath:@"age"];
        }
        @end

        打印结果: 点击了屏幕
        点击了按钮
        监听到属性变化了
        keyPath:age
        object:<WGAnimal: 0x600002684360>
        change:{
            kind = 1;
            new = 14;
            old = 21;
        }
         context:(null)
        newValue:14
        oldValue:21

### 7.KVO的优缺点
**优点**
1. 能够提供一种简单的方法实现两个对象间的同步
2. 能够对非我们创建的对象的属性状态变化作出响应，而不需要改变这个对象的内部实现；
3. 能够提供属性变化的前后值
4. 可以观察嵌套对象的属性

**缺点**
1. 观察的对象属性，必须以string来定义，容易出现拼写错误，而这些在编译期并不会被编译器检查
2. KVO必须实现监听方法来处理属性的变化，不能用block来回调处理，每次添加观察者之后，都需要实现监听方法observeValueForKeyPath
3. 如果监听的属性比较多，我们需要在监听方法中写好多判断语句来确定是哪个属性发生了改变
4. 当对同一个keyPath进行两次removeObserver时，程序会crash

### 8. 自定义KVO
#### 为什么要自定义KVO，因为我们知道KVO的实现需要注册观察者，然后实现监听方法，我们能不能注册和监听放在一个方法中，即将监听的事件放在block的回调中，然后将block放在注册方法中。接下来我们来实现这个需求
#### TODO
