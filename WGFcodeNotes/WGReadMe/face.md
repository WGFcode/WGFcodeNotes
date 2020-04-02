
#### 1.方法调用三种方式
1. [testObject testMethod];
2. [self perform(<#T##aSelector: Selector!##Selector!#>, with: <#T##Any!#>)]
3.  1) 通过方法调用者创建方法签名,
     2) 然后通过方法签名生成NSInvocation对象
     3) 设置方法调用者，方法选择器，方法参数
     4) 执行并获取返回值
