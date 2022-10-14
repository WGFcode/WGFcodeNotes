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


@interface Person()

@end

@implementation Person

-(void)run {
    NSLog(@"-----%s----",__func__);
}

+(int)thisClassMethod:(NSString *)name {
    NSLog(@"-----%s----name:%@",__func__,name);
    return 0;
}
//
//+(int)thisClassMethod {
//    NSLog(@"-----%s----",__func__);
//    return 0;
//}

//-(instancetype)initWithCoder:(NSCoder *)coder {
//    self = [super init];
//    if (self) {
//        self.name = [coder decodeObjectForKey:@"name"];
//    }
//    return self;
//}
//
//-(void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:self.name forKey:@"name"];
//}

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


/// KVO默认是自动通知，也就是当我们属性的值变化时，就会自动发送通知
//+(BOOL)automaticallyNotifiesObserversOfName {
//    return YES;
//}
//+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    return NO;
//}

-(void)dealloc {
    NSLog(@"%s",__func__);
}


@end


