## KVC 
### (Key-value coding)键值编码，在iOS中不需要调用明确的方法而直接通过字符串Key就可以直接访问对象的属性或者给对象的属性赋值，在运行时动态的访问和赋值，而不需要在编译期确定；所有继承自NSObjct的类型都可以使用KVC;一些纯swift类和结构体不能使用KVC，因为没有继承自NSObjct；
### OC中有个显式的NSKeyValueCoding类别名，KVC所有的方法都在这个类别中(@interface NSObject(NSKeyValueCoding))；swift中KVC所有的方法都是在NSObjct的扩展中(extension NSObject),下面是KVC中常用的方法

## Swift
    func value(forKey key: String) -> Any?                   通过字符串Key获取值
    func setValue(_ value: Any?, forKey key: String)         通过字符串Key设置值
    func value(forKeyPath keyPath: String) -> Any?           通过字符串keyPath获取值
    func setValue(_ value: Any?, forKeyPath keyPath: String) 通过字符串keyPath设置值
    func setNilValueForKey(_ key: String)                    如何设置值为nil会调用这个方法 
    获取值:key不存在且KVC无法搜索到任何和Key有关的字段或者属性，会调用这个方法，默认抛出异常
    func value(forUndefinedKey key: String) -> Any?
    设置值:key不存在且KVC无法搜索到任何和Key有关的字段或者属性，会调用这个方法，默认抛出异常
    func setValue(_ value: Any?, forUndefinedKey key: String)
    直接访问实例变量，默认是true:表示如果没有找到setKey方法时，会按照_key，_iskey，key，iskey的顺序搜 索成员,如何设置为false,则表示没有找到setKey方法时，就不会继续查找了
    class var accessInstanceVariablesDirectly: Bool { get }
    属性值的验证，用来检查设置的值是否正确,如何不正确会抛出异常
    func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey inKey: String) throws
    func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKeyPath inKeyPath: String) throws
    属性可以是NSMutableArray/NSMutableOrderedSet/NSMutableSet
    可以调用下列方法通过Key来获取对应的类型
    func mutableArrayValue(forKey key: String) -> NSMutableArray
    func mutableArrayValue(forKeyPath keyPath: String) -> NSMutableArray
    func mutableOrderedSetValue(forKey key: String) -> NSMutableOrderedSet
    func mutableOrderedSetValue(forKeyPath keyPath: String) -> NSMutableOrderedSet
    func mutableSetValue(forKey key: String) -> NSMutableSet
    func mutableSetValue(forKeyPath keyPath: String) -> NSMutableSet
    通过数组Key,返回这些Key对象的Value,通常用于Model转字典
    func dictionaryWithValues(forKeys keys: [String]) -> [String : Any]
    通过给定的字典为对象的属性设置值
    func setValuesForKeys(_ keyedValues: [String : Any])

#### KVC是OC的特性且是基于运行时的，而swift并没有运行时特性，如果在swift中使用KVC，必须同时满足下列条件,否则不能使用KVC或者使用过程中会发生crash
1. 必须继承自NSObject
2. 对需要访问或赋值的属性前面添加@objc标识；或者在这个自定义的类前面添加@objcMembers标识
3. @objc修饰符:可以修饰类/协议/属性/方法等,目的就是暴露接口给OC的运行时，使修饰的“东西”可以在运行时被操作;@objcMembers一般用来修饰类/子类/扩展/子类扩展，使修饰的“东西”可以在运行时被操作

### 1. KVC 通过Key设值和获取值
        @objcMembers
        public class WGAnimalModel : NSObject {
            private var name = ""  //KVC无法访问私有属性
            //var tuple = ("","")  无法对元组赋值
            var age = 0
            var isSex = false
            var dic = [String: Any]()
            var arr = [String]()
        }
        
        let entity = WGAnimalModel.init()   
        //赋值
        entity.setValue(18, forKey: "age")
        entity.setValue(true, forKey: "isSex")
        entity.setValue(["height": 130], forKey: "dic")
        entity.setValue(["color","weight","room"], forKey: "arr")
        //获取值
        let age = entity.value(forKey: "age")!
        let isSex = entity.value(forKey: "isSex")!
        let dic = entity.value(forKey: "dic")!
        let arr = entity.value(forKey: "arr")!
        NSLog("age:\(age)\nisSex:\(isSex)\ndic:\(dic)\narr:\(arr)")

        打印结果: age:18
        isSex:1
        dic:{
            height = 130;
        }
        arr:(
            color,
            weight,
            room
        )
#### 分析，在swift中可以对String/Bool/Int/Array/Dictionary类型的属性进行访问和赋值，但无法对元组类型的属性进行赋值操作;KVC无法对私有的属性进行访问或赋值，会发生crash；

### 2 KVC处理异常
#### 上面我们都是正常的访问和赋值，如果访问的Key不存/设置的值为nil/获取一个不存在的Key对应的值时，程序会发生crash,为了避免crash，我们采用下面方法来处理异常

        @objcMembers
        public class WGAnimalModel : NSObject {
            private var name = ""  //KVC无法访问私有属性
            //var tuple = ("","")  无法对元组赋值
            var age = 0
            var isSex = false
            var dic = [String: Any]()
            var arr = [String]()
            
            //如果将Key对应的值设置为nil，会导致程序crash,重写这个方法可避免crash
            public override func setNilValueForKey(_ key: String) {
                NSLog("\(key)的值被设置成了nil")
            }
            //如果对不存在的Key赋值，会导致程序crash,重写该方法可避免crash
            public override func setValue(_ value: Any?, forUndefinedKey key: String) {
                NSLog("\(key)不存在")
            }
            //如果去获取一个不存在的Key对应的值，会导致程序crash,重写该方法可避免crash
            public override func value(forUndefinedKey key: String) -> Any? {
                NSLog("\(key)不存在，所以无法获取值")
                return nil
            }
        }

        let entity = WGAnimalModel.init()
        entity.setValue(nil, forKey: "age")
        entity.setValue(18, forKey: "ages")
        entity.value(forKey: "ages")
        
        打印结果: age的值被设置成了nil
                ages不存在
                ages不存在，所以无法获取值

### 3.KVC 通过KeyPath(键路径)设值和获取值
#### 在通过Key设值和获取值的demo中，我们可以发现，每次设值和获取值都需要手动写Key,很容易在写 代码的时候出现错误，在swift4.0我们可以使用#keyPath来避免因为拼写错误而导致的错误，继续重用上面的类
        let entity = WGAnimalModel.init()
        entity.setValue(18, forKeyPath: #keyPath(WGAnimalModel.age))
        let age = entity.value(forKeyPath: #keyPath(WGAnimalModel.age))!
        NSLog("age:\(age)")
        
        打印结果: age:18
#### 分析:这种写法可以有效避免因拼写错误而引发问题，但这种方式下通过value(forKeyPath: #keyPath)来获取值的时候，返回的都是Any?类型，我们还需要去转成对应的类型很不方便，在swift4.0之后苹果有了很大改动，可以直接使用\作为开头来创建KeyPath

#### swift4.0之后 使用\作为开头来创建KeyPath的优点
* 定义类型的时候不需要添加@objc或者@objcMembers标识
* 不需要调用明确的KVC方法就可以实现设值和获取值
* 类型安全和类型推断(entity.setValue(18, forKeyPath: #keyPath(WGAnimalModel.age))返回的是Any？，而entity[keyPath: \WGAnimalModel.age]返回的是Int类型)
* 类型可以定义为 class、struct;结构体也可以支持KVC了

        public class WGAnimalModel {
            private var name = ""  //KVC无法访问私有属性
            var age = 0
            var isSex = false
            var dic = [String: Any]()
            var arr = [String]()
        }

        let entity = WGAnimalModel.init()
        //通过KVC赋值
        entity[keyPath: \WGAnimalModel.age] = 18
        //通过KVC获取值
        let age = entity[keyPath: \WGAnimalModel.age]
        NSLog("age:\(age)")

        打印结果: age:18
        
        将类换成结构体
        public struct WGAnimalModel {
            private var name = ""  //KVC无法访问私有属性
            var age = 0
            var isSex = false
            var dic = [String: Any]()
            var arr = [String]()
        }
        //这里需要将之前的let方法换成var
        var entity = WGAnimalModel.init()
        //通过KVC赋值
        entity[keyPath: \WGAnimalModel.age] = 18
        //通过KVC获取值
        let age = entity[keyPath: \WGAnimalModel.age]
        NSLog("age:\(age)")
        
        打印结果: age:18
    #### ⚠️重点，在swift中也可以使用KVC而不需要其他的额外设置,swift4.0之后使用KVC不会去明确的调用KVC中的方法，而是通过使用\开头来创建keyPath，然后通过keyPath来对属性进行访问或者赋值，而原来的实现方法也仍然可用，只是这种方式更加的快捷和方便，并且这种方式也不需要去处理KVC异常，因为不会出现异常,同时结构体也开始支持KVC了

#### KeyPath键路径在swift中继承关系如下,并通过demo可以更好的理解各个父类及子类的含义
    文档: A key path that supports reading from and writing to the resulting value with reference semantics
    public class ReferenceWritableKeyPath<Root, Value> : WritableKeyPath<Root, Value>(支持语义)
    
    文档: A key path that supports reading from and writing to the resulting value(支持读写)
    public class WritableKeyPath<Root, Value> : KeyPath<Root, Value>
    
    文档: A key path from a specific root type to a specific resulting value type(仅可读)
    public class KeyPath<Root, Value> : PartialKeyPath<Root>
    
    文档: A partially type-erased key path, from a concrete root type to any resulting value type.
    public class PartialKeyPath<Root> : AnyKeyPath
    
    public class AnyKeyPath : Hashable, _AppendKeyPath
    public protocol _AppendKeyPath
    
    public class WGAnimalModel {
        var age = 0
        var isSex = false
        var dic = [String: Any]()
        var arr = [String]()
        var name: String?=nil
        //只读计算属性
        var cardId: String {
            return "sdfdsf"
        }
        var info: WGInfoModel?
    }
    public class WGInfoModel {
        var weight = 0
        var height = 0
    }
    
    let agePath: WritableKeyPath<WGAnimalModel,Int> = \WGAnimalModel.age
    let sexPath: WritableKeyPath<WGAnimalModel,Bool> = \WGAnimalModel.isSex
    let arrPath: WritableKeyPath<WGAnimalModel,[String]> = \WGAnimalModel.arr
    let dicPath: WritableKeyPath<WGAnimalModel,[String: Any]> = \WGAnimalModel.dic
    let namePath: WritableKeyPath<WGAnimalModel,String?> = \WGAnimalModel.name
    let cardIdPath: KeyPath<WGAnimalModel,String> = \WGAnimalModel.cardId
    let infoPath: ReferenceWritableKeyPath<WGAnimalModel, WGInfoModel?> = \WGAnimalModel.info
    let infoWeight: KeyPath<WGAnimalModel, Int?> = \WGAnimalModel.info?.weight
