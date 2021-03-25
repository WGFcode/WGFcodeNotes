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



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    Person *p = [[Person alloc]init];
    [p run];
    
//    //获取一个类的所有方法
//    unsigned int count;
//    Method *methodList = class_copyMethodList([Person class], &count);
//    for (int i = 0 ; i < count; i++) {
//        Method method = methodList[i];
//        SEL methodSEL = method_getName(method);
//        NSString *methodName = NSStringFromSelector(methodSEL);
//        NSLog(@"%@------方法:%@",[Person class],methodName);
//    }
//
//    //获取一个类的成员变量
//    unsigned int count1;
//    Ivar *ivarList = class_copyIvarList([Person class], &count1);
//    for (int i = 0; i < count1; i++) {
//        Ivar iv = ivarList[i];
//        const char *ivarNameC = ivar_getName(iv);
//        NSString *ivarName = [[NSString alloc]initWithUTF8String:ivarNameC];
//        NSLog(@"%@---成员变量:%@",[Person class],ivarName);
//    }
    
    
    
//    unsigned int count;
//    // 获取方法数组
//    Method *methodList = class_copyMethodList(cls, &count);
//    // 存储方法名
//    NSMutableString *methodNames = [NSMutableString string];
//    // 遍历所有的方法
//    for (int i = 0; i < count; i++) {
//        // 获得方法
//        Method method = methodList[i];
//        // 获得方法名称
//        NSString *methodName = NSStringFromSelector(method_getName(method));
//        [methodNames appendString:methodName];
//        [methodNames appendString:@","];
//    }
//    // 释放
//    free(methodList);
//    //打印方法名
//    NSLog(@"%@类中的方法---%@",cls, methodNames);
    
    
    
}

@end


