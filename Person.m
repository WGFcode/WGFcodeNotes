//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"
#import <objc/runtime.h>

@implementation Person
/*
 typedef struct objc_method *Method;
 objc_method其实等价于method_t结构体
 struct method_t {
            SEL name;
            const char *types;
            IMP imp;
 };
 */

+(void)otherTest{
    NSLog(@"---%s---",__func__);
}


//类方法
+(BOOL)resolveClassMethod:(SEL)sel {
    if (sel == @selector(test)) {
        //获取类方法
        Method otherMethod = class_getClassMethod(self, @selector(otherTest));
        //将类方法添加到元类对象中, 类(self)的object_getClass就是元类对象
        class_addMethod(object_getClass(self),
                        sel,
                        method_getImplementation(otherMethod),
                        method_getTypeEncoding(otherMethod)
                        );
        return YES;
    }
    return [super resolveClassMethod:sel];
}

@end


