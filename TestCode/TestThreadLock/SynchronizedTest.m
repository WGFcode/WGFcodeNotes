//
//  SynchronizedTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "SynchronizedTest.h"



@implementation SynchronizedTest

- (void)__drawMoney {
    @synchronized (self) { //加锁
        [super __drawMoney];
    } //解锁
}
-(void)__saveMoney {
    @synchronized (self) { //加锁
        [super __saveMoney];
    } //解锁
}




- (void)__saleTickets {
    @synchronized (self) {  //加锁
        [super __saleTickets];
    } //解锁
}
@end
