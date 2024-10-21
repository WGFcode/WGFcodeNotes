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
