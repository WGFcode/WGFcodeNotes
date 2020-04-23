//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGAnimal

@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    WGAnimal *a = [[WGAnimal alloc]init];
    a.name = @"小狗";
    __weak typeof(a) weakSelfA = a;
    a.block = ^(int age) {
        __strong typeof(a) strongSelfA = weakSelfA;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"我的名字是:%@,我的年龄是:%d,weakSelfA:%@",strongSelfA.name,age,weakSelfA);
        });
        NSLog(@"我的名字是:%@,我的年龄是:%d,weakSelfA:%@",weakSelfA.name,age,weakSelfA);
    };
    a.block(18);
}
@end
