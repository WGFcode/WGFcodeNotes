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


@interface WGMainObjcVC()
{
    int totalAppleNum;
}
@end
@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;
    totalAppleNum = 30;
    
    for (int i = 1; i < totalAppleNum; i++) {
        NSThread *thread1 = [[NSThread alloc]initWithTarget:self selector:@selector(eatApple) object:nil];
        [thread1 start];
    }
}



-(void)eatApple{
    totalAppleNum -= 1;
    NSLog(@"当前线程:%@----当前苹果数:%d",[NSThread currentThread],totalAppleNum);
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


