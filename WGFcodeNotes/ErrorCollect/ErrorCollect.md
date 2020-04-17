## 错误集锦
### 1.提交APP审核的时候，遇到❌您的 App 正在使用广告标识符 (IDFA)。您必须先提供关于 IDFA 的使用信息或将其从 App 中移除，然后再上传您的二进制文件。，APP中并没有用到广告，但提示这个错误了，排除问题方法如下
* 检查项目是否使用了AdSupport.framework
* cd到工程目录，使用命令行【grep -r advertisingIdentifier .】检查什么地方引用的相关广告


