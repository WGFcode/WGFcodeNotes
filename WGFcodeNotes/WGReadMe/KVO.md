## KVO键值观察
#### KVO(Key-Value Observing)键值观察,就是对对象的属性添加观察，当属性值变化的时候，通过观察者对象实现的KVO接口方法来自动的通知观察者，在swift中KVO的接口都定义在NSObject的扩展中，在OC中所有的KVO接口都定义在@interface NSObject(NSKeyValueObserving)类别中，也就是所有的NSObject对象都可以实现KVO

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
* observer: 观察者，也就是KVO通知的订阅者。订阅着必须实现observeValueForKeyPath:方法
* keyPath: 观察者的属性，可以理解为被观察者
* options: KVO的配置参数
* context: 上下文，这个会传递到订阅着(观察者)的函数中，用来区分消息，所以应当是不同的
* change: 字典类型，保存了监听属性的变更信息，信息内容受options:NSKeyValueObservingOptions枚举的影响
#### NSKeyValueObservingOptions枚举包含下列4个选项
* NSKeyValueObservingOptionNew：change字典中包含属性改变后的值，即包含新值
* NSKeyValueObservingOptionOld： change字典中包含属性改变前的值，即包含旧值
* NSKeyValueObservingOptionInitial：注册后立即触发KVO通知，即触发observeValueForKeyPath方法
* NSKeyValueObservingOptionPrior：值改变前是否也要通知（决定了是否在改变前改变后触发通知两次）


