//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
/*
 extern都是写在.h文件中，声明全局变量或常量；这里仅仅是声明，实现是在.m文件中
 如果这里只声明，而在.m文件中没有实现，外部如果使用的话编译会报错
 */
//extern NSString *name1;         //声明全局变量-外部可以修改
//extern NSString *const name2;   //声明全局常量-外部不能修改


typedef void(^WGBlock)(void);

NSString *WG_student;
extern bool sex;

@interface Person : NSObject

//显式声明extern表明其不是成员变量，而是全局变量
extern NSString *name;
extern int age;

@end


NS_ASSUME_NONNULL_END
