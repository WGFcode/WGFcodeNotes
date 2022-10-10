//
//  NSRecursiveLockTest.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/10/10.
//  Copyright © 2022 WG. All rights reserved.
//

#import "NSRecursiveLockTest.h"


@interface NSRecursiveLockTest()

@property(nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation NSRecursiveLockTest


-(instancetype)init {
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc]init];
    }
    return self;
}


-(void)otherTest {
    [self.lock lock];
    NSLog(@"%s",__func__);
    static int count = 0;
    if (count < 10) {
        count++;
        [self otherTest];
    }
    [self.lock unlock];
}
@end
