
#  Framework制作总结
#### iOS中的库分为动态库(.dylib和.framework)和静态库(.a和.framework)
#### 静态库:针对编辑期
静态库在程序编译时会被链接到目标代码中，链接时完整地拷贝至可执行文件中，被多次使用就有多份冗余拷贝
#### 动态库:针对运行期，链接时不复制，程序运行时由系统动态加载到内存，供程序调用，系统只加载一次，多个程序共用，节省内存
#### 注意:静态库不需要签名，但动态库得需要签名

#### 项目使用Framework做静态库的原因:

#### 1.a是一个纯二进制文件，而.framework中除了有二进制文件之外还有头文件和资源文件
#### 2.a文件不能直接使用，至少要有.h文件配合，.framework文件可以直接使用。
.a + .h + sourceFile = .framework
#### 3.framework可以是动态库，也可以是静态库。在库类型的切换上有天然的优势

## 创建静态库流程（非工程中创建）

#### 1.File->New->Target->iOS->Framework & Library -> Framework -> XXXSDK，Team可以选择None，这样FrameWork不参与签名，任何人、组织都可以使用

#### 2.设置SDK运行的最低版本: TARGETS -> Build Setting -> iOS Deployment Target

#### 3.设置为静态库TARGETS -> Build Setting -> Mach-O Type -> 选择Static Library,默认新创建的都为动态库，Link With Standard Libraries 设置为NO，包瘦身 Build Setting ->Dead Code Stripping 是对程序编译出的可执行二进制文件中没有被实际使用的代码进行Strip操作(可改可不改)

#### 4.设置支持的架构 TARGETS -> Build Setting -> Build Active Architecture Only -> NO，YES:仅支持当前运行设备(模拟器或真机)下的架构，NO:支持所有的架构，这样可能会导致编辑过程比较慢，可以暂时设置为YES，上线是一定要设置为NO

#### 5.设置Release模式，Edit Scheme - Run/Test/Profile/Analyze/Archive均设置为Release，因为上线时必须是Release

#### 6.TARGETS —> Build Phases  —> Headers 将需要呈现出来的头文件,直接从Project拖到Public中. 不想呈现出来的.h文件不建议拖到Private中. 放在project中即可，项目中暂时用的swift，所以没关注这个

#### 7.编写相应的功能，然后将所有需要暴露的头文件（OC需要，swift暂时不需要）引用到XXXSDK.h文件中，形如#import <XXXSDK/PublicHeader.h>

#### 8.完成之后，选择真机或模拟器编辑，在项目的Products下，找到XXXSDK.framework,show in finder,会看到对应的文件，Release-iphoneos和Release-iphonesimulator文件夹，对应的分别是真机和模拟器下的SDK，通过lipo合并SDK为真机和模拟器下都能运行的SDK，具体分两种方式

### 方式一:
#### 1)查看framework支持的架构信息: lipo -info /Users/baicai/.../XXXSDK.framework/XXXSDK
#### 2)将模拟器和真机下的SDK进行合并lipo -create 真机SDK路径 模拟器SDK路径 -output 合并后的文件路径: lipo -create /User/baicia/.../(真机)XXXSDK.framework/XXXSDK /User/baicia/.../(模拟器)XXXSDK.framework/XXXSDK -output /User/baicai/Desket/XXXSDK，回车获得合并后的XXXSDK文件
#### 3)找到(真机)XXXSDK.framework，将其XXXSDK文件替换成新合并后的XXXSDK文件，然后将(模拟器)XXXSDK.framework/Modules/XXXSDK.swiftmodule文件下的内容全部拷贝到(真机)XXXSDK.framework下对应的XXXSDK.swiftmodule文件中，重新组成新的(真机)(XXXSDK.framework)
#### 4)将组成新的framework导入到主工程中，并在swift工程的桥接文件中引入自定义的静态库 例: #import <XXXSDK/XXXSDK.h>

#### 合并过程可能会出现类似如下错误：....../Products/Release-iphonesimulator/SwiftMQTT.framework/SwiftMQTT have the same architectures (arm64) and can't be in the same fat output file
#### 原因就是XCode12之前：
* 编译模拟器静态库支持i386 x86_64两架构
* 编译真机静态库支持armv7 arm64两架构
#### XCode12编译的模拟器静态库也支持了arm64，导致出现真机库和模拟器库不能合并的问题。
#### 解决方法
1. 如果手里有静态库工程，在静态库工程中Build Settings -> Excluded Architectures -> Release -> Any iOS Simulator SDK 添加arm64就可以了
2. 如果手里只有.a或framework文件，使用lipo remove命令将模拟器库的arm64架构移除: lipo xxx.a -remove arm64 -output xxx.a


### 方式二:

#### 1.在framework工程中，TARGET -> Build Phases -> + -> New Run Script Phase,添加脚本如下
```
   if [ "${ACTION}" = "build" ]
   then
   INSTALL_DIR=${SRCROOT}/Products/${PROJECT_NAME}.framework
   DEVICE_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework
   SIMULATOR_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework

   # 如果真机包或模拟包不存在，则退出合并
   if [ ! -d "${DEVICE_DIR}" ] || [ ! -d "${SIMULATOR_DIR}" ]
   then
   exit 0
   fi

   # 如果合并包已经存在，则替换
   if [ -d "${INSTALL_DIR}" ]
   then
   rm -rf "${INSTALL_DIR}"
   fi

   #创建INSTALL_DIR路径，即 /Products/XXX.framework
   mkdir -p "${INSTALL_DIR}"

   #将目录DEVICE_DIR下所有内容复制到INSTALL_DIR路径下
   cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"
   #将模拟器下的XXX.framework/Modules/XXX.swiftmodule/目录下的内容复制到Products/XXX.framework/Modules/XXX.swiftmodule
   cp -R "${SIMULATOR_DIR}/Modules/${PROJECT_NAME}.swiftmodule/" "${INSTALL_DIR}/Modules/${PROJECT_NAME}.swiftmodule/"

   # 使用lipo命令将其合并成一个通用framework 
   # 最后将生成的通用framework放置在工程根目录下新建的Products目录下 
   lipo -create "${DEVICE_DIR}/${PROJECT_NAME}" "${SIMULATOR_DIR}/${PROJECT_NAME}" -output "${INSTALL_DIR}/${PROJECT_NAME}"

   #合并完成后打开目录
   open "${SRCROOT}/Products"

   fi
```
#### 2.分别运行编辑器和真机，会自动弹出Products ->XXXSDK.framework，这个就是最终合并的真机和模拟器下都可以运行的静态库,注意检查Modules/XXX.swiftmodule/目录下支持的架构是否合规(包含arm、arm64、armv 7、i386、x86-64等文件)


## 静态库与主工程并存的注意点 （https://www.jianshu.com/p/e05363d700dd）

#### 1.打开主工程 File -> New -> Workspace 名称和工程名称一致，创建完成后，主工程路径下会出现新的文件夹 (主工程名.xcworkspace)
#### 2.  File -> Add Files to "主工程名"... ,然后选择主工程下的(主工程名.xcodeproj)  
#### 遇到错误Multiple commands produce '/Users/baicai/Library/Developer/Xcode/DerivedData/WGBuyBalProject-cfdbrczbjbbauxcnpicupdbicyze/Build/Products/Release-iphoneos/WGWLK.app/Info.plist':
#### 解决:File -> Workspace Settings.... -> Shared Workspace Seetings: -> Build System -> Legacy Build System ->Done
#### 3.打开 “主工程名.xcworkspace”,File -> New -> Project -> iOS->Framework & Library -> Framework,注意Team选择None（即不参与签名）,Next,Add to: 和 Group:  都选择主工程(这个主工程是图标为蓝白色的xcworkspace)
#### 4.设置制作静态库所需的配置，添加shell脚本进行合并
#### 5.在主工程中 Target -> Build Phases -> Link Binary With Libraries 添加用脚本合成的静态库
#### 6.在主工程的 General -> Frameworks, Libraries, and Embedded Content中可以看到添加的静态库，并且Embed为 Do Not Embed 

#### 7.动态库使用动态链接Embbed Frameworks（会自动在下面的Link Binary With Libraries也添加一次)，并且在静态库使用静态链接Link Binary With Libraries。


## 静态库中引入资源包(图片、xib、音视频文件等)，需要先将资源打包成Bundle,Bundle制作流程如下
方式一:
1.在静态库中创建文件(和静态库名称一致)，后缀名改为.bundle
2.添加需要的图片资源，（这中方式不能使用@1x,@2x,@3x图片）
3.在静态库中使用图片的方式为：
 UIImage.init(named: "OpenInvoice.bundle/111", in: Bundle.init(for: self.classForCoder), compatibleWith: nil)
 4.在主工程中，将静态库和存放图片的.bundle资源文件一块拖进工程中即可（在主工程中,.bundle文件下是可以看到每一张图片的,自己感觉不太好）
 方式二:
 
 

#### 1.新建工程 -> macOS -> Framework & Library -> Bundle，此创建过程中也不需要Team,即不需要签名，设置工程为Release模式
#### 2.因创建的是macOS，所以在Build Setting -> Base SDK 修改为iOS
#### 3.Build Setting -> COMBINE_HIDPI_IMAGES 设置为NO，否则Bundle中图片格式就会为tiff格式
#### 4.作为资源包只需要编译就好，不需要安装相关配置，Build Setting ->Skip Install的值为YES，同时删除Installation Directory的键值
#### 5.在TARGET -> General -> Deployment Info -> Target 设置支持的系统版本（iOS 8.0）
#### 6. Build Active Architecture Only设置为NO
#### 7.创建完成后，可以导入资源文件了，本案例以Asset Catalog引入图片 New File -> Asset Catalog -> 然后导入 @1x @2X @3X图片
#### 8.运行程序，包含模拟器和真机模式，打包上线的时候要使用真机下的Bundle包
#### 9.Produce -> show in Finder 找到对应的Bundle包，导入到主工程中(这里我们用的主工程是frameWork)
#### 10.在主工程中使用图片:
##### (1)找到资源包的路径path : Bundle.main.path(forResource: "testBundle", ofType: ".bundle")
##### (2)创建Bundle对象bundle: Bundle(path: path!)
##### (3)赋值 UIImage(named: "com_img", in: bundle, compatibleWith: nil)


## 静态库中导入第三方库
### 本案例中将使用Carthage管理第三方
#### 1.在静态库中使用Carthage导入第三方
#### 2.在打包静态库后，静态库目录下会有Frameworks/第三方库，这些库需要在主工程中导入使用，并且在主工程中Target -> General -> Frameworks,Libraries,and Embedded Content中的Embed为 Embed & Sign,否则会报错


## 静态库的使用
#### 1.静态库导入项目中，项目打包上线时，是不会显示静态库的


#### 2. 一个framework如何区分是动态库还是动态库?
    例如WGBaseTool.framework和Alamofire.framework
    打开终端输入: file xxx/xxx/WGBaseTool.framework/WGBaseTool 
    //静态库
    /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/WGBaseTool: 
    Mach-O universal binary with 4 architectures: [arm_v7:current ar archive] [i386:current ar 
    archive] [x86_64:current ar archive] [arm64:current ar archive]
    
    /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/WGBaseTool 
    (for architecture armv7):    current ar archive
    
    /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/WGBaseTool 
    (for architecture i386):    current ar archive
    
    /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/WGBaseTool 
    (for architecture x86_64):    current ar archive
    
    /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/WGBaseTool 
    (for architecture arm64):    current ar archive
    
    //动态库
    /Users/baicai/Library/Developer/Xcode/DerivedData/Alamofire-belqpwecoaawcubpenaiytdogpll/Build/Products/
    Debug-iphoneos/Alamofire.framework/Alamofire: Mach-O 64-bit dynamically linked shared library arm64
#### 若出现的都是 archive 则为静态库；若出现dynamically则为动态库

#####  1.MQTT集成过程的坑
#### 项目采用的是swift，所以到https://github.com/aciidb0mb3r/SwiftMQTT去下载(手动集成)，打开demo,demo中包含了SwiftMQTT.framework工程，这个工程是动态库的，然后就是运行在模拟器和真机上在framework工程下的Product找到对应的真机framework和模拟器framework，然后利用lipo进行真机和模拟器SDK的合并，导入到项目中，发现运行报错，暂时没能解决
#### 更换思路，将SwiftMQTT.framework工程设置为静态库，然后利用lipo进行合并真机和模拟器的framework，导入到项目中，最终成功在模拟器和真机上运行

#### 如果不想用framework，就直接将framework工程下的用到的代码拷贝到项目中也是可以的


































