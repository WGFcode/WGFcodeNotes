//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"
#import "Student.h"

@implementation Person

/// 返回一个方法签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(test:)) {
        return [NSMethodSignature signatureWithObjCTypes:"v20@0:8i16"];
        
    }
    return [super methodSignatureForSelector:aSelector];
}

/// 这里可以尽情的实现方法调用
-(void)forwardInvocation:(NSInvocation *)anInvocation {
    //参数顺序: receiver、selector、other arguments
    int age;
    [anInvocation getArgument:&age atIndex:2];
    anInvocation getReturnValue:<#(nonnull void *)#>
    NSLog(@"%d",age+10);
}

@end


