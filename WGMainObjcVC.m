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


@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *nameStrong;
@property(nonatomic, copy) NSString *nameCopy;
@end


@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSMutableString *baseName = [NSMutableString stringWithString:@"张三"];
    NSString *copyName = [baseName copy];
    NSString *mutableName = [baseName mutableCopy];
    
    NSLog(@"-----%p------%p-----%p",baseName, copyName,mutableName);
    
    
}


@end


