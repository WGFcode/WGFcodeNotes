//
//  WGTestModel.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/4.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGTestModel.h"


@implementation WGTeacher

- (void)eat {
    NSLog(@"%@:开始吃饭吧",_name);
}

-(int)answerQuestionNum {
    if ([_name hasPrefix:@"张"]) {
        return 30;
    }else if ([_name hasPrefix:@"赵"]) {
        return 20;
    }else {
        return 10;
    }
}

//私有方法
-(void)run {
    NSLog(@"%@:开始起来跑步了",_name);
}

-(void)footName:(NSString *)name {
    NSLog(@"今天吃了%@",name);
}

@end


