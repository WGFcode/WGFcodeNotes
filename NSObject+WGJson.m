//
//  NSObject+WGJson.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import "NSObject+WGJson.h"
#import <objc/runtime.h>


@implementation NSObject (WGJson)
+(instancetype)WG_objectWithJson:(NSDictionary *)json {
    id obj = [[self alloc]init];
    unsigned int count;  //成员变量的数量
    Ivar *ivars = class_copyIvarList(self, &count);
    for (int i = 0; i < count; i++) {
        //取出i位置的成员变量
        Ivar iva = ivars[i];
        //C语言的成员变量字符串
        const char *charName = ivar_getName(iva);
        //C语言字符串转为OC语言
        NSMutableString *name = [NSMutableString stringWithUTF8String:charName];
        //将成员变量的_去除
        [name deleteCharactersInRange:NSMakeRange(0, 1)];
        //设置值
        [obj setValue:json[name] forKey:name];
    }
    return obj;
}
@end
