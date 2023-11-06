//
//  WGDoubleNode.h
//  appName
//
//  Created by 白菜 on 2021/11/17.
//  Copyright © 2021 baicai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGDoubleNode : NSObject

{
    @public WGDoubleNode *prev;     //上一个结点
    @public WGDoubleNode *next;     //下一个结点
    @public int element;            //存储的元素
}


/// 初始化一个链表中的节点 上一个结点 元素 下一个结点
-(instancetype)initWithPrev:(WGDoubleNode *__nullable)prevv withElement:(int)elementt withNext:(WGDoubleNode *__nullable)nextt;


@end

NS_ASSUME_NONNULL_END
