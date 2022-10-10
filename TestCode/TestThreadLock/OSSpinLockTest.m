//
//  OSSpinLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/9.
//  Copyright © 2022 WG. All rights reserved.
//

#import "OSSpinLockTest.h"
#import <libkern/OSAtomic.h>

@interface OSSpinLockTest()
@property(nonatomic, assign) OSSpinLock moneyLock;
@property(nonatomic, assign) OSSpinLock ticketsLock;
@end


@implementation OSSpinLockTest

-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化锁
        self.moneyLock = OS_SPINLOCK_INIT;
        self.ticketsLock = OS_SPINLOCK_INIT;
    }
    return self;
}


-(void)__drawMoney {
    //加锁
    OSSpinLockLock(&_moneyLock);
    [super __drawMoney];
    //解锁
    OSSpinLockUnlock(&_moneyLock);
}
-(void)__saveMoney {
    //加锁
    OSSpinLockLock(&_moneyLock);
    [super __saveMoney];
    //解锁
    OSSpinLockUnlock(&_moneyLock);
}



-(void)__saleTickets {
    //加锁
    OSSpinLockLock(&_ticketsLock);
    [super __saleTickets];
    //解锁
    OSSpinLockUnlock(&_ticketsLock);
}

@end
