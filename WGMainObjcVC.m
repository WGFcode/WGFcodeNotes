//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import "Student.h"
#import "Student+WGStudent.h"
#import "Student+StudentCategory.h"

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    Student *stu = [[Student alloc]init];
    [stu test];
//    [stu test111];
}
@end


