//
//  Student.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/22.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Student.h"

//这种在Student类的.m文件中写@interface...@end的方式就是类扩展
@interface Student()
{
    int _age;
}
@property(nonatomic, strong) NSString *name;
-(void)test111;

@end


@implementation Student

-(void)test{
    _age = 50;
    NSLog(@"我几年的年纪是:%d",_age);
}

@end
