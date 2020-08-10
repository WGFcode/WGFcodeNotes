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


@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id array = [[NSMutableArray alloc]init];
    void (^WGCustomBlock)(id obj) = ^(id obj) {
        [array addObject:obj];
        NSLog(@"array count is:%ld",[array count]);
    };
    WGCustomBlock([[NSObject alloc]init]);
    WGCustomBlock([[NSObject alloc]init]);
    WGCustomBlock([[NSObject alloc]init]);
    
//    id array = [[NSMutableArray alloc]init];
//    WGCustomBlock = ^(id obj) {
//        [array addObject:obj];
//        NSLog(@"array count is:%ld",[array count]);
//    };
    
    
//    id array = [[NSMutableArray alloc]init];
//    void (^WGCustomBlock)(id) = [^(id obj) {
//        [array addObject:obj];
//        NSLog(@"array count is:%ld",[array count]);
//    } copy];
//    WGCustomBlock([[NSObject alloc]init]);
//    WGCustomBlock([[NSObject alloc]init]);
//    WGCustomBlock([[NSObject alloc]init]);
    
}


@end


