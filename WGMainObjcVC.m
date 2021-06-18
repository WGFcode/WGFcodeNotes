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


@interface WGMainObjcVC()
{
    int totalAppleNum;
}
@end
@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;
    totalAppleNum = 30;
    
    for (int i = 1; i < totalAppleNum; i++) {
        NSThread *thread1 = [[NSThread alloc]initWithTarget:self selector:@selector(eatApple) object:nil];
        [thread1 start];
    }
}



-(void)eatApple{
    totalAppleNum -= 1;
    NSLog(@"当前线程:%@----当前苹果数:%d",[NSThread currentThread],totalAppleNum);
}

@end


