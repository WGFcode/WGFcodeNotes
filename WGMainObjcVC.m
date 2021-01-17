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



@interface WGMainObjcVC()
@property(nonatomic, copy) NSString *name;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    Person *person1 = [[Person alloc]init];
    person1.name= @"zhang san";
    NSLog(@"name is %@",person1.name);
    
    Person *person2 = [[Person alloc]init];
    person2.name= @"li si";
    NSLog(@"name is %@",person2.name);
    
}
@end


