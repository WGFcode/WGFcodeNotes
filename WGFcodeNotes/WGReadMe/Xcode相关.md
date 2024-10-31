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

### 1.清理Xcode
#### 1.1 移除DerivedData,建议定期清理，会重新生成 【~/Library/Developer/Xcode/DerivedData】
#### 1.2 移除Archives，可以清理 【~/Library/Developer/Xcode/Archives】
#### 1.3 移除iOS DeviceSupport，建议清理，连接设备会重新生成 【~/Library/Developer/Xcode/iOS DeviceSupport】
#### 1.4 移除模拟器文件，可以清理，运行模拟器会重新生成 【~/Library/Developer/CoreSimulator/Devices】
#### 1.5 磁盘清理，Xcode项目运行残留文件，常规方法无法清除，步骤：【 /private/var/folders/2g/rblj4zp502n0kd06tng4srph0000gn/C/com.apple.DeveloperTools/All/Xcode/EmbeddedAppDeltas/】删除 EmbeddedAppDeltas文件夹下的内容


Xcode16 上传app包然后验证时报错 涉及bitcode问题
Invalid Executable. The executable “XXX/Framework/NIMSDK.frame/NIMSDK” contains bitcode 

解决方法就是将手动移除 framework 中的 Bitcode
如果是通过 pod install 获取的 SDK，则进入 pods 文件夹，然后一层一层找到NIMSDK.framework下的NIMSDK

命令检查 framework 是否包含 bitcode，返回 0 即为不包含
otool -l NIMSDK | grep __LLVM | wc -l
移除 NIMSDK.framework 的 Bitcode。
xcrun bitcode_strip -r NIMSDK -o NIMSDK

亲测有效，记得一定要


### Xcode错误总结
#### 1.升级Xcode12.0.1后，出现如下错误
    module compiled with Swift 5.1.3 cannot be imported by the Swift 5.3 compiler: /Users/baicai/Desktop/XXX.framework/Modules/XXX.swiftmodule/arm.swiftmodule
    
#### 原因分析：Swift编译的Framework的swift版本和使用者APP使用的Swift版本不一致就会报这个错误，所以解决思路是同步Swift版本：

#### 解决方法：从https://swift.org/download/#releases网站下载(swift-5.3-RELEASE-osx.pkg)安装适用于您的特定Xcode版本的Xcode Toolchain。
Xcode Toolchain包括编译器，lldb以及其他相关工具的副本，这些副本可提供在特定版本的Swift中工作时提供相应环境。打开Xcode的首选项，Components > Toolchains ，然后选择已安装的Swift工具链即可。



#### 2. carthage update --platform iOS时报错
    Build Failed
        Task failed with exit code 1:
        /usr/bin/xcrun lipo -create /Users/baicai/Library/Caches/org.carthage.CarthageKit/DerivedData/12.0.1_12A7300/Alamofire/5.3.0/Build/Intermediates.noindex/ArchiveIntermediates/Alamofire\ iOS/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/Alamofire.framework/Alamofire /Users/baicai/Library/Caches/org.carthage.CarthageKit/DerivedData/12.0.1_12A7300/Alamofire/5.3.0/Build/Products/Release-iphonesimulator/Alamofire.framework/Alamofire -output /Users/baicai/Desktop/XXX/Carthage/Build/iOS/Alamofire.framework/Alamofire

    This usually indicates that project itself failed to compile. Please check the xcodebuild log for more details: /var/folders/2g/rblj4zp502n0kd06tng4srph0000gn/T/carthage-xcodebuild.BqWiTS.log
#### 原因分析:应该是 AppleSilicon 上的 iPhoneSimulator 是 arch arm64，而 iPhoneSimulator 则与同一 arch arm64 上的 iPhoneOS 库有冲突，所以出现了这种问题。
#### 解决方案1
1. 在项目目录，使用命令行工具 touch XXXCarthage.xcconfig
2. open tmp.xcconfig,将如下代码粘贴上

        EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e armv7 armv7s armv6 armv8
        EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))
3. 在终端执行 export XCODE_XCCONFIG_FILE=$PWD/XXXCarthage.xcconfig
4. carthage update --platform iOS --no-use-binaries --cache-builds

#### 解决方案2: https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md，推荐使用这种方式，这样就可以避免在多个工程中创建**tmp.xcconfig**文件了
#### ⚠️存在问题，就是Alamofire.framwork中缺失Header文件，导致项目中的桥接文件找不到对应的Alamofire.h文件，但最终在github上咨询后，是因为Alamofire新版本已经移除了OC的模块，所以后续新版本的Alamofire就不能再桥接文件中引入Alamofire.h文件了，只能是哪里用到了就import了
1. 在/usr/local/bin 目录下创建carthage.sh，如: touch carthage.sh
2. 在carthage.sh文件下粘贴如下代码：
3. 终端修改权限：chmod +x /usr/local/bin/carthage.sh
4. 进入项目目录，carthage.sh bootstrap --platform iOS --cache-builds即可
        
        # carthage.sh
        # Usage example: ./carthage.sh build --platform iOS

        set -euo pipefail

        xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
        trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

        # For Xcode 12 make sure EXCLUDED_ARCHS is set to arm architectures otherwise
        # the build will fail on lipo due to duplicate architectures.

        CURRENT_XCODE_VERSION=$(xcodebuild -version | grep "Build version" | cut -d' ' -f3)
        echo "EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$CURRENT_XCODE_VERSION = arm64 arm64e armv7 armv7s armv6 armv8" >> $xcconfig

        echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$(XCODE_PRODUCT_BUILD_VERSION))' >> $xcconfig
        echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> $xcconfig

        export XCODE_XCCONFIG_FILE="$xcconfig"
        carthage "$@"

3.  升级Xcode12后，运行项目，导入的第三方库会报警告：
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.1.99.
#### 原因是升级Xcode12后，Xcode默认支持的iOS版本是iOS9.0，如果想支持iOS8.0，那么就需要在/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport文件中添加iOS8.0的版本包，然后在同级目录的Developer/SDKs/iPhoneOS.sdk/SDKSettings.plist中添加支持的iOS版本号，这里修改SDKSettings.plist文件可能没有权限，那么就需要将SDKSettings.plist文件和它的上一级文件的权限打开，点击显示简介->共享与权限->打开锁->设置本用户权限为可读可写并应用到该项目中即可


4. 升级Xcode12后，真机运行没问题，运行到模拟器上是报错:Module “XXX”was created for incompatible target arm64-apple-ios10.0:,XXX是我自己创建的静态库
#### 解决方法：选择调用端的target,注意是调用端,不是生成的framework端,之前我改了framework端还是报错浪费了时间.
build Settings ->Excluded Architecture->debug 和 release ->Any ios simulator SDK 点击 + 加号,手动输入arm64 ,debug 和 release操作一样,都要修改,之后再运行模拟器编译就不报错了.

5. 在OC的农信聚合小二中，运行项目到模拟器会发生如下错误

        ld: building for iOS Simulator, but linking in dylib built for iOS, file '/Users/baicai/Desktop/XXX/Pods/NIMSDK_LITE/NIMSDK/NIMSDK.framework/NIMSDK' for architecture arm64
        clang: error: linker command failed with exit code 1 (use -v to see invocation)
#### 解决方案：在Build Settings -> Excluded Architectures中添加arm64,但是如果添加后在真机上运行就运行不了了，会提示如下信息，所以如果需要模拟器运行，我们可以添加，如果是真机运行就不要添加
    NXYXE's architectures (armv7) include none that 武智功 can execute (arm64v8, arm64, armv8).

6. 在家银小二项目中，如果连接iOS14.4跑代码没问题，但是一但断开直接运行在真机上会出现crash，但是在iOS12.2的设备上没问题，跑代码日子看了没问题，但是不连接代码，又看不到日志，所以采用将项目打包，导出dsym文件，然后利用Bugly生成符号表，真机运行就可以直接看到crash日志，同时也发现了Bugly是实时监控crash日志的，详细的日志信息如下：

        #2 NSUnknownKeyException
        [<AFHTTPSessionManager 0x280a3c000> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key Content-Type.
        appName +[WGNetworkAPI requestWithFunCode:param:success:fail:] (WGNetworkAPI.m:)
        解决方案： 找不到该key值
        
        被重点标记的行，可以发现crash发生在WGNetworkAPI.m文件的第111行代码
        appName    +[WGNetworkAPI requestWithFunCode:param:success:fail:] (WGNetworkAPI.m:111)
        appName    -[WGLoginVC login] (WGLoginVC.m:177)

#### 解决方案： 将[[WGNetworkAPI manager] setValue:@"application/json" forKey:@"Content-Type"];去掉就可以了，

7. 升级到Xcode12.3后，运行家银小二在模拟器上，报错：

        ld: in /Users/baicai/Desktop/XXX/Bugly.framework/Bugly(libBugly.a-arm64-master.o), building for iOS Simulator, but linking in object file built for iOS,
        clang: error: linker command failed with exit code 1 (use -v to see invocation)
#### 解决方法：1.Excluded Architecture 加上 arm64；2.Build Active Architecture Only 设置为 NO,设置可行 但打真机包的时候 Excluded Architecture 里的值要去掉

8. 将模拟器和真机的SDK合并后，导入到项目中，发生如下错误
     Building for iOS,but the linked and embedded framework "XXX.framework" was build for iOS + iOS Simulator
#### 解决方法：
1. 在File -> Project Settings -> Build System 设置为 Legacy Build System
2. Frameworks, Libraries,and Embedded Content 将对应的framework设置为Do not Embed即可
#### ⚠️静态库一般都不需要嵌入和签名，所以选择Do Not Embed,动态库一般都需要Embed，如果动态库需要签名，则选择Embed & Sign；若不需要签名，则选择Embed Without Signing


8. 真机运行项目没问题，模拟器上运行项目报错: dyld: dyld_sim cannot be loaded in a restricted process
(lldb) 
#### 解决方法: Build Settings -> Other Linker Flags 删除-Wl,-sectcreate,__RESTRICT,__restrict,/dev/null 就可以在模拟器上运行了

9. 运行项目，报警告⚠️: ld: warning: object file (/Users/baicai/Desktop/XXX/JYSDK/EAccountHYSDK.framework/EAccountHYSDK(EAccountHYUiEventHandler.o)) was built for newer iOS version (10.0) than being linked (9.0)
#### 解决方法： Build Settings -> Other Linker Flags 添加-w即可消除警告

10. 添加第三方库XWPushSDK.framework，默认的会在Build Phases -> Link Binary with Libraries中显示该framework，一切都很正常，但是运行项目报错
ld: framework not found XWPushSDK
#### 解决方法：首先通过lipo -info xxx/xxx/XWPushSDK.framework/XWPushSDK查看该framework支持的架构(模拟器还是真机)；再通过file xxx/xxx/XWPushSDK.framework/XWPushSDK 查看该framework是动态库还是静态库，静态库动态库区别如下
    动态库: ....Mach-O 64-bit dynamically linked shared....  
    静态库: ....current ar archive random library....
结果发现XWPushSDK.framework是动态库，所以会出现错误，添加动态库的方法不是添加到Link Binary with Libraries，而是在General -> Frameworks, Libraries,and Embedded Content,直接将动态库拖到这里面即可，这时工程目录下的Frameworks会出现该库，并且在Link Binary with Libraries下也有该库
11. 运行项目报错：xxx has conflicting provisioning settings，问题分析：勾选了Automatically manage signing，xcode会自动管理描述文件和证书等，但是由于项目原来的描述文件被设置为其他的值，所有会出现这个报错，提示描述文件冲突！解决方案：选择xxx.xcodeproj，显示包内容，找到project.pbxproj，打开，全局搜索被设定的描述文件，把指定行全部删除保存（可提前备份以备不时之需），重启xcode就好了为了安全，可以先把指定行备份！

12. 继承友盟统计导入SDK后报错 28 duplicate symbols for architecture arm64
#### 友盟统计SDK和项目中个推SDK和极光SDK有冲突，Other Linker Flags增加-ObjC这个是集成友盟时需要添加的，把这个-ObjC去掉后就不会再有冲突了

12. ld: warning: directory not found for option '-F/Users/baicai/Desktop/XXX/Carthage/Build/iOS'
#### 依次 Project -> targets -> Build Setting -> Framework Search Paths 删除里面的路径即可消除警告

13. directory not found for option '-L/Users/baicai/Desktop/XXX/Lib-noidfa'
#### 依次 Project -> targets -> Build Setting -> Library Search Paths 删除里面的路径

14.NXYMer 运行项目到模拟器报错
could not find module 'XXX' for target 'arm64-apple-ios-simulator'; found: x86_64-apple-ios-simulator, armv7-apple-ios, i386-apple-ios-simulator, arm64-apple-ios, at: /Users/baicai/Desktop/XXX/XXX.framework/Modules/XXX.swiftmodule
原来xcode里面的VALID_ARCHS选项：arm64e armv7 armv7s arm64
修改后xcode里面的VALID_ARCHS选项：arm64e armv7 armv7s arm64 x86_64
然后运行模拟器就可以了


14. Xcode14.1 运行项目报错
swift Module compiled with Swift 5.6 cannot be imported by the Swift 5.7.1 compiler:

解决方式如下:
1. 去https://swift.org/download/#releases网站下载(swift-5.7.1-RELEASE)，下载完成后安装即可
2. 重新利用新的Xcode编辑第三方库: cd 到工程目录，然后执行如下命令去重新编辑第三方库
   carthage build --use-xcframeworks --platform iOS 
   
⚠️:执行carthage build过程中，出现了如下问题
A shell task (/usr/bin/xcrun xcodebuild -project /Users/baicai/Desktop/XXX/Carthage/Checkouts/MJRefresh/Examples/MJRefreshExample/MJRefreshExample.xcodeproj -scheme MJRefreshFramework -configuration Release CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= CARTHAGE=YES archive -showBuildSettings -skipUnavailableActions) failed with exit code 6: 
.....  
Thread:   <_NSMainThread: 0x600002d28500>{number = 1, name = main}
Hints: 

Backtrace:
  0   -[DVTAssertionHandler handleFailureInMethod:object:fileName:lineNumber:assertionSignature:messageFormat:arguments:] (in DVTFoundation)
  1   _DVTAssertionHandler (in DVTFoundation)
  2   _DVTAssertionFailureHandler (in DVTFoundation)
  3   +[IDERunDestinationCLI resolveRunDestinationsWithWorkspace:scheme:buildAction:schemeCommand:schemeTask:destinationSpecifications:architectures:timeout:runDestinationManager:deviceManager:fallbackPreferredSDK:fallbackPreferredArchitectures:skipUnsupportedDestinations:shouldSkipRunDestinationValidation:didDisambiguate:disambiguatedMatches:disambiguatedMatchesDescription:error:] (in IDEFoundation)
  4   -[Xcode3CommandLineBuildTool _resolveRunDestinationsForBuildAction:] (in Xcode3Core)
  5   -[Xcode3CommandLineBuildTool _resolveInputOptionsWithTimingSection:] (in Xcode3Core)
  6   -[Xcode3CommandLineBuildTool run] (in Xcode3Core)
  7   XcodeBuildMain (in libxcodebuildLoader.dylib)
  8   start (in dyld)
#### 解决方法：将carthage中的MJRefresh第三方库删除，并且将Build和Checkouts文件下有关MJRefresh第三方库也删除就可以了


15.升级Xcode15运行报错 Command PhaseScriptExecution failed with a nonzero exit code
找到Build的错误日志，会发现如下信息

Showing Recent Messages
None of the architectures in ARCHS (arm64) are valid. Consider setting ARCHS to $(ARCHS_STANDARD) or updating it to include at least one value from VALID_ARCHS (arm64, arm64e, armv7, armv7s) which is not in EXCLUDED_ARCHS (arm64).


Showing Recent Messages
/Users/baicai/Desktop/XXX/Pods/Target Support Files/Pods-NXYXE/Pods-NXYXE-frameworks.sh: line 132: ARCHS[@]: unbound variable

说明 需要将Excluded Architectures中的arm64去除就可以了


16.升级Xcode15后，运行项目报错: Assertion failed: (false && "compact unwind compressed function offset doesn't fit in 24 bits"), function operator(), file Layout.cpp, line 5758.
解决方案: 在Other Linker Flags中添加 "-ld_classic"

17. 新启动河北银行项目时，通过Carthage方式管理第三方库，添加库后运行项目，报错
dyld[2112]: Library not loaded: @rpath/libXCTestSwiftSupport.dylib
  Referenced from: <06577033-ED7F-3F04-A23F-18CCA77A8858> /private/var/containers/Bundle/Application/94936656-A77D-4231-A99C-93A1BF6DE450/XXX.app/Frameworks/RxTest.framework/RxTest
  Reason: tried: '/usr/lib/system/introspection/libXCTestSwiftSupport.dylib' (no such file, not in dyld cache), '/usr/lib/swift/libXCTestSwiftSupport.dylib' (no such file, not in dyld cache), '/private/preboot/Cryptexes/OS/usr/lib/swift/libXCTestSwiftSupport.dylib' (no such file), '/private/var/containers/Bundle/Application/94936656-A77D-4231-A99C-93A1BF6DE450/XXX.app/Frameworks/libXCTestSwiftSupport.dylib' (no such file), '/private/var/containers/Bundle/Application/94936656-A77D-4231-A99C-93A1BF6DE450/XXX.app/Frameworks/RxTest.framework/Frameworks/libXCTestSwiftSupport.dylib' (no such file), '/usr/lib/swift/libXCTestSwiftSupport.dylib' (no such file, not in dyld cache),
  解决方法： Target->General->Frameworks,Libraries,and Embedded Content下找到RxTest.xcframeworks，然后Embed标签下选择Do Not Embed，并且在Target->Build Phases -> Link Binary With Libraries下找到RxTest.xcframeworks,Status状态更改为Optional即可

18 xcode15运行报错
    Assertion failed: (false && "compact unwind compressed function offset doesn't fit in 24 bits"), function operator(), file Layout.cpp, line 5758.
解决方法: 在Build Settings -> Other linker flags中添加"-ld_classic"


19.代码统计： find . -name "*.swift" | xargs wc -l 
            find . -name "*.h" | xargs wc -l
            find . -name "*.m" | xargs wc -l



#### APP ipa包文件包含下列内容:
#### 1.DistributionSummary.plist
#### 2.ExportOptions.plist (打开后,method的value为app-store：appstore的ipa包，value为ad-hoc为上传到蒲公英或者便于测试用到的安装包)
#### 3.XXXX.ipa（scheme.ipa）
#### 4.Packaging.log


## xcodebuild命令行打包(cd到工程目录,注意是基于工程自动签名而非手动管理)
####  1.清理工程 xcodebuild clean -workspace <xxx.workspace> -scheme <schemeName> -configuration <Debug|Release>

#### 根据是工程承载的是project还是workspace进行clean 案例如:xcodebuild clean -workspace WGAppName.xcworkspace -scheme WGAppName -configuration Release  或者 xcodebuild clean -peoject WGAppName.xcodeproj -scheme WGAppName -configuration Release 

#### 2.编译并生成.xcarchive包 xcodebuild archive -archivePath <archivePath> -workspace <workspaceName>
-scheme <schemeName> -configuration <Debug或者Release>

#### 编辑成功之后，桌面上会出现AppName.xcarchive文件 案例如: xcodebuild archive -archivePath /Users/baicai/Desktop/AppName -workspace WGAppName.xcworkspace -scheme WGAppName -configuration Release


#### 3.生成的.archive包导出成ipa文件 xcodebuild -exportArchive -archivePath <xcarchivepath> -exportPath <destinationpath> -exportOptionsPlist <plistpath>。这个plist文件可以通过打一次ipa包里面去获取ExportOptions.plist，类型有以下4种，Appstore/蒲公英等需要Ad-Hoc/Development/企业内容包enterprise,因为账号和实际需要，只需要appstore和Ad-Hoc
#### 案例如下 xcodebuild -exportArchive -archivePath /Users/baicai/Desktop/AppName.xcarchive -exportPath /Users/baicai/Desktop/AppNameIPA -exportOptionsPlist /Users/baicai/Desktop/XXX/aa脚本打包资料/Ad-hoc/adhoc/ExportOptions.plist

#### 4. ,Xcodebuild命令介绍https://www.cnblogs.com/liuluoxing/p/8622108.html 。xcodebuild -list 查看工程中的Targets、Configurations和Schemes等信息


## 将APP上传到appstore
### 使用xcrun altool进行打包上传，具体步骤如下
#### 1.获取开发者账号的用户名(账号)，获取apiKey，apiIssuer,目前使用用户名和密码验证已经不支持了，所以使用apiKey，apiIssuer这种方式进行验证和上传
#### 使用--apiKey --apiIssuer进行验证和上传
#### altool --validate-app -f <file> -t <platform> -u <username> --apiKey <api_key> --apiIssuer <issuer_id>
#### apiKey和apiIssuer需要在App Store Connect 用户和访问->密钥->生成API密钥->设置名称和访问权限(权限尽量给予最高权限-管理),Issuer ID就是AppStore_apiIssuer，密钥ID就是AppStore_apiKey，后面有个蓝色字体的【下载API密钥】，该文件只能下载一次，所以下载后要妥善保管，丢了就只能删除重新生成一下，该文件是和Issuer ID对应的,以网联客为例：下载下来后的文件名称为[AuthKey_RVV6XL677X.p8]，即AuthKey_apiKey值.p8
#### 直接运行脚本会出现下面错误，其实就是系统在根目录下找不到你的apiKey文件放哪里了
#### Could not find private key file: AuthKey_RVV6XL677X.p8, in any of the following locations.\\n ./private_keys or <user home>/private_keys or <user home>/.private_keys or <user home>/.appstoreconnect/private_keys.
#### 使用linux命令将下载下来的密钥文件放在系统跟目录
#### cd ~  到根目录
#### mkdir .private_keys 根目录下生产了一个名叫private_keys隐藏文件夹
#### ls -a 查看根目录下所有的文件，包括隐藏文件private_keys
#### cd .private_keys 进入文件夹
#### pwd 打印文件夹路径p1 /Users/baicai/.private_keys
#### cd 下载AuthKey_RVV6XL677X.p8的路径下
#### mv AuthKey_RVV6XL677X.p8 /Users/baicai/.private_keys 将下载下来的文件移动到.private_keys文件夹下


#### 2.验证包:xcrun altool --validate-app -f <file> -t <platform> -u <username> --apiKey <api_key> --apiIssuer <issuer_id>
#### 3.上传包: xcrun altool --upload-app -f <file> -t <platform>  --apiKey <api_key> --apiIssuer <issuer_id>



## 上传到蒲公英相关总结
#### https://www.pgyer.com/doc/view/upload_one_command
#### curl -F "file=@{$filePath}" \   #应用安装包(ipa)文件的路径
#### -F "uKey={$uKey}" \             #是开发者的用户 Key，在应用管理-API中查看
#### -F "_api_key={$apiKey}" \       #是开发者的 API Key，在应用管理-API中查看

## 详细请查看WG.sh文件
