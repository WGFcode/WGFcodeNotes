//
//  WGTestModel.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/5/3.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGTestModel.h"

@interface WGTestModel()
{
    NSString *_parents;
    BOOL _isSex;
}

@end

@implementation WGTestModel

+(void)run {
    NSLog(@"开始跑步了");
}
-(void)eat {
    NSLog(@"开始吃饭了");
}
-(void)sleepWithTime:(NSTimeInterval)time {
    NSLog(@"我睡了%f分钟了",time);
}

-(void)love {
    NSLog(@"我喜欢你");
}

@end
