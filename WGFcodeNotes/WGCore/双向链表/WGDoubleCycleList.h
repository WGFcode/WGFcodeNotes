//
//  WGDoubleCycleList.h
//  ZJKBank
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 buybal. All rights reserved.
//
/*  双向循环链表
   1.双向循环链表就是在双向链表的基础上对【添加】【删除】进行改动即可
          -------------------first
          |                  last---------------------------
          |                  size                           |
          ↓                                                 ↓
          12        45        34        89        12        8
null<//---prev <--- prev <--- prev <--- prev <--- prev <--- prev
       ↓  next ---> next ---> next ---> next ---> next ---> next ---//>null
       ↓   ↑                                                 ↓ ↑
       ↓   -------------------------------------------------<- ↑                                                     |↑
       -------------------------------------------------------->
 2. 为了发挥循环链表的威力，这里我们增加一个成员变量和三个方法
 成员变量: current:--->用于值向某个结点
 reset()方法: 让current指向头结点first
 next()方法: 让current往后走一步，也就是current = current->next
 remove()方法: 删除current指向的结点，删除成功后让current指向下一个结点
 这种改造方式可以解决约瑟夫问题
 
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGDoubleCycleList : NSObject

///让current指向头结点first
-(void)resetCurrent;

///让current往后走一步，也就是current = current->next，,并返回当前current的元素
-(int)nextCurrent;

///删除current指向的结点，删除成功后让current指向下一个结点
-(int)removeCurrent;


/// 获取数组元素的个数
-(int)size;

/// 清除所有的元素
-(void)clear;

/// 链表是否为空
-(BOOL)isEmpty;

/// 返回index位置的元素
-(int)get:(int)index;

/// 设置index位置的元素,并返回被覆盖的值
-(int)set:(int)index withElement:(int)element;

/// 向指定位置添加元素
-(void)add:(int)index withElement:(int)element;

/// 添加元素到最面
-(void)add:(int)element;

/// 删除index位置的元素,并返回删除的元素
-(int)remove:(int)index;

/// 打印链表中内容
-(void)printContent;
@end

NS_ASSUME_NONNULL_END
