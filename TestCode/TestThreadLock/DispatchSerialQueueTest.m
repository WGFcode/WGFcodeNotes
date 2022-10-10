//
//  DispatchSerialQueueTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "DispatchSerialQueueTest.h"

@interface DispatchSerialQueueTest()

@property(nonatomic, strong) dispatch_queue_t moneyQueue;
@property(nonatomic, strong) dispatch_queue_t ticketsQueue;

@end
@implementation DispatchSerialQueueTest

-(instancetype)init {
    self = [super init];
    if (self) {
        
        
        self.moneyQueue = dispatch_queue_create("moneyQueue", DISPATCH_QUEUE_SERIAL);
        self.ticketsQueue = dispatch_queue_create("ticketsQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

//存钱和取钱在同一个串行队列中
- (void)__drawMoney {
    //同步任务，在串行对了中，一次只能执行一个任务(存钱或取钱)
    dispatch_sync(self.moneyQueue, ^{
        [super __drawMoney];
    });
}
- (void)__saveMoney {
    dispatch_sync(self.moneyQueue, ^{
        [super __saveMoney];
    });
}


- (void)__saleTickets {
    dispatch_sync(self.ticketsQueue, ^{
        [super __saleTickets];
    });
}
@end
