//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"

@implementation Person


//+(instancetype)shareInstance {
//    static Person *p;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        p = [[Person alloc]init];
//    });
//    return p;
//}
//
//+(instancetype)allocWithZone:(struct _NSZone *)zone {
//    return [Person shareInstance];
//}













//static Person *p = nil;
//static dispatch_once_t onceToken;
//
//+(instancetype)shareInstance {
//    dispatch_once(&onceToken, ^{
//        p = [[Person alloc]init];
//    });
//    return p;
//}
//
////销毁单例，必须把static dispatch_once_t onceToken;写在函数的最外面，作为一个全局的静态变量
//+(void)cleanInstance {
//    // 只有置成0,GCD才会认为它从未执行过.它默认为0,这样才能保证下次再次调用shareInstance的时候,再次创建对象.
//    onceToken = 0;
//    p = nil;
//}

@end
