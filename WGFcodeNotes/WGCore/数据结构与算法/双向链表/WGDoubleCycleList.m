//
//  WGDoubleCycleList.m
//  appName
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 baicai. All rights reserved.
//
/* 1.双向循环链表就是在双向链表的基础上对【添加】【删除】进行改动即可
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
 */
#import "WGDoubleCycleList.h"
#import "WGDoubleNode.h"

@interface WGDoubleCycleList()
{
    int size;
    WGDoubleNode *first;    //头结点
    WGDoubleNode *last;     //尾结点
    WGDoubleNode *current;  //用于指向某一个结点
}
@end

@implementation WGDoubleCycleList

///让current指向头结点first
-(void)resetCurrent {
    current = first;
}

///让current往后走一步，也就是current = current->next,并返回当前current的元素
-(int)nextCurrent {
    if (current == nil) {
        return -1;
    }
    current = current->next;
    return current->element;
}

///删除current指向的结点，删除成功后让current指向下一个结点
-(int)removeCurrent {
    if (current == nil) {
        return -1;
    }
    WGDoubleNode *nextNode = current->next;
    int removeElement = [self removeNode:current];
    //删除完结点后，如果链表中就这一个元素，相当于删除完这一个元素后，链表应该是空的，所以current应该等于nil;否则让current等于它的下一个结点
    if (size == 0) {
        current = nil;
    }else {
        current = nextNode;
    }
    return removeElement;
}
//私有方法 删除结点
-(int)removeNode:(WGDoubleNode *)node {
    if (size == 1) {
        first = nil;
        last = nil;
    }else {
        WGDoubleNode *deleteNodePrev = node->prev;
        WGDoubleNode *deleteNodeNext = node->next;
        deleteNodePrev->next = deleteNodeNext;
        deleteNodeNext->prev = deleteNodePrev;
        if (node == first) {  // index == 0
            first = deleteNodeNext;
        }
        if (node == last) { // index == size - 1
            last = deleteNodePrev;
        }
    }
    size--;
    return node->element;
}


/// 获取数组元素的个数
-(int)size {
    return size;
}

/// 清除所有的元素
-(void)clear {
    size = 0;
    first = nil;
    last = nil;
}

/// 链表是否为空
-(BOOL)isEmpty {
    return size == 0;
}

/// 返回index位置的元素
-(int)get:(int)index {
    WGDoubleNode *node = [self getNodeWithIndex:index];
    return node->element;
}



/// 设置index位置的元素,并返回被覆盖的值
-(int)set:(int)index withElement:(int)element {
    WGDoubleNode *changeNode = [self getNodeWithIndex:index];
    int oldElement = changeNode->element;
    changeNode->element = element;
    return oldElement;
}

/*
          -------------------first
          |                  last---------------------------
          |                  size                           |
          ↓                                                 ↓
          12        45        34        89        12        8
null<--- prev <--- prev <--- prev <--- prev <--- prev <--- prev
         next ---> next ---> next ---> next ---> next ---> next --->null
                        在index=2位置添加元素
 */
/// 向指定位置添加元素
-(void)add:(int)index withElement:(int)element {
    if (index < 0 || index > size) {
        NSLog(@"无法添加元素:index is %d, size is %d",index,size);
        return;
    }
    if (index == size) { //往最后面添加元素
        /*
        WGDoubleNode *oldLast = last;
        //新的last指针指向新添加的元素  之前last的next指向新的元素
        last = [[WGDoubleNode alloc]initWithPrev:oldLast withElement:element withNext:nil];
        if (oldLast == nil) { //这是链表添加的第一个元素，相当于链表是空的
            first = last;  //last已经指向新添加的元素了，那么first也应该指向新添加的元素，因为就一个元素
        }else {
            oldLast->next = last; //之前last的next指向新添加的元素（新添加的结点就是last）
        }
         */
        //⚠️双向循环链表需要改动的地方
        WGDoubleNode *oldLast = last;
        //新的last指针指向新添加的元素  之前last的next指向新的元素
        last = [[WGDoubleNode alloc]initWithPrev:oldLast withElement:element withNext:first];
        if (oldLast == nil) { //这是链表添加的第一个元素，相当于链表是空的
            first = last;  //last已经指向新添加的元素了，那么first也应该指向新添加的元素，因为就一个元素
            first->next = first;
            first->prev = first;
        }else {
            oldLast->next = last; //之前last的next指向新添加的元素（新添加的结点就是last）
            first->prev = last;
        }
    }else {
        /*
        WGDoubleNode *next = [self getNodeWithIndex:index];  //新加结点的下一个结点
        WGDoubleNode *prev = next->prev;                     //新加结点的上一个结点
        WGDoubleNode *newNode = [[WGDoubleNode alloc]initWithPrev:prev withElement:element withNext:next];
        next->prev = newNode;
        if (prev == nil) {  //等价于index == 0，第一个结点的prev是nil,相当于向链表的开始位置加入元素
            first = newNode;
        }else {
            prev->next = newNode;
        }
        */
        //⚠️双向循环链表需要改动的地方
        WGDoubleNode *next = [self getNodeWithIndex:index];  //新加结点的下一个结点
        WGDoubleNode *prev = next->prev;                     //新加结点的上一个结点
        WGDoubleNode *newNode = [[WGDoubleNode alloc]initWithPrev:prev withElement:element withNext:next];
        next->prev = newNode;
        prev->next = newNode;
        
        if (index == 0) {   //index == 0
            first = newNode;
        }
    }
    size++;
}



/// 添加元素到最面
-(void)add:(int)element {
    [self add:size withElement:element];
}

/*
          -------------------first
          |                  last---------------------------
          |                  size                           |
          ↓                                                 ↓
          12        45        34        89        12        8
null<--- prev <--- prev <--- prev <--- prev <--- prev <--- prev
         next ---> next ---> next ---> next ---> next ---> next --->null
                         删除index=2位置元素
 */
/// 删除index位置的元素,并返回删除的元素
-(int)remove:(int)index {
    if (index < 0 || index >= size) {
        NSLog(@"无法删除:index is %d, size is %d",index,size);
        return -1;
    }
    /*
     WGDoubleNode *deleteNode = [self getNodeWithIndex:index];
     WGDoubleNode *deleteNodePrev = deleteNode->prev;
     WGDoubleNode *deleteNodeNext = deleteNode->next;
    //这里有特殊情况deleteNodePrev=nil deleteNodeNext=nil
    if (deleteNodePrev == nil) {  //删除的是第一个元素 index == 0
        first = deleteNodeNext;
    }else {
        deleteNodePrev->next = deleteNodeNext;
    }
    if (deleteNodeNext == nil) { //删除的是最后一个元素 index == size - 1
        last = deleteNodePrev;
    }else {
        deleteNodeNext->prev = deleteNodePrev;
    }
    */
    WGDoubleNode *deleteNode = first;
    //⚠️双向循环链表需要改动的地方
    if (size == 1) {
        first = nil;
        last = nil;
    }else {
        deleteNode = [self getNodeWithIndex:index];
        WGDoubleNode *deleteNodePrev = deleteNode->prev;
        WGDoubleNode *deleteNodeNext = deleteNode->next;
        deleteNodePrev->next = deleteNodeNext;
        deleteNodeNext->prev = deleteNodePrev;
        if (index == 0) {  // deleteNode == first
            first = deleteNodeNext;
        }
        if (index == size - 1) { // deleteNode == last
            last = deleteNodePrev;
        }
    }
    size--;
    return deleteNode->element;
}


//私有方法
//MARK: 获取index位置的结点WGDoubleNode
-(WGDoubleNode *)getNodeWithIndex:(int)index {
    if (index < 0 || index >= size) {
        NSLog(@"无法删除:index is %d, size is %d",index,size);
        return nil;
    }
    //双向链表从first或者last都可以寻找，为了效率要看index是靠近first端还是靠近last端
    if (index < (size >> 1)) { //index小于size的一半 靠近左边(first)
        WGDoubleNode *node = first;
        for (int i = 0; i < index; i++) {
            node = node->next;
        }
        return node;
    }else {
        WGDoubleNode *node = last;
        for (int i = size - 1; i > index; i--) {
            node = node->prev;
        }
        return node;
    }
}


/// 打印链表中内容
-(void)printContent {
    WGDoubleNode *node = first;
    NSMutableString *str = [NSMutableString stringWithString:@"["];
    if (size > 0) {
        [str appendString: [NSString stringWithFormat:@"%d,",node->element]];
        for (int i = 1; i < size; i++) {  //size = 5
            node = node->next;
            if (i == 1) {
                [str appendString: [NSString stringWithFormat:@"%d",node->element]];
            }else {
                [str appendString: [NSString stringWithFormat:@",%d",node->element]];
            }
        }
    }
    [str appendString:@"]"];
    NSLog(@"元素个数:%d----元素内容:%@",size,str);
}
@end
