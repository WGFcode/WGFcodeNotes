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
#import "Student.h"
#import "Car.h"
#import "message.h"


@interface WGMainObjcVC()
@property(nonatomic, assign) int totalTicket;  //总票数
@end

@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //总票数10张
    _totalTicket = 10;
    
    //线程1 卖5张
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i < 5; i++) {
            [self sealTicket];
        }
    });
    //线程1 卖5张
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i < 5; i++) {
            [self sealTicket];
        }
    });
}


-(void)sealTicket {
    @synchronized (self) {
        _totalTicket -= 1;
        NSLog(@"当前剩余票数:%d",_totalTicket);
    }
}

@end


