//
//  WGStack.m
//  ZJKBank
//
//  Created by 白菜 on 2021/11/21.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGStack.h"
#import "WGDynamicArray.h"
#import "WGDoubleList.h"

@interface WGStack()
{
    int size;      //栈中元素的个数
    WGDynamicArray *array;   //动态数组
    WGDoubleList *list;            //双向链表
}

@end

@implementation WGStack


//在WGStack初始化方法中初始化array
-(instancetype)init {
    self = [super init];
    if (self) {
        array = [[WGDynamicArray alloc]init];
        list = [[WGDoubleList alloc]init];
    }
    return self;
}
                     
/// 获取栈中元素的个数
-(int)size {
    //return array.size;
    return list.size;
}

/// 判断栈是否为空
-(BOOL)isEmpty {
    //return [array isEmpty];
    return [list isEmpty];
}

/// 入栈
-(void)push:(int)element {
    //[array add:element];
    [list add:element];
}

/// 出栈
-(int)pop {
    //return [array remove:array.size - 1];
    return [list remove:list.size - 1];
}

/// 获取栈顶元素
-(int)top {
    //return [array get:array.size - 1];
    return [list get:list.size - 1];
}
@end
