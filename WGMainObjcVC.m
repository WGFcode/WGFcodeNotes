//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Person.h"

@interface WGMainObjcVC()
{
    int totalAppleNum;
}
@end
@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;

    
    Person *p1 = [[Person alloc]init];
    Person *p2 = [[Person alloc]init];
    Person *p3 = [[Person alloc]init];
    NSArray *baseArr = @[p1, p2, p3];
    NSArray *copyArr = [baseArr copy];

    //2、归档和解档
    //归档
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:baseArr];
    //接档
    NSMutableArray *mutableCopyArr = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    NSLog(@"\n源数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    baseArr,baseArr[0],baseArr[1],baseArr[2]);
    NSLog(@"\n浅拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    copyArr,copyArr[0],copyArr[1],copyArr[2]);
    NSLog(@"\n深拷贝copy后数组地址:%p\n---元素1:%p\n---元素2:%p\n---元素3:%p\n",
    mutableCopyArr,mutableCopyArr[0],mutableCopyArr[1],mutableCopyArr[2]);
}





/*
 observer：观察者，即通知的接收者
 selector：接收到通知时的响应方法
 name: 通知name
 object：携带对象
 */
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    //1.创建一个observation对象，持有观察者和SEL，下面进行的所有逻辑就是为了存储它
    o = obsNew(TABLE, aSelector, observer);
    
    // case1: 如果aName存在
    if (aName) {
        //NAMED是个宏，表示名为named字典。以aName为key，从named表中获取对应的mapTable
        n = GSIMapNodeForKey(NAMED, (GSIMapKey)(id)aName);
        if (n == 0) {
            //不存在，则创建
            m = mapNew(TABLE);  //先取缓存，如果缓存没有则新建一个map
            GSIMapAddPair(NAMED, (GSIMapKey)(id)aName, (GSIMapVal)(void*)m);
        }else {
            //存在则把值取出来 赋值给m
            m = (GSIMapTable)n->value.ptr;
        }
    
        //以anObject为key，从字典m中取出对应的value，其实value被MapNode的结构包装了一层，这里不追究细节
        n = GSIMapNodeForSimpleKey(m, (GSIMapKey)anObject);
        if (n == 0) {
            //不存在，则创建,然后将新创建的observation对象进行保存
            o->next = ENDOBS;
            GSIMapAddPair(m, (GSIMapKey)anObject, (GSIMapVal)o);
        }else {
            //存在，则将新创建的observation对象进行保存
            list = (Observation*)n->value.ptr;
            o->next = list->next;
            list->next = o;
        }
    }else if (anObject) { //case2: 如果name为空，但object不为空
        //以anObject为key，从nameless字典中取出对应的value，value是个链表结构
        n = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)anObject);
        if (n == 0) {
            //不存在则新建链表，并存到map中
            o->next = ENDOBS;
            GSIMapAddPair(NAMELESS, (GSIMapKey)object, (GSIMapVal)o);
        }else {
            //存在 则把值接到链表的节点上
        }
    }else { //case3: name 和 object 都为空
        // 则存储到wildcard链表中
        o->next = WILDCARD;
        WILDCARD = o;
    }
}
@end


