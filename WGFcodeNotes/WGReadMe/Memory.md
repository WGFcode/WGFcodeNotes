## 内存管理


### 一 自动释放池AutoreleasePool  https://www.jianshu.com/p/9c8139fc3100
#### 1 自动释放池简介
#### Autorelease机制是为了延时释放对象, OC对象的生命周期取决于引用计数, 有两种方式可以释放对象: (1)直接调用release释放(2)调用autorelease将对象加入自动释放池中。而自动释放池用来存放那些需要在某个时刻(当次的RunLoop事件循环将要结束的时候会释放掉)释放的对象,如果没有自动释放池而给对象发送autorelease消息,控制台会报错,但一般我们不需要担心自动释放池的创建问题,系统会自动创建一些线程,例如主线程和GCD中的线程,都默认拥有自动释放池,每次执行“事件循环”(event loop)时，就会将自动释放池清空,简单说就是在当次的RunLoop将要结束的时候调用objc_autoreleasePoolPop，并push进来一个新的AutoreleasePool

#### 2. 自动释放池的底层结构 https://www.jianshu.com/p/afdf1e081fa2
####  1.1 自动释放池的底层结构是以栈为节点，以双向链表形式组合而成的一个数据结构。通俗讲自动释放池是以多个AutoreleasePoolPage为结点，通过链表的方式串连起来的结构，这一整串就是自动释放池,即每个自动释放池都是由若干个AutoreleasePoolPage组成的双向链表结构。每个AutoreleasePoolPage对象占用4096个字节,除了存放它内部的成员变量,剩下的用来存放autorelease对象的地址,所有的AutoreleasePoolPage对象通过双向链表的形式连接在一起

#### 1.2 AutoreleasePoolPage中的parent、child指针分别指向上一个和下一个page,当前page的空间被占满(每个AutorelePoolPage的大小为4096字节)时，就会新建一个AutorelePoolPage对象并连接到链表中，后来的 Autorelease对象也会添加到新的page中；另外，当next== begin()时，表示AutoreleasePoolPage为空；当next == end()，表示AutoreleasePoolPage已满。

        class AutoreleasePoolPage {
            #define EMPTY_POOL_PLACEHOLDER ((id*)1)  //空池占位
            #define POOL_BOUNDARY nil                //边界对象(即哨兵对象）
            magic_t const magic;        //校验AutoreleasePagePoolPage结构是否完整
            id *next;                   //指向新加入的autorelease对象的下一个位置，初始化时指向begin()
            pthread_t const thread;     //当前所在线程，AutoreleasePool是和线程一一对应的
            AutoreleasePoolPage * const parent;  //双向链表中指向父节点page，第一个结点的parent值为nil
            AutoreleasePoolPage *child;          //双向链表中指向子节点page，最后一个结点的child值为nil
            uint32_t const depth;                //链表深度，节点个数
            uint32_t hiwat;                      //数据容纳的一个上限
        }
        
#### 1.3 哨兵对象(边界对象)(POOL_BOUNDARY)的作用
        #define POOL_BOUNDARY nil
#### 边界对象其实就是nil的别名,作用也就是为了起到一个标识的作用,每当自动释放池初始化调用objc_autoreleasePoolPush方法时，总会通过AutoreleasePoolPage的push方法，将POOL_BOUNDARY放到当前page的栈顶，并且返回这个边界对象;而在自动释放池释放调用objc_autoreleasePoolPop方法时，又会将边界对象以参数传入，这样自动释放池就会向释放池中对象发送release消息，直至找到第一个边界对象为止


#### 3 自动释放池释放
        @autoreleasepool {
            id obj = [[NSObject alloc]init];
        }
        编辑器会将上面的代码转为, 整个程序中push和pop的操作都是一一对应的
        void *atautoreleasepoolobj = objc_autoreleasePoolPush(void)
        id obj = [[NSObject alloc]init];
        objc_autoreleasePoolPop(atautoreleasepoolobj)
        
#### 下面我们通过Runtime源码了解下详细的方法含义
#### 3.1 push的调用方法
        //调用方法1
        void * _objc_autoreleasePoolPush(void) {
            return objc_autoreleasePoolPush();
        }
        //调用方法2
        void * objc_autoreleasePoolPush(void) {
            return AutoreleasePoolPage::push();
        }
        //调用方法3
        static inline void *push() {
            id *dest;
            if (DebugPoolAllocation) { // Each autorelease pool starts on a new pool page.
                dest = autoreleaseNewPage(POOL_BOUNDARY);
            } else {
                dest = autoreleaseFast(POOL_BOUNDARY);
            }
            return dest;
        }
        //调用方法4
        //这个函数的作用就是，找到最顶层的一个AutoreleasePoolPage对象，如果没有那就创建一个；
        //如果找到了，判断他是否已经装满了full()，因为一个AutoreleasePoolPage只有4096个字节大小，
        //如果满了那就会调用autoreleaseNoPage()创建一个AutoreleasePoolPage对象并添加add；如果没满则直接执行add(obj)。
        static inline id *autoreleaseFast(id obj) {
            //hotPage()函数会对应线程去取自动释放池，这里也可以看出释放池和线程是一一对应的关系
            AutoreleasePoolPage *page = hotPage();
            if (page && !page->full()) {
                //obj是一个POOL_BOUNDARY对象(哨兵对象)，并不是我们的autorelease的对象
                //每次执行push操作时都会插入一个哨兵对象，并且把哨兵对象的地址作为返回值返回了,pop函数需要用到这个哨兵对象的地址
                //对应的每次pop都是寻找到上一个哨兵对象，对期间所有的autorelease对象执行一次release操作。
                return page->add(obj);
            } else if (page) {
                return autoreleaseFullPage(obj, page);
            } else {
                return autoreleaseNoPage(obj);
            }
        }
#### 观察上述代码，每次调用push其实就是创建一个新的AutoreleasePool，在对应的AutoreleasePoolPage中插入一个POOL_BOUNDARY,并且返回插入的POOL_BOUNDARY的内存地址。push方法内部调用的是autoreleaseFast方法，并传入边界对象(POOL_BOUNDARY)。hotPage可以理解为当前正在使用的AutoreleasePoolPage。自动释放池最终都会通过page->add(obj)方法将边界对象添加到释放池中，而这一过程在autoreleaseFast方法中被分为三种情况：
1. 当前page存在且不满,调用page->add(obj)方法将对象添加至page的栈中，即next指向的位置
2. 当前page存在但是已满,调用autoreleaseFullPage初始化一个新的page，调用page->add(obj)方法将对象添加至page的栈中
3. 当前page不存在时,调用autoreleaseNoPage创建一个hotPage，再调用page->add(obj) 方法将对象添加至page的栈中

#### 3.2 Pop函数
#### AutoreleasePool的释放调用的是objc_autoreleasePoolPop方法，此时需要传入边界对象作为参数。这个边界对象正是每次执行objc_autoreleasePoolPush方法返回的对象atautoreleasepoolobj；
        //调用方法1
        void _objc_autoreleasePoolPop(void *ctxt) {
            objc_autoreleasePoolPop(ctxt);
        }
        //调用方法2:
        void objc_autoreleasePoolPop(void *ctxt) {
            AutoreleasePoolPage::pop(ctxt);
        }
        //调用方法3: 核心方法 向栈中的对象发送release消息，直到遇到第一个哨兵对象
        void releaseUntil(id *stop)  {
            while (this->next != stop) { //一直遍历
                // Restart from hotPage() every time, in case -release 
                // autoreleased more objects
                AutoreleasePoolPage *page = hotPage();
                // fixme I think this `while` can be `if`, but I can't prove it
                // 如果当前page中的autorelease对象已释放完毕则会重新遍历父结点的page，知道找到传递来的哨兵对象为止
                while (page->empty()) {
                    page = page->parent;
                    setHotPage(page);
                }
                page->unprotect();
                id obj = *--page->next;
                memset((void*)page->next, SCRIBBLE, sizeof(*page->next));
                page->protect();

                if (obj != POOL_BOUNDARY) {
                    objc_release(obj);
                }
            }
            setHotPage(this);
            #if DEBUG
            // we expect any children to be completely empty
            for (AutoreleasePoolPage *page = child; page; page = page->child) {
                assert(page->empty());
            }
            #endif
        }
#### 首先根据传入的边界对象地址找到边界对象所处的page；然后选择当前page中最新加入的对象一直向前清理，可以向前跨越若干个page，直到边界所在的位置；清理的方式是向这些对象发送一次release消息，使其引用计数减一；另外，清空page对象还会遵循一些原则：
1. 如果当前的page中存放的对象少于一半，则子page全部删除；
2. 如果当前的page存放的多余一半,(意味着马上将要满),则保留一个子page,节省创建新page的开销;


#### 4. autorelease方法
#### autorelease方法最终也会调用上面提到的autoreleaseFast方法,将当前对象加到AutoreleasePoolPage中。
autorelease函数和push函数一样，关键代码都是调用autoreleaseFast函数向自动释放池的链表栈中添加一个对象，不过push函数入栈的是一个边界对象，而autorelease函数入栈的是一个具体的Autorelease的对象。


#### 5. 自动释放池(autoreleasepool)作用
1. 延迟对象的释放时间
2. 合理运用自动释放池，可以降低程序的内存峰值
3. 可以避免无意间误用那些在清空池之后已被系统回收的对象, 如果用了编辑器会提示的

#### 5.1 @autoreleasepool的作用可以用来降低内存峰值,先看一个面试题
        //面试题: 修改代码中的错误
        for (int i = 0; i < 10000; i++) {
            NSString *str = @"Zhang San";
            str = [str lowercaseString];
            str = [str stringByAppendingString:@"Li Si"];
            NSLog(@"%@",str);
        }
        
#### 分析: stringByAppendingString方法可能会创建一个临时对象,这个临时对象很可能会放在自动释放池中,即便临时对象在调用完方法后就不再使用了，它们也依然处于存活状态,等待系统稍后进行回收,但自动释放池却要等到该线程执行下一次事件循环时才会清空,这就意味着在执行for循环时，会有持续不断的新的临时对象被创建出来，并加入自动释放池。要等到结束for循环才会释放。在for循环中内存用量会持续上涨，而等到结束循环后，内存用量又会突然下降,为了优化性能,我们可以这么解决,通过这种方式可以发现尽管字符串在不断地创建，但由于得到了及时的释放，堆内存始终保持在一个很低的水平。

        for (int i = 0; i < 10000; i++) {
            //在循环中自动释放的对象就会放在这个池，而不是在线程的主池里面
            @autoreleasepool {
                NSString *str = @"Zhang San";
                str = [str lowercaseString];
                str = [str stringByAppendingString:@"Li Si"];
                NSLog(@"%@",str);
            }
        }
#### 5.2 避免无意间误用那些在清空池之后已被系统回收的对象,
        @autoreleasepool {
            id obj = [[NSObject alloc]init];
        }
        [self useObject:obj];
        在编译时就会基于错误警告，因为obj出了自动释放池就不可用了。
#### 6 总结
####  自动释放池排布在栈中，对象受到autorelease消息后，系统将其放入栈顶的池里;自动释放池的机制就像“栈”。系统创建好池之后，将其压入栈中，而清空自动释放池相当于将池从栈中弹出。在对象上执行自动释放操作，
就等于将其放入位于栈顶的那个池;
    
#### 7.AutoreleasePool与NSThread、NSRunLoop的关系
#### 7.1 RunLoop和NSThread的关系
1. RunLoop与线程是一一对应关系,每个线程(包括主线程)都有一个对应的RunLoop对象,其对应关系保存在一个全局的Dictionary里；
2. 主线程的RunLoop默认由系统自动创建并启动；而其他线程在创建时并没有RunLoop，若该线程一直不主动获取，就一直不会有RunLoop；
3. 苹果不提供直接创建RunLoop的方法；所谓其他线程Runloop的创建其实是发生在第一次获取的时候，系统判断当前线程没有RunLoop就会自动创建；
4. 当前线程结束时，其对应的Runloop也被销毁；

#### 7.2 RunLoop和AutoreleasePool的关系
#### 主线程的NSRunLoop在监测到事件响应开启每一次event loop之前，会自动创建一个autorelease pool，并且会在event loop结束的时候执行drain操作，释放其中的对象。

#### 7.3 Thread和AutoreleasePool的关系
#### 包括主线程在内的所有线程都维护有它自己的自动释放池的堆栈结构。新的自动释放池被创建的时候，它们会被添加到栈的顶部，而当池子销毁的时候，会从栈移除。对于当前线程来说，Autoreleased对象会被放到栈顶的自动释放池中。当一个线程线程停止，它会自动释放掉与其关联的所有自动释放池。

#### 8. AutoreleasePool在线程上的释放时机
#### 8.1 主线程上自动释放池的使用过程如下
1. App启动后，苹果在主线程RunLoop里注册了两个Observer
2. 第一个Observer监视的事件是Entry(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush()创建自动释放池
3. 第二个Observer监视了两个事件

        BeforeWaiting(准备进入休眠)时调用_objc_autoreleasePoolPop()和_objc_autoreleasePoolPush()释放旧的池并创建新池；
        Exit(即将退出Loop) 时调用 _objc_autoreleasePoolPop()来释放自动释放池。
4. 在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop创建好的AutoreleasePool环绕着，所以不会出现内存泄漏，开发者也不必显示创建AutoreleasePool了;

6. 程序启动到加载完成后，主线程对应的RunLoop会停下来等待用户交互
7. 用户的每一次交互都会启动一次运行循环，来处理用户所有的点击事件、触摸事件。
8. RunLoop检测到事件后，就会创建自动释放池;
9. 所有的延迟释放对象都会被添加到这个池子中;
10. 在一次完整的运行循环结束之前，会向池中所有对象发送release消息，然后自动释放池被销毁;

#### 8.2 AutoreleasePool子线程上的释放时机
#### 子线程默认不开启RunLoop,那么其中的延时对象该如何释放呢?依然要从Thread和AutoreleasePool的关系来考虑：每一个线程都会维护自己的 Autoreleasepool栈，所以子线程虽然默认没有开启RunLoop，但是依然存在AutoreleasePool，在子线程退出的时候会去释放autorelease对象。所以，一般情况下，子线程中即使我们不手动添加自动释放池，也不会产生内存泄漏。

#### 9. AutoreleasePool需要手动添加的情况
#### 尽管ARC已经做了诸多优化，但是有些情况我们必须手动创建AutoreleasePool，而其中的延时对象将在当前释放池的作用域结束时释放.苹果文档中说明了三种情况，我们可能会需要手动添加自动释放池：
1. 编写的不是基于UI框架的程序，例如命令行工具；
2. 通过循环方式创建大量临时对象；
3. 使用非Cocoa程序创建的子线程；

#### https://www.jianshu.com/p/7bd2f85f03dc
