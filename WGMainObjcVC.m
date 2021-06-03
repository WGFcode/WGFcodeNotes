//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Student.h"



@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    Student *s = [[Student alloc]init];
    s->age = 8;
    s->sex = YES;
    
    NSLog(@"---%ld",class_getInstanceSize([s class]));
    //0x0000000282d451f0
    // A1 7B 4B 02 A1 01 00 00 04 00 00 00 00 00 00 00
    
    //0x0000000282ba5050
    //C9 7B C7 04    A1 01 00 00     08 00 00 00     00 00 00 00  60 50 6B 25 5F 26 00 00
    //C9 BB 74 04    A1 01 00 00     08 00 00 00     01 00 00 00
}

@end


