//
//  UIControl+WGHookMethod.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//想拦截按钮的点击事件,就要创建UIControl的分类,来拦截到方法-(void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
@interface UIControl (WGHookMethod)

@end

NS_ASSUME_NONNULL_END
