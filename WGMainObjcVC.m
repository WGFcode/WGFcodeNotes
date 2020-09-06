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

@interface WGMainObjcVC()

@property(nonatomic, strong) NSString *strongStr;
@property(nonatomic, copy) NSString *copyyStr;
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1. 用可变字符串赋值操作,
    NSString *baseStr = [NSString stringWithFormat:@"123"];
    NSLog(@"baseStr对象地址: %p,对象的指针地址:%p, 值:%@",baseStr,&baseStr,baseStr);
    self.strongStr = baseStr;
    self.copyyStr = baseStr;
//    NSArray NSMutableArray
       
//    _strongStr = baseStr;
//    _copyyStr = baseStr;
    baseStr = @"456";
    
    //当重新对baseStr进行赋值时，因为baseStr是不可变字符串，为了保持不可变性，系统会另外开辟内存空间来存放变更后的内容
    //但是这并不会影响copy和strong修饰的对象
//    [baseStr appendString:@"456"];
    NSLog(@"baseStr对象地址: %p,对象的指针地址:%p, 值:%@",baseStr,&baseStr,baseStr);
    NSLog(@"strongStr对象地址: %p,对象的指针地址:%p, 值:%@",_strongStr,&_strongStr,_strongStr);
    NSLog(@"copyyStr对象地址: %p,对象的指针地址:%p, 值:%@",_copyyStr,&_copyyStr,_copyyStr);
}

@end


