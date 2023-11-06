//
//  WGLeetCodeTestVC.h
//  appName
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 baicai. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WGNode;
@interface WGLeetCode : NSObject


//MARK:************************链表************************

/*237. 删除链表中的节点
  https://leetcode-cn.com/problems/delete-node-in-a-linked-list/
*/
-(void)deleteNode:(WGNode *)node;


/*206. 反转链表 递归方式
 https://leetcode-cn.com/problems/reverse-linked-list/
*/
-(WGNode *)reverseList1:(WGNode *)head;
//206. 反转链表 非递归
-(WGNode *)reverseList2:(WGNode *)head;


/* 141. 环形链表
 给你一个链表的头节点 head ，判断链表中是否有环。
 https://leetcode-cn.com/problems/linked-list-cycle/
 */
-(BOOL)hasCycle:(WGNode *)head;


/*203. 移除链表元素
 给你一个链表的头节点 head 和一个整数 val ，请你删除链表中所有满足 Node.val == val 的节点，并返回 新的头节点 。
 https://leetcode-cn.com/problems/remove-linked-list-elements/
 */
-(WGNode *)removeElements:(WGNode *)head withElement:(int)val;


/*83. 删除排序链表中的重复元素
 存在一个按升序排列的链表，给你这个链表的头节点 head ，请你删除所有重复的元素，使每个元素 只出现一次 。返回同样按升序排列的结果链表。
 https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list/
*/
-(WGNode *)deleteDuplicates:(WGNode *)head;


/*876. 链表的中间结点
给定一个头结点为 head 的非空单链表，返回链表的中间结点。如果有两个中间结点，则返回第二个中间结点
 https://leetcode-cn.com/problems/middle-of-the-linked-list/
*/
-(WGNode *)middleNode:(WGNode *)head;


/* 约瑟夫问题(单向循环链表、双向循环链表都可以解决约瑟夫问题)
 举例：8个人围成一圈，从第1开始报数，数到3的将被杀掉，然后从第4开始重新报数，数到3的将被杀掉(6)，依次循环，直到最后剩下一个，其余人都将被杀掉。
 deathNum: 报数到deathNum的人挂掉，
 */
-(void)josephusProblem:(int)deathNum;


/*20. 有效的括号
 给定一个只包括 '('，')'，'{'，'}'，'['，']' 的字符串 s ，判断字符串是否有效。
 有效字符串需满足：左括号必须用相同类型的右括号闭合; 左括号必须以正确的顺序闭合。
 链接：https://leetcode-cn.com/problems/valid-parentheses
*/
-(BOOL)isValid:(NSString *)contentStr;

@end

NS_ASSUME_NONNULL_END
