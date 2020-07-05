//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "BinaryTree.h"

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];


    NSArray *arr = @[@12, @53, @2, @234, @12, @34, @123, @34, @66];
    BinaryTree *tree = [BinaryTree create:arr];
    NSLog(@"-----%@-----",tree);


}

@end


