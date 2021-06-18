//
//  WGTestKVCEntity.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2021/6/11.
//  Copyright © 2021 WG. All rights reserved.
//

#import "WGTestKVCEntity.h"

@interface WGTestKVCEntity()

@end

@implementation WGTestKVCEntity

-(void)test{
    _age = 20;
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"找不到对应的key呀");
}
@end
