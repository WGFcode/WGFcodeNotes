### Xcode错误总结
#### 1.升级Xcode12.0.1后，出现如下错误
    module compiled with Swift 5.1.3 cannot be imported by the Swift 5.3 compiler: /Users/baicai/Desktop/WLKProject/WLKOrder/WLKOrder/WLKLib/WGBaseTool.framework/Modules/WGBaseTool.swiftmodule/arm.swiftmodule
    
#### 原因分析：Swift编译的Framework的swift版本和使用者APP使用的Swift版本不一致就会报这个错误，所以解决思路是同步Swift版本：

#### 解决方法：从https://swift.org/download/#releases网站下载(swift-5.3-RELEASE-osx.pkg)安装适用于您的特定Xcode版本的Xcode Toolchain。
Xcode Toolchain包括编译器，lldb以及其他相关工具的副本，这些副本可提供在特定版本的Swift中工作时提供相应环境。打开Xcode的首选项，Components > Toolchains ，然后选择已安装的Swift工具链即可。



#### 2. carthage update --platform iOS时报错
    Build Failed
        Task failed with exit code 1:
        /usr/bin/xcrun lipo -create /Users/baicai/Library/Caches/org.carthage.CarthageKit/DerivedData/12.0.1_12A7300/Alamofire/5.3.0/Build/Intermediates.noindex/ArchiveIntermediates/Alamofire\ iOS/IntermediateBuildFilesPath/UninstalledProducts/iphoneos/Alamofire.framework/Alamofire /Users/baicai/Library/Caches/org.carthage.CarthageKit/DerivedData/12.0.1_12A7300/Alamofire/5.3.0/Build/Products/Release-iphonesimulator/Alamofire.framework/Alamofire -output /Users/baicai/Desktop/WLKProject/WLK/Carthage/Build/iOS/Alamofire.framework/Alamofire

    This usually indicates that project itself failed to compile. Please check the xcodebuild log for more details: /var/folders/2g/rblj4zp502n0kd06tng4srph0000gn/T/carthage-xcodebuild.BqWiTS.log
#### 原因分析:应该是 AppleSilicon 上的 iPhoneSimulator 是 arch arm64，而 iPhoneSimulator 则与同一 arch arm64 上的 iPhoneOS 库有冲突，所以出现了这种问题。
#### 解决方案1
1. 在项目目录，使用命令行工具 touch WLKOrderCarthage.xcconfig
2. open tmp.xcconfig,将如下代码粘贴上

        EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e armv7 armv7s armv6 armv8
        EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))
3. 在终端执行 export XCODE_XCCONFIG_FILE=$PWD/WLKOrderCarthage.xcconfig
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


4. 升级Xcode12后，真机运行没问题，运行到模拟器上是报错:Module “WGBaseTool”was created for incompatible target arm64-apple-ios10.0:,WGBaseTool是我自己创建的静态库
#### 解决方法：选择调用端的target,注意是调用端,不是生成的framework端,之前我改了framework端还是报错浪费了时间.
build Settings ->Excluded Architecture->debug 和 release ->Any ios simulator SDK 点击 + 加号,手动输入arm64 ,debug 和 release操作一样,都要修改,之后再运行模拟器编译就不报错了.

5. 在OC的农信聚合小二中，运行项目到模拟器会发生如下错误

        ld: building for iOS Simulator, but linking in dylib built for iOS, file '/Users/baicai/Desktop/WLKProject/NXYJHXEProject/Pods/NIMSDK_LITE/NIMSDK/NIMSDK.framework/NIMSDK' for architecture arm64
        clang: error: linker command failed with exit code 1 (use -v to see invocation)
#### 解决方案：在Build Settings -> Excluded Architectures中添加arm64,但是如果添加后在真机上运行就运行不了了，会提示如下信息，所以如果需要模拟器运行，我们可以添加，如果是真机运行就不要添加
    NXYXE's architectures (armv7) include none that 武智功 can execute (arm64v8, arm64, armv8).

6. 在家银小二项目中，如果连接iOS14.4跑代码没问题，但是一但断开直接运行在真机上会出现crash，但是在iOS12.2的设备上没问题，跑代码日子看了没问题，但是不连接代码，又看不到日志，所以采用将项目打包，导出dsym文件，然后利用Bugly生成符号表，真机运行就可以直接看到crash日志，同时也发现了Bugly是实时监控crash日志的，详细的日志信息如下：

        #2 NSUnknownKeyException
        [<AFHTTPSessionManager 0x280a3c000> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key Content-Type.
        ZJKBank +[WGNetworkAPI requestWithFunCode:param:success:fail:] (WGNetworkAPI.m:)
        解决方案： 找不到该key值
        
        被重点标记的行，可以发现crash发生在WGNetworkAPI.m文件的第111行代码
        ZJKBank    +[WGNetworkAPI requestWithFunCode:param:success:fail:] (WGNetworkAPI.m:111)
        ZJKBank    -[WGLoginVC login] (WGLoginVC.m:177)

#### 解决方案： 将[[WGNetworkAPI manager] setValue:@"application/json" forKey:@"Content-Type"];去掉就可以了，

7. 升级到Xcode12.3后，运行家银小二在模拟器上，报错：

        ld: in /Users/baicai/Desktop/WLKProject/BankXE/BankXE/WGLib/Bugly.framework/Bugly(libBugly.a-arm64-master.o), building for iOS Simulator, but linking in object file built for iOS,
        clang: error: linker command failed with exit code 1 (use -v to see invocation)
#### 解决方法：1.Excluded Architecture 加上 arm64；2.Build Active Architecture Only 设置为 NO,设置可行 但打真机包的时候 Excluded Architecture 里的值要去掉

8. 将模拟器和真机的SDK合并后，导入到项目中，发生如下错误
     Building for iOS,but the linked and embedded framework "WGBaseTool.framework" was build for iOS + iOS Simulator
#### 解决方法：
1. 在File -> Project Settings -> Build System 设置为 Legacy Build System
2. Frameworks, Libraries,and Embedded Content 将对应的framework设置为Do not Embed即可
#### ⚠️静态库一般都不需要嵌入和签名，所以选择Do Not Embed,动态库一般都需要Embed，如果动态库需要签名，则选择Embed & Sign；若不需要签名，则选择Embed Without Signing


8. 真机运行项目没问题，模拟器上运行项目报错: dyld: dyld_sim cannot be loaded in a restricted process
(lldb) 
#### 解决方法: Build Settings -> Other Linker Flags 删除-Wl,-sectcreate,__RESTRICT,__restrict,/dev/null 就可以在模拟器上运行了

9. 运行项目，报警告⚠️: ld: warning: object file (/Users/baicai/Desktop/WLKProject/NXYJHXEProject/NXYXE/WGLib/JYSDK/EAccountHYSDK.framework/EAccountHYSDK(EAccountHYUiEventHandler.o)) was built for newer iOS version (10.0) than being linked (9.0)
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
