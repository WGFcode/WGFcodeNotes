//
//  Student.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/22.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Student.h"
#import <objc/runtime.h>

@implementation Student
/*
/*
 struct __rw_objc_super {
     struct objc_object *object;
     struct objc_object *superClass;
 };
 
 */

-(void)run {
    [super run];
    /*
     [super run];底层分析
    objc_msgSendSuper({self, class_getSuperclass(objc_getClass("Student")}, sel_registerName("run"));
    objc_msgSendSuper({消息接收着，消息接收着父类},@selector(run));
     消息接收着仍然是self,即当前的Student对象，只是方法查找是从Student的父类中开始查找的
    */
    NSLog(@"----------%s",__func__);
}


-(instancetype)init {
    if (self = [super init]) {
        NSLog(@"[self class] = %@",[self class]);           //Student
        NSLog(@"[self superclass] = %@",[self superclass]); //Person
        NSLog(@"-----");
        /*
         [super class]底层分析：消息接收着仍然是当前的Student对象，只是查找class方法是从student对象的父类中开始查找的
         我们知道class方法是NSObject类中的方法，所以会从Person类开始查找，最终找到NSObject类中，然后进行调用
         class方法底层如下，所以返回什么，和self是有关系的，这里self就是消息接收着，而消息接收者是Student对象，所以将self
         传递给object_getClass后得到的就是Student类
         - (Class)class {
             return object_getClass(self);
         }
         [super superclass]底层分析： 这个过程其实和[super class]是一样的，都是从父类(Person)中开始查找superclass方法
         superclass方法底层如下，而消息接收者就是self，即Student对象，所以通过superclass后获取的就是Person对象了
         - (Class)superclass {
             return [self class]->superclass;
         }
         */
        NSLog(@"[super class] = %@",[super class]);         //Student
        NSLog(@"[super superclass] = %@",[super superclass]);//Person
    }
    return self;
}




//1. 消息发送阶段如果没有找到方法，就走动态方法解析阶段
//动态方法解析阶段，其实就是在这个阶段添加要实现的方法
-(void)otherTest{
    NSLog(@"----%s",__func__);
}
//处理类方法
+(BOOL)resolveClassMethod:(SEL)sel {
    return [super resolveClassMethod:sel];
}
//处理对象方法
+(BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(test)) {
        Method method = class_getInstanceMethod(self, @selector(otherTest));
        class_addMethod(self, sel, method_getImplementation(method), method_getTypeEncoding(method));
    }
    return [super resolveInstanceMethod:sel];
}


//2. 如果动态解析阶段没有处理，就走消息转发阶段
@end
