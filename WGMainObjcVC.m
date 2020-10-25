//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import "Person.h"
#import <objc/runtime.h>
#import "Student.h"
#import <malloc/malloc.h>
#import "WGTargetProxy.h"


@interface WGMainObjcVC()
@property(nonatomic, copy) NSString *name;
@end

@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    __strong Person *person1;    //__strong可以不写,因为默认都是强引用
    __weak Person *person2;
    __unsafe_unretained Person *person3;
    
    NSLog(@"begin");
    {
        Person *person = [[Person alloc]init];
        //1. person1是强引用,所以出了{},person对象并不会销毁,而是在viewDidLoad方法执行结束后销毁
        //所以打印结果是: begin  -->   end   --> -[Person dealloc]---
        //person1 = person;
        
        //2. person2是弱引用,所以出了{},person对象就销毁了
        //所以打印结果是: begin  -->   -[Person dealloc]---   -->   end
        //person2 = person;
        
        //3. person3也是弱引用,所以出了{},person对象就销毁了
        //所以打印结果是: begin  -->   -[Person dealloc]---   -->   end
        person3 = person;
        
        //4.__weak和__unsafe_unretained都是弱指针,区别就是__weak弱引用在对象销毁时,会对对象自动置为nil; 而__unsafe_unretained弱引用在对象销毁时,不会对对象自动置为nil,会出现野指针问题,即虽然对象销毁了,但是它的内存仍然存在,如果继续访问该对象,会导致坏内存访问
    }
    NSLog(@"end");
}




@end


