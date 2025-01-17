## Instruments(仪器) APP性能分析工具简介


#### 1.System Trace(系统跟踪)
#### 介绍翻译:全面了解操作系统中正在发生的事情。了解线程是如何跨CPU调度的，并了解系统调用和虚拟内存故障是如何影响应用程序性能的。

#### 2.Time Profiler(时间分析器): 显示APP中各个函数的执行时间        
#### Time Profiler每隔1ms，Instruments会暂停程序的执行，会对运行线程的堆栈进行采样，通过对比堆栈，推算出来方法的执行时间    
帮助我们分析代码/方法的执行时间，找出程序变慢的原因，告诉我们那些方法使用时间较多，可以进行响相应的优化

![图片](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/timerProfile.png)
   
* 设置编译条件

        (1)必须真机调试 
        (2)Release模式下: 因为会开启编译器优化提高代码运行效率
        (3)设置Debug Information Format -> DWARF with dSYM File开启调试符号，即dsym格式文件
* 打开Time Profiler工具，然后Xcode运行项目同时点击Instruments工具中的录制/暂停按钮
     
        (1)选中Time Profiler、选中Profile
        (2)Call Tree选项中 勾选           
                Separate by Thread  
                Hide systerm Libraries 
                Invert call tree 
        (3)Call Tree Constraints 中Min 选择2 表示过滤掉2ms秒以下的调用堆栈信息
* 通过截图上面的内容我们可以发现哪些方法调用比较耗时，然后进行相应的优化
        










#### 3.Leaks(泄漏)工具
* 分析内存泄漏问题。它会监测应用程序的内存分配和释放情况，并标记出可能存在的内存泄漏点

#### 4.Allocations(分配)工具
* 监测应用程序的内存分配情况。通过查看对象的生命周期和内存使用情况，可以找到潜在的内存泄漏问题，并进行优化

#### 5.Zombies(僵尸)工具
* 检测应用程序中的僵尸对象。当一个对象被释放后，如果还有其他代码尝试访问该对象，就会导致僵尸对象的出现
