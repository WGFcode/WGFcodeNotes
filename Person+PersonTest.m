//
//  Person+PersonTest.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/1/17.
//  Copyright © 2021 WG. All rights reserved.
//

#import "Person+PersonTest.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation Person (PersonTest)

NSString *name_;

-(void)setName:(NSString *)name {
    name_ = name;
}

-(NSString *)name {
    return name_;
}

//const void *PersonNameKey = &PersonNameKey;

//-(void)setName:(NSString *)name {
//    //添加关联对象: 关联哪个对象(self)、、关联的值是什么(name)、关联策略(name用的是copy修饰所以使用如下策略)
//    objc_setAssociatedObject(self, @selector(name), name, OBJC_ASSOCIATION_COPY_NONATOMIC);
//
//}
//-(NSString *)name {
//    //获取关联对象
//    return objc_getAssociatedObject(self, _cmd);
//}

/*
关联策略
typedef OBJC_ENUM(uintptr_t, objc_AssociationPolicy) {
    OBJC_ASSOCIATION_ASSIGN = 0,                //对应的修饰符: assign
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,      //对应的修饰符: strong、nonatomic
    OBJC_ASSOCIATION_COPY_NONATOMIC = 3,        //对应的修饰符: copy、nonatomic
    OBJC_ASSOCIATION_RETAIN = 01401,            //对应的修饰符: strong、atomic
    OBJC_ASSOCIATION_COPY = 01403               //对应的修饰符: copy、atomic
};
*/
@end
