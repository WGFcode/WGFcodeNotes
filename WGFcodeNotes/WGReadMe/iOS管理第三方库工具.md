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


##  CocoaPods使用心得
### 1.[CocoaPods安装指南](https://guides.cocoapods.org/using/getting-started.html)
1. pod --version     :查看CocoaPods版本号
2. sudo gem install cocoapods       :更新 CocoaPods,只需再次安装 gem
3. sudo gem install cocoapods --pre         :更新CocoaPods预发布版本

### 2. CocoaPods使用
1. cd 到工程的根目录
2. touch Podfile 创建Podfile文件，注意必须是这个名字
3. open -a Xcode Podfile  打开Podfile文件进行编辑，

        #1.第一行要指定支持的平台和版本。
        platform :ios, '9.0'

        #忽略引入库的所有警告
        inhibit_all_warnings!


        #2.定义将它们链接到Xcode的目标，其实就是添加项目名称
        target 'AAA' do
          pod 'AFNetworking', '~> 4.0'
        end
4. 保存Podfile，然后pod install, pod install过程可能会失败多次，大部分是因为访问github时的网络问题

        Pod之前项目目录  
        AAA项目 ----【AAA AAA.xcodeproj】
        
        Pod install后项目目录
        AAA项目 ----【AAA AAA.xcodeproj Podfile Pods AAA.xcworkspace Podfile.lock】
5. 点击AAA.xcworkspace打开项目，可以发现和AAA并列的还有个Pods的工程，在AAA项目下还多出来了Pods和Frameworks两个文件夹
6. 在项目中创建XXX.pch文件，然后在里面导入第三方库如: #import <AFNetworking.h>,然后在Build Settings -> Prefix Header中设置pch文件的路径如:$(SRCROOT)/AAA/PrefixHeader.pch,然后就可以直接使用第三方库了

### 3. CocoaPods文件分析
#### 3.1Podfile: Podfile 是一种规范，用于描述一个或多个 Xcode 项目的目标的依赖关系
#### 3.2Podfile.lock: 当第一次运行**pod install**后，该文件就会自动生成，该文件记录了项目中使用CocoaPods的版本、第三方库的真实版本、来源和他们生成的哈希值。一般用在多人协作中，来确定版本是否被更改。这份文件中的第三方库的版本才是你项目中真实使用的版本，而不是Podfile文件中写的版本号；Podfile更像是一个版本约束，而Podfile.lock才是你真正使用的版本；如果让你去确定你使用某一个三方库的版本，你不应该找Podfile，而是应该找Podfile.lock文件。 即使你Podfile使用的定死版本的方式。

#### 为了整个团队第三方库的一致性，推荐将**Podfile.lock**文件加入到版本控制中；当A执行**pod install**后，podfile.lock文件中就会记录下当时最新Pods依赖库的版本，此时Bcheck下来这份包含podfile.lock文件的工程后，再去执行**pod install**后获取下来的Pods依赖库的版本就和最开始用户获取到的版本一致；若没有**podfile.lock**文件，后续团队所有成员都执行**pod install**后，都会获取最新版本的依赖库(可能执行install时机不一样，第三方库可能有新的版本)，有可能造成同一个团队使用的依赖库版本不一致


### 4. **pod install**和**pod update**区别
#### 很多人认为**pod install**是用在第一次使用CocoaPods去配置项目，而**pod update**是用在之后的更新配置中，这种想法是错误的
* pod install: 使用pod install在你的项目中安装新的库，即使你已经有了Podfile文件并且运行过pod install命令，或者你已经有添加、删除过库
* pod update: 仅仅是在你想更新库版本的时候
#### 4.1 **pod install**
1. 第一次在项目中获取第三方库时使用；每次对**Podfile**编辑时(添加/更新/删除)使用
2. 每次运行**pod install**后，都回去下载安装新的库，并且会修改**Podfile.lock**文件中记录的库的版本，**Podfile.lock**文件是用来追踪和锁定这些库的版本的
3. 运行**pod install**仅仅只能解决**Podfile.lock**中没有列出来的依赖关系，在**Podfile.lock**中列出的那些库，也仅仅只是去下载Podfile.lock中指定的版本，并不会去检查最新的版本
4. 没有在**Podfile.lock**中列出的那些库，会去检索Podfile中指定的版本

#### 4.2 **pod update**
1. 当运行**pod update 库名称**，CocoaPods将不会考虑**Podfile.lock**中列出的版本，而直接去查找该库的新版本。它将更新到这个库尽可能新的版本，只要符合**Podfile**中的版本限制要求。
2. 如果使用**pod update** 命令不带库名称参数，CocoaPods将会去更新**Podfile**中每一个库的尽可能新的版本。

#### 4.3 **pod outdated**
#### 当你使用**pod outdated**时，CocoaPods会罗列出所有在Podfile.lock中记录的有最新版本的库
#### 4.4 总结
1. 使用**pod update 库名称**可以去更新一个库的指定版本(检查相应的库是否存在更新的版本，并且更新)；而使用**pod install**将不会更新那些已经下载安装了的库
2. 当在Podfile文件中新增加一个库时，应该使用**pod install**而不是**pod update**,这样安装了新增的库，也不会重复安装已经存在的库。
3. 使用pod update仅仅只是去更新指定库的版本（或者全部库）
4. 必须将**Podfile.lcok**添加到版本控制提交中

### 5 什么时候用**pod install**？什么时候用**pod update**?
* 第一次使用cocoapod导入第三方库时，使用**pod install**
* 编辑**Podfile**文件，添加/删除/更新第三方库时使用**pod install**
* 有新的成员加入项目时，clone项目后，需要使用**pod install**去更新第三方库，如果用**pod update**会导致第三方库更新到最新的版本，这样和之前成员的第三方库版本就会不一样，导致冲突
* 检查哪些第三方库有最新的版本更新时，使用**pod outdated**
* 需要更新库版本时,使用**pod update 库名称**或者**pod update**

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
### 5.导入第三方库(Alamofire)到项目中,在Target—>General->Frameworks, Libraries, and Embedded Content—>”+”—>add file —>选择/Carthage/Build下的第三方库即可 
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
        fatal: unable to access 'https://github.com/Homebrew/homebrew-core/': LibreSSL SSL_connect: 
        SSL_ERROR_SYSCALL in connection to github.com:443 
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
        A shell task (/usr/bin/env git clone --bare --quiet https://github.com/onevcat/Kingfisher.git
        /Users/baicai/Library/Caches/org.carthage.CarthageKit/dependencies/Kingfisher) failed with 
        exit code 128:
        fatal: unable to access 'https://github.com/onevcat/Kingfisher.git/': LibreSSL SSL_connect: 
        SSL_ERROR_SYSCALL in connection to github.com:443 

### 暂时总结为就是访问GitHub上的第三方时的网络问题

### 7.3 从Xcode12.1升级到Xcode12.3后，我们开始使用如下命令即可管理第三方库
    carthage update --platform iOS --use-xcframeworks
    carthage update SnapKit --platform iOS --use-xcframeworks  指定更新某个库
### 这样在Carthage/Build下都是XXX.xcframework格式，直接在General->Frameworks、Libraries、and Embedded Content中添加第三方库(.xcframework格式)即可，不需要再Build Phases中再去添加Run Scrip项了，也不用再在里面写库路径了

### 当我们采用.xcframework格式后，模拟器运行没有问题，但是真机运行会报错
    dyld: launch, loading dependent libraries
    DYLD_LIBRARY_PATH=/usr/lib/system/introspection
    DYLD_INSERT_LIBRARIES=/Developer/usr/lib/libBacktraceRecording.dylib:/Developer/usr/lib/
    libMainThreadChecker.dylib:/Developer/Library/PrivateFrameworks/DTDDISupport.framework/
    libViewDebuggerSupport.dylib
### 解决方法就是在General->Frameworks、Libraries、and Embedded Content中将导入的第三方库后面的选项都选择为Embed&Sign选项即可

### 7.4 升级Xcode12.5 后报错，先到https://swift.org/download/#releases下载swift5.4的toolchain包，运行项目报如下错误
      module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler:  
      /Users/baicai/Library/Developer/Xcode/DerivedData/NXY-bdiioyaaxczbxlgusvqtvlkagrqv/Build/Products/  
      Debug-iphoneos/SnapKit.framework/Modules/SnapKit.swiftmodule/arm64-apple-ios.swiftmodule
### 解决方法就是更新第三方库： carthage update --platform iOS --use-xcframeworks，这个过程比较扯淡，老是访问失败，只能慢慢尝试，多运行几次了，或者利用carthage update SnapKit --platform iOS --use-xcframeworks一个库一个库的更新接口，但是更新完成后运行项目又报如下错误
    <unknown>:0: error: module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler:  
    /Users/baicai/Desktop/XXX.../XXX.framework  
    /Modules/XXX.swiftmodule/arm64-apple-ios.swiftmodule
#### ⚠️最好的方式就是删除项目目录下的Carthage和Cartfile.resolved文件，然后重新carthage update --platform iOS --use-xcframeworks，失败了就多重试几次；
#### ⚠️如果项目中有多个分支，切记要在主分支上进行更新第三方库，这样再切换到其他分支，就不需要重新更新第三方库了
#### 原因是XXX是我自定义的framework，所以也要对XXX所在的项目用Xcode12.5进行运行编译然后再合并模拟器和真机下的framework，然后保存在XXX/BaseFramework文件夹下
#### 合并真机SDK的流程如下：先选择XXX，然后分别选择真机和模拟器，在Xcode->XXX->Products下
Show in Finder，然后将真机和模拟器的XXX.framework保存下来，利用lipo -create 真机SDK 模拟器SDK -output /Users/baicai/Desktop/111111/XXX，将生成的XXX保存到桌面的111111文件夹下，然后将真机SDK中的XXX用111111文件下的XXX文件进行替换，将模拟器中的Modules/XXX.swiftmodule中内容拷贝到真机对应的Modules/XXX.swiftmodule文件中，但是模拟器中的Modules/XXX.swiftmodule/Project文件可以不用拷贝，然后直接将合并完成的真机SDK保存到XXX/BaseFramework文件夹下供其他项目使用

#### 升级Xcode16后 carthage出现各种问题并且太慢了 开始采用新的SPM来管理第三方库，但是SPM太慢了，开启ClashX Pro也不行，因为Xcode中的git是不会走代理的，方法就是在终端开启代理，先关闭Xcode
    git config --global http.proxy “http://127.0.0.1:7890” 
    git config --global https.proxy “http://127.0.0.1:7890”
    然后open -a Xcode.app打开Xcode即可
    取消代理
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    
