## 错误集锦
### 1.加载webView时候，Xcode会打印如下日志
![](https://github.com/WGFcode/WGFcodeNotes/blob/master/WGFcodeNotes/WGScreenshots/error1.png)

#### 解决方案：Xcode -> Product -> Edit Scheme -> Run -> Arguments -> Environment Variables 添加name: OS_ACTIVITY_MODE Value:disable，可以去掉该日志

