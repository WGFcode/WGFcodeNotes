//
//  WGListNode.m
//  appName
//
//  Created by 白菜 on 2021/11/8.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGSingleList.h"
#import "WGNode.h"
/*
                 0        1         2         3         4
               WGNode   WGNode    WGNode    WGNode    WGNode
    size         12       34        45        4         99
    first  ---> next --->next ---->next ---->next ----->next ----->null
 */
/// 找不到元素
static int ELEMENT_NOT_FOUND = -1;

@interface WGSingleList()
{
    int size;        //结点个数
    WGNode *first;   //指向第一个结点
}
@end

@implementation WGSingleList


//MARK: 获取链表元素的个数
-(int)size {
    return size;
}


//MARK: 判断链表是否为空
-(BOOL)isEmpty {
    return size == 0;
}


//MARK: 判断是否包含某个元素
-(BOOL)contains:(int)element {
    WGNode *node = first;
    for (int i = 0; i < size; i++) {
        if (node->element == element) {
            return YES;
        }
        node = node->next;
    }
    return NO;
}


//MARK: 添加元素到最面
-(void)add:(int)element {
    [self add:size withElement:element];
}


//MARK: 向指定位置添加元素
-(void)add:(int)index withElement:(int)element {
    if (index < 0 || index > size) {
        NSLog(@"无法添加元素:index is %d, size is %d",index,size);
        return;
    }
    //⚠️ 链表操作需要注意边界位置
    if (index == 0) {
        //新建一个元素，让它的next指向_fitst指向的结点，即原来的0下标的结点
        WGNode *newNode = [[WGNode alloc]initWithElement:element withNext:first];
        //然后让_first指向新创建的结点
        first = newNode;
    }else {
        //先获取到index结点对象的上一个结点
        WGNode *previousNode = [self getNodeWithIndex:(index-1)];
        //新建一个元素，让它的next指向原来的结点对象previousNode.next
        WGNode *newNode = [[WGNode alloc]initWithElement:element withNext:previousNode->next];
        //让原结点的上一个结点的next指向新的结点
        previousNode->next = newNode;
    }
    size++;
}


//MARK: 返回index位置的元素
-(int)get:(int)index {
    if (index < 0 || index >= size) {
        NSLog(@"无法获取元素:index is %d, size is %d",index,size);
        return -1;
    }
    //先获取到index的结点
    WGNode *node = [self getNodeWithIndex:index];
    return node->element;
}


//MARK: 设置index位置的元素,并返回被覆盖的值
-(int)set:(int)index withElement:(int)element {
    if (index < 0 || index >= size) {
        NSLog(@"无法设置元素:index is %d, size is %d",index,size);
        return -1;
    }
    //先获取到index的结点
    WGNode *node = [self getNodeWithIndex:index];
    //获取原来的值，临时保存一下
    int oldElement = node->element;
    //覆盖原来的元素element
    node->element = element;
    return oldElement;
}


//MARK: 删除index位置的元素,并返回删除的元素
-(int)remove:(int)index {
    /*
                     0        1         2         3         4
                   WGNode   WGNode    WGNode    WGNode    WGNode
        size         12       34        45        4         99
        first  ---> next --->next ---->next ---->next ----->next ----->null
                                       删除index=2
     */
    if (index < 0 || index >= size) {
        NSLog(@"无法删除:index is %d, size is %d",index,size);
        return -1;
    }
    //获取删除index的结点 然后做返回使用
    WGNode *oldNode = [self getNodeWithIndex:index];
    if (index == 0) {
        //让first指针指向first的next下一个结点
        first = first->next;
    }else {
        //找到要删除结点的上一个结点
        WGNode *previousNode = [self getNodeWithIndex:index-1];
        //让上一个结点的next指向要当前结点的下一个结点
        previousNode->next = previousNode->next->next;
    }
    size--;
    return oldNode->element;
}


//MARK: 删除指定元素
-(void)removeElement:(int)element {
    //先找到元素的下标
    int index = [self indexOf:element];
    // 若能找到下标则进行删除操作
    if (index != ELEMENT_NOT_FOUND) {
        [self remove:index];
    }else {
        NSLog(@"无法删除:链表中找不到对应的元素:%d",element);
    }
}


//MARK: 查看元素的位置   4
-(int)indexOf:(int)element {
    //从first链表开头开始遍历，查找相同的元素
    WGNode *node = first;
    for (int i = 0; i < size; i++) {
        if (node->element == element) {
            return i;
        }
        node = node->next;
    }
    return ELEMENT_NOT_FOUND;
}

//MARK: 清除所有的元素
-(void)clear {
    //只需要把first的指针断开就行了
    first = nil;
    size = 0;
}


//MARK: 打印链表中内容
-(void)printContent {
    WGNode *node = first;
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


//私有方法
//MARK: 获取index位置的结点WGNode
-(WGNode *)getNodeWithIndex:(int)index {
    //这里不需要去判断index了。因为调用该方法前都已经判断过了
    //获取index所处的结点，就需要从first开始遍历
    WGNode *node = first;
    for (int i = 0; i < index; i++) {
        node = node->next;
    }
    return node;
}

@end
