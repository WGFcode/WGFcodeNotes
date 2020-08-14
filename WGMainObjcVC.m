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

// Block起别名
typedef void (^WGCustomBlock)(WGMainObjcVC *);
@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *name;
@property(nonatomic, copy) WGCustomBlock block;
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.name = @"张三";
    self.block = ^(WGMainObjcVC *vc) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"我的名字是:%@",vc.name);
        });
    };
    self.block(self);
}

-(void)dealloc {
    NSLog(@"对象销毁了");
}

@end


