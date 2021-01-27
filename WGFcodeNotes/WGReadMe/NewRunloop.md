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
