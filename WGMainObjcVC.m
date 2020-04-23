//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //__weak typeof(self) weakSelf = self;
    _block = ^(NSString *name) {
        NSLog(@"我的名字是:%@,我所在的类是:%@",name,self);
    };
    _block(@"张三");
}

@end
