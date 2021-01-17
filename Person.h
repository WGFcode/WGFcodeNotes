//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WGBlock) (void);

@interface Person : NSObject
//属性会帮我们 1.生成_age的成员变量、2.生成setter/getter方法声明、3.setter/getter方法的具体实现
@property(nonatomic, assign) int age;
@end


NS_ASSUME_NONNULL_END
