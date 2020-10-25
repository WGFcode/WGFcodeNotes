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


