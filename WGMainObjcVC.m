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
#import "Student.h"
#import "Car.h"
#import "message.h"


@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *nameStrong;
@property(nonatomic, copy) NSString *nameCopy;
@end


@implementation WGMainObjcVC



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    int a = 10;
    int b = 20;
    NSNumber *num = [NSNumber numberWithInt:1];
    
}

@end


