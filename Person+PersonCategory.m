//
//  Person+PersonCategory.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person+PersonCategory.h"
#import <objc/runtime.h>

@implementation Person (PersonCategory)

//重写teachName属性的getter/setter方法
-(NSString *)teachName {
    return objc_getAssociatedObject(self, @"teachName");
}

-(void)setTeachName:(NSString *)teachName {
    objc_setAssociatedObject(self, @"teachName", teachName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(void)sleep {
    NSLog(@"PersonCategory am sleeping");
}
@end
