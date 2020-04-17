## KVO键值观察
#### KVO(Key-Value Observing)键值观察,就是对对象的属性添加观察，当属性值变化的时候，通过观察者对象实现的KVO接口方法来自动的通知观察者,KVO是基于KVC实现的;在swift中KVO的接口都定义在NSObject的扩展中，在OC中所有的KVO接口都定义在@interface NSObject(NSKeyValueObserving)类别中，也就是所有的NSObject对象都可以实现KVO

### KVO使用过程注意点
* 添加了一个观察者，就必须在合适的时机移除观察者，否则会造成内存泄露；
* 如果在添加观察者方法中，拼写错了属性，则KVO是不会触发的
* KVO只能监听属性，不能监听成员变量
* 如果观察者已经被移除了，那么当属性发生变化的时候，就不在触发监听方法了；
* 如果观察者已经被移除了，当再次调用移除观察者的方法removeObserver的时候，程序会crash(errorInfo: because it is not registered as an observer.)，所以使用过程中一定要注意了

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
* context: 可选的参数,可以传值也可以传nil，这个参数会被传递到订阅着(观察者)的响应方法中，用来区分不同的通知;如果你想用来区分通知,推荐使用[声明一个静态变量,其保持它自己的地址,这个变量没什么意义,但能起到区分通知的作用]
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
    WGMainObjcVC.m文件中
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
    }

    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        self.name = @"zhangsan";
    }

    -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
        NSString *newName = [change objectForKey:NSKeyValueChangeNewKey];
        NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\ncontext:%@\nnewName:%@\n",keyPath,object,change,context,newName);
    }
    
    //适当的时机移除观察者
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
#### 分析: KVO的实现步骤就是添加观察者，实现监听属性变化的方法，然后在适当的时机移除观察者；在监听属性变化的方法中，change字典中必然会有kind这个键，其含义就是监听属性变化的类型(设置/插入/删除/替换)，一般情况下是NSKeyValueChangeSetting类型，其值为1。change字典中其他值的内容取决于添加观察方法时候option的选项，下面是对应设置option下change字典中包含的其他值

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
#### 分析: 从中可以发现，如果单独设置option的选项，那么只有NSKeyValueObservingOptionNew和NSKeyValueObservingOptionOld能够从监听方法的change中分别获取到属性改变后的新值和改变前的旧值，而NSKeyValueObservingOptionInitial和NSKeyValueObservingOptionPrior选项只是获取不到属性变化前后的值的，只是提供给我们KVO触发的时机，前者添加注册后立即触发；后者属性变化前会调用一次变化后会再调用一次。option选项可以根据具体的业务场景需求通过 | 进行多选项的组合。

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
#### 总结：KVO监听数组元素变化的时候，不能直接将数组作为观察者的属性，而是需要将数组封装在一个类中，然后观察者持有这个类，然后添加观察方法，监听的属性就是封装的类中声明的数组属性(这里的数组肯定是可变数组，否则无法进行增删改查)；对数组进行增删改查操作时，必须通过mutableArrayValueForKeyPath方法获取封装类中的数组属性，然后再进行addObject等操作

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
