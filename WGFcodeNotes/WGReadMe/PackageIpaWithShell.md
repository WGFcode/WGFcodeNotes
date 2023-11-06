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
