//
//  WGNode.h
//  appName
//
//  Created by 白菜 on 2021/11/12.
//  Copyright © 2021 baicai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGNode : NSObject

{
    @public WGNode *next;
    @public int element;
}

//为了提供给外界(WGListNode)访问，所以这里设置成属性
//@property(nonatomic, strong) WGNode *next;    //指向下一个结点
//@property(nonatomic, assign) int element;    //结点元素
/// 初始化一个链表中的节点
-(instancetype)initWithElement:(int)element withNext:(WGNode *)next;

@end

NS_ASSUME_NONNULL_END
