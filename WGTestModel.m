//
//  WGTestModel.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/4.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGTestModel.h"



@implementation WGTestModel

//声明一个静态变量
static WGTestModel *_instance;
+(instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[WGTestModel alloc]init];
    });
    return _instance;
}
@end
