//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"


@implementation WGMainObjcVC



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    //1.有参数有返回值
//    NSString* (^WGCustomBlock)(NSString *) = ^(NSString *name){
//        NSLog(@"名称是:%@",name);
//        return [NSString stringWithFormat:@"%@",name];
//    };
//    NSString *name = WGCustomBlock(@"张三");
//    NSLog(@"%@",name);
    //2.有多个参数有返回值
    NSString* (^WGCustomBlock)(NSString *, int) = ^(NSString *name, int age) {
        NSLog(@"name:%@-age:%d",name,age);
        return [NSString stringWithFormat:@"%@-%d",name,age];
    };
    NSString *info = WGCustomBlock(@"张三",18);
    NSLog(@"%@",info);
    
    //3.有参数无返回值
//    void (^WGCustomBlock)(NSString *) = ^(NSString *name) {
//        NSLog(@"我的名字叫:%@",name);
//    };
//    WGCustomBlock(@"张三");
    //4. 无参数有返回值
//    NSString *(^WGCustomBlock)(void) = ^(void) {
//        NSLog(@"我是张三");
//        return @"张三";
//    };
//    NSString *name = WGCustomBlock();
//    NSLog(@"%@",name);
    
//    NSString *(^WGCustomBlock)(void) = ^{
//        NSLog(@"我是张三");
//        return @"张三";
//    };
//    NSString *name = WGCustomBlock();
//    NSLog(@"%@",name);
    //5 无参数无返回值
//    void(^WGCustomBlock)(void) = ^(void) {
//        NSLog(@"我是张三");
//    };
//    void(^WGCustomBlock)(void) = ^{
//        NSLog(@"我是张三");
//    };

    
    
    
    
    
    
}


@end
