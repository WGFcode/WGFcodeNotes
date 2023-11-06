//
//  WGLeetCodeTestVC.m
//  appName
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGLeetCode.h"
#import "WGNode.h"
#import "WGDoubleCycleList.h"
#import "WGStack.h"


@interface WGLeetCode ()

@end

@implementation WGLeetCode
/*
                 0        1         2         3         4
               WGNode   WGNode    WGNode    WGNode    WGNode
    size         12       34        45        4         99
    first  ---> next --->next ---->next ---->next ----->next ----->null
                                   删除index=2
                                    4
 */


/*237. 删除链表中的节点
  https://leetcode-cn.com/problems/delete-node-in-a-linked-list/
*/
-(void)deleteNode:(WGNode *)node {
    //把自己变成下一个结点，然后删除下一个结点
    node->element = node->next->element; //变成下个倒霉蛋
    node->next = node->next->next;       //把倒霉蛋干掉
}



/*206. 反转链表 递归方式
 https://leetcode-cn.com/problems/reverse-linked-list/

            12        45         8
 head ---> next ---> next ----> next --->null
        
 newHead = [self reverseList1:head] 显示的结果应该是下面的样子
            12        45        8
 null <--- next <--- next <--- next <--- newHead
 
 假如我们传入的head是45元素的结点，那么递归函数结果应该是下面的样子,接下来我们只需要处理head结点就可以了,让45元素结点指向12元素，12元素的next指向nill即可
           12        45         8
head ---> next ---> next <---- next <---newHead
                     ↓
                    null
*/
-(WGNode *)reverseList1:(WGNode *)head {
    if (head == nil || head->next == nil) { //头结点为nil,或者只有一个头结点
        return head;
    }
    WGNode *newHead = [self reverseList1:head->next];
    //首先获取到45元素的结点(head->next)，让其next指向12元素的结点
    head->next->next = head;
    //让head->next指向nill即可
    head->next = nil;
    return newHead;
}

/*

           12        45         8
head ---> next ---> next ----> next --->null
 
newHead --->null
       
                    temp 为了避免链表死掉，先用临时的temp结点保存
                     ↑
           12        45         8
head ---> next ---> next ----> next --->null
            ↓
newHead --->null
 
先让head的next指向 newHead, 然后让newHead指向head,再让head指向它的下一个结点,就变成下面的样子了，然后进行循环，每次都把head添加到newHead上
           temp
            ↑
           45         8
head ---> next ---> next ----> next --->null

*/
//206. 反转链表 非递归
-(WGNode *)reverseList2:(WGNode *)head {
    if (head == nil || head->next == nil) {
        return head;
    }
    WGNode *newHead = nil;
    while (head != nil) {
        WGNode *temp = head->next;
        head->next = newHead;
        newHead = head;
        head = temp;
    }
    return newHead;
}


/* 141. 环形链表
 给你一个链表的头节点 head ，判断链表中是否有环。
 https://leetcode-cn.com/problems/linked-list-cycle/
 
            slow     fast
            12        34        3         7         99
 head ---> next ---> next ---> next ---> next ---> next
                      ↑                             |
                      -------------------------------
 slow慢指针每次走一步
 fast快指针每次走两步
 如果有环则快慢指针肯定会相遇的
 */
-(BOOL)hasCycle:(WGNode *)head {
    if (head == nil || head->next == nil) {
        return NO;
    }
    //⚠️采用快慢指针
    WGNode *slow = head;
    WGNode *fast = head->next;
    while (fast != nil && fast->next != nil) {
        if (slow == fast) {
            return YES;
        }
        slow = slow->next;
        fast = fast->next->next;
    }
    return NO;
}


/*203. 移除链表元素
 给你一个链表的头节点 head 和一个整数 val ，请你删除链表中所有满足 Node.val == val 的节点，并返回 新的头节点 。
 https://leetcode-cn.com/problems/remove-linked-list-elements/
 */
-(WGNode *)removeElements:(WGNode *)head withElement:(int)val {
    if (head == nil) {
        return head;
    }
    if (head->next == nil) { //只有一个元素
        //相等则删除，返回头结点为nil就代表删除了；否则头结点不变仍然返回head即可
        return head->element == val ? nil : head;
    }
    //默认情况下新的头结点就是head
    WGNode *newHead = head;
    while (head->next != nil) {
        if (head->element == val) {
            newHead = head->next;
        }
        head = head->next;
    }
    return newHead;
}


/*83. 删除排序链表中的重复元素
 存在一个按升序排列的链表，给你这个链表的头节点 head ，请你删除所有重复的元素，使每个元素 只出现一次 。返回同样按升序排列的结果链表。
 https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list/
*/
-(WGNode *)deleteDuplicates:(WGNode *)head {
    //TODO
    return head;
}




/*876. 链表的中间结点
给定一个头结点为 head 的非空单链表，返回链表的中间结点。如果有两个中间结点，则返回第二个中间结点
 https://leetcode-cn.com/problems/middle-of-the-linked-list/
*/
-(WGNode *)middleNode:(WGNode *)head {
    //TODO
    return head;
}


/* 约瑟夫问题(单向循环链表、双向循环链表都可以解决约瑟夫问题)
 举例：8个人围成一圈，从第1开始报数，数到3的将被杀掉，然后从第4开始重新报数，数到3的将被杀掉(6)，依次循环，直到最后剩下一个，其余人都将被杀掉。
 deathNum: 报数到deathNum的人挂掉，
 打印结果中最后一个删除的元素就是可以活下来的人
 */
-(void)josephusProblem:(int)deathNum {
    WGDoubleCycleList *list = [[WGDoubleCycleList alloc]init];
    for (int i = 1; i <= 8; i++) {
        [list add:i];
    }
    //先让current指向头结点first
    [list resetCurrent];
    while (![list isEmpty]) {
        for (int j = 1; j < deathNum; j++) {  //报数到3 则连续调用2次就可以了
            [list nextCurrent];
        }
//        走2步 这个nextCurrent方法调用几次根据要求看需要报数到几开始删除
//        [list nextCurrent];
//        [list nextCurrent];
        //然后删除
        NSLog(@"%d",[list removeCurrent]);
    }
}

/*20. 有效的括号
 给定一个只包括 '('，')'，'{'，'}'，'['，']' 的字符串 s ，判断字符串是否有效。
 有效字符串需满足：左括号必须用相同类型的右括号闭合; 左括号必须以正确的顺序闭合。
 链接：https://leetcode-cn.com/problems/valid-parentheses
 解题思路：
 1. 遇见左字符，将左字符入栈
 2. 遇见右字符
    如果栈是空的，说明括号无效
    如果栈不为空，将栈顶字符出栈，与右字符匹配
        如果左右字符不匹配，说明括号无效
        如果左右字符匹配，继续扫描下一个字符
 3. 所有字符扫描完毕后
    栈为空，说明括号有效
    栈不为空，说明括号无效
*/

-(BOOL)isValid:(NSString *)contentStr {
    NSInteger size = contentStr.length;
    for (int i = 0; i < size; i++) {
        unichar c = [contentStr characterAtIndex:i];
    }
    return contentStr.length == 0;
}
/* 方法二*/
-(BOOL)isValid1:(NSString *)contentStr {
    while ([contentStr containsString:@"{}"] || [contentStr containsString:@"[]"] || [contentStr containsString:@"()"]) {
        [contentStr stringByReplacingOccurrencesOfString:@"{}" withString:@""];
        [contentStr stringByReplacingOccurrencesOfString:@"[]" withString:@""];
        [contentStr stringByReplacingOccurrencesOfString:@"()" withString:@""];
    }
    return contentStr.length == 0;
}


@end
