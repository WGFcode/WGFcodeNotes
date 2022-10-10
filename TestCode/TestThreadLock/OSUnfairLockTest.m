//
//  OSUnfairLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "OSUnfairLockTest.h"
#import <os/lock.h>

@interface OSUnfairLockTest()

@property(nonatomic, assign) os_unfair_lock moneyLock;
@property(nonatomic, assign) os_unfair_lock ticketsLock;

@end


@implementation OSUnfairLockTest


-(instancetype)init {
    self = [super init];
    if (self) {
        //初始化锁
        self.moneyLock = OS_UNFAIR_LOCK_INIT;
        self.ticketsLock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

-(void)__saveMoney {
    //加锁
    os_unfair_lock_lock(&_moneyLock);
    [super __saveMoney];
    //解锁
    os_unfair_lock_unlock(&_moneyLock);
}

-(void)__drawMoney {
    //加锁
    os_unfair_lock_lock(&_moneyLock);
    [super __drawMoney];
    //解锁
    os_unfair_lock_unlock(&_moneyLock);
}


-(void)__saleTickets {
    //加锁
    os_unfair_lock_lock(&_ticketsLock);
    [super __saleTickets];
    //解锁
    os_unfair_lock_unlock(&_ticketsLock);
}

@end
