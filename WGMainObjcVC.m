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


@interface WGMainObjcVC()
@property(nonatomic, strong) NSString *nameStrong;
@property(nonatomic, copy) NSString *nameCopy;
@end


@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    /*
     如果是类方法
     1.isMemberOfClass: 类的类对象(元类对象)是否是指定的元类对象
     2.isKindOfClass: 类的类对象(元类对象)是否是指定的元类对象或者是指定的元类对象的子类
     2中有个特例：NSObject的元类对象的superClass指向的是NSObject类对象
     如果是对象方法
     1.isMemberOfClass: 对象的类对象是否是指定的类对象
     2.isKindOfClass: 对象的类对象是否是指定的类对象或者指定的类对象的子类
     + (BOOL)isMemberOfClass:(Class)cls {
         return object_getClass((id)self) == cls;
     }

     - (BOOL)isMemberOfClass:(Class)cls {
         return [self class] == cls;
     }

     + (BOOL)isKindOfClass:(Class)cls {
         for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
             if (tcls == cls) return YES;
         }
         return NO;
     }

     - (BOOL)isKindOfClass:(Class)cls {
         for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
             if (tcls == cls) return YES;
         }
         return NO;
     }
     
     */
    Person *per = [[Person alloc]init];
    
    NSLog(@"%d",[NSObject isKindOfClass:[NSObject class]]);  //1
    NSLog(@"%d",[NSObject isMemberOfClass:[NSObject class]]); //0
    NSLog(@"-----");
    NSLog(@"%d",[per isKindOfClass:[Person class]]);    //1
    NSLog(@"%d",[per isMemberOfClass:[Person class]]);  //1
    NSLog(@"-----");
    NSLog(@"%d",[per isKindOfClass:[NSObject class]]);    //1
    NSLog(@"%d",[per isMemberOfClass:[NSObject class]]);   //0
}



@end


