//
//  WGSearchTreeNode.h
//  appName
//
//  Created by 白菜 on 2021/12/2.
//  Copyright © 2021 baicai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGSearchTreeNode : NSObject
{
    /// 元素
    @public int element;
    /// 左子节点
    @public WGSearchTreeNode *left;
    /// 右子节点
    @public WGSearchTreeNode *right;
    /// 父节点
    @public WGSearchTreeNode *parent;
}

//MARK: 初始化一个节点 指定它的元素、父节点
-(instancetype)initWithElement:(int)elementt withParentNode:(WGSearchTreeNode *__nullable)nodee;

/// 判断是否是叶子节点
-(BOOL)isLeaf;

/// 判断是否有2个子节点(度为2的节点)
-(BOOL)hasTwoChildren;

@end

NS_ASSUME_NONNULL_END
