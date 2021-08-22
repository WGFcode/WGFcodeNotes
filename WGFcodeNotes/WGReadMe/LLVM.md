## LLVM (http://www.llvm.org)
#### 1. The LLVM Project is a collection of modular and reusable compiler and toolchain technologies,LLVM项目是模块化、可重用的编译器以及工具链技术的集合.LLVM并不是首字母的什么的缩写,它是项目的全名,它就叫做LLVM项目


#### 2. 传统编译器架构
    Source Code ---> Frontend ---> Optimizer ---> Backend ---> machine Code
      源代码            前端           优化器           后端          机器码
      
1.  Frontend(前端): 词法分析、语法分析、语义分析、生成中间代码
2. Optimizer(优化器): 中间代码优化
3. Backend(后端): 生成机器码

#### 3. LLVM架构
#### 不同的语言使用的前端编译器是不一样的 后端也是不一样的架构,但是中间的优化器是一样的
        Fronted                     Optimizer              Backend
    C ---> Clang C/C++/Objc                            LLVM X86 Backend ---> X86
    Fortran ---> llvm-gcc         LLVM  Optimizer      LLVM PowerPC Backend ---> PowerPC
    Haskell ---> GHC                                   LLVM ARM Backend ---> ARM

1. 不同的前端后端使用的都是统一的中间代码 LLVM Intermediate Representation (LLVM IR)
2. 不管什么编程语言,不管编译器的前端是什么,只要是基于LLVM架构的,最终生成的中间代码格式都是LLVM IR
3. 如果需要支持一种新的编程语言,那么只需要实现一个新的前端即可
3. 如果需要支持一种新的硬件设备,那么只需要实现一个新的后端即可
4. 优化阶段是一个通用的阶段,它针对的是统一的LLVM IR,不论是支持新的编程语言还是新的硬件设备,都不需要对优化阶段做修改
5. 相比之前,GCC的前端和后端没分得太开,前端后端耦合在一起.所以GCC为了支持一门新的语言,或者支持新的设备,就变的很难, 因为GCC需要实现9个编译器,而LLVM只需要实现6个即可
6. LLVM现在被作为实现各种静态和运行时编译语言的通用基础结构(GCC、Java、.NET、Python、Ruby等)

#### 4. Clang
#### Clang是LLVM项目的一个子项目. 是基于LVVM架构的C/C++/Objective-C编译器前端, 即Clang是属于LLVM架构的前端

#### 4.1 Clang优点(相对于GCC)
1. 编译速度快: Clang编译速度显著快过GCC
2. 占用内存小: Clang生成的AST(语法树)占用的内存是GCC的五分之一
3. 模块化设计: Clang采用基于库的模块化设计,易于IDE集成及其他用途的重用
4. 诊断信息可读性强: 编译过程,clang创建并保留了大量的元数据,利于调试和
5. 设计清晰简单,容易理解.易于扩展增强


#### 5. Clang与LLVM
    LLVM架构
                        
                        词法分析
                        语法分析
                   语意分析、生成中间代码      以上均属于Clang
                           |
                        代码优化            优化器
                           |
                       生成目标程序          后端
                       
       C/C++/OC ---> Frontend ---> IR ---> pass ---> IR ---> pass ---> IR ---> Backend ---> machine Code
                      clang        ----------------------LLVM Proper------------------
#### 广义的LLVM指的就是整个LLVM架构; 狭义的LLVM指的就是LLVM后端(代码优化、目标代码生成)
  
#### 6. OC 源文件的编译过程
1. 命令行查看编译的过程: clang -ccc-print-phases main.m
2. 查看预处理的结果: clang -E main.m
           
#### 2. 学习LLVM能干什么事情? 比如编译器插件


#### 7. swift和OC中利用LLVM研究底层源码
1. swfit使用前端编译器swiftc，降级编译成IR，再通过后端编译器LLVM生成.o可执行文件
2. OC使用前端编译器Clang编译出IR，再通过后端编译器LLVM生成.o可执行文件

#### swift编译过程

    swift源码--->Parse--->AST--->Sema--->SILGen--->SIL--->IRGen--->IR--->LLVM--->*.o文件
1. Parse解析：swift源码通过词法分析、语法分析生成AST抽象语法树：xcrun swiftc -dump-ast main.swift
2. SILGen:生成swift中间语言，要在此阶段之后获得未优化的 SIL代码：xcrun swiftc -emit-silgen main.swift
3. SIL优化：对生成的SIL执行一些性能优化获取到SIL文件(类似OC探索中的cpp文件)：xcrun swiftc -emit-sil main.swift
4. IRGen: 通过IRGen生成IR：xcrun swiftc -emit-ir main.swift
5. 最终生成二进制代码


#### swiftc编译器
    swiftc -h                         :查看swiftc有哪些命令
    swiftc -dump-ast main.swift       :语法和类型检查，打印AST语法树
    swiftc -dump-parse main.swift     :语法检查，打印AST语法树
    swiftc -emit-ir  main.swift       :展示IR中间代码
    swiftc -emit-sil  main.swift      :展示标准的SIL文件
    swiftc -emit-silgen main.swift    :展示原始SIL文件
    swiftc -parse main.swift          :解析文件
    swiftc -print-ast main.swift      :解析文件并打印（漂亮/简洁的）语法树
    swiftc -emit-sil main.swift > ./main.sil     :生成标准的SIL文件到指定的目录下
#### SIL文件中可能会混写一些数字字母的字符串(类似@$s4main6personAA7TeacherCvp),我们可以通过xcrun命令还原混写后的字符串

    localhost:test1111111 baicai$ xcrun swift-demangle s4main6personAA7TeacherCvp
    $s4main6personAA7TeacherCvp ---> main.person : main.Teacher
    localhost:test1111111 baicai$ 
