//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"



@interface WGMainObjcVC()
{
    NSString *_name;
    int _age;
}
@end

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _age = 18;
    _name = @"张三";
    void(^WGCustomBlock)(void) = ^{
        NSLog(@"我的名字是:%@,我的年龄是:%d",self->_name,self->_age);
    };
    _age = 30;
    _name = @"李四";
    WGCustomBlock();
}




@end
