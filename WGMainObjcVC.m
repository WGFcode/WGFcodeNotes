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

    WGTeacher *tea1 = [[WGTeacher alloc]init];
    tea1.name = @"张老师";
    WGTeacher *tea2 = [[WGTeacher alloc]init];
    tea2.name = @"赵老师";
    WGTeacher *tea3 = [[WGTeacher alloc]init];
    tea3.name = @"王老师";
    NSArray *teacherArr = @[tea1,tea2,tea3];
    //公开方法 无返回值 无参数
    NSArray *eatResultArr = [teacherArr valueForKey:@"eat"];
    //公开方法 有返回值 无参数
    NSArray *answerQuestionNumArr = [teacherArr valueForKey:@"answerQuestionNum"];
    //私有方法 无返回值 无参数
    NSArray *runResultArr = [teacherArr valueForKey:@"run"];
    NSLog(@"\neatResultArr:%@\nanswerQuestionNumArr:%@\nrunResultArr:%@",eatResultArr,answerQuestionNumArr, runResultArr);
    
    
    NSArray *foodNameArr = [teacherArr valueForKey:@"footName"];
    NSLog(@"foodName:%@",foodNameArr);
    
}


@end
