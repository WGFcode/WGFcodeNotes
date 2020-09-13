//
//  WGProxy.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/13.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGProxy.h"

@implementation WGProxy
//作用就是 消息转发
-(void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}
@end
