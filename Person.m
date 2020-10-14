//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"

@interface Person()

@end


@implementation Person
//重写监听属性的setter方法
-(void)setAge:(int)age {
    NSLog(@"setAge方法---");
    _age = age;
}

-(void)willChangeValueForKey:(NSString *)key {
    NSLog(@"willChangeValueForKey---begin");
    [super willChangeValueForKey: key];
    NSLog(@"willChangeValueForKey---end");
}

-(void)didChangeValueForKey:(NSString *)key {
    NSLog(@"didChangeValueForKey---begin");
    [super didChangeValueForKey:key];
    NSLog(@"didChangeValueForKey---begin");
}

@end


