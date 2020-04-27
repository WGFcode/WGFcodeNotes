#  Carthage使用心得
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
### 4.执行`carthage update`:更新包含了iOS/mac的库 `carthage update --platform iOS`: 更新了只包含iOS的库; 第三方库已经导入到了,此时项目路径下会自动创建Carthage文件夹,更新完成后会出现checkout和Build两个文件夹(Carthage可以删除的,删除后相当于重新倒入第三方库,然后update即可)
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

