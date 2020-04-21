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
    
    __unsafe_unretained WGAnimal *animal = [[WGAnimal alloc]init];
    animal.block1 = ^(NSString * _Nonnull name) {
        NSLog(@"动物的年龄是:%d",animal.age);
    };
    
}




@end
