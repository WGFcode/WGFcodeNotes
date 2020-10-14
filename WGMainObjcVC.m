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

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    Person *p1 = [[Person alloc]init];
    [p1 addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //class方法是NSObject中的方法
    [p1 class]; //通过isa指针找到NSKVONotifying_Person类对象，如果里面没有class方法，就通过NSKVONotifying_Person的supperclass找到Person类对象，然后再找到NSObject类对象，NSObject类对象中的class方法实现如下
}

-(Class)class {
    return [Person class];
}

//观察者实现监听方法
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"监听到%p的%@发生改变了---%@",object,keyPath,change);
}

@end


