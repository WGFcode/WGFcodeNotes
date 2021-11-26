//
//  WGDoubleList.h
//  ZJKBank
//
//  Created by 白菜 on 2021/11/15.
//  Copyright © 2021 buybal. All rights reserved.
//
/*
 1.用双向链表可以提升链表的综合性能
 2. 粗略对比单向链表和双向链表删除的操作数量,虽然复杂度还是一样O(n),但操作数量减少了一半
    单向链表: 1/2 + n / 2
    双向链表: 1/2 + n / 4
 3.双向链表 VC 动态数组
    动态数组: 开辟、销毁内存空间的次数相对较少，但可能造成内存空间浪费(可以通过缩容来解决)
    双向链表: 开辟、销毁内存空间的次数相对较多，但不会造成内存空间的浪费
 ⚠️: 如果频繁的在尾部进行添加、删除操作，动态数组、双向链表均可选择
 ⚠️: 如果是频繁的在头部进行添加、删除操作，建议选择使用双向链表，因为如果是数组，需要将后面所有的元素都要移动，复杂度是O(n),但是双向链表是O(1)
 ⚠️: 如果有频繁的(在任意位置)添加、删除操作，建议选择使用双向链表
 ⚠️: 如果有频繁的查询操作(随机访问操作),建议选择使用动态数组
 4. 有了双向链表、单向链表是否就没有任何用处了？ 并非如此，哈希表的设计中就用的是单向链表
 
          -------------------first
          |                  last---------------------------
          |                  size                           |
          ↓                                                 ↓
          12        45        34        89        12        8
null<--- prev <--- prev <--- prev <--- prev <--- prev <--- prev
         next ---> next ---> next ---> next ---> next ---> next --->null
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGDoubleList : NSObject

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
