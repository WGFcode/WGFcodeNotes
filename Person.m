//
//  Person.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Person.h"

//在Person.m文件中这些写其实就是匿名分类
@interface Person()
//声明的成员变量必须写在{}里面,并且一定是在声明的属性和方法前面,声明的成员变量为了规范我们一般都是加下划线_XXX,成员变量不能用self访问
{
    int age;
}
/* 这里可以写方法声明,但是这里不能写方法实现,匿名分类其实就是方法的私有化, 作用其实就是代码规范,我们进入Person.m文件后
 可以直接看到.m文件中那些方法是私有的
 */
-(void)setAge;
/*
 一般在这里我们都是声明属性,说明这个属性是私有的
 */
@property(nonatomic, strong) NSString *name;

@end


@implementation Person

-(void)test{
    
}

+(void)load {
    NSLog(@"Person--load");
    
}

@end


