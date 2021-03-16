//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface Person : NSObject
/*
 写上这么一个属性,编译器会自动帮我们
 1.生成对应的getter/setter方法的声明
 -(void)setAge:(int)age;
 -(int)age;
 
 2._age成员变量
 {
    int _age;
 }
 
 3. getter/setter方法的实现
 -(void)setAge:(int)age {
     _age = age;
 }
 -(int)age {
     return _age;
 }
 */
@property(nonatomic, assign)int age;


@end


NS_ASSUME_NONNULL_END
