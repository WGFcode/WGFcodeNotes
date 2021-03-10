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
#import "Person.h"


@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *nameStrong;
@property(nonatomic, copy) NSString *nameCopy;
@end


@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    [Person test];
}




@end


