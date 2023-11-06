//
//  WGStack.h
//  appName
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 baicai. All rights reserved.
//
/* 栈是一种特殊的线性表，只能在一端进行操作,【后进先出】
 1.往栈中添加元素的操作，一般叫做push,入栈
 2.从栈中移除元素的操作，一般叫做pop,出栈（只能移除栈顶元素，也叫做弹出栈顶元素）
 3.后进后出的原则，Last In First Out,LIFO
 ⚠️栈的内部实现是否可以直接利用以前学过的数据结构？ 动态数据和链表都是可以的，因为在栈中操作最频繁的就是栈顶元素了
 其实让WGStack可以直接继承自动态数组或者链表就可以实现栈的基本操作，但是这种方式会导致动态数组和链表中其他的方法也暴露给WGStack了
 为了更加的严谨，这里我们采用将动态数组后者链表当成WGStack的变量来使用即可
 4. 栈的应用：【浏览器的前进和后退】、【软件的撤销Undo、恢复Redo功能】
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGStack : NSObject

/// 获取栈中元素的个数
-(int)size;

/// 判断栈是否为空
-(BOOL)isEmpty;

/// 入栈
-(void)push:(int)element;

/// 出栈
-(int)pop;

/// 获取栈顶元素
-(int)top;

@end

NS_ASSUME_NONNULL_END
