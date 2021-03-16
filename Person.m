//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"
#import "Student.h"
#import <objc/runtime.h>


@implementation Person
/// 1. 消息发送阶段
/// 2. 动态方法解析
+(BOOL)resolveInstanceMethod:(SEL)sel {
    return [super resolveInstanceMethod:sel];
}

+(BOOL)resolveClassMethod:(SEL)sel {
    return [super resolveClassMethod:sel];
}

/// 动态方法解析如果没有处理会进入消息转发阶段
///3.消息转发阶段
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(testInstanceMethod:)) {
        //返回一个可以处理的事件的对象
        //return [[Student alloc]init];
        return nil;
    }
    return [super forwardingTargetForSelector:aSelector];
}
///4. 如果第三步返回的是nil,那么就继续看执行下面的方法
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //返回一个方法签名： 方法签名其实包含了方法返回值类型，参数类型
    //return [NSMethodSignature signatureWithObjCTypes:"v16@0:8"];
    return [[[Student alloc]init] methodSignatureForSelector:aSelector];
}
//5.如果方法签名返回的有效，那么就会继续执行下面这一步
-(void)forwardInvocation:(NSInvocation *)anInvocation {
    //[anInvocation invokeWithTarget:[[Student alloc]init]];
    //NSLog(@"-------");
}

@end


