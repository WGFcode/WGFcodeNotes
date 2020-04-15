//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "WGTestModel.h"


@interface WGMainObjcVC ()

@end

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    WGTeacher *tea = [[WGTeacher alloc]init];
    WGStudent *stu = [[WGStudent alloc]init];
    stu.teacher = tea;
    //赋值
    [stu setValue:@"小明" forKey:@"name"];
    [stu setValue:@"王老师" forKeyPath:@"teacher.name"];
    //获取值
    NSString *teaName = [stu valueForKeyPath:@"teacher.name"];
    NSString *stuName = [stu valueForKey:@"name"];
    NSLog(@"学生姓名:%@---老师姓名:%@",stuName,teaName);
    
    
    
}


@end
