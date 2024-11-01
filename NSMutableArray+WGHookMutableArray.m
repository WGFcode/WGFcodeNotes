//
//  NSMutableArray+WGHookMutableArray.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import "NSMutableArray+WGHookMutableArray.h"
#import <objc/runtime.h>

@implementation NSMutableArray (WGHookMutableArray)

+(void)load {
    //这里不能填写self,因为NSString、NSArray、NSDictionary属于类簇,类簇的真实类型是其它类型
    //Method method1 = class_getInstanceMethod(self, @selector(insertObject:atIndex:));
    
    Class cls = NSClassFromString(@"__NSArrayM");
    Method method1 = class_getInstanceMethod(cls, @selector(insertObject:atIndex:));
    Method method2 = class_getInstanceMethod(cls, @selector(WG_insertObject:atIndex:));
    method_exchangeImplementations(method1, method2);

}
                                             
-(void)WG_insertObject:(id)anObject atIndex:(NSUInteger)index {
    if (anObject == nil) { //如果添加的元素为nil,直接返回,不需要再去调用添加的方法了
        return;
    }
    //如果不为nil,则可以继续进行添加元素的方法
    [self WG_insertObject:anObject atIndex:index];
}

@end
