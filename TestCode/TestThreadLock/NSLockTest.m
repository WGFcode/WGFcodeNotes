//
//  NSLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "NSLockTest.h"

@interface NSLockTest()
@property(nonatomic, strong) NSLock *moneyLock;
@property(nonatomic, strong) NSLock *ticketsLock;
@end

@implementation NSLockTest

-(instancetype)init {
    self = [super init];
    if (self) {
        self.moneyLock = [[NSLock alloc]init];
        self.ticketsLock = [[NSLock alloc]init];
    }
    return self;
}


-(void)__saveMoney {
    //加锁
    [self.moneyLock lock];
    
    [super __saveMoney];
    
    //解锁
    [self.moneyLock unlock];
}

-(void)__drawMoney {
    //加锁
    [self.moneyLock lock];
    
    [super __drawMoney];
    
    //解锁
    [self.moneyLock unlock];
}


-(void)__saleTickets {
    //加锁
    [self.moneyLock lock];
    
    [super __saleTickets];
    
    //解锁
    [self.moneyLock unlock];
}

@end
