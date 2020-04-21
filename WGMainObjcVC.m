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
    
    void (^WGCustomBlock)(NSString *) = ^(NSString *name){
        NSLog(@"我的名字是:%@,所在的类是:%@",name,[self class]);
    };
    WGCustomBlock(@"张三");
}




@end
