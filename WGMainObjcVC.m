//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "BinaryTree.h"
#import <UIKit/UIKit.h>
#import "WGFirstVC.h"
#import "Person.h"
#import "Person+PersonCategory.h"

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];

    Person *p = [[Person alloc]init];
    [p sleep];
}

-(void)dealloc {
    NSLog(@"对象销毁了");
}

@end


