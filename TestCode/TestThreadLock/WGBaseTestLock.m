//
//  WGBaseTestLock.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/9.
//  Copyright © 2022 WG. All rights reserved.
//

#import "WGBaseTestLock.h"
@interface WGBaseTestLock()

@property(nonatomic, assign)int money;
@property(nonatomic, assign)int ticketsCount;

@end



@implementation WGBaseTestLock


/// 存钱测试
-(void)moneyTest {
    self.money = 100;
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self __saveMoney];
        }
    });
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self __drawMoney];
        }
    });
}
/// 存钱   
-(void)__saveMoney {
    int old = self.money;
    old += 50;
    self.money = old;
    NSLog(@"存50，还剩余：%d元",self.money);
}
/// 取钱
-(void)__drawMoney {
    int old = self.money;
    old -= 20;
    self.money = old;
    NSLog(@"取20，还剩余：%d元",self.money);
}




/// 卖票测试
-(void)ticketsTest {
    self.ticketsCount = 15;
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self __saleTickets];
        }
    });
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self __saleTickets];
        }
    });
    dispatch_async(queue, ^{
        for (int i = 0; i < 5; i++) {
            [self __saleTickets];
        }
    });
}
-(void)__saleTickets {
    int old = self.ticketsCount;
    old -= 1;
    self.ticketsCount = old;
    NSLog(@"还剩余：%d张票",self.ticketsCount);
}



/// 其他测试
-(void)otherTest {
    
}

@end
