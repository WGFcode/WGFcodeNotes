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
解决方法: 在Build Settings -> Other linker flags中添加"-ld64"
