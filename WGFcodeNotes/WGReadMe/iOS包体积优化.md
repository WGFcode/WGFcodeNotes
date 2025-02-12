### ios包体积优化 (这里以NXYXE有案例进行分析)


#### 1.准备NXYXE.ipa包，然后将其后缀修改为NXYXE.zip，然后解压缩, 选择NXYXE右键显示包内容
    NXYXE.ipa -> NXYXE.zip ->解压缩 -> Payload -> NXYXE
1. _CodeSignature: ipa包签名文件的存放文件夹
2. Assets.car: Assets.xcassts在编译过程中生成的最终展示文件，默认里面存放各种分辨率图片
3. embedded.mobileprovision: 证书配置文件
4. Info.plist：项目配置表
5. Plugins：App创建的扩展，比如推送扩展等(这里没有推送扩展，所以没有改文件夹)
6. .Iproj：App所支持的语言文件
7. exec文件：可执行文件
8. 图片资源：.png，.jpg，.webp，.gif
9. 其它资源文件：
        项目中使用资源的.plist文件、.xml、.json；
        相关的证书配置文件.cer，.der，.p12；
        音频文件.wav、.m4a 

#### 2. 各文件大小
NXYXE.ipa   38.8MB       解压缩后67.6MB

_CodeSignature                 250KB
Assets.car（部分使用）           9.6MB
embedded.mobileprovision       18KB
Info.plist                     4KB
Plugins                        不存在
Iproj                          1KB
exec                           29.1MB
图片资源（.png，.jpg，.webp，.gif）144KB
others                         28.5MB

#### 3. 知道ipa内部组成后，我们优化包体积主要从以下三方面进行优化
一、Xcode编译优化：一次设置永久有效，不需要持续关注       
二、资源文件优化        
三、代码优化            

#### 4. Xcode编译优化
#### 4.1编译指令集: 就是剔除项目中不需要适配的架构

##### 首先查看我们项目目前支持的架构组成
终端执行 **lipo -info NXYXE**，注意这里的NXYXE是ipa包中的exec可执行文件，执行终端后显示的架构是：armv7 arm64
#### 下面是各个架构指令集对应的机型
(1)armv6: iPhone, iPhone 3G, iPod 1G/2G  
(2)armv7: iPhone 3GS, iPhone 4, iPhone 4S, iPod 3G/4G/5G, iPad, iPad 2, iPad 3, iPad Mini  
(3)armv7s: iPhone 5, iPhone 5c, iPad 4  
(4)arm64: iPhone X，iPhone 8(Plus)，iPhone 7(Plus)，iPhone 6(Plus)，iPhone 6s(Plus), iPhone 5s, iPad Air(2), Retina iPad Mini(2,3)  
(5)arm64e: XS/XS Max/XR/ iPhone 11, iPhone 11 pro,iPhone 11 Pro Max,iPhone SE (2nd generation),iPhone 12 mini,iPhone 12,iPhone 12 Pro,iPhone 12 Pro Max,Phone 13 mini,Phone 13,iPhone 13 Pro,iPhone 13 Pro Max
(6)x86_64: 模拟器64位处理器
(7)i386: 模拟器32位处理器

#### 我们可以发现项目中我们是不需要支持armv7架构的，所以我们可以设置在打包的时候进行只打armv64即可。解决方法如下
##### 方法一：Build Settings-Architectures，把你需要的打包标识符下的设置为arm64；
Architectures指定工程可以编译出多个指令集的代码包，ipa就会变大；
##### 方法二：Build Settings-Excluded Arcitectures，在你要的打包标识符下面增加两个配置项目Any iOS SDK和Any iOS Simulator SDK，然后分别设置为armv7和arm64；这个选项的意思是Release模式下针对真机armv7指令集排除，针对模拟器把arm64排除。



#### 4.2 Xcode中设置代码优化
#### Build Settings-Optimization Level在发布模式设置为[-Oz]，其他模式根据场景进行选择；这个设置指的是生成的代码在速度和二进制大小方面的优化程度；Optimization Level默认是-Os，-Oz是Xcode 11新增的编译优化选项，该设置通过将重复的代码模式隔离到编译器生成的函数中来实现额外的尺寸节省
#### 以下是不同的选项对应的编译速度和二进制文件大小变化趋势      

        ｜
        ｜    -o3
        ｜            -o2
        ｜                     -os
        ｜                              -oz          
        ｜


#### 4.3 Xcode中设置资源目录优化
#### Build Settings-Asset Catalog Compiler Options-Optimization设置为space；这个选项可以改变actool在构建Assets.car时选取的编码压缩算法，减少包大小
#### 使用以下命令检查Assets.car中图片的编码压缩算法： xcrun --sdk iphoneos assetutil --info Assets.car > Assets.json



#### 4.4 Xcode中设置调试符号
#### Build Settings-Generate Debug Symbols设置为NO；这个选项的意思是是否在源文件编程成.o文件时，添加编译参数-g和-gmodule，就是generate complete debug info，所以产生的.o会变大，从而最终的可执行文件也就会变大。
#### 需要注意的是，如果设置为NO，在Xcode中设置断点不会中断，不能进行断点调试。且最后不能生成dSYM文件，即使Debug Infomation Format设置了，也无法生成，因为生成的前提是得有调试信息，建议不要设置。


#### 4.5 Xcode中设置无用符号
#### Build Settings-Deployment Postprocessing，调试模式下NO，发布模式下YES
#### Deployment Postprocessing是Strip的总开关。也就是说，只有Deployment Postprocessing这里设置了YES，Strip Debug Symbols During Copy和Strip Linked Product设置为YES才会生效，其余情况均不生效
(1)Strip Linked Product：对最终的二进制文件是否进行去除无用符号
(2)Strip Debug Symbols During Copy：文件拷贝编译阶段是否进行strip，设置为YES之后，会把拷贝进项目的第三方库、资源或者Extension的调试符号剥离


#### 4.6 Xcode中设置复用字符串
#### Build Settings-Make Strings Read-Only设置为YES；就是复用字符串字面。


#### 4.7 Xcode中设置无效代码
#### Build Settings-Dead Code Stripping设置为YES；是否消除无用代码



#### 5. 资源文件优化
#### 资源的优化需要平时开发就需要关注，比如新资源的压缩，无用资源的删除等。资源文件优化大体分为两个方向，第一个就是无用资源的删除，第二个就是已用资源的压缩
#### 已定义未使用的代码：推荐使用AppCode来静态检查无用代码，虽然AppCode完成了大部分的工作，但是还是有一些问题存在：1.子类使用了父类的方法，父类的这个方法会判断为未使用；2.通过点语法使用属性，该属性会被认为未使用；3.使用performSelector方式调用的方法检查不出来等问题

#### 已引入未使用的图片: 推荐使用LSUnusedResource检测项目中无用的图片资源
#### 某些重复资源的导入，重复资源分为静态库和项目文件；针对静态库，有多个相似功能进行需求整合，把最优解决方案的静态库留下；针对项目文件，可以使用fdupes工具进行重复文件扫描，该工具的原理是通过校验所有的资源的MD5值，筛选出项目中重复的资源，文件比较顺序是
    文件大小 > 部分MD5签名对比 > 完整MD5签名对比 > 逐字节对比

#### fdupes的安装和使用
###### install fdupes
$ brew install fdupes 
###### where xxx is the directory to be scanned, and xxxFdupesResult.txt is the output file of the scan result
$ fdupes -Sr /User/augus/Documents/xxx > /User/augus/Documents/xxxFdupesResult.txt

#### 5.1图片的压缩
#### 将图片放入xcassets，因为xcassets里的@2x和@3x图片，在上传时，会根据具体设备分开对应分辨率的图片，不会同时包含。而放入.bundle中的都会包含，所以要尽量把图片放入xcassets中。Assets.car编译过程中有时会选择一些图片，拼凑成一张大图来提高图片的加载效率。被放进这张大图的小图会变为通过偏移量的引用，建议使用频率高且小的图片放到xcassets中，xcassets能保证加载和渲染速度最优。

#### 大于100KB就不要放入xcassets中了。大的图片可以考虑将图片转成WebP。WebP是Google公司的一个开源项目，能够把图片压缩到很小，但是肉眼看不出来差别，目前iOS常用的图片显示类库都支持该格式解析的拓展。可使用[WebP Converter - AnyWebP](https://apps.apple.com/us/app/webp-converter-anywebp/id1527716894?mt=12) 进行批量转换



### 1. bitcode是什么
#### bitcode是被编译程序的一种中间形式的代码。包含bitcode配置的程序将会在App store上被编译和链接。bitcode允许苹果在后期重新优化我们程序的二进制文件，而不需要我们重新提交一个新的版本到App store上
#### 当我们提交程序到App store上时，Xcode会将程序编译为一个中间表现形式(bitcode)。然后App store会再将这个botcode编译为可执行的64位或32位程序
#### 给 App 瘦身的另一个手段是提交 Bitcode 给 Apple，而不是最终的二进制。Bitcode 是 LLVM 的中间码，在编译器更新时，Apple 可以用你之前提交的 Bitcode 进行优化，这样你就不必在编译器更新后再次提交你的 app，也能享受到编译器改进所带来的好处。Bitcode 支持在新项目中是默认开启的，没有特别理由的话，你也不需要将它特意关掉。

#### 从pem证书中提取公钥 wgmem.cer是公钥的格式为cer格式, 需要添加-outform DER参数
// OpenSSL在提取公钥时不会改变公钥的编码格式。公钥通常以PEM格式输出，即Base64编码的ASCII码。如果你需要DER格式（二进制），可以添加-outform DER参数。
    输出的wgmem.cer可以通过文本编译.app打开
    openssl x509 -in wgmem.pem -pubkey -out wgmem.cer
    输出的wgmem.cer 【不可以】通过文本编译.app打开，会提示文本编码Unicode(UFT-8)不适用,DER 格式使用二进制编码，将数据以二进制形式保存不经过 Base64 编码,DER 格式的文件是二进制文件，不可读
    openssl x509 -in wgmem.pem -pubkey -outform DER -out wgmem.cer
    
#### PEM和DER格式的区别
PEM
编码方式： PEM格式适用Base64编码将二进制数据转换为文本形式，并在数据开始和结束部分加上标头和尾部，如"BEGIN CERTIFICATE"和"END CERTIFICATE"

文件扩展名：PEM 格式的文件通常以 .pem、.crt、.cer 或 .key 结尾。

可读性： 由于使用 Base64 编码，PEM 格式的文件是文本文件，可以被文本编辑器打开查看，也可以在终端中输出查看内容

支持的数据类型： PEM 格式可以用来表示证书（包括 X.509 证书）、私钥、公钥等
https://blog.csdn.net/ARV000/article/details/134099324

DER
编码方式： DER 格式使用二进制编码，将数据以二进制形式保存，不经过 Base64 编码。

文件扩展名： DER 格式的文件通常以 .der 或 .cer 结尾。

可读性： DER 格式的文件是二进制文件，不可读，需要专用的工具或编程语言解析。

在实际使用中支持的数据类型： DER 格式同样可以用来表示证书、私钥、公钥等。
PEM 格式常用于人可读的配置文件，而 DER 格式通常用于机器间的数据交换，因为它更紧凑且不需要进行 Base64 编码解码
                     
#### 格式转换
openssl x509 -in cert.der -outform PEM -out cert.pem   //der转换为 PEM 格式  指定输出格式为 PEM
openssl x509 -in cert.pem -outform DER -out cert.der   //PEM 转换为 DER 格式 指定输出格式为 DER








































