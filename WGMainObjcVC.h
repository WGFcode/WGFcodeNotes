//
//  WGMainObjcVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGMainObjcVC : UIViewController
/*
 nonatomic: 非原子属性
 atomic: 原子属性
 原子在物理学中就是不可再分割的,代码层面就是 int a = 10, int b = 20 int c = a+b, 正常情况三行代码会按照顺序逐条执行,如果有
 多个线程访问,那么同一时间可能线程1访问int a = 10, 线程2访问int b = 20, 线程3访问int c = a+b,而如果是原子属性,那么就是不可
 分割的,线程会把这三行代码看成是一个整体,即同一时间多个线程访问时,某一个线程只能访问的是这三行代码的整体
 */
@property(atomic, strong) NSString *name;

@end


NS_ASSUME_NONNULL_END
