//
//  WGSingleCycleList.h
//  ZJKBank
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 buybal. All rights reserved.
//
/*
 单向循环链表
 1.单向循环链表就是在单向链表的基础上对【添加】【删除】进行改动即可

                 0        1         2         3         4
               WGNode   WGNode    WGNode    WGNode    WGNode
    size         12       34        45        4         99
    first  ---> next --->next ---->next ---->next ----->next //----->null
                 ↑                                       |
                 |                                       |
                 -----------------------------------------
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGSingleCycleList : NSObject
/// 获取数组元素的个数
-(int)size;

/// 判断数组是否为空
-(BOOL)isEmptry;

/// 判断是否包含某个元素
-(BOOL)contains:(int)element;

/// 添加元素到最面
-(void)add:(int)element;

/// 向指定位置添加元素
-(void)add:(int)index withElement:(int)element;

/// 返回index位置的元素
-(int)get:(int)index;

/// 设置index位置的元素,并返回被覆盖的值
-(int)set:(int)index withElement:(int)element;

/// 删除index位置的元素,并返回删除的元素
-(int)remove:(int)index;

/// 删除指定元素
-(void)removeElement:(int)element;


/// 查看元素的位置
-(int)indexOf:(int)element;

/// 清除所有的元素
-(void)clear;


/// 打印链表中内容
-(void)printContent;

@end

NS_ASSUME_NONNULL_END
