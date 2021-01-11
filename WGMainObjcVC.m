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




@interface WGMainObjcVC()
@property(nonatomic, copy) NSString *name;
@end


typedef void (^WGBlock) (void);

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    Person *person = [[Person alloc]init];
    __block __weak Person *weakPerson = person;
    WGBlock block = ^{
        NSLog(@"---%p",weakPerson);
    };
    block();
}




@end


