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

@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    Person *person = [[Person alloc]init];
    __weak Person *weakPerson = person;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"1----%@",person);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"2----%@",weakPerson);
        });
    });
    NSLog(@"%s",__func__);
}


@end


