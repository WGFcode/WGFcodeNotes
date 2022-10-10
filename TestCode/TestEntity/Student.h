//
//  Student.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/22.
//  Copyright © 2020 WG. All rights reserved.
//
/* iOS消息发送机制经历三大阶段
 1.消息发送
 方法调用其实就是给方法调用者发送消息，会通过调用者的isa指针获取到类对象，然后在类对象的方法缓存cache(哈希表一维数组)中找方法，找到了就调用该方法；
 获取过程：哈希表中存放的是方法名SEL和方法实现的地址，通过方法命 &mask获取到哈希表的下标，然后找到SEL对比，如果方法名相同，则取出IMP进行调用，
 存放过程: 通过方法名和mask(哈希表长度-1)进行&结果得到index下标，然后找到下标，存放方法名和方法调用；如果下标中已经有了，则index-1下标减-1依次寻找，如果哈希表个数超过四分三，则进行扩容，扩大原来容量的2倍，然后清楚原来哈希表中的数据进行重新存放
 
 找不到就在类对象的方法列表method_array_list二维数组中查找（如果已经排好序了就使用二分查找，如果没有排好序就遍历查找），如果找到直接调用；
 找不到就通过类对象的superclass指针找到父类的类对象，在这里面首先查找方法缓存列表，找到调用，找不到去方法列表中查找；找到调用；
 找不到就继续通过suerClass找到父类的父类的类对象，依次循环茶渣，如果找到基类NSObject的类对象还找不到,那么就进入动态方法解析阶段(因为基类NSObject类的superClass等于nil)
 
 
 2.动态方法解析
 检查是否解析过：如果没有解析过，则调用resolveInstanceMethod:(SEL)sel/resolveClassMethod:(SEL)sel方法进行动态方法解析
 在resolveInstanceMethod方法中，动态添加方法class_getMethodImplementation,为该方法动态添加一个实现，然后重新走消息发送阶段
 如果添加成功了，那么走消息发送阶段就会找到这个动态添加的方法进行实现；如果实现了resolveInstanceMethod方法，但是在里面没有动态添加方法，则走完消息发送流程后，会再次来到动态方法解析，判断已经动态解析过了，就会走消息转发阶段
 
 3.消息转发
 首先判断-(id)forwardingTargetForSelector:(SEL)aSelector有没有实现，并且返回了一个可以处理该方法的有效对象，然后直接调用该对象的方法即可;
 该对象的方法必须和调用的方法名称和参数一直，返回值不一致没关系；
 若在forwardingTargetForSelector阶段没有返回一个处理消息的对象，则会进入下一步实现方法methodSignatureForSelector，返回一个有效的方法签名，这个方法签名对于返回值、参数类型、参数个数没有任何要求，只要是有效果的就行
 然后必须要实现+-forwardInvocation:(NSInvocation *)anInvocation方法，在这个方法里面可以任意处理，即使什么都不做也可以；还可以指定一个对象来调用方法
 分类的方法是如何添加到类的？
 分类信息都存储在category_t结构体中，在程序运行时，runtime会动态将分类信息添加到类对象信息中，通过内存移动和内存拷贝将分类中的方法列表/属性列表/协议列表添加到类信息中对应的方法/属性协议列表信息中
 KVO实现原理及使用
 利用runtime动态生成一个子类，让对象的isa指针指向这个全新的子类，当修改instance对象的属性时，会调用Foundation下的NSSetXXXvalueandNotify函数
 该函数内部会调用willchangeValueforkey，父类猿类的setter方法，didchangeValueforkey,didivalueforkey方法内部会调用observervalueforkeypath方法
 
 */
#import "Person.h"

NS_ASSUME_NONNULL_BEGIN

@interface Student : Person

-(void)run;
-(void)otherRun;
+(void)thisClassMethod;

@end

NS_ASSUME_NONNULL_END
