//
//  WGSearchTree.m
//  ZJKBank
//
//  Created by 白菜 on 2021/12/1.
//  Copyright © 2021 buybal. All rights reserved.
//
/*
 ⚠️二叉搜索树中的元素必须具备可比较性，这里我们都是用的int类型元素，比如可能存在自定义类型Person，
 那么就需要提供自定义类型的比较方法
 二叉树中存放的都是WGSearchTreeNode节点元素
 */
/// 访问器，访问遍历的元素
typedef void (^visitor)(int element);

#import "WGBinarySearchTree.h"
#import "WGSearchTreeNode.h"
//层级遍历需要用到队列
#import "WGQueue.h"

@interface WGBinarySearchTree()
{
    int size;
    WGSearchTreeNode *rootNode; //根节点
}
@end

@implementation WGBinarySearchTree


/// 获取元素的个数
-(int)size {
    return size;
}

/// 判断是否为空
-(BOOL)isEmpty {
    return size == 0;
}

/// 添加元素
-(void)addElement:(int)element {
    /* 添加步骤:
     1.找到父节点parent
     2.创建新节点newNode
     3.parent.left = newNode 或 parent.right = newNode
     遇到值相等的情况，建议直接覆盖
     */
//    if (element == nil) { //这里element不能为nil
//        NSLog(@"add element is not nil");
//        return;
//    }
    if (rootNode == nil) { //添加的第一个节点,让根节点指向新创建的节点
        WGSearchTreeNode *newNode = [[WGSearchTreeNode alloc]initWithElement:element withParentNode:nil];
        rootNode = newNode;
        size++;
        return;
    }
    //添加的不是第一个节点，开始找父节点,需要拿新添加的元素和根节点进行比较
    WGSearchTreeNode *parent = rootNode;  //父节点
    WGSearchTreeNode *node = rootNode;
    int com = 0;
    while (node != nil) {
        com = [self compare:element withElement2:node->element];
        parent = node;
        if (com > 0) { //添加的元素要大于node节点的元素，继续和节点的右子树节点进行比较
            node = node->right;
        }else if (com < 0) {
            node = node->left;
        }else { //相等,进行覆盖
            node->element = element;
            return;
        }
    }
    //看看插入到父节点的那个位置，需要利用到比较结果
    WGSearchTreeNode *newNode = [[WGSearchTreeNode alloc]initWithElement:element withParentNode:parent];
    if (com > 0) { //插入到父节点的右子树
        parent->right = newNode;
    }else { //插入到父节点的左子树
        parent->left = newNode;
    }
    size++;
}


/*
删除的是叶子节点
 1.如果node == node.parent.left,则直接node.parent.left = nil即可
 2.如果node == node.parent.right,则直接node.parent.right = nil即可
 3.如果node.parent = nil,删除的肯定就是只有根节点的树了，则直接root = nil即可
删除度为1的节点(用子节点替代原节点的位置,child是node.left或者child是node.right)
 1.如果node是左子节点，child.parent = node.parent; node.parent.left = child
 2.如果node是右子节点，child.parent = node.parent; node.parent.right = child
 3.如果node是根节点, root = child; child.parent = nil
删除度为2的节点
 先用前驱或后驱节点的值覆盖原节点的值，然后删除相应的前驱或后继节点
 有个规则：如果一个节点的度为2，那么它的前驱、后继节点的度只可能是1和0
 所以删除度为2的节点其实并不是真正删除该节点，而是删除这个节点的前驱或后继节点
 */
/// 删除元素
-(void)removeElement:(int)element {
    //先找到这个节点
    WGSearchTreeNode *node = [self nodeWithElement:element];
    //然后再删除这个节点
    [self removeNode:node];
}
//删除节点
-(void)removeNode:(WGSearchTreeNode *)node {
    if (node == nil) {
        return;
    }
    size--;
    if (node.hasTwoChildren) { //度为2的节点
        //找到后继节点
        WGSearchTreeNode *s = [self successor:node];
        //用后继节点的值覆盖度为2的节点的值
        node->element = s->element;
        //删除后继节点,这里我们让node 先等于s,这样后面代码删除node就是代表删除s，后继节点的度肯定是1或者0
        node = s;
    }
    // 能来到这里，说明节点的度肯定是为1 或者度为0的节点
    // 删除node节点(node的节点是1或0)
    WGSearchTreeNode *replaceNode = node->left != nil ? node->left : node->right;
    if (replaceNode != nil) { //node是度为1的节点
        //更改parent
        replaceNode->parent = node->parent;
        //更改parent的left、right的指向
        if (node->parent == nil) { //node是度为1的节点，并且是根节点
            rootNode = replaceNode;
        }else if (node == node->parent->left) {
            node->parent->left = replaceNode;
        }else { //node == node->parent->right
            node->parent->right = replaceNode;
        }
    }else if (node->parent == nil) { //node是度为0的节点并且是根节点
        rootNode = nil;
    }else { //node是叶子节点，但不是根节点
        if (node == node->parent->left) {
            node->parent->left = nil;
        }else { //node == node->parent->right
            node->parent->right = nil;
        }
    }
}
//先通过元素找到对应的节点
-(WGSearchTreeNode *)nodeWithElement:(int)element {
    WGSearchTreeNode *node = rootNode;
    while (node != nil) {
        int com = [self compare:element withElement2:node->element];
        if (com == 0) { //找到了
            return node;
        }
        if (com > 0) { //新添加的元素比较大,需要去节点的右边开始找
            node = node->right;
        }else {
            node = node->left;
        }
    }
    return nil;
}



/// 是否包含指定的元素
-(BOOL)containsElement:(int)element {
    return [self nodeWithElement:element] != nil;
}


/// 清空
-(void)clear {
    size = 0;
    rootNode = nil;
}

/// 前序遍历 根-左-右
-(void)preOrderTraverse {
    [self preOrderTraverseWithNode:rootNode];
}
-(void)preOrderTraverseWithNode:(WGSearchTreeNode *)node {
    if (node == nil) return;
    NSLog(@"%d",node->element);
    [self preOrderTraverseWithNode:node->left];
    [self preOrderTraverseWithNode:node->right];
}

/// 中序遍历 左-根-右
-(void)inOrderTraverse {
    [self inOrderTraverseWithNode:rootNode];
}
-(void)inOrderTraverseWithNode:(WGSearchTreeNode *)node {
    if (node == nil) return;
    [self inOrderTraverseWithNode:node->left];
    NSLog(@"%d",node->element);
    [self inOrderTraverseWithNode:node->right];
}

/// 后序遍历 左-右-根
-(void)postOrderTraverse {
    [self postOrderTraverseWithNode:rootNode];
}
-(void)postOrderTraverseWithNode:(WGSearchTreeNode *)node {
    if (node == nil) return;
    [self postOrderTraverseWithNode:node->left];
    [self postOrderTraverseWithNode:node->right];
    NSLog(@"%d",node->element);
}

/* 实现思路: 使用队列
 1. 将根节点入队
 2.循环执行以下操作，直到队列为空
    将队头节点A出队，进行访问
    将A的左子节点入队
    将A的右子节点入队
 */
/// 层序遍历 从上到下-从左到右
-(void)levelOrderTraverse {
    if (rootNode == nil) {
        return;
    }
    /* 下面实现方式是正确的，只是我们自定义实现的队列WGQueue目前只支持int类型的数据，而不支持WGSearchTreeNode类型的节点，
     但是逻辑是一样的
    WGQueue *queue = [[WGQueue alloc]init];
    //根节点元素入队
    [queue enQueue:rootNode->element];
    while (!queue.isEmpty) {
        //将根节点出队
        WGSearchTreeNode *node = [queue deQueue];
        NSLog(@"%d",node->element);
        if (node->left != nil) {
            [queue enQueue:node->left];
        }
        if (node->right != nil) {
            [queue enQueue:node->right];
        }
    }
     */
}


/// 比较方法 element1: 新添加的元素  element2: 待比较的元素
-(int)compare:(int)element1 withElement2:(int)element2 {
    if (element1 > element2) {
        return 1;
    }else if (element1 < element2) {
        return -1;
    }else { //相等
        return 0;
    }
}


/* 递归计算二叉树的高度
 计算二叉树的高度，就是计算根节点的高度
 计算根节点的高度就是计算它的左右子节点的高度的最大值
 */
/// 二叉树的高度-递归
-(int)heightWithRecursion {
    return [self heightWithNode:rootNode];
}
-(int)heightWithNode:(WGSearchTreeNode *)node {
    if (node == nil) {
        return 0;
    }
    return 1 + MAX([self heightWithNode:node->left], [self heightWithNode:node->right]);
}


/* 层序遍历，访问完一层，高度就+1，如何确定一层访问完成？
 当访问完第一层(根节点)，下一层节点数量就是队列中元素的数量，因为层序遍历中，根节点出出队后，就把它的左右子节点入队了
 */
///二叉树的高度-非递归(利用层序遍历)
-(int)height {
    if (rootNode == nil) {
        return 0;
    }
    int height = 0;    //二叉树的高度
    int levelSize = 1; //存储着每一层的元素数量
    /*
    WGQueue *queue = [[WGQueue alloc]init];
    //根节点元素入队
    [queue enQueue:rootNode->element];
    while (!queue.isEmpty) {
        //将根节点出队
        WGSearchTreeNode *node = [queue deQueue];
        每次取出一个节点后(出队)，该层没有访问的元素数量就要减减
        levelSize--;
        
        if (node->left != nil) {
            [queue enQueue:node->left];
        }
        if (node->right != nil) {
            [queue enQueue:node->right];
        }
        if (levelSize == 0) { //意味着即将要访问下一层
            levelSize = queue.size;
            height++;
        }
    }
    */
    return height;
}


/*判断一棵二叉树是否是完全二叉树思路总结
 1. 如果树为空，则返回NO
 2. 如果树不为空，则开始层序遍历二叉树(用队列)
    如果node.left != nil,则将node.left入队
    如果node.left == nil && node.right != nil,则返回NO
    如果node.right != nil,则将node.right入队
    如果node.right == nil,那么后面遍历的节点都应该是叶子节点，才是完全二叉树，否则返回NO
 3.遍历结束后，返回YES
 总结：以后凡是用到层序遍历，都先将层序遍历的代码写下来，然后再开始进行修改，为了就是防止没有有所有的节点入队，即没有访问到所有的节点
 */
/// 判断一棵二叉树是否是完全二叉树
-(BOOL)isComplete {
    if (rootNode == nil) {
        return NO;
    }
    WGQueue *queue = [[WGQueue alloc]init];
    [queue enQueue:rootNode->element];  //根节点元素入队
    
    BOOL isLeaf = NO; //是否是叶子节点
    /*
    while (!queue.isEmpty) {
        //将根节点出队
        WGSearchTreeNode *node = [queue deQueue];
        if (isLeaf && !node.isLeaf) { //如果是叶子节点，但是它不是叶子节点，那么就不是完全二叉树
            return NO;
        }
        
        if (node->left != nil) {
            [queue enQueue:node->left];
        }else if (node->right != nil) { //左边为空，右边不为空，则肯定不是完全二叉树
            //node->left == nil && node->right != nil
            return NO;
        }
        
        if (node->right != nil) {
            [queue enQueue:node->right];
        }else {
            //能来到这里就是这两种情况 这两种情况下再往后遍历的都为叶子节点，才是完全二叉树
            //node->left == nil && node->right == nil;
            //node->left != nil && node->right == nil;
            isLeaf = YES;
        }
    }
     */
    return YES;
}


/* 前驱节点: 中序遍历(左根右)时的前一个节点
如果是二叉搜索树，前驱节点就是前一个比它小的节点(肯定是在它左子树中的最大值，而左子树中的最大值肯定是在从左子树开始一直找它的右子树的节点)
                ------------8------------
                ↓                        ↓
           -----4-----              -----13
           ↓          ↓             ↓
        ---2---    ---6---       ---10---
        ↓      ↓   ↓     ↓       ↓      ↓
        1      3   5     7       9   ---12
                                     ↓
                                     11
 中序遍历顺序：1 2 3 4 5 6 7 8 9 10 11 12
1. 如果node.left != nil,前驱节点predecessor = node.left.right.right...,终止条件: right = nil
 6的前驱节点就是5: 6的left = 5,5的right=nil,所以前驱节点就是5(predecessor = node.left)
 13的前驱节点就是12，13的left = 10, 10的right = 12， 12的right=nil,所以前驱节点就是12(predecessor = node.left.right)
 8的前驱节点就是7，8的left = 4, 4的right = 6, 6的right = 6, 7的right = nil,所以前驱节点就是7(predecessor = node.left.right.right)
2.如果node.left == nil && node.parent != nil,predecessor = node.parent.parent.parent...,终止条件:node在parent的右子树中
 7的前驱节点就是6，7的left = nil && 7.parent != nil,7.parent = 6,并且7在parent(6)的右子树中，
 所以6就是前驱节点(predecessor = node.parent)
 11的前驱节点就是10，11的left = nil && 11.parent != nil,11的parent = 12,12的parent=10,而节点11在10的右子树上，
 所以前驱节点就是10(predecessor = node.parent.parent)
3.如果node.left == nil && node.parent == nil,那就没有前驱节点
 */
/// 前驱节点
-(WGSearchTreeNode *)predecessor:(WGSearchTreeNode *)node {
    if (node == nil) {
        return nil;
    }
    //前驱节点在左子树当中,(left.right.right.right...)
    WGSearchTreeNode *p = node->left;
    if (p != nil) { //如果左子树不为空，则先找到左节点A，然后开始一直找左节点A的right.right
        while (p->right != nil) { //只要right不为空，就一直找right
            p = p->right;
        }
        //如果p->right=nil,则p就是前驱节点
        return p;
    }
    //从祖父节点开始寻找前驱节点(如果node的父节点不为空，并且节点是在父节点的左子树上，则就一直找，知道遇到节点是在父节点的右子树上)
    while (node->parent != nil && node == node->parent->left) {
        node = node->parent;
    }
    //退出循环后，有下面两种情况
    // node->parent == nil  父节点为nil ,所以返回的就是node->parent，其实写成nil也可以
    // node == node->parent->right 节点在父节点的右子树上, 返回的就是node->parent
    return node->parent;
}

//https://github.com/CoderMJLee/BinaryTrees
/* 后继节点: 中序遍历时的后一个节点,如果是二叉搜索树，前驱节点就是最后一个比它大的节点
 1.如果node.right != nil, successor = node.right.left.left...,终止条件: left为nil
 2.如果node.right == nil && node.parent != nil,successor = node.parent.parent...,终止条件: node在parent的左子树中
 3.如果node.right == nil && node.parent == nil,那就没有后继节点(例如没有右子树的根节点)
 */
/// 后继节点
-(WGSearchTreeNode *)successor:(WGSearchTreeNode *)node {
    if (node == nil) {
        return nil;
    }
    //后继节点在右子树当中,(right.left.left.left...)
    WGSearchTreeNode *p = node->right;
    if (p != nil) {
        while (p->left != nil) {
            p = p->left;
        }
        return p;
    }
    //从祖父节点开始寻找后继节点
    while (node->parent != nil && node == node->parent->right) {
        node = node->parent;
    }
    return node->parent;
}
@end
