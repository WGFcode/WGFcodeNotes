//
//  WGTestKVCEntity.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2021/6/11.
//  Copyright © 2021 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGTestKVCEntity : NSObject
{
    //默认的权限是protected，如果外部访问，则需要添加@public,否则编译期会报错 KVC也可以给成员变量属性设置值和获取值
    @public
    int _age;
    NSString *name; //成员变量
}
@property(nonatomic, assign) int age;
@end

NS_ASSUME_NONNULL_END
