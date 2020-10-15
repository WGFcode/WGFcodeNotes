//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"

@interface Person()

@end


@implementation Person

-(void)willChangeValueForKey:(NSString *)key {
    NSLog(@"willChangeValueForKey---begin");
    [super willChangeValueForKey: key];
    NSLog(@"willChangeValueForKey---end");
}

-(void)didChangeValueForKey:(NSString *)key {
    NSLog(@"didChangeValueForKey---begin");
    [super didChangeValueForKey:key];
    NSLog(@"didChangeValueForKey---begin");
}
@end


