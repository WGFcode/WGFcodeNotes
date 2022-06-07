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
    
}
@end
@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;
    
    __strong Person *person1;
    __weak Person *person2;
    __unsafe_unretained Person *person3;
    NSLog(@"1111");
    {
        Person *person = [[Person alloc]init];
        
        person3 = person;
    }
    //离开大括号就会销毁
    NSLog(@"2222---%@",person3);
}



@end


