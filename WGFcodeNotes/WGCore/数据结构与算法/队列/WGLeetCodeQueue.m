//
//  232. 用栈实现队列.m
//  ZJKBank
//
//  Created by 白菜 on 2021/11/30.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGLeetCodeQueue.h"
#import "WGStack.h"

@interface WGLeetCodeQueue()
{
    WGStack *inStack;
    WGStack *outStack;
}
@end

@implementation WGLeetCodeQueue

//在WGStack初始化方法中初始化array
-(instancetype)init {
    self = [super init];
    if (self) {
        inStack = [[WGStack alloc]init];
        outStack = [[WGStack alloc]init];
    }
    return self;
}

/// 将元素 x 推到队列的末尾
-(void)push:(int)element {
    [inStack push:element];
}


/// 从队列的开头移除并返回元素
-(int)pop {
    if (outStack.isEmpty) { //为空，将inStack出栈，然后弹出栈顶元素
        while (!inStack.isEmpty) {
            [outStack push:[inStack pop]];
        }
    }
    return [outStack pop];
}


/// 返回队列开头的元素
-(int)peek {
    if (outStack.isEmpty) { //为空，将inStack出栈，然后弹出栈顶元素
        while (!inStack.isEmpty) {
            [outStack push:[inStack pop]];
        }
    }
    return [outStack top];
}


/// 如果队列为空，返回 true ；否则，返回 false
-(BOOL)isEmpty {
    return inStack.isEmpty && outStack.isEmpty;
}

@end
