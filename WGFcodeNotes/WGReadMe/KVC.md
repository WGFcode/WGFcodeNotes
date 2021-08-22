## KVC 
### (Key-value coding)键值编码，在iOS中不需要调用明确的setter/getter方法而直接通过字符串Key就可以直接访问对象的属性或者给对象的属性赋值，在运行时动态的访问和赋值，而不需要在编译期确定；所有继承自NSObjct的类型都可以使用KVC;一些纯swift类和结构体不能使用KVC，因为没有继承自NSObjct；
### OC中有个显式的NSKeyValueCoding类别名，KVC所有的方法都在这个类别中(@interface NSObject(NSKeyValueCoding))；swift中KVC所有的方法都是在NSObjct的扩展中(extension NSObject),下面是KVC中常用的方法

### KVC使用场景
* 基于运行时动态的取值和设值
* 访问和修改私有变量(验证了在swift中是无法访问私有变量的，OC中是可以的)
* 字典和数据层Model之间的转换
* 修改系统控件的内部属性(UIDatePicker中字体颜色设置)或系统类调用(NSUserDefaults)

        [datePicker setValue:[UIColor blackColor] forKey:@"textColor"];
        [[NSUserDefaults standardUserDefaults] setValue:currentVersion forKey:LastVersionKey];
* 实现高阶消息传递

### KVC总结
* KVC是基于动态运行时的，属于OC的特性，所有继承自NSObject的对象都可以实现KVC
* KVC可以让对象通过字符串key或者通过keypath动态的设值、取值、处理异常等基本操作
* KVC在调用setValue:forKey:时，如果value是值类型或者结构体类型，需要先将value转为NSNumber(值类型)或者NSValue(结构体类型)对象类型进行设值，如果需要使用的时候，再将NSNumber或者NSValue对象类型转为需要的值类型或者结构体类型
* 在swift3.0版本中想使用KVC，除了该类必须继承自NSObject外，该类还必须添加@objcMembers标识或者在需要使用KVC的变量前面添加@objc的修饰符，目的就是为了暴露接口给OC的运行时，利用运行时特性能动态的设值、取值等；在swift4.0之后，苹果剔除了这些限制条件，可以直接使用KVC，但是不再明确调用KVC的方法了，而是通过\开头创建的keypath来实现KVC，并且值类型的结构体也开始支持KVC了，KVC在swift中不能访问private的变量
* swift中使用KVC比在OC中更加的高效和安全，swift中使用Keypath的方式进行KVC操作时候不需要担心因为拼写Key错误而导致的异常问题，而拼写错误在OC中出现频率比较高

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
    直接访问实例变量，默认是true:表示如果没有找到setKey方法时，会按照_key，_iskey，key，iskey的顺序搜  
    索成员,如何设置为false,则表示没有找到setKey方法时，就不会继续查找了
    class var accessInstanceVariablesDirectly: Bool { get }
    属性值的验证，用来检查设置的值是否正确,如何不正确会抛出异常
    func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>,   
    forKey inKey: String) throws
    func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>,   
    forKeyPath inKeyPath: String) throws
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

### **swift3.0之前**,由于KVC是OC的特性且是基于运行时的，而swift并没有运行时特性，如果在swift中使用KVC，必须同时满足下列条件,否则不能使用KVC或者使用过程中会发生crash
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
#### 分析:这种写法可以有效避免因拼写错误而引发问题，但这种方式下通过value(forKeyPath: #keyPath)来获取值的时候，返回的都是Any?类型，我们还需要去转成对应的类型很不方便！

### **swift4.0**之后苹果有了很大改动，类/结构体都可以使用KVC了，直接使用\作为开头来创建KeyPath，进而实现KVC的访问和赋值
#### 使用\作为开头来创建KeyPath的优点
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
    文档: A key path that supports reading from and writing to the resulting value   
    with reference semantics
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

## Objective-C
    @property (class, readonly) BOOL accessInstanceVariablesDirectly;
    设置值
    - (void)setValue:(nullable id)value forKey:(NSString *)key;
    - (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;
    通过Key获取值
    - (nullable id)valueForKey:(NSString *)key;
    - (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
    - (NSMutableSet *)mutableSetValueForKey:(NSString *)key;
    - (NSMutableOrderedSet *)mutableOrderedSetValueForKey:(NSString *)key;
    通过keyPath获取值
    - (nullable id)valueForKeyPath:(NSString *)keyPath;
    - (NSMutableArray *)mutableArrayValueForKeyPath:(NSString *)keyPath;
    - (NSMutableSet *)mutableSetValueForKeyPath:(NSString *)keyPath;
    - (NSMutableOrderedSet *)mutableOrderedSetValueForKeyPath:(NSString *)keyPath;
    验证值
    - (BOOL)validateValue:(inout id _Nullable * _Nonnull)ioValue forKey:(NSString *)inKey   
    error:(out NSError **)outError;        
    - (BOOL)validateValue:(inout id _Nullable * _Nonnull)ioValue forKeyPath:(NSString *)  
    inKeyPath error:(out NSError **)outError;
    获取一个不存在的Key对应的Value会发生crash，重写该方法可避免程序crash
    - (nullable id)valueForUndefinedKey:(NSString *)key;
    为一个不存在的Key设置Value会发生crash，重写该方法可避免程序crash
    - (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key;
    将Key对应的value设置为nil会发生crash，重写该方法可避免程序crash
    - (void)setNilValueForKey:(NSString *)key;
    输入一组key,返回该组key对应的Value，再转成字典返回，用于将Model转到字典。
    - (NSDictionary<NSString *, id> *)dictionaryWithValuesForKeys:(NSArray<NSString *> *)keys;
    通过给定的字典为对象的属性设置值
    - (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *, id> *)keyedValues;
### 1 KVC设值和获取值
    @interface WGTestModel : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) BOOL isSex;
    @end
    
    @implementation WGTestModel
    @end
        
    - (void)viewDidLoad {
        [super viewDidLoad];
        WGTestModel *model = [[WGTestModel alloc]init];
        //赋值
        [model setValue:@"张三" forKey:@"name"];
        //获取值
        NSString *name = [model valueForKey:@"name"];
        NSLog(@"name:%@",name);
    }

    输出结果: name:张三
#### KVC赋值比较简单，这里不再累述，现在重点关注一下setValue: forKey: 方法底层是如何查找到对应的Key并赋值的,寻找过程如下，搜索过程已代码验证，这里不再贴代码了
1. 首先查找setKey方法，找到了就直接赋值；如果没有找到:
2. KVC会判断对象是否实现了accessInstanceVariablesDirectly方法，该方法默认返回YES，如果返回NO，则KVC不再去查找，直接调用setValue:forUndefinedKey:抛出异常，使程序crash,如果返回YES(表示KVC可以继续查找):
3. 查找.h和.m文件(无论是私有的还是可访问的)中有没有对应的成员变量_key(注意如果存在以@property声明的_key属性，KVC是不会去查找也不会赋值的)，如果找到的话，直接赋值；如果没有找到:
4. KVC会搜索_isKey的成员变量(只会搜索成员变量，@property声明的属性是不会搜索的；_iskey也不会搜索的，只能搜索_isKey)，如果找到就赋值；如果没有找到:
5. KVC会搜索isKey的属性，如果有就赋值(其实赋给的是属性isKey生成的成员变量_isKey);如果没有就在.h文件和.m文件中找isKey的成员变量，如果找到了就赋值，如果没有找到就调用setValue:forUndefinedKey:抛出异常
6. 整个搜索流程就是setKey方法->accessInstanceVariablesDirectly方法判断(YES)->_key成员变量->_isKey成员变量->isKey属性->isKey成员变量->setValue:forUndefinedKey:如果想让某个类禁用KVC，在该类中重写accessInstanceVariablesDirectly方法并返回NO即可
#### 当调用valueForKey时，KVC的检索顺序如下
1. KVC按照getKey->key->isKey的顺序查找getter方法，找到直接调用,如果没有找到：
2. 查找countOfKey/objectInKeyAtindex/KeyAtindexes格式的方法。如果其中一个方法被找到，那么就会返回一个可以响应NSArray所有方法的代理集合，调用这个代理集合的方法，或者说给这个代理集合发送属于NSArray的方法，就会以countOfKey/objectInKeyAtindex/KeyAtindexes这几个方法组合的形式调用。如果没有找到:

3. 查找countOfKey/enumeratorOfKey/memberOfKey格式的方法。如果这三个方法都找到，就返回一个可以响应NSSet所有方法的代理集合，给这个代理集合发NSSet的消息，就会以countOfKey/enumeratorOfKey/memberOfKey组合的形式调用。如果没有找到:
4. 检查accessInstanceVariablesDirectly方法，如果返回YES，会按照_key -> _isKey -> key -> iskey的顺序搜索成员；如果没有找到，调用valueForUndefinedKey方法，抛出异常

### 2.KVC中KeyPath
#### 如果一个类的属性是自定义类型或者其它复杂的数据类型，通过KVC获取该属性会比较繁琐，所以KVC提供了KeyPath键路径来简化获取属性的过程;注意如果不小心使用了key而非keyPath，那么KVC就会找Key(teacher.name)没有找到就会抛出异常，所以一定要小心使用。
    @interface WGTeacher : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) BOOL isSex;
    @end

    @interface WGStudent : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, strong) WGTeacher *teacher;
    @end

    WGTeacher *tea = [[WGTeacher alloc]init];
    WGStudent *stu = [[WGStudent alloc]init];
    stu.teacher = tea;
    //赋值
    [stu setValue:@"小明" forKey:@"name"];
    [stu setValue:@"王老师" forKeyPath:@"teacher.name"];
    //获取值
    NSString *teaName = [stu valueForKeyPath:@"teacher.name"];
    NSString *stuName = [stu valueForKey:@"name"];
    NSLog(@"学生姓名:%@---老师姓名:%@",stuName,teaName);

    打印结果: 学生姓名:小明---老师姓名:王老师

### 4.处理异常
#### KVC在使用的过程中，下列情况会导致异常，同时KVC也提供了想对应的处理异常机制
* 设置值的时候，Key不存在；重写setValue: forUndefinedKey:方法来捕获异常，防止程序crash
* 设置值的时候，将value设置为nil；重写setNilValueForKey:方法来捕获异常，防止程序crash
* 获取值的时候，Key不存在；重写valueForUndefinedKey:方法来捕获异常，防止程序crash

        @interface WGTeacher : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) BOOL isSex;
        @end

        @implementation WGTeacher
        -(void)setNilValueForKey:(NSString *)key {
            NSLog(@"将%@对应的value设置为了nil",key);
        }
        -(void)setValue:(id)value forUndefinedKey:(NSString *)key {
            NSLog(@"为不存在的Key:%@设置了值", key);
        }
        -(id)valueForUndefinedKey:(NSString *)key {
            NSLog(@"获取一个不存在Key:%@对应的Value", key);
            return nil;
        }
        @end

### 5.KVC处理数值或结构体类型属性
#### 我们知道valueForKey: 方法返回的都是id对象,如果属性对应的类型是值或结构体，那么valueForKey: 方法会自动将这些类型转为NSNumber/NSValue,我们使用的时候需要手动将NSNumber/NSValue转为我们需要的类型
        @interface WGTeacher : NSObject
        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) BOOL isSex;
        @property(nonatomic, assign) int age;
        @end

        WGTeacher *tea = [[WGTeacher alloc]init];
        id age = [tea valueForKey:@"age"];
        id sex = [tea valueForKey:@"isSex"];
![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/kvc1.png)

#### 当使用setValue: forKey:方法时，如果直接给值或者结构体类型赋值(例如:[tea setValue:18 forKey:@"age"];)编辑器会报错并有提示信息Implicit conversion of 'int' to 'id _Nullable' is disallowed with ARC，即提示在ARC环境下不能隐式地将“int”转换为“id _Nullable”，所以我们需要将值类型转为NSNumber对象，将结构体类型转为NSValue对象，来进行值的设置

    WGTeacher *tea = [[WGTeacher alloc]init];
    //Implicit conversion of 'int' to 'id _Nullable' is disallowed with ARC
    //[tea setValue:18 forKey:@"age"];
    [tea setValue:[NSNumber numberWithInt:18] forKey:@"age"];
    [tea setValue:[NSNumber numberWithBool:YES] forKey:@"isSex"];
    NSLog(@"age:%@----isSex:%@",[tea valueForKey:@"age"],[tea valueForKey:@"isSex"]);
    NSLog(@"点语法---age:%d,isSex:%d",tea.age, tea.isSex);

    打印结果: age:18----isSex:1
            点语法---age:18,isSex:1

### 6. KVC 键值验证
#### KVC为我们提供了验证Value有效性的方法，但是需要我们自己手动调用验证方法（CoreData会自动调用）；比如我们给老师设置年龄，但有个限制条件(设置的年龄不能超过150岁)

    @interface WGTeacher : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) BOOL isSex;
    @property(nonatomic, assign) int age;
    @end

    @implementation WGTeacher
    -(BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)  
    inKey error:(out NSError *__autoreleasing  _Nullable *)outError {
        NSNumber *age = *ioValue;
        if ([age intValue] > 150) { //年龄超过150岁的就说明设置的value是无效的
            return NO;
        }
        return YES;
    }
    @end


    WGTeacher *tea = [[WGTeacher alloc]init];
    NSNumber *age = @151;
    NSError *error;
    BOOL isEffectValue = [tea validateValue:&age forKey:@"age" error:&error];
    if (isEffectValue) { //如果设置的Value不超过150
        [tea setValue:age forKey:@"age"];
    }else {
        NSLog(@"设置的值不满足条件");
    }
    NSLog(@"老师的年龄是:%@",[tea valueForKey:@"age"]);
    
    打印结果: 设置的值不满足条件
            老师的年龄是:0
### 7.KVC处理集合运算符和对象运算符
#### KVC在处理集合的时候，提供了@avg，@count ，@max ，@min ，@sum五种集合运算符；在处理对象的时候，提供了@distinctUnionOfObjects，@unionOfObjects两种对象运算符，返回的都是一个NSArray数组，使用demo如下

    @interface WGTeacher : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) int age;
    @end

    WGTeacher *tea1 = [[WGTeacher alloc]init];
    tea1.name = @"张老师";
    tea1.age = 32;
    WGTeacher *tea2 = [[WGTeacher alloc]init];
    tea2.name = @"王老师";
    tea2.age = 22;
    WGTeacher *tea3 = [[WGTeacher alloc]init];
    tea3.name = @"李老师";
    tea3.age = 43;
    WGTeacher *tea4 = [[WGTeacher alloc]init];
    tea4.name = @"武老师";
    tea4.age = 22;
    NSArray *teacherArr = @[tea1, tea2, tea3, tea4];
        
    //集合运算符
    NSNumber *sumAge = [teacherArr valueForKeyPath:@"@sum.age"];
    NSNumber *countAge = [teacherArr valueForKeyPath:@"@count.age"];
    NSNumber *maxAge = [teacherArr valueForKeyPath:@"@max.age"];
    NSNumber *minAge = [teacherArr valueForKeyPath:@"@min.age"];
    NSNumber *avgAge = [teacherArr valueForKeyPath:@"@avg.age"];
    NSLog(@"\n年龄和:%d\n总个数:%d\n最大年龄是:%d\n最小年龄:%d\n平均年龄:%f",[sumAge intValue],  
    [countAge intValue],[maxAge intValue],[minAge intValue],[avgAge floatValue]);
        
    //对象运算符
    //返回对应属性的值(返回的元素都是唯一的，是去重以后的结果)
    NSArray *ageArr1 = [teacherArr valueForKeyPath:@"@distinctUnionOfObjects.age"];
    for (NSNumber *age in ageArr1) {
        NSLog(@"ageArr1--年龄:%d",[age intValue]);
    }
    //返回对应属性的值(返回元素的全集)
    NSArray *ageArr2 = [teacherArr valueForKeyPath:@"@unionOfObjects.age"];
    for (NSNumber *age in ageArr2) {
        NSLog(@"ageArr2--年龄:%d",[age intValue]);
    }

    打印结果: 年龄和:119
                    总个数:4
                    最大年龄是:43
                    最小年龄:22
                    平均年龄:29.750000
                    ageArr1--年龄:43
                    ageArr1--年龄:22
                    ageArr1--年龄:32
                    ageArr2--年龄:32
                    ageArr2--年龄:22
                    ageArr2--年龄:43
                    ageArr2--年龄:22
### 8.KVC 处理字典
#### 处理字典上，KVC提供了两个方法:dictionaryWithValuesForKeys,是指输入一组key，返回这组key对应的值Value，然后再把Key/Value组成一个字典；setValuesForKeysWithDictionary:传进去一个字典，用来修改对象中属性的值，其实可以理解成第一方法是为了获取值，第二个方法是用来设置值的

    @interface WGTeacher : NSObject
    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) int age;
    @end

    WGTeacher *tea = [[WGTeacher alloc]init];
    tea.name = @"张老师";
    tea.age = 32;
    //传进去一组Key数组，返回key对应的value,并组装成字典返回
    NSDictionary *dic1 = [tea dictionaryWithValuesForKeys:@[@"name",@"age"]];
    NSString *name = [dic1 objectForKey:@"name"];
    NSNumber *age = [dic1 objectForKey:@"age"];
    NSLog(@"name:%@,age:%d",name,[age intValue]);

    //传进去一个字典，用来修改对象中对应Key的value（修改对象中属性的值）
    NSDictionary *dic2 = @{@"name": @"张三", @"age": @18};
    [tea setValuesForKeysWithDictionary:dic2];
    NSLog(@"name:%@----age:%d",tea.name, tea.age);
    
    打印结果: name:张老师,age:32
            name:张三----age:18

### 9.KVC 实现高阶消息传递
#### 集合类型(NSArray/NSSet/NSOrderedSet)的在使用KVC的valueForKey:时，会将这个Key传递给集合中的每一个元素，返回的结果也是这个集合类型的，例如数组NSArray调用valueForKey:返回的结果也是个NSArray，结果数组中存放的就是传进去的Key对集合中每个元素“影响”的结果

####  valueForKey:方法，传递进去的key可以是属性或者方法，这里的属性指的是能够影响原集合元素的属性，其实也类似于方法的功能，只是被定义成了属性而已，比如NSString中的属性capitalizedString(实现首字母大写)/uppercaseString(实现字符串转大写)/lowercaseString(实现字符串转小写),如果Key是具有“功能”的属性

    NSArray *nameArr = @[@"zhangsan",@"lisi",@"wangwu",@"liy"];
    //将capitalizedString属性传递给nameArr中的每一个元素，让每个元素都能响应capitalizedString的功能
    NSArray *resultNameArr = [nameArr valueForKey:@"capitalizedString"];
    NSLog(@"将字符串首字符大写:\nresultNameArr---:%@",resultNameArr);

    //将uppercaseString属性传递给nameArr中的没一个元素，让每个元素都能响应uppercaseString的功能
    NSArray *resultNameArr1 = [nameArr valueForKey:@"uppercaseString"];
    NSLog(@"将字符串全部大写:\nresultNameArr1---:%@",resultNameArr1);

    打印结果: 将字符串首字符大写:
            resultNameArr---:(
                Zhangsan,
                Lisi,
                Wangwu,
                Liy
            )
            将字符串全部大写:
            resultNameArr1---:(
                ZHANGSAN,
                LISI,
                WANGWU,
                LIY
            )

#### 如果Key是方法,那么集合调用valueForKey:时，集合中的每个元素都会调用这个方法,这里验证过了，这里的方法不能携带参数，否则会调用valueForUndefinedKey:方法，会导致程序crash

    @interface WGTeacher : NSObject

    @property(nonatomic, strong) NSString *name;
    @property(nonatomic, assign) int age;
    - (void)eat;
    - (int)answerQuestionNum;

    @end

    @implementation WGTeacher
    - (void)eat {
        NSLog(@"%@:开始吃饭吧",_name);
    }

    -(int)answerQuestionNum {
        if ([_name hasPrefix:@"张"]) {
            return 30;
        }else if ([_name hasPrefix:@"赵"]) {
            return 20;
        }else {
            return 10;
        }
    }

    //私有方法
    -(void)run {
        NSLog(@"%@:开始起来跑步了",_name);
    }
    @end

    WGTeacher *tea1 = [[WGTeacher alloc]init];
    tea1.name = @"张老师";
    WGTeacher *tea2 = [[WGTeacher alloc]init];
    tea2.name = @"赵老师";
    WGTeacher *tea3 = [[WGTeacher alloc]init];
    tea3.name = @"王老师";
    NSArray *teacherArr = @[tea1,tea2,tea3];
    //公开方法 无返回值 无参数 eatResultArr数组中存放的NSNull类型的空置，因为无返回值
    NSArray *eatResultArr = [teacherArr valueForKey:@"eat"];
    //公开方法 有返回值 无参数 answerQuestionNumArr数组中存放的是多个元素响应answerQuestionNum方法的返回值
    NSArray *answerQuestionNumArr = [teacherArr valueForKey:@"answerQuestionNum"];
    //私有方法 无返回值 无参数
    NSArray *runResultArr = [teacherArr valueForKey:@"run"];
    NSLog(@"\neatResultArr:%@\nanswerQuestionNumArr:%@\nrunResultArr:%@",  
    eatResultArr,answerQuestionNumArr, runResultArr);

    打印结果: 张老师:开始吃饭吧
            赵老师:开始吃饭吧
            王老师:开始吃饭吧
            张老师:开始起来跑步了
            赵老师:开始起来跑步了
            王老师:开始起来跑步了
            eatResultArr:(
                "<null>",
                "<null>",
                "<null>"
            )
            answerQuestionNumArr:(
                30,
                20,
                10
            )
            runResultArr:(
                "<null>",
                "<null>",
                "<null>"
            )
                
### MJExtension底层班 
#### 1 KVC基本方法
    设置属性值
    setValue:(nullable id) forKey:(nonnull NSString *)
    setValue:(nullable id) forKeyPath:(nonnull NSString *)
    获取属性值
    valueForKey:(nonnull NSString *)
    valueForKeyPath:(nonnull NSString *)
#### 1.1 基本操作
    //Person.h文件
    @interface Person : NSObject
    @property(nonatomic, assign)int age;
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *p = [[Person alloc]init];
        //1. 点语法给属性赋值
        p.age = 10;
        //2. 通过KVC赋值 注意这里的value是id类型，所以需要转为OC对象NSNumber
        //[p setValue:@10 forKey:@"age"];
        [p setValue:[NSNumber numberWithInt:10] forKey:@"age"];
        NSLog(@"\n属性age的值:%d\n", p.age);
    }
    打印结果: 属性age的值: 10
#### 1.2 KVC赋值的过程/原理(setValue: forKey:)

    调用setValue:forKey:方法
            |            NO                                      NO  抛出异常
    按照setKey:/:-->+(BOOL)accessInstanceVariablesDirectly-->setValue:forUndefinedKey:
       _setKey顺序查找方法                       |YES
            | YES             按照_key、_isKey、key、isKey  NO   抛出异常
    若找到，传递参数，调用方法               顺序查找成员变量  ------>setValue:forUndefinedKey:
                                               |YES
                                            直接赋值
       
#### 1.3 KVC取值的过程/原理(valueForKey:)
    
    调用valueForKey:方法
            |                  NO                                      NO   抛出异常
    按照getKey/key/isKey/-->+(BOOL)accessInstanceVariablesDirectly-->valueForUndefinedKey:
       _key:顺序查找方法                            |YES
            | YES                    按照_key、_isKey、key、isKey  NO    抛出异常
    若找到，调用方法                             顺序查找成员变量    ------>valueForUndefinedKey:
                                                  |YES
                                                直接赋值

#### 2. 面试题
#### 2.1 通过KVC修改属性会触发KVO吗？会
    //Person.h文件
    @interface Person : NSObject
    @property(nonatomic, assign)int age;
    @end
        
    //Person.m文件
    @implementation Person
    //重写监听属性的setter方法
    -(void)setAge:(int)age {
        NSLog(@"setAge方法---");
        _age = age;
    }
    -(void)willChangeValueForKey:(NSString *)key {
        NSLog(@"willChangeValueForKey---begin");
        [super willChangeValueForKey: key];
        NSLog(@"willChangeValueForKey---end");
    }

    -(void)didChangeValueForKey:(NSString *)key {
        NSLog(@"didChangeValueForKey---begin");
        [super didChangeValueForKey:key];
        NSLog(@"didChangeValueForKey---begin");
    }
    @end
        
    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *p = [[Person alloc]init];
        //为对象p的age属性添加观察者
        [p addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew   
        | NSKeyValueObservingOptionOld context:nil];
        // 1. 点语法对属性进行赋值，是会触发KVO的
        //p.age = 10;
        // 2. 通过KVC对属性进行赋值
        [p setValue:@10 forKeyPath:@"age"];
    }
    //观察者实现监听方法
    -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  
    change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
        NSLog(@"监听到%p的%@发生改变了---%@",object,keyPath,change);
    }
        
    打印结果:  willChangeValueForKey---begin
              willChangeValueForKey---end
              setAge方法---
              didChangeValueForKey---begin
              监听到0x61000000ffb0的age发生改变了---{
                kind = 1;
                new = 10;
                old = 0;
              }
              didChangeValueForKey---begin
#### 结论：通过KVC对属性进行赋值会触发KVO的，KVC底层内部是也会调用willChangeValueForKey和didChangeValueForKey方法的；

#### 2.2 通过KVC修改成员变量，会触发KVO吗？ 会
#### 如果通过KVC对成员变量进行赋值，即便没有setter方法同样是会触发KVO的，因为KVC找到成员变量进行赋值时，底层也调用了触发KVO的方法willChangeValueForKey和didChangeValueForKey，但是通过对象->成员变量是无法触发KVO的；验证如下：
    @interface Person : NSObject
    {
        @public
        int age;
    }
    @end

    @implementation Person
    -(void)willChangeValueForKey:(NSString *)key {
        NSLog(@"willChangeValueForKey---begin");
        [super willChangeValueForKey: key];
        NSLog(@"willChangeValueForKey---end");
    }
    -(void)didChangeValueForKey:(NSString *)key {
        NSLog(@"didChangeValueForKey---begin");
        [super didChangeValueForKey:key];
        NSLog(@"didChangeValueForKey---begin");
    }
    @end

    - (void)viewDidLoad {
        [super viewDidLoad];
        Person *p = [[Person alloc]init];
        //为对象p的age属性添加观察者
        [p addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew   
        | NSKeyValueObservingOptionOld context:nil];
        //1.直接通过对象->成员变量是不会触发KVO的
        //p->age = 100;
        //2. 通过KVC对成员变量进行赋值，是可以触发KVO的
        [p setValue:@10 forKey:@"age"];
    }

    //观察者实现监听方法
    -(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  
    change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
        NSLog(@"监听到%p的%@发生改变了---%@",object,keyPath,change);
    }
        
    打印结果:  willChangeValueForKey---begin
              willChangeValueForKey---end
              didChangeValueForKey---begin
              监听到0x61000000ffb0的age发生改变了---{
                kind = 1;
                new = 10;
                old = 0;
              }
              didChangeValueForKey---begin
