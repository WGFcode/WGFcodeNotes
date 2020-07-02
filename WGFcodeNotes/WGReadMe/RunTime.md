## RunTime
#### 我们知道OC是动态性的编程语言，所谓的动态性就是将程序的一些决定性工作从编译期推迟到运行时。由于OC的运行时特性，所以OC不仅需要依赖编辑器还需要依赖运行时环境，在运行时系统中动态的创建类和对象、消息传递和转发等。而RunTime就是OC语言面向对象和动态机制的基石，RunTime是一套比较底层的纯C语言的API。高级编程语言想成为可执行文件，必须先编译为汇编语言再汇编为机器语言，而OC语言不能直接编译为汇编语言，而是先编译为C语言，然后再编辑为汇编语言和机器语言，而OC到C语言的过渡就是RunTime来完成的。

### 如何查看OC的底层代码？
#### 我们使用**clang**来查看OC的源码实现，**clang**是由Apple主导编写，基于LLVM的C/C++/Objective-C编译器.LLVM 设计思想分为前端/优化器/后端，这里的前端实际上指的就是**clang**，整个流程可以简单概括为**clang**对代码进行处理形成中间层作为输出，LLVM把CLang的输出作为输入生成机器码。接下来我们重点介绍使用**clang**编译器来将OC代码编译为C语言代码，并生成一个.cpp的C++文件
* cd 到当前文件项目的需要转化的文件目录下 
* clang -rewrite-objc WGTestModel.m 
* 在需要转化的文件目录下，会生成对应的WGTestModel.cpp文件

### 一.源码分析
        //.h文件
        @interface WGTestModel : NSObject

        @property(nonatomic, strong) NSString *name;
        @property(nonatomic, assign) int age;

        +(void)run;
        -(void)eat;
        -(void)sleepWithTime:(NSTimeInterval)time;

        @end

        //.m文件
        @interface WGTestModel()
        {
            NSString *_parents;
            BOOL _isSex;
        }

        @end

        @implementation WGTestModel

        +(void)run {
            NSLog(@"开始跑步了");
        }
        -(void)eat {
            NSLog(@"开始吃饭了");
        }
        -(void)sleepWithTime:(NSTimeInterval)time {
            NSLog(@"我睡了%f分钟了",time);
        }
        -(void)love {
            NSLog(@"我喜欢你");
        }

        @end
#### 打开生成的WGTestModel.cpp文件，全局查找到WGTestModel对应的地方，以下是摘取的cpp文件的内容和RunTime源码中

#### 1.每个对象本质就是个结构体(objc_objec),结构体中包含了isa指针,该指针指向了对象所属的类

    typedef struct objc_object WGTestModel;  
    struct objc_object {
        Class _Nonnull isa;         指向自己所属的类
    };
#### 2. 通过对象的isa指针找到对象所属的类,该类也是个结构体(objc_class),并且继承自结构体objc_object,所以类也是个对象;既然是继承自objc_object,那么在类的结构体objc_class中也包含了isa指针,而这个isa指针又指向了类对象自身的元类,类对象和元类对象的类型都是Class;类对象和元类对象在内存中本质都是objc_class结构体

* 什么是元类?
元类就是类对象所属的类,元类用于描述类对象本身所具有的特征，而在元类的 methodLists 中，保存了类的方法链表，即所谓的[类方法]

        typedef struct objc_class *Class;
        struct objc_class : objc_object {
        // Class ISA;
        Class superclass;           指向当前类的父类
        cache_t cache;              用于方法缓存来加速方法的调用
        class_data_bits_t bits;     存储类的方法、属性、遵循的协议等信息的地方,可以理解为一个指针
        class_rw_t *data() {        存储方法、属性、协议列表等信息；rw可读可写
            return bits.data();
        }
        ...
        }
    
        通过class_data_bits_t和FAST_DATA_MASK找到class_rw_t
        class_rw_t* data() {
            return (class_rw_t *)(bits & FAST_DATA_MASK);
        }
    
        存储方法、属性、协议列表等信息(如果是[类对象]这里的方法指的是[实例方法],如果是[元类对象]这里的方法指的是[类方法])
        struct class_rw_t {
            const class_ro_t *ro;          存储了当前类在编译期就已经确定的属性、方法以及遵循的协议
            //下面三个都是二维数组,这三个二位数组中的数据有一部分是从class_ro_t中合并过来的
            method_array_t methods;        方法列表
            property_array_t properties;   属性列表
            protocol_array_t protocols;    协议列表
            ...
            这里是没有成员变量信息的,成员变量的信息是编译期就已经确定并添加到 class_ro_t 中去，并且只读
        }
    
        存储了当前类在编译期就已经确定的属性、方法以及遵循的协议
        struct class_ro_t {                     class_ro_t意思是readonly,在编译阶段就已经确定了，不可以修改
            const char * name;                  类名(不能修改)
            uint32_t instanceSize;              对象所占用的内存大小
            method_list_t * baseMethodList;     方法列表
            protocol_list_t * baseProtocols;    协议列表
            const ivar_list_t * ivars;          成员变量列表(不能修改)
            property_list_t *baseProperties;    属性列表
            const uint8_t * weakIvarLayout;     weak 成员变量内存布局
            const uint8_t * ivarLayout;         (不能修改)
            ...
            ivarLayout:成员变量ivar内存布局，是放在我们的io里面的，并且是const不允许修改的，也就是说明，我们的
            成员变量布局，在编译阶段就确定了，内存布局已经确定了，在运行时是不可以修改了，
            这就说明了，为什么运行时不能往类中动态添加成员变量。
        };
        
        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_name;
        extern "C" unsigned long OBJC_IVAR_$_WGTestModel$_age;
        OC中声明的属性，系统会自动为其生成一个带下划线的成员变量，所以我们在声明成员变量的时候规范性的以_XXX的格式进行声明    

#### 总结: 初始化一个类的过程
* 在编译期将类中已经确定的信息(属性/成员变量/方法/协议)添加到class_ro_t结构体中,这里面信息在运行时是不会改变的
* 递归初始化类的父类和元类
* 运行时会动态创建class_rw_t结构体,
* 将class_ro_t中的信息(属性/方法/协议)添加到class_rw_t结构体对应的数组中,注意成员变量仍然在class_ro_t中
* 将分类中的信息(属性/方法/协议)添加到class_rw_t结构体对应的数组中
* 在运行期,不能动态的在类中添加成员变量/弱引用成员变量/修改类名
* 为什么在运行时可以动态添加属性/方法/协议,而不能添加成员变量到类中?因为**rw**中引用了**ro**,**ro**中的属性/方法/协议添加到了我们**rw**对应的数组中,所以为动态添加提供了可能;而成员变量在**ro**中并没有添加到**rw**中,所以不能动态添加
* runtime 虽然提供了动态添加成员变量的方法 class_addIvar() ，但官方文档明确说明必须在alloc和register之间调用,程序在编译时,就已经生成了成员变量布局,程序启动后就没有机会再添加成员变量
* 我们的类实例是需要一块内存空间的，他有isa指针指向，如果我们在运行时允许动态修改成员变量的布局，那么创建出来的类实例就属于无效的了，能够被任意修改，但是属性和方法是我们 objc_class 可以管理的，增删改都不影响我们实例内存布局。

#### 3. 接下来我们解读cache_t结构体
        实际上cache_t结构体内部本质是一个散列表(哈希表),用来缓存调用过的方法,进而提高访问方法的速度
        struct cache_t {
            struct bucket_t *_buckets;     //缓存方法的散列表(也可称为数组)
            mask_t _mask;                  //总槽位-1(实际就是散列表总长度-1)
            mask_t _occupied;              //实际已经使用的槽位(已经占用的散列表长度)
            
            public:
            struct bucket_t *buckets();    //_buckets对外的一个获取函数
            mask_t mask();                 //获取缓存容量_mask
            mask_t occupied();             //获取已经占用的缓存个数_occupied
            void incrementOccupied();      //增加缓存，_occupied自++
            void setBucketsAndMask(struct bucket_t *newBuckets, mask_t newMask);  //设置一个新的_buckets
            void initializeToEmpty();      //初始化cache并设置为空

            mask_t capacity();             //获取_buckets的容量
                思考:为什么需要mask()+1? 扩容算法需要：expand()中的扩容算法基本逻辑
                (最小分配的容量是4，当容量存满3/4时，进行扩容，扩容当前容量的两倍)；
                这样最小容量4的 1/4就是1，这就是mask() + 1的原因。
                mask_t cache_t::capacity() {
                    return mask() ? mask()+1 : 0;  //当mask()=0时,返回0;当mask()>0时,返回mask()+1
                }

            bool isConstantEmptyCache();    //判断_buckets是否为空
            bool canBeFreed();

            static size_t bytesForCapacity(uint32_t cap);
            static struct bucket_t * endMarker(struct bucket_t *b, uint32_t cap);

            void expand();  //扩容
            void reallocate(mask_t oldCapacity, mask_t newCapacity);   //重新分配
            //通过 cache_key_t 查找receiver中的 bucket_t *
            struct bucket_t * find(cache_key_t key, id receiver);

            static void bad_cache(id receiver, SEL sel, Class isa) __attribute__((noreturn));
        }
        
        bucket_t * cache_t::find(cache_key_t k, id receiver){
            assert(k != 0);
            bucket_t *b = buckets();
            mask_t m = mask();
            mask_t begin = cache_hash(k, m);    //找到对应的下标
            mask_t i = begin;
            do {
                if (b[i].key() == 0  ||  b[i].key() == k) {
                    return &b[i];
                }
            } while ((i = cache_next(i, m)) != begin); //哈希表会有碰撞问题
            // hack
            Class cls = (Class)((uintptr_t)this - offsetof(objc_class, cache));
            cache_t::bad_cache(receiver, (SEL)k, cls);
        }

        //发生映射的关系是: key&mask=index,index一定是<=mask的;key就是方法名称,mask就是总槽位-1
        //散列表(又叫哈希表)的实现原理是f(key)=index,通过一个函数直接找到对应的index
        static inline mask_t cache_hash(cache_key_t key, mask_t mask) {
            return (mask_t)(key & mask);  //取余法计算索引
        }
        
        struct bucket_t {
            private:
                cache_key_t _key;    //指方法的名字:@selector()
                IMP _imp;            //函数地址
            public:
                inline cache_key_t key() const { return _key; }
                inline IMP imp() const { return (IMP)_imp; }
                inline void setKey(cache_key_t newKey) { _key = newKey; }
                inline void setImp(IMP newImp) { _imp = newImp; }
                void set(cache_key_t newKey, IMP newImp);
        };
        
* 问题1: 为什么需要cache_t?,我们知道对象调用方法的过程是这样的
1. 通过obj的isa指针找到obj的类对象Class -> 通过bits找到class_rw_t中的method_array_t方法列表,然后进行循环遍历,如果找到就调用,没有找到继续下一步
2. objc的Class对象 -> superclass父类 ->  method_array_t方法列表,循环遍历,如果找到就调用,没有找到继续找父类
3. 一直递归这样找obj的父类,如果一直到obj的根父类NSObjct -> isa -> NSObject的Class对象 -> method_array_t方法列表,如果这里仍然没有找到,就走各种判断,然后抛出异常
4. 每次调用方法都要进行这么耗时的查找流程,所以cache_t方法缓存列表出现了
5. cache_t底层是通过哈希表来实现读取的,调用过的方法会直接从cache_t缓存中获取,大大提高查找速度

        
* 问题2: 哈希表会出现碰撞问题(@selector(test)&_mask 和 @selector(test1)&_mask 的index相同时)
        当出现碰撞问题的时候,索引会查找下一个,当(i+1)=mask时,因为有&mask,所以索引i = 0又回到了散列表头部,
        这样就会把散列表头尾连接起来形成一个环
        
        static inline mask_t cache_next(mask_t i, mask_t mask) {
            return (i+1) & mask;
        }
        
* 问题3: 当实际占用的槽位_occupied和_mask相等时,即_buckets数组有4个元素,而_occupied和_mask值都是3的时候,
        当再次添加一个缓存方法时,槽位的总量会变大为原来的 2倍(_mask*2=6) 进行扩容;
        在扩容的同时,会将哈希表里原来缓存的内容进行清空;扩容的策略就是当当前的哈希表中使用的空间占总空间的3/4时,会扩容当前使用空间的2倍
        
        void cache_t::expand(){
            cacheUpdateLock.assertLocked();
            uint32_t oldCapacity = capacity(); //获取原来的_buckets容量
            //计算新_buckets的容量;INIT_CACHE_SIZE=4,
            //如果oldCapacity==0,则使用最小容量4; 如果oldCapacity>0,则扩容两倍
            uint32_t newCapacity = oldCapacity ? oldCapacity*2 : INIT_CACHE_SIZE;
            if ((uint32_t)(mask_t)newCapacity != newCapacity) {
                // mask overflow - can't grow further
                // fixme this wastes one bit of mask
                newCapacity = oldCapacity;
            }
            reallocate(oldCapacity, newCapacity); //重新分配
        }
        
        void cache_t::reallocate(mask_t oldCapacity, mask_t newCapacity) {
            bool freeOld = canBeFreed();
            //拿到原有buckets
            bucket_t *oldBuckets = buckets();
            //创建一个新的buckets
            bucket_t *newBuckets = allocateBuckets(newCapacity);
            assert(newCapacity > 0);
            assert((uintptr_t)(mask_t)(newCapacity-1) == newCapacity-1);
            //设置新的buckets 和 mask（capacity - 1）
            setBucketsAndMask(newBuckets, newCapacity - 1);
            //抹掉原有buckets的数据
            if (freeOld) {
                cache_collect_free(oldBuckets, oldCapacity);
                cache_collect(false);
            }
        }
* 🤔思考:当扩容的时候,为什么要创建新的哈希表buckets,来抹掉旧的buckets数据,而不是在旧的buckets基础上进行扩容?
        1.减少对方法快速查找流程的影响：调用objc_msgSend时会触发方法快速查找，
        如果进行扩容需要做一些读写操作，对快速查找影响比较大。
        2.对性能要求比较高：开辟新的buckets空间并抹掉原有buckets的消耗比在原有buckets上进行扩展更加高效
        
* 问题4: 当子类没有实现方法的时候,会调用父类的方法,会将父类方法加入到子类自己的cache里

* 问题5: 什么时候缓存到cache中

        objc_msgSend第一次发送消息会触发方法查找，找到方法后会调用cache_fill()方法把方法缓存到cache中
        
        cache_fill核心代码
        void cache_fill(Class cls, SEL sel, IMP imp, id receiver) {
            mutex_locker_t lock(cacheUpdateLock);  //lock-线程锁,保证线程安全
            cache_fill_nolock(cls, sel, imp, receiver);  //填充cache
        }
        
        static void cache_fill_nolock(Class cls, SEL sel, IMP imp, id receiver) {

            //如果能找到缓存就直接返回，确保没有其它线程把方法加入到cache中
            if (cache_getImp(cls, sel)) return;
            
           
            cache_t *cache = getCache(cls);       //获取cls的cache
            cache_key_t key = getKey(sel);        //换算出sel的key

            mask_t newOccupied = cache->occupied() + 1;  //加上即将加入缓存的占用数
            mask_t capacity = cache->capacity();         //拿到当前buckets的容量
            if (cache->isConstantEmptyCache()) {         //当cache为空时，则重新分配空间；
                //当 capacity == 0时 ，使用最小的缓存空间 INIT_CACHE_SIZE = 4
                cache->reallocate(capacity, capacity ?: INIT_CACHE_SIZE);
            } else if (newOccupied <= capacity / 4 * 3) {  
                //使用的空间newOccupied<=3/4, 不需要扩容
            } else {
                //使用的空间 newOccupied > 3/4, 对cache进行扩容
                cache->expand();
            }
            //find 使用hash找到可用的bucket指针
            bucket_t *bucket = cache->find(key, receiver);
            //判断 bucket 是否可用，如果可用对齐occupied +1
            if (bucket->key() == 0) cache->incrementOccupied();
            //把缓存方法放到bucket中
            bucket->set(key, imp);
        }

* 问题6: 当调用方法的时候,先从方法缓存cache_t列表中查找**imp**,如果找到就调用,没有就走普通流程,找到后就缓存到cache_t中

#### 4. objc_class中其它的成员
        方法
        struct method_t {
            SEL name;              //函数名
            const char *types;     //包含了函数返回值、参数编码的字符串
            IMP imp;               //指向函数的指针(函数地址)
        };
        属性
        struct property_t {
            const char *name;
            const char *attributes;
        };
        





### 二,Runtime特性之方法调用和消息转发
#### OC中所有方法的调用都是通过Runtime实现的,Runtime进行方法发送本质上是发送消息,通过objc_msgSend()函数进行消息发送
