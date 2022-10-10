### 1. Frameworks, Libraries, and Embedded Content
Do Not Embed: 不嵌入，一般用于静态库
Embed & Sign: 嵌入并且签名，
Embed Without Signing: 嵌入不签名
#### 静态库：链接时完整地拷贝至可执行文件中，被多次使用就有多份冗余拷贝，存在形式：.a和.framework
#### 动态库：链接时不复制，程序运行时由系统动态加载到内存，供程序调用，系统只加载一次，多个程序共用，节省内存。存在形式：.dylib和.framework
#### 嵌入Embed是用于动态库的，Signing：只用于动态库，如果已经有签名了就不需要再签名

#### 如何判断动态库静态库
file Alamofire.framework/Alamofire 
动态库：出现Mach-O 64-bit dynamically linked shared library arm64
静态库: 出现current ar archive，导入项目时选择 “Do Not Embed”

#### 如何判断是否需要签名Signing
codesign -dv Alamofire.framework
如果返回：code object is not signed at all 或 adhoc 选择Embed & Sign
其他的则选择Embed Without Signing


