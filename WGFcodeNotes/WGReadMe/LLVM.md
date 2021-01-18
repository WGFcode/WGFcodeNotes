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


