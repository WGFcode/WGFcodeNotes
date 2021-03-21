//
//  NSMutableDictionary+WGHookMutableDictionary.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import "NSMutableDictionary+WGHookMutableDictionary.h"
#import <objc/runtime.h>

@implementation NSMutableDictionary (WGHookMutableDictionary)

+(void)load {
    //这里不能填写self,因为NSString、NSArray、NSDictionary属于类簇,类簇的真实类型是其它类型
    //Method method1 = class_getInstanceMethod(self, @selector(insertObject:atIndex:));
    
    Class cls = NSClassFromString(@"__NSDictionaryM");
    Method method1 = class_getInstanceMethod(cls, @selector(setObject:forKeyedSubscript:));
    Method method2 = class_getInstanceMethod(cls, @selector(WG_setObject:forKeyedSubscript:));
    method_exchangeImplementations(method1, method2);
}

-(void)WG_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (key == nil) {
        return;
    }
    [self WG_setObject:obj forKeyedSubscript:key];
}
@end
