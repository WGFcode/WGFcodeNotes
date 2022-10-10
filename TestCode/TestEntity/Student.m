//
//  Student.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/22.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Student.h"
#import <objc/runtime.h>

@implementation Student
/*
-(void)run {
    NSLog(@"-----%s-----",__func__);
}

+(void)thisClassMethod {
    NSLog(@"-----%s----",__func__);
}

-(void)otherRun {
    NSLog(@"-----%s-----",__func__);
}

+(BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(run)) {
        //动态添加方法实现
        Method method = class_getClassMethod(self, @selector(otherRun));
        class_addMethod(self, sel, method_getImplementation(method), method_getTypeEncoding(method));
        return true;
    }
    return [super resolveInstanceMethod:sel];
}
//实例方法
-(id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(run)) {
        return [[Person alloc]init];
    }
    return [super forwardingTargetForSelector:aSelector];
}
//类方法
+(id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(thisClassMethod)) {
        //如果调用的是类方法，必须返回一个类对象
        //return object_getClass([[Person alloc]init]);
        return [Person class];
    }
    return [super forwardingTargetForSelector:aSelector];
}


//返回一个方法签名
-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(run)) {
        //返回一个有效的方法签名 这个方法签名必须是有效的，可以是任意参数类型
        return [NSMethodSignature signatureWithObjCTypes:"i@:i::"];
    }
    return [super methodSignatureForSelector:aSelector];
}

-(void)forwardInvocation:(NSInvocation *)anInvocation {
    //实现方法1:可以转发给其他对象
    //[anInvocation invokeWithTarget:[[Person alloc]init]];
    //实现方法2:可以什么都不做，直接打印一段话/或者什么也不干/ 但是必须要实现这个方法
    //NSLog(@"11111");
}

//类方法调用的消息转发方法
+(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(thisClassMethod)) {
        //返回一个有效的方法签名
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

+(void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"222222");
}
*/

@end
