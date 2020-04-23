## 错误集锦
## 1.提交APP审核的时候，遇到❌您的 App 正在使用广告标识符 (IDFA)。您必须先提供关于 IDFA 的使用信息或将其从 App 中移除，然后再上传您的二进制文件。，APP中并没有用到广告，但提示这个错误了，排除问题方法如下
* 检查项目是否使用了AdSupport.framework
* cd到工程目录，使用命令行【grep -r advertisingIdentifier .】检查什么地方引用的相关广告

## 2. Github上传的图片不显示的问题
* Mac终端输入  sudo vi /etc/hosts
* 输入密码后点击 i键，进入Insert模式，将下面内容拷贝进去

        # GitHub Start
        192.30.253.112    github.com
        192.30.253.119    gist.github.com
        199.232.28.133    assets-cdn.github.com
        199.232.28.133    raw.githubusercontent.com
        199.232.28.133    gist.githubusercontent.com
        199.232.28.133    cloud.githubusercontent.com
        199.232.28.133    camo.githubusercontent.com
        199.232.28.133    avatars0.githubusercontent.com
        199.232.28.133    avatars1.githubusercontent.com
        199.232.28.133    avatars2.githubusercontent.com
        199.232.28.133    avatars3.githubusercontent.com
        199.232.28.133    avatars4.githubusercontent.com
        199.232.28.133    avatars5.githubusercontent.com
        199.232.28.133    avatars6.githubusercontent.com
        199.232.28.133    avatars7.githubusercontent.com
        199.232.28.133    avatars8.githubusercontent.com
         # GitHub End
* 点击esc键，然后输入:wq（如果出现E45: 'readonly' option is set (add ! to override)错误，则输入:wq!进行强制保存并退出）

## 3. 使用clang编辑器将OC代码转为.cpp文件报错
使用clang编译器将Objective-C代码编译成C语言代码, 并生成在一个.cpp的 C++文件中，在执行clang -rewrite-objc main.m,出现如下错误：

        main.m:9:9: fatal error: 'UIKit/UIKit.h' file not found
        #import <UIKit/UIKit.h>
                ^~~~~~~~~~~~~~~
        1 error generated.
* 解决方法：使用命令行clang -x objective-c -rewrite-objc -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk main.m，如果项目目录下出现main.cpp文件证明成功了，
