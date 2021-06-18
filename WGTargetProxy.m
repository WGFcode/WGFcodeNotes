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


- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

@end
