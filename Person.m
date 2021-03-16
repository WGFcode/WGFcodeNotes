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
/*
 1.@synthesize关键词是很早之前的写法,现在已经不需要再写这个关键词了,Xcode默认已经实现了,只要写
 上属性@property,就会自动生成成员变量和getter/setter方法的实现
 2.@synthesize age = _age; 为age属性生成_age的成员变量,并且自动生成getter/setter方法的实现,这里可以指定成员变量的
 名称,例如也可以这样写@synthesize age = _age1111;
 */
@synthesize age = _age;


/*
 如果我们不希望Xcode自动帮我们生成属性的getter/setter方法的实现,可以这么写@dynamic age;
 提醒编译器不要自动生成getter/setter的实现,不要自动生成成员变量
 外部仍然可以调用setAge方法,因为@dynamic并步影响属性的getter/setter方法的声明
 */
@dynamic age;

@end


