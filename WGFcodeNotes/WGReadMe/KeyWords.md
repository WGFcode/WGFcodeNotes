#  iOS开发中常用关键字
## extern
### extern:声明外部全局变量或者常量,一般只能用于声明,不能用于实现.开发中经常使用的场景是在管理全局变量的类中使用,例如统一管理通知名称
### 在.h文件中声明
#### 全局变量 `extern NSString *name`  
#### 全局常量 `extern NSString * const name` 
### 在.m文件中实现
#### 全局变量 `NSString *name = @"张三"`  
#### 全局常量 `extern NSString * const name`  


## `static`静态的意思
### 1修饰局部变量: 保证局部变量只会被初始化一次,在程序运行过程中,只会分配一次内存,生命周期类似全局变量,但作用域不变
### 例子如下
` -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
          int i = 0;   //打印结果都是1 每次点击后i都被初始化为0
          static int i = 0;  //打印结果1 2 3 4 5 ...i只会被初始化一次
          i ++;
         NSLog(@"------%d----",i);
 }`
 ### 2.修饰全局变量: 全局变量的作用域仅限于当前文件内部，即当前文件内部才能访问该全局变量
 ### 3.修饰函数:被修饰的函数被称为静态函数，使得外部文件无法访问这个函数，仅本文件可以访问
 
 
 
## const
### const是常量的意思,用来修饰它右边的基本变量或者指针变量,被修饰的变量是只读的,不能被修改;
`NSString * const name = @"张三"` const修饰的是name,所有name是只读的不能被修改的
`int const *a`                  *a只读,a变量
`int * const a`                *a变量 ,a只读
`const int * const a`    a和*a都只读
`int const * const a`    a和*a都只读
经常用来定义全局只读变量
`NSString * const name = "张三"` 
static修饰后全局变量只能在所在的文件中访问
`static NSString * const name = "张三"`


## 注意
### 1.在多个文件中,经常需要使用同一个常量,有三种方法可以实现
#### (1)使用static和const,在多个文件中都定义一个静态全局的常量
#### (2)使用extern和const,定义一份全局变量,多个文件共用
#### (3)使用define宏进行定义
### 2.const和宏的区别
`编译时刻:宏是预编译（编译之前处理），const是编译阶段。`
`编译检查:宏不做检查，不会报编译错误，只是替换，const会编译检查，会报编译错误。`
`宏的好处:宏能定义一些函数，方法。 const不能。`
`宏的坏处:使用大量宏，容易造成编译时间久，每次都需要重新替换。`
1.extern: (外面的、外部的)声明外部全局变量，只能用于声明，不能用于实现
extern NSString * const XXX: 声明一个全局常量，需要在.m文件中实现
2.const: (常量)被const修饰的变量是只读的（变量－>只读变量）
const只修饰右边的变量
3.static修饰局部变量,让变量只初始化一次，一份内存；
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
int i = 0  声明一个局部变量
i ++;
NSLog(@"----%ld----",i)
}
打印结果:都是1,每次点击之后，出了方法体，i变量被回收，每次进来后，i都又被初始化为0
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
static int i = 0
i ++;
NSLog(@"----%ld----",i)
}
打印结果:1 2 3 4 5... 被static修饰的局部变量，只会被初始化一次，声明周期和程序一样，但作用域不变
static修饰全局变量,让外界文件无法访问
static 类型 变量名 = 初始化值
static 修饰的变量只作用于它声明所在的.m文件中，static修改的变量必须放在@implementation外面或方法中，它只在程序启动初始化一次。
开发中static与const的联合使用 定义一个只能在当前文件访问的全局常量
static 类型 const 常量名 = 初始化值
开发中extern与const的联合使用 定义一个整个项目都能访问的全局常量
创建.h和.m文件在.h文件中声明,在.m文件中赋值
4.静态变量：当我们希望一个变量的作用域不仅仅是作用域某个类的某个对象，而是作用域整个类的时候，这时候就可以使用静态变量，静态变量是指用static修饰的变量。
静态变量只能作用于.m文件，放在@implementation外面或方法中，只在程序启动初始化一次
5.全局变量: extern修饰的变量，是一个全局变量。
extern NSString * LMJName = @"XXX";
此时全局变量只能被初始化一次，即变成了全局常量
extern NSString * const LMJName = @"iOS开发者公会;
6.静态常量: const修改的变量是不可变的
*/
//声明一个外部的全部常量(外部不能修改): extern 类型 const 常量名
