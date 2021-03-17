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

-(void)run {
    NSLog(@"----%s",__func__);
}

//拦截因为unrecognized selector sent to instance而crash闪退的问题
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //本来能调用的方法
    if ([self respondsToSelector:aSelector]) {
        return [super methodSignatureForSelector:aSelector];
    }
    //找不到方法调用时,返回一个方法签名
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
}
//找不到的方法
-(void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"找不到%@方法",NSStringFromSelector(anInvocation.selector));
}
@end


