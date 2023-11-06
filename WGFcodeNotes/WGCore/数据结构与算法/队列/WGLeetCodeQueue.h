//
//  232. 用栈实现队列.h
//  appName
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 baicai. All rights reserved.
//
/*232. 用栈实现队列
  请你仅使用两个栈实现先入先出队列。队列应当支持一般队列支持的所有操作（push、pop、peek、empty）：
  链接：https://leetcode-cn.com/problems/implement-queue-using-stacks/
 分析：准备两个栈 inStack、outStack
 1.入队时，push到inStack栈中
 2.出队时：
     如果outStack为空，将inStack所有元素逐一弹出，push到outStack栈中，outStack弹出栈顶元素
     如果outStack不为空，outStack弹出栈顶元素
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGLeetCodeQueue : NSObject

/// 将元素 x 推到队列的末尾
-(void)push:(int)element;

/// 从队列的开头移除并返回元素
-(int)pop;


/// 返回队列开头的元素
-(int)peek;


/// 如果队列为空，返回 true ；否则，返回 false
-(BOOL)isEmpty;


@end

NS_ASSUME_NONNULL_END
