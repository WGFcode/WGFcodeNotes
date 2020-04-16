## KVO键值观察
#### KVO(Key-Value Observing)键值观察,就是对对象的属性添加观察，当属性值变化的时候，通过观察者对象实现的KVO接口方法来自动的通知观察者,KVO是基于KVC实现的;在swift中KVO的接口都定义在NSObject的扩展中，在OC中所有的KVO接口都定义在@interface NSObject(NSKeyValueObserving)类别中，也就是所有的NSObject对象都可以实现KVO

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
* NSKeyValueObservingOptionPrior：值改变前是否也要通知（决定了是否在改变前改变后触发通知两次）
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



