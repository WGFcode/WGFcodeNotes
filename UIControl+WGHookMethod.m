//
//  UIControl+WGHookMethod.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import "UIControl+WGHookMethod.h"
#import <objc/runtime.h>

@implementation UIControl (WGHookMethod)

+(void)load {
    //系统方法
    Method method1 = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
    //自定义方法
    Method method2 = class_getInstanceMethod(self, @selector(WG_sendAction:to:forEvent:));
    //交换方法
    method_exchangeImplementations(method1, method2);
}

-(void)WG_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    // 拦截到按钮的点击事件后,可以做自己想做的事情,但注意,一旦拦截到按钮点击事件后,按钮本身添加的事件就不会再次响应了
    NSLog(@"self:%@---target:%@---selectorName:%@",self, target, NSStringFromSelector(action));
    //如果我们在拦截到按钮事件后,处理完自己想处理的事,仍然想让按钮继续处理它的事件,那么可以这么做
    //去调用WG_sendAction:to:forEvent:)方法即可,本来应该调用系统方法sendAction:to:forEvent:),但是因为已经方法交换了,所以调用WG_sendAction:to:forEvent:)方法最终才能去执行系统方法sendAction:to:forEvent:),
    [self WG_sendAction:action to:target forEvent:event];
}
@end
