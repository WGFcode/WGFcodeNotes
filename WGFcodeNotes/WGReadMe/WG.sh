#! /bin/sh

#$0：当前Shell程序的文件名
#dirname $0，获取当前Shell程序的路径
#cd `dirname $0`，进入当前Shell程序的目录
#工程绝对路径(这里注意是shell脚本所在的路径，把.sh文件放在和工程.xcworkspace/.xcodeproj平级的目录中即可)

#gitignore规则不生效的解决办法，先把本地缓存删除然后更新 git rm -r --cached .
#为了使脚本不上传到仓库，添加 *./sh进行忽略


# 使用方法:
# step1: 将该脚本放在工程的根目录下（跟.xcworkspace文件或者 .xcodeproj文件同目录）
# step2: 根据情况修改下面的参数
# step3: 打开终端，执行脚本bash WGAppName.sh 或者sh WGAppName.sh


# =============项目自定义部分(自定义好下列参数后再执行该脚本)=================== #
# 如果上线到appStore，需要到https://appstoreconnect.apple.com/access/api中，App Store Connect 用户和访问->密钥->生成API密钥->设置名称和访问权限(权限尽量给予最高权限-管理),Issuer ID就是appStore_ApiIssuer，密钥ID就是appStore_ApiKey，后面有个蓝色字体的【下载API密钥】，该文件只能下载一次，所以下载后要妥善保管，丢了就只能删除重新生成一下，该文件是和Issuer ID对应的,以网联客为例：下载下来后的文件名称为[AuthKey_RVV6XL677X.p8]，即AuthKey_apiKey值.p8
#直接运行脚本会出现下面错误，其实就是系统在根目录下找不到你的apiKey文件放哪里了
#Could not find private key file: AuthKey_B9WDY298W5.p8, in any of the following locations.\\n ./private_keys or <user home>/private_keys or <user home>/.private_keys or <user home>/.appstoreconnect/private_keys.\\\" UserInfo={NSLocalizedRecoverySuggestion=Could not find private key file: AuthKey_B9WDY298W5.p8, in any of the following locations.\\n ./private_keys or <user home>/private_keys or <user home>/.private_keys or <user home>/.appstoreconnect/private_keys., NSLocalizedDescription=Could not find private key file: AuthKey_B9WDY298W5.p8, in any of the following locations.\\n ./private_keys or <user home>/private_keys or <user home>/.private_keys or <user home>/.appstoreconnect/private_keys.
#使用linux命令将下载下来的密钥文件放在系统跟目录 /Users/baicai/.private_keys
# cd ~  到根目录
# mkdir .private_keys 根目录下生产了一个名叫private_keys隐藏文件夹
#⚠️，error: mkdir: .private_keys: File exists,管理的项目太多，其他项目下载的API密钥文件已经放在/Users/baicai/.private_keys路径下了，所以不需要再创建.private_keys，直接添加到.private_keys文件下即可，.private_keys文件下可能有多个AuthKey_XXXX.p8密钥文件
# ls -a 查看根目录下所有的文件，包括隐藏文件private_keys
# cd .private_keys 进入文件夹
# pwd 打印文件夹路径p1 /Users/baicai/.private_keys #
# cd 下载AuthKey_RVV6XL677X.p8的路径下
# mv AuthKey_RVV6XL677X.p8 /Users/baicai/.private_keys 将下载下来的文件移动到.private_keys文件夹下


#编译空间是否是.xcworkspace,
#true:Cocopods管理的.xcworkspace项目
#false:用Xcode默认创建的.xcodeproj
is_Workspace="true"
# .xcworkspace的名字,若is_workspace为true，则必须填写，否则可不填
workspace_Name="WGAppName"
# .xcodeproj的名字，如果is_workspace为false，则必须填。否则可不填
project_Name=""
# 指定项目的Scheme名称（也就是工程Target名称），必填
scheme_Name="WGAppName"
# 指定要打包编译的方式: Release,Debug。一般用Release,必填
build_Configuration="Release"
# 指定打包的方式. 分别有development, ad-hoc, app-store, enterprise，必填，需要根据这个值去生成ExportOptions.plist文件
method="app-store"
# 为了方便打包文件的可读性，这里设置文件的前缀
fileHeader=""

#上传到appStore
appStore_ApiKey="RVV6XL677X"
appStore_ApiIssuer="69a6de7d-ec44-47e3-e053-5b8c7c11a4d1"

#上传到蒲公英，_api_key:对于同一个蒲公英的注册用户来说，这个值在固定的,每个蒲公英账号对应一个api_key
#用户Key，用来标识当前用户的身份，对于同一个蒲公英的注册用户来说，这个值在固定，但在API 2.0中，uKey已被舍弃
# http://www.pgyer.com/doc/view/api
pgy_api_key="c71aa37ed96c8947db74637eabb072d7"


echo "Please enter the number you want to export method? [1:app-store 2:ad-hoc 3:development 4:enterprise 5: 退出]"
echo "———————————————————等待输入———————————————"
read number
while ([[ $number != 1 ]] && [[ $number != 2 ]] && [[ $number != 3 ]] && [[ $number != 4 ]] && [[ $number != 5 ]])
do
    echo "\033[40;31m Error! you should enter 1 or 2 or 3 or 4 or 5\033[0m"
    echo "Please enter the number you want to export method? [1:app-store 2:ad-hoc 3:development 4:enterprise 5: 退出]"
read number
done

if [ $number == 1 ]; then
    method="app-store"
    fileHeader="AppStore"
elif [ $number == 2 ];then
    method="ad-hoc"
    fileHeader="AdHoc"
elif [ $number == 3 ];then
    method="development"
    fileHeader="Development"
elif [ $number == 4 ];then
    method="enterprise"
    fileHeader="Enterprise"
else
    exit
fi



# ==================脚本配置参数检查==================
# 黑底红色"\033[40;31m   \033[0m"  黑底黄色"\033[40;43m
# 输出颜色格式串 格式: echo -e "\033[字背景颜色;字体颜色m字符串\033[0m"
# 字背景颜色范围:40-49，40:黑 41:深红 42:绿 43:黄色 44:蓝色 45:紫色 46:深绿 47:白色
#字颜色范围:30-39，30:黑 31:红 32:绿 33:黄 34:蓝色 35:紫色 36:深绿 37:白色
# ANSI控制码的说明 \33[0m:关闭所有属性  \33[1m:设置高亮度  \33[4m:下划线  \33[5m:闪烁  \33[7m:反显  \33[8m:消隐
echo "\033[33;1m——————————is_workspace=${is_Workspace}——————————"
echo "——————————workspace_Name=${workspace_Name}——————————"
echo "——————————project_Name=${project_Name}——————————"
echo "——————————scheme_Name=${scheme_Name}——————————"
echo "——————————build_configuration=${build_Configuration}——————————"
echo "——————————method=${method}—————————— \033[0m"



# =======================脚本的一些固定参数定义(无特殊情况不用修改)====================== #
#这里统一将涉及到打包的文件都放在 根目录/WGPackage下，为了防止每次打包导致git仓库的变动，在.gitignore中添加 WGPackage/，忽略WGPackage文件下所有的改动

# 获取当前脚本所在目录
shell_Path=$(cd `dirname $0`; pwd)
# 工程跟目录
project_Path=$shell_Path

# 时间
start_time=$(date "+%Y-%m-%d-%H:%M:%S")
# 指定输出导出文件夹路径 根目录/WGPackage/APPStoreWGAppName-2019-12-25-11:20:30/
export_Path=$project_Path/WGPackage/$fileHeader-$scheme_Name-$start_time
# 指定输出归档文件的路径 根目录/WGPackage/WGAppName-2019-12-25-11:20:30/WGAppName.xcarchive
export_archive_Path=$export_Path/$scheme_Name.xcarchive
# 指定输出ipa文件夹路径 根目录/WGPackage/WGAppName-2019-12-25-11:20:30/
export_ipa_Path=$export_Path
# 指定导出ipa包需要用到的plist配置文件的路径 根目录/WGPackage/WGAppName-2019-12-25-11:20:30/ExportOptions.plist
export_options_plist_Path=$export_Path/ExportOptions.plist


# =======================自动打包部分(无特殊情况不用修改)====================== #
# 指定输出文件目录不存在则创建
if [ -d "$export_Path" ]; then
    echo $export_Path
else
    mkdir -pv $export_Path
fi

# 判断编译的项目类型是workspace还是project
if [ $is_Workspace = "true" ];then
    #清理工程
    echo "——————————清理工程——————————"
    xcodebuild clean -workspace ${workspace_Name}.xcworkspace \
                     -scheme ${scheme_Name} \
                     -configuration ${build_Configuration} \
                     -quiet || exit
    #shell中使用符号“$?”来显示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败
    if [ $? -eq 0 ];then
        echo "\033[40;43m——————————清理工程完成——————————\033[0m"
    else
        echo "\033[40;31m——————————清理工程失败——————————\033[0m"
        exit
    fi
    #编译工程
    echo "——————————编译工程——————————"
    xcodebuild archive -workspace ${workspace_Name}.xcworkspace \
                       -scheme ${scheme_Name} \
                       -configuration ${build_Configuration} \
                       -archivePath ${export_archive_Path} \
                       -quiet || exit
    if [ $? -eq 0 ];then
        echo "\033[40;43m——————————编译工程成功——————————\033[0m"
    else
        echo "\033[40;31m——————————编译工程失败——————————\033[0m"
        exit
    fi
else
    #清理工程
    echo "——————————清理工程——————————"
    xcodebuild clean -project ${project_Name}.xcodeproj \
                     -scheme ${scheme_Name} \
                     -configuration ${build_Configuration} \
                     -quiet || exit
    #shell中使用符号“$?”来显示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败
    if [ $? -eq 0 ];then
        echo "\033[40;43m——————————清理工程完成——————————\033[0m"
    else
        echo "\033[40;31m——————————清理工程失败——————————\033[0m"
        exit
    fi
    #编译工程
    echo "——————————编译工程——————————"
    xcodebuild archive -project ${project_Name}.xcodeproj \
                       -scheme ${scheme_Name} \
                       -configuration ${build_Configuration} \
                       -archivePath ${export_archive_Path} \
                       -quiet || exit
    if [ $? -eq 0 ];then
        echo "\033[40;43m——————————编译工程成功——————————\033[0m"
    else
        echo "\033[40;31m——————————编译工程失败——————————\033[0m"
        exit
    fi
fi


# 检查是否构建成功
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$export_archive_Path" ]; then
    echo "\033[40;43m——————————项目构建成功——————————\033[0m"
else
"\033[40;31m   \033[0m"
    echo "\033[40;31m——————————项目构建失败——————————\033[0m"
    exit
fi


# 根据参数生成export_options_plist文件 ，根目录/WGPackage/WGAppName-2019-12-25-11:20:30/ExportOptions.plist
/usr/libexec/PlistBuddy -c  "Add :method String ${method}"  $export_options_plist_Path
/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:"  $export_options_plist_Path


echo "——————————开始导出ipa包——————————"
#导出ipa包
xcodebuild -exportArchive \
           -archivePath ${export_archive_Path} \
           -exportPath ${export_ipa_Path} \
           -exportOptionsPlist ${export_options_plist_Path} \
           -quiet || exit
if [ $? -eq 0 ]; then
    echo "\033[40;43m——————————导出ipa包执行成功——————————\033[0m"
else
    echo "\033[40;31m——————————导出ipa包执行失败——————————\033[0m"
fi

# 检查ipa文件是否存在
if [ -f "$export_ipa_Path/$scheme_Name.ipa" ]; then
    echo "\033[40;43m——————————ipa包文件存在，导出ipa包成功——————————\033[0m"
else
    echo "\033[40;31m——————————ipa包文件不存在，导出ipa包失败——————————\033[0m"
    exit
fi

#start_time=$(date "+%Y-%m-%d-%H:%M:%S")
export_ipa_endTime=$(date "+%Y-%m-%d-%H:%M:%S")
echo "\033[40;43m––导出ipa包耗时start:$start_time-----end:${export_ipa_endTime}——\033[0m"


# 通过输入数字来确定是否继续将包上传 ，目前由于账号类型和需求的限制，仅用于上传到AppStore或者蒲公英
# [1:app-store 2:ad-hoc 3:development 4:enterprise 5: 退出]
if [ $number == 1 ];then
    
    echo "⚠️The current packaging method is app-store,whether to upload to AppStore ? [1: 上传到AppStore  2: 退出]"
    read isUploadAppStore
    while ([ $isUploadAppStore != 1 ] && [[ $isUploadAppStore != 2 ]])
    do
        echo "\033[40;31m Error! you should enter 1 or 2"
        echo "⚠️The current packaging method is app-store,whether to upload to AppStore ? [1: 上传到AppStore  2: 退出]"
    read isUploadAppStore
    done
    
    if [ $isUploadAppStore == 2 ];then
        exit
    else
        #上传到appStore
        #验证包
        echo "——————————验证IPA包——————————"
        #error: You must specify authentication credentials (username/password or apiKey/apiIssuer)，username/password验证方法已经行不通了，
        #这里的验证并没有去判断版本号和构建版本，所以每次上线前要自己去检查项目的版本号、构建版本号
        xcrun altool --validate-app \
        -f $export_ipa_Path/$scheme_Name.ipa \
        -t iOS \
        --apiKey $appStore_ApiKey \
        --apiIssuer $appStore_ApiIssuer
        #验证成功开始上传
        if [ $? -eq 0 ]; then
            echo "\033[40;43m——————————验证IPA包执行成功——————————\033[0m"
            echo "——————————开始上传IPA包——————————"
            #上传包的时候发生错误: The -apiIssuer option must not include the -u option. 即去掉-u $AppStore_userName
            xcrun altool --upload-app \
            -f $export_ipa_Path/$scheme_Name.ipa \
            -t iOS \
            --apiKey $appStore_ApiKey \
            --apiIssuer $appStore_ApiIssuer
            if [ $? -eq 0 ]; then
                echo "\033[40;43m——————————IPA包上传执行成功——————————\033[0m"
            else
                echo "\033[40;31m——————————IPA包上传执行失败——————————\033[0m"
            fi
        else
            echo "\033[40;31m——————————验证IPA包执行失败——————————\033[0m"
            exit
        fi
    fi
elif [ $number == 2 ];then
    
    echo "⚠️The current packaging method is ad-hoc,whether to upload to PGY ? [1: 上传到蒲公英  2: 退出]"
    read isUploadPGY
    while ([ $isUploadPGY != 1 ] && [[ $isUploadPGY != 2 ]])
    do
        echo "\033[40;31m Error! you should enter 1 or 2 \033[0m"
        echo "⚠️The current packaging method is ad-hoc,whether to upload to PGY ? [1: 上传到蒲公英  2: 退出]"
    read isUploadPGY
    done
    
    if [ $isUploadPGY == 2 ];then
        exit
    else
        #上传到蒲公英 使用API 2.0，API 1.0中的uKey已经舍弃掉
        #上传到蒲公英 这里遇到问题，每次安装都跳转到让登录蒲公英账号才能下载安装，需要在控制台->设置->App设置中，将邀请安装更改为密码安装即可。内测安装方式为密码安装和邀请安装两种安装方式。邀请安装时，需要被邀请用户登录蒲公英账号（不需要实名制认证）
        curl -F "file=@$export_ipa_Path/$scheme_Name.ipa" \
        -F "_api_key=${pgy_api_key}" \
        https://www.pgyer.com/apiv2/app/upload
        #如果上传成功，接口会以 JSON 格式返回应用的详细信息。如果上传失败，则会返回相应的错误信息
        if [ $? -eq 0 ];then
            echo "\033[40;43m——————————上传到蒲公英成功——————————\033[0m"
        else
            echo "\033[40;31m——————————上传到蒲公英失败——————————\033[0m"
            exit
        fi
    fi
elif [ $number == 3 ];then
    #TODO
    echo "⚠️ The current packaging method is development，useless"
    exit
else
    #TODO
    echo "⚠️The current packaging method is enterprise，No Enterprise Development Account, so useless"
    exit
fi
    
    
    

#======================脚本第一版============================
#project_path=$(cd `dirname $0`; pwd)
#
##在工程目录下创建一个文件夹用来存放archive文件、ExportOptions.plist、ipa包等相关内容,此文件名称自定义即可
#project_Package="appStoreAndAdHoc"
#
## TODOscheme名
#project_scheme_name="WGAppName"
#
## TODO 项目名称 一般跟scheme名称一致
#project_name="WGAppName"
#
##编译模式 Debug或者Release
#project_build_type=Debug
#
##TODO workspace名(xxx.xcworkspace) 或者project名(xxx.xcodeproj)
#project_WorkSpace_name="WGAppName.xcworkspace"
#



###包名后缀(日期+时间) date后面有一个空格
##1 Y显示4位年份，如：2018；y显示2位年份，如：18。
##2 m表示月份；M表示分钟。
##3 d表示天；D则表示当前日期，如：1/18/18(也就是2018.1.18)。
##4 H表示小时，而h显示月份。
##5 s显示当前秒钟，单位为毫秒；S显示当前秒钟，单位为秒。
## time1=$(date) 输出2018年 09月 30日 星期日 15:55:15 CST
## time1=$(date "+%Y-%m-%d %H:%M:%S") 输出2018-09-30 15:55:15
## time1=$(date "+%Y.%m.%d")  输出2018.09.30
#date="$(date "+%Y-%m-%d-%H:%M:%S")"



#temp_time="_${date}"
##包名后缀 AppStore AdHoc
#project_channel_Type="AppStore"
#
## archive_path 编辑出来的文件路径 存放在工程目录/appStoreAndAdHoc/WGAppName.archive
#project_archive_path=${project_path}/${project_Package}/${project_channel_Type}${temp_time}
#
##ipa文件存放路径 存放在工程目录/appStoreAndAdHoc/WGAppName.ipa
#project_export_ipa_path=${project_path}/${project_Package}/${project_channel_Type}${temp_time}
##TODO ExportOptions.plist路径(plist文件内容可以根据需要进行配置)目前appStoreAndAdHoc文件下放了AdHocExportOptions.plist和AppStoreExportOptions.plist两个文件
#project_export_options_plist=${project_path}/${project_Package}/AdHocExportOptions.plist
#
#
##清理工程
#funCleanProject() {
#    echo "********开始清理工程********"
#    xcodebuild clean -workspace ${project_WorkSpace_name} -scheme ${project_scheme_name} -configuration ${project_build_type} -quiet || exit
#    #shell中使用符号“$?”来显示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败
#    #-eq:等于 -ne:不等于 -gt:大于 -lt:小于 -ge:大于等于 -le:小于等于
#    #shell 语言中 0 代表 true，0 以外的值代表 false。
#    if [ $? -eq 0 ];then
#        echo "———————————————————清理工程完成———————————————————"
#    else
#        echo "———————————————————清理工程失败———————————————————"
#        exit
#    fi
#}
##编译工程
#funcCompileProject() {
#    echo "———————————————————开始编译工程———————————————————"
#    echo "———————————————————编译模式:${project_build_type}———————————————————"
#    xcodebuild archive -workspace ${project_WorkSpace_name} -scheme ${project_scheme_name} -configuration ${project_build_type} -archivePath ${project_archive_path} -quiet || exit
#    if [ $? -eq 0 ];then
#        echo "———————————————————编译工程成功———————————————————"
#    else
#        echo "———————————————————编译工程失败———————————————————"
#        exit
#    fi
#}
##导出ipa包到指定的平台
#funcExportIpa() {
#    echo "———————————————————开始导出IPA包———————————————————"
#    echo "———————————————————ipa路径:${project_export_ipa_path}———————————————————"
#    xcodebuild -exportArchive -archivePath ${project_archive_path}.xcarchive -exportPath ${project_export_ipa_path} -exportOptionsPlist ${project_export_options_plist} -quiet || exit
#    #导包完成后，判断是否成功
#    if [ $? -eq 0 ];then
#        #是否在指定的路径下存在ipa包
#        if [[ -e ${project_export_ipa_path}/$project_scheme_name.ipa ]];then
#            echo "———————————————————成功导出IPA———————————————————"
#            #打开存放ipa包的文件
#            open ${project_export_ipa_path}
#        else
#            echo "———————————————————导出IPA失败———————————————————"
#            exit
#        fi
#    else
#        echo "———————————————————导出IPA失败———————————————————"
#        exit
#    fi
#}
##删除archive文件
#funcDeleteArchive() {
#    echo "———————————————————删除archive文件———————————————————"
#    #判断archive文件是否存在
#    if [[ -e $project_archive_path.xcarchive ]];then
#        #如果存在删除该文件
#        #rm -rf 要删除的文件名或目录
#        rm -rf $project_archive_path.xcarchive
#        #上条命令执行成功后，再去判断文件是否存在，如果不存在，表示删除工程
#        if [ $? -eq 0 ];then
#            #如果对象不存在，则表示已经删除
#            if [ ! -e $project_archive_path.xcarchive ];then
#                echo "———————————————————删除archive文件成功———————————————————"
#            else
#                echo "———————————————————archive文件仍然存在，删除失败———————————————————"
#                exit
#            fi
#        else
#            echo "———————————————————删除archive文件失败———————————————————"
#            exit
#        fi
#    else
#        echo "———————————————————archive文件不存在———————————————————"
#        exit
#    fi
#}
#
##==================上传包相关方法========================
##上传ipa包到appStore
#funcUploadAppStore() {
#    echo "————————————————————————上传到AppStore————————————————————————"
#    AppStore_userName="苹果开发者账号邮箱"
#    AppStore_apiKey="RVV6XL677X"
#    AppStore_apiIssuer="69a6de7d-ec44-47e3-e053-5b8c7c11a4d1"
#    #验证包
#    echo "———————————————————验证IPA包———————————————————————"
#    xcrun altool --validate-app \
#    -f $project_export_ipa_path/$project_scheme_name.ipa \ #ipa包路径
#    -t iOS \
#    -u $AppStore_userName \
#    --apiKey $AppStore_apiKey \
#    --apiIssuer $AppStore_apiIssuer
#    #验证成功开始上传
#    if [ $? -eq 0 ];then
#        echo "———————————————————验证IPA包执行成功———————————————————————"
#        echo "————————————————开始上传IPA包———————————————————"
#        #上传包的时候发生错误: The -apiIssuer option must not include the -u option. 即去掉-u $AppStore_userName
#        xcrun altool --upload-app \
#        -f $project_export_ipa_path/$project_scheme_name.ipa \
#        -t iOS \
#        --apiKey $AppStore_apiKey \
#        --apiIssuer $AppStore_apiIssuer
#        if [ $? -eq 0 ];then
#            echo "———————————————————IPA包上传执行成功——————————————————"
#        else
#            echo "———————————————————IPA包上传执行失败——————————————————"
#        fi
#    else
#        echo "———————————————————验证IPA包执行失败———————————————————————"
#        exit
#    fi
#}
##上传ipa包到蒲公英
#funcUploadPGY() {
#    echo "————————————————上传到蒲公英平台————————————————"
#    curl -F "file=@$project_export_ipa_path/$project_scheme_name.ipa" \
#    -F "uKey=ed16193c55d89ebff0c1ee114e346394" \
#    -F "_api_key=c71aa37ed96c8947db74637eabb072d7" \
#    https://www.pgyer.com/apiv2/app/upload
#    #如果上传成功，接口会以 JSON 格式返回应用的详细信息。如果上传失败，则会返回相应的错误信息
#    if [ $? -eq 0 ];then
#        echo "————————————————上传到蒲公英成功————————————————"
#    else
#        echo "————————————————上传到蒲公英失败————————————————"
#        exit
#    fi
#}
#
#
##所有函数在使用前必须定义。这意味着必须将函数放在脚本开始部分，直至shell解释器首次发现它时，才可以使用。调用函数仅使用其函数名即可。shell 语言中 0 代表 true，0 以外的值代表 false。
##函数返回，可以显示加：return 返回，如果不加，将以最后一条命令运行结果，作为返回值
##$? 仅对其上一条指令负责，一旦函数返回后其返回值没有立即保存入参数
#
##funCleanProject
##echo $?
##如果funCleanProject指定执行的结果是0，即成功，打印0，否则打印非0
#
#funcInitProfile() {
#    echo "Please enter the number you want to export ? [1:App-Store包 2:Ad-Hoc包 3: 退出]"
#    echo "———————————————————等待输入———————————————"
#    read number
#    while ([[ $number != 1 ]] && [[ $number != 2 ]] && [[ $number != 3 ]])
#    do
#        echo "Error! you should enter 1 or 2 or 3"
#        echo "Please enter the number you want to export ? [1:App-Store包 2:Ad-Hoc包 3: 退出]"
#    read number
#    done
#    if [[ $number == 1 ]];then
#        project_channel_Type="AppStore"
#        project_build_type=Release
#        project_export_options_plist=${project_path}/${project_Package}/AppStoreExportOptions.plist
#    elif [[ $number == 2 ]];then
#        project_channel_Type="AdHoc"
#        project_build_type=Release
#        project_export_options_plist=${project_path}/${project_Package}/AdHocExportOptions.plist
#    else
#        exit
#    fi
#    project_archive_path=${project_path}/${project_Package}/${project_channel_Type}${temp_time}
#    project_export_ipa_path=${project_path}/${project_Package}/${project_channel_Type}${temp_time}
#}
#
##初始化相关配置参数
#funcInitProfile
##清理工程
#funCleanProject
##编译工程
#funcCompileProject
##导出IPA
#funcExportIpa
##删除archvie
#funcDeleteArchive
#
##判断是否继续下一步包上传操作
#echo "————————Please enter the number you want to next action？[1:上传到App-Store 2:上传到蒲公英 3:退出]————————"
#read isAction
#while ([[ $isAction != 1 ]] && [[ $isAction != 2 ]] && [[ $isAction != 3 ]])
#do
#    echo "Error! you should enter 1 or 2 or 3"
#    echo "————————Please enter the number you want to next action？[1:上传到App-Store 2:上传到蒲公英 3:退出]————————"
#read isAction
#done
#
#if [[ $isAction == 1 ]];then
#    funcUploadAppStore
#elif [[ $isAction == 2 ]];then
#    funcUploadPGY
#else
#    exit
#fi
#
#
##if比较的字符用法
##-e 判断对象是否存在
##-d 判断对象是否存在，并且为目录
##-f 判断对象是否存在，并且为常规文件
##-L 判断对象是否存在，并且为符号链接
##-h 判断对象是否存在，并且为软链接
##-s 判断对象是否存在，并且长度不为0
##-r 判断对象是否存在，并且可读
##-w 判断对象是否存在，并且可写
##-x 判断对象是否存在，并且可执行
##-O 判断对象是否存在，并且属于当前用户
##-G 判断对象是否存在，并且属于当前用户组
#
#
### ******************上传到APPStore相关总结********************
##上传ipa包一般用命令:xcrun altool 查看命令功能
##-f <file> specifies the path to the file to process
##-t <platform> {osx | ios | appletvos}  Specify the platform of the file.
##-u, --username <username> Username. Required to connect for validation, upload, and notarization.
##-p, --password <password> Password. Required if username specified and apiKey/apiIssuer are not.
##--apiKey <api_key>
##--apiIssuer <issuer_id>}
##altool --validate-app -f <file> -t <platform> -u <username> {[-p <password>] | --apiKey <api_key> --apiIssuer <issuer_id>}
##altool --upload-app -f <file> -t <platform> -u <username> {[-p <password>] | --apiKey <api_key> --apiIssuer <issuer_id>}
##AppStore_userName="苹果开发者账号邮箱"
##AppStore_pwd="Bai3KFZZH6bo"
##验证包
##xcrun altool --validate-app -f $project_export_ipa_path/$project_scheme_name.ipa -t iOS -u ${AppStore_userName} -p ${AppStore_pwd}
##上传包
##xcrun altool --upload-app -f $project_export_ipa_path/$project_scheme_name.ipa -t iOS -u ${AppStore_userName} -p ${AppStore_pwd}
##使用开发者账号的用户名和密码进行上传的时候，会报下面的错误信息，大意就是说你的我们现在采用了新的验证方式,不是你输入的密码不对,而是你需要用上面命令中的--apiKey --apiIssuer
##Error: Unable to validate archive '/Users/baicai/Desktop/XXX/appStoreAndAdHoc/WGAppName_2019-12-24_14:45:43/WGAppName.ipa': (
##"Error Domain=ITunesSoftwareServiceErrorDomain Code=-22020 \"We are unable to create an authentication session.\" UserInfo={NSLocalizedDescription=We are unable to create an authentication session., NSLocalizedFailureReason=Unable to validate your application.}"
#
##使用--apiKey --apiIssuer进行验证和上传
##altool --validate-app -f <file> -t <platform> -u <username> --apiKey <api_key> --apiIssuer <issuer_id>
##apiKey和apiIssuer需要在App Store Connect 用户和访问->密钥->生成API密钥->设置名称和访问权限(权限尽量给予最高权限-管理),Issuer ID就是AppStore_apiIssuer，密钥ID就是AppStore_apiKey，后面有个蓝色字体的【下载API密钥】，该文件只能下载一次，所以下载后要妥善保管，丢了就只能删除重新生成一下，该文件是和Issuer ID对应的,以网联客为例：下载下来后的文件名称为[AuthKey_RVV6XL677X.p8]，即AuthKey_apiKey值.p8
##直接运行脚本会出现下面错误，其实就是系统在根目录下找不到你的apiKey文件放哪里了
##Could not find private key file: AuthKey_RVV6XL677X.p8, in any of the following locations.\\n ./private_keys or <user home>/private_keys or <user home>/.private_keys or <user home>/.appstoreconnect/private_keys.
##使用linux命令将下载下来的密钥文件放在系统跟目录
## cd ~  到根目录
## mkdir .private_keys 根目录下生产了一个名叫private_keys隐藏文件夹
## ls -a 查看根目录下所有的文件，包括隐藏文件private_keys
## cd .private_keys 进入文件夹
## pwd 打印文件夹路径p1 /Users/baicai/.private_keys
## cd 下载AuthKey_RVV6XL677X.p8的路径下
## mv AuthKey_RVV6XL677X.p8 /Users/baicai/.private_keys 将下载下来的文件移动到.private_keys文件夹下
#
#
### ******************上传到蒲公英相关总结********************
##使用 Fastlane 上传 App 到蒲公英，https://www.pgyer.com/doc/view/fastlane
##curl -F "file=@{$filePath}" \   #应用安装包(ipa)文件的路径
##-F "uKey={$uKey}" \             #是开发者的用户 Key，在应用管理-API中查看
##-F "_api_key={$apiKey}" \       #是开发者的 API Key，在应用管理-API中查看
