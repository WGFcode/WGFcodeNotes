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

@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *nameStrong;
@property(nonatomic, copy) NSString *nameCopy;
@end


@implementation WGMainObjcVC

void myRun() {
    NSLog(@"---my Run");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *obj = nil;
    NSMutableDictionary *muDic = [NSMutableDictionary dictionary];
    //下面代码等价于 [muDic setObject:@"zhangSan" forKey:@"name"];
    muDic[@"name"] = @"zhangSan";
    muDic[obj] = @"ceShi";
}

@end


