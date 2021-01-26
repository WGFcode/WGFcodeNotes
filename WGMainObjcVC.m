//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import "Person.h"
#import <objc/runtime.h>
#import "Student.h"
#import <malloc/malloc.h>
#import "WGTargetProxy.h"
#import "Person+PersonTest.h"

#import <pthread.h>

@interface WGMainObjcVC()

@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];

}


@end


