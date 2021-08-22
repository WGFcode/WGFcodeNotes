#### 管理第三方库有一下三种方式
1. CocoaPods: Cocoapods会将所有的依赖库都放到另一个名为Pods的项目中，然后让主项目依赖Pods项目
2. Carthage: 自动将第三方框架编程为Dynamic framework(动态库)
3. SPM(swift packages manager): Swift构建系统集成在一起，可以自动执行依赖项的下载，编译和链接过程

                            CocoaPods                Carthage                  SPM
 
        适用语言              swift/OC                  swift/OC                swift

        是否兼容            兼容Carthage/SPM          兼容Carthage/SPM          兼容Carthage/SPM
        
        支持库数量           多，基本大部分都支持     大部分支持，但少于CocoaPods     大部分支持，但少于CocoaPods
        
        使用/配置复杂度            中                       高                       低
        
        项目入侵性               严重入侵                没有侵入性                   没有侵入性

        项目编译速度              慢                       快                         慢 
        
        源码可见                可见                     不可见                       可见






















##  Carthage使用心得
## 1.安装
### 安装的前提是你本机已经安装好了`homebrew`,我们使用`brew`来进行安装
#### 1.首先我们先升级brew
#### `brew update` 需要很长时间,耐心等待吧
#### 2.`brew install carthage` 进行安装,安装完成后,会显示出你安装的Carthage的版本
#### 使用 `carthage version` 可以查看当前的版本 
#### 更新carthage版本：brew upgrade carthage
#### 删除carthage旧版本： brew cleanup carthage


## 2.使用
### 1.`touch Cartfile` 创建一个空的Cartfile文件
### 2.`open -a Xcode Cartfile` 打开Cartfile文件
### 3.在Github上找到需要的第三方库,例如`github "Alamofire/Alamofire" ~> 4.7`复制到Cartfile文件中
### 4.执行`carthage update`:更新包含了iOS/mac的库 `carthage update --platform iOS`: 更新了只包含iOS的库;或者 `carthage update --platform iOS --use-xcframeworks `使用最新的xcframeworks格式进行导入 第三方库已经导入到了,此时项目路径下会自动创建Carthage文件夹,更新完成后会出现checkout和Build两个文件夹(Carthage可以删除的,删除后相当于重新倒入第三方库,然后update即可)
### 5.导入第三方库(Alamofire)到项目中,在Target—>Build Phases —>”+”—>New Run Script Phase—>添加脚本`/usr/local/bin/carthage copy-frameworks`
### 6.添加文件`Input Files—>添加路径＂$(SRCROOT)/Carthage/Build/iOS/Alamofire.framework＂`
### 7.在TARGETS->General->Embedded Binaries->"+"->"Add Other..."->找到`Alamofire.framework`并添加即可,同时项目根目录下/General->Linked Frameworks with Libraries/Build Phases->Embed Frameworks/Build Phases->Linked Binary with Libraries也会出现添加的框架 
## 3.创建桥接文件
### 1.New file-> Header File -> WGNoteBridgeHeader
### 2.在Build Setting -> Objective-C Bridging Header中添加桥接文件的路径,然后在桥接文件中y引入项目中用到的第三方文件
#import <Alamofire/Alamofire.h>

## 4.卸载
### 1. 执行`brew uninstall Carthage`
### ![avatar](/Users/apple/Desktop/WGLearnNote/ReadMePhoto/CarthageDelete1.png)
### 2. 如果要想删除本地所有版本的Carthage,执行`brew uninstall --force carthage`
### ![avatar](/Users/apple/Desktop/WGLearnNote/ReadMePhoto/CarthageDelete2.png)


## 5.遇到错误总结
###1.更新过程中遇到Could not find any available simulators for iOS,解决方案:升级carthage版本

## 6.常用操作
### 查看Carthage版本`carthage version`
### 升级Carthage版本`brew upgrade carthage`
### 创建空的Cartfile文件`touch Cartfile`
### 使用Xcode命令打开Cartfile文件`open -a Xcode Cartfile`
### 更新Cartfile文件中所有的第三方库`carthage update --platform iOS`
### 查看Carthage版本`carthage version`


## 7. 常见错误总结
### 7.1当我们想从版本0.36.0升级到0.37.0时，当执行brew upgrade carthage会遇到如下错误
        Error: 
          homebrew-core is a shallow clone.
        To `brew update`, first run:
          git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
        This command may take a few minutes to run due to the large size of the repository.
        This restriction has been made on GitHub's request because updating shallow
        clones is an extremely expensive operation due to the tree layout and traffic of
        Homebrew/homebrew-core and Homebrew/homebrew-cask. We don't do this for you
        automatically to avoid repeatedly performing an expensive unshallow operation in
        CI systems (which should instead be fixed to not use shallow clones). Sorry for
        the inconvenience!
        Warning: carthage 0.36.0 already installed
### 按照提示我们执行git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow命令
        fatal: unable to access 'https://github.com/Homebrew/homebrew-core/': LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443 
### 若遇到上面问题时，我们要打开手机热点，用电脑连接手机热点去更新下载最新的版本，然后继续执行git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow命令,遇到下面打印表示执行成功
        homebrew-core fetch --unshallow
        remote: Enumerating objects: 594107, done.
        remote: Counting objects: 100% (594062/594062), done.
        remote: Compressing objects: 100% (206094/206094), done.
        remote: Total 584546 (delta 381674), reused 578322 (delta 375600), pack-reused 
        Receiving objects: 100% (584546/584546), 227.15 MiB | 1.46 MiB/s, done.
        Resolving deltas: 100% (381674/381674), completed with 8459 local objects.
        From https://github.com/Homebrew/homebrew-core
           93cadf3457..a80f042079  master     -> origin/master

### 最后我们再执行brew upgrade carthage即可，然后通过carthage version查看是否升级到了最新版本0.37.0 

### 7.2 Xcode从Xcode12.1升级到Xcode12.3后，当更新第三方版本库时，执行carthage update --platform iOS，会遇到如下问题
        *** Cloning lottie-ios
        *** Cloning Kingfisher
        A shell task (/usr/bin/env git clone --bare --quiet https://github.com/onevcat/Kingfisher.git /Users/baicai/Library/Caches/org.carthage.CarthageKit/dependencies/Kingfisher) failed with exit code 128:
        fatal: unable to access 'https://github.com/onevcat/Kingfisher.git/': LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443 

### 暂时总结为就是访问GitHub上的第三方时的网络问题

### 7.3 从Xcode12.1升级到Xcode12.3后，我们开始使用如下命令即可管理第三方库
    carthage update --platform iOS --use-xcframeworks
    carthage update SnapKit --platform iOS --use-xcframeworks  指定更新某个库
### 这样在Carthage/Build下都是XXX.xcframework格式，直接在General->Frameworks、Libraries、and Embedded Content中添加第三方库(.xcframework格式)即可，不需要再Build Phases中再去添加Run Scrip项了，也不用再在里面写库路径了

### 当我们采用.xcframework格式后，模拟器运行没有问题，但是真机运行会报错
    dyld: launch, loading dependent libraries
    DYLD_LIBRARY_PATH=/usr/lib/system/introspection
    DYLD_INSERT_LIBRARIES=/Developer/usr/lib/libBacktraceRecording.dylib:/Developer/usr/lib/libMainThreadChecker.dylib:/Developer/Library/PrivateFrameworks/DTDDISupport.framework/libViewDebuggerSupport.dylib
### 解决方法就是在General->Frameworks、Libraries、and Embedded Content中将导入的第三方库后面的选项都选择为Embed&Sign选项即可

### 7.4 升级Xcode12.5 后报错，先到https://swift.org/download/#releases下载swift5.4的toolchain包，运行项目报如下错误
      module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler: /Users/baicai/Library/Developer/Xcode/DerivedData/NXY-bdiioyaaxczbxlgusvqtvlkagrqv/Build/Products/Debug-iphoneos/SnapKit.framework/Modules/SnapKit.swiftmodule/arm64-apple-ios.swiftmodule
### 解决方法就是更新第三方库： carthage update --platform iOS --use-xcframeworks，这个过程比较扯淡，老是访问失败，只能慢慢尝试，多运行几次了，或者利用carthage update SnapKit --platform iOS --use-xcframeworks一个库一个库的更新接口，但是更新完成后运行项目又报如下错误
    <unknown>:0: error: module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler: /Users/baicai/Desktop/WLKProject/NXYMerchantsProject/NXY/WGLib/WGCustomSDK/WGBaseTool.framework/Modules/WGBaseTool.swiftmodule/arm64-apple-ios.swiftmodule
#### 原因是WGBaseTool是我自定义的framework，所以也要对WGBaseTool所在的项目用Xcode12.5进行运行编译然后再合并模拟器和真机下的framework，然后保存在WLKProject/WLK/WGBaseTool/WGBaseTool/BaseFramework文件夹下
#### 合并真机SDK的流程如下：先选择WGBaseTool，然后分别选择真机和模拟器，在Xcode->WGBaseTool->Products下
Show in Finder，然后将真机和模拟器的WGBaseTool.framework保存下来，利用lipo -create 真机SDK 模拟器SDK /Users/baicai/Desktop/111111/WGBaseTool，将生成的WGBaseTool保存到桌面的111111文件夹下，然后将真机SDK中的WGBaseTool用111111文件下的WGBaseTool文件进行替换，将模拟器中的Modules/WGBaseTool.swiftmodule中内容拷贝到真机对应的Modules/WGBaseTool.swiftmodule文件中，但是模拟器中的Modules/WGBaseTool.swiftmodule/Project文件可以不用拷贝，然后直接将合并完成的真机SDK保存到WLKProject/WLK/WGBaseTool/WGBaseTool/BaseFramework文件夹下供其他项目使用
