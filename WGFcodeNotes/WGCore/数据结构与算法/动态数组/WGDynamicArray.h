//
//  WGCustomArray.h
//  ZJKBank
//
//  Created by 白菜 on 2021/11/9.
//  Copyright © 2021 buybal. All rights reserved.
//
/* ⚠️验证通过
 这里我们自定义的数组，就是可以实现动态扩容、缩容，类似NSMutableArray
 1.数组是一种顺序存储的线性表，所有元素的内容地址是连续的
 2.在很多编程语言中，数组有个致命的缺点：就是不能动态扩容
 3.如果内存比较紧张，动态数组有比较多的剩余空间，可以考虑进行缩容操作
 4.缩容：比如剩余空间占总容量的一半时，就进行缩容
 5. 数组在进行动态扩容、缩容时，如果扩容的倍数，缩容的机设计不当，会导致复杂度震荡
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGDynamicArray : NSObject

//MARK: 初始化动态数组 指定容量 若制定的容量小于默认容量，则用默认的容量
-(instancetype)initWithCapaticy:(int)capaticy;

/// 获取数组元素的个数
-(int)size;

/// 判断数组是否为空
-(BOOL)isEmpty;

/// 判断是否包含某个元素
-(BOOL)contains:(int)element;

/// 添加元素到最后面
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

/// 打印数组内容
-(void)printContent;

@end

NS_ASSUME_NONNULL_END
