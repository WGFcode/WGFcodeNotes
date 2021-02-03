## RunLoop
### 面试题
1. 讲讲RunLoop,项目中有用到吗?
2. Runloop内部实现逻辑
3. RunLoop和线程的关系
4. timer和RunLoop关系
5. 程序中添加每3秒响应一次的NSTimer,当拖动tableview时,timer可能无法响应怎么解决?
6. runloop是怎么响应用户操作的,具体流程是什么样的?
7. 说说RunLoop的几种状态
8. RunLoop的mode作用是什么

### 1. 什么是RunLoop
#### RunLoop就是运行循环,在程序运行过程中循环做一些事情,做了哪些事情?应用范畴是?
1. 定时器(NSTimer)、performSelector
2. GCD Async Main Queue
3. 事件响应、手势识别、界面刷新
4. 网络请求
5. AutoreleasePool自定释放池

#### 如果没有RunLoop程序会立马退出; 如果有RunLoop,程序并不会马上退出,而是保持运行状态,RunLoop基本作用有
1. 保持程序的持续运行
2. 处理APP中的各种事件(比如触摸事件、定时器事件)
3. 节省CPU资源,提高程序性能: 该做事时做事,该休息时休息
4. RunLoop其实内部很像是个do-while循环

### 2. RunLoop对象
#### iOS中有2套API来访问和使用RunLoop,NSRunLoop和CFRunLoopRef都代表着RunLoop对象
1. Foundation: NSRunLoop(基于CFRunLoopRef的一层OC包装)
2. Core Foundation: CFRunLoopRef(是开源的:https://opensource.apple.com/tarballs/CF/)

### 3. RunLoop与线程的关系
* 每条线程都有唯一的一个与之对应的RunLoop对象
* RunLoop保存在一个全局的Dictionary字典里,线程作为Key,RunLoop作为value
* 线程刚创建时并没有RunLoop对象,RunLoop会在第一次获取它时创建
* RunLoop会在线程结束时销毁
* 主线程的RunLoop已经自动获取(创建),子线程默认没有开启RunLoop

### 4. RunLoop相关的类
#### Core Foundation关于RunLoop的5个类
1. CFRunLoopRef
2. CFRunLoopModeRef: 代表RunLoop的运行模式
3. CFRunLoopSourceRef
4. CFRunLoopTimerRef
5. CFRunLoopObserverRef

        typedef struct __CFRunLoop * CFRunLoopRef;
        struct __CFRunLoop {
            pthread_t _pthread;                 //线程
            CFMutableSetRef _commonModes;       //
            CFMutableSetRef _commonModeItems;   //
            CFRunLoopModeRef _currentMode;      //
            CFMutableSetRef _modes;             //(无序)集合,存放的是CFRunLoopModeRef类型
        };
        
        typedef struct __CFRunLoopMode *CFRunLoopModeRef;
        struct __CFRunLoopMode {
            CFStringRef _name;              //model名字
            CFMutableSetRef _sources0;      //装的CFRunLoopSourceRef对象
            CFMutableSetRef _sources1;      //装的CFRunLoopSourceRef对象
            CFMutableArrayRef _observers;   //装的CFRunLoopObserverRef对象
            CFMutableArrayRef _timers;      //装的CFRunLoopTimerRef对象
        }
        
        ----------------------RunLoop-------------------
        mode        mode         mode         mode      ...
        sources0    sources0     sources0     sources0
        sources1    sources1     sources1     sources1
        observers   observers    observers    observers
        timers      timers       timers       timers
* CFRunLoopModeRef代表RunLoop的运行模式
* 一个RunLoop包含若干个Mode,每个Mode又包含若干个Sources0/Sources1/Timer/Observer
* RunLoop启动时只能选择其中一个Mode,作为currentMode
* 如果需要切换Mode,只能退出当前Loop,再选择一个Mode进入(这里的退出并不是退出RunLoop循环,而是在RunLoop循环中退出,所以不会导致程序退出)
* 不同组的Sources0/Sources1/Timer/Observer能分割开来,互不影响(主要就是提高交互,当滚动时在一个Mode中,专心处理滚动的事情就行了)
* 如果Mode里没有任何Sources0/Sources1/Timer/Observer,RunLoop会立马退出
* 常见的两种运行Mode: 

        kCFRunLoopDefaultMode: App的默认Mode,通常主线程是在这个Mode下运行的
        UITrackingRunLoopMode: 界面跟踪Mode,用于scrollView追踪触摸滑动,保证界面滚动不受其他Mode影响

### 5. RunLoop运行逻辑
#### RunLoop就是在循环处理某个Mode下的Sources0/Sources1/Timer/Observer这些事件的
1. Sources0: 触摸事件处理、performSelector: onThread:
2. Sources1: 基于Port(端口)的线程间通信、系统事件捕捉(点击屏幕,先通过Sources1捕捉点击事件,然后交给Sources0去处理)
3. Timers:NSTimer、performSelector: withObject: afterDelay:
4. Observers: 用于监听RunLoop的状态、UI刷新(BeforeWaiting)、Autorelease pool(自动释放池)

        //UI刷新: 下面代码并不是说执行到这句代码就立马执行,而是先记住这件事,
        //等到RunLoop睡眠之前去处理这件事(将页面背景设置为红色),RunLoop没有事件处理就会去睡眠
        self.view.backgroundColor = [UIColor whiteColor];

#### RunLoop运行状态 6 中
        /* Run Loop Observer Activities */
        typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
            kCFRunLoopEntry = (1UL << 0),          //即将进入Loop
            kCFRunLoopBeforeTimers = (1UL << 1),   //即将处理Timer
            kCFRunLoopBeforeSources = (1UL << 2),  //即将处理Sources
            kCFRunLoopBeforeWaiting = (1UL << 5),  //即将进入休眠
            kCFRunLoopAfterWaiting = (1UL << 6),   //刚从休眠中唤醒
            kCFRunLoopExit = (1UL << 7),           //即将退出Loop
            kCFRunLoopAllActivities = 0x0FFFFFFFU  //所有状态
        };
