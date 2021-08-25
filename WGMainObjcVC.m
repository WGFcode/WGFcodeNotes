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

@interface WGMainObjcVC()
{
    int totalAppleNum;
}
@end
@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;

    
    Person *p1 = [[Person alloc]init];
    Person *p2 = [[Person alloc]init];
    Person *p3 = [[Person alloc]init];
    NSArray *baseArr = @[p1, p2, p3];
    NSArray *copyArr = [baseArr copy];

    //2、归档和解档
    //归档
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:baseArr];
    //接档
    NSMutableArray *mutableCopyArr = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    NSLog(@"\n源数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    baseArr,baseArr[0],baseArr[1],baseArr[2]);
    NSLog(@"\n浅拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    copyArr,copyArr[0],copyArr[1],copyArr[2]);
    NSLog(@"\n深拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    mutableCopyArr,mutableCopyArr[0],mutableCopyArr[1],mutableCopyArr[2]);
}





@end


