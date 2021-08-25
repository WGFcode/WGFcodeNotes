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
/*
 extern声明全局变量或常量的实现，必须实现，否则外部使用时，编译期会报错
 */
//NSString *name1 = @"zhangsan";
//NSString *const name2 = @"lisi";


@interface Person() <NSCoding>

@end

@implementation Person

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.name = [coder decodeObjectForKey:@"name"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
}

//-(instancetype)initWithCoder:(NSCoder *)coder {
//    self = [super init];
//    if (self) {
//        self.name = [coder decodeObjectForKey:@"name"];
//    }
//    return self;
//}
//-(void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:self.name forKey:@"name"];
//}

@end


