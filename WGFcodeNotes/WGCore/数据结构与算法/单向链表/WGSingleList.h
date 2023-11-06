//
//  WGListNode.h
//  appName
//
//  Created by 白菜 on 2021/11/8.
//  Copyright © 2021 baicai. All rights reserved.
//
/*
 ⚠️验证通过了
 单向链表  可视化网站：https://visualgo.net/zh/list
 1.动态数组有个明显的缺点：会造成大量的内存浪费
 2.能否用到多少就申请多少内容？ 链表就可以
 3.链表是一个链式存储的线性表，所有元素的内存地址不一定是连续的
 
                  动态数组                      单向链表
            最好     最坏     平均       最好      最坏      平均
 add        O(1)    O(n)     O(n)      O(1)     O(n)     O(n)
 remove     O(1)    O(n)     O(n)      O(1)     O(n)     O(n)
 set        O(1)    O(1)     O(1)      O(1)     O(n)     O(n)
 get        O(1)    O(1)     O(1)      O(1)     O(n)     O(n)

                 0        1         2         3         4
               WGNode   WGNode    WGNode    WGNode    WGNode
    size         12       34        45        4         99
    first  ---> next --->next ---->next ---->next ----->next ----->null
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGSingleList : NSObject

/// 获取数组元素的个数
-(int)size;

/// 判断数组是否为空
-(BOOL)isEmpty;

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
