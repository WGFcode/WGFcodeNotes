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
    self.view.backgroundColor = [UIColor redColor];
    [self getName:^(NSString * _Nonnull name) {
        NSLog(@"我的名字是:%@",name);
    }];
}

-(void)getName:(WGCustomBlock)block {
    block(@"张三");
}


@end
