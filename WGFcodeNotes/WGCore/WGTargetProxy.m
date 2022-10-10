//
//  WGProxy.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/10/15.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGTargetProxy.h"

@implementation WGTargetProxy
+(instancetype)proxyWithTarget:(id)target {
    //继承自NSProxy类的对象没有init方法
    WGTargetProxy *proxy = [WGTargetProxy alloc];
    proxy.target = target;
    return proxy;
}

//下面两个方法是NSProxy内部提供的方法，其实就是普通NSObject的消息机制中的第三阶段:消息转发中的最后一次判断
//继承自NSProxy的中间代理方法好处：可以有效避免方法繁琐的方法查找流程,最起码消息发送和动态方法解析阶段可以不需要再去寻找了，直接就到消息转发的最后一步进行处理
//返回方法签名
-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}




@end
