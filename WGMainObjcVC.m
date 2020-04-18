//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "WGTestModel.h"
#import <objc/message.h>

@implementation WGAnimal

//-(void)setAge:(int)age {
//    //年龄在【10-20】之间才触发监听方法
//    if (age >= 10 && age <= 20) {
//        [self willChangeValueForKey:@"age"];
//        self willChangeValueForKey:<#(nonnull NSString *)#>
//        _age = age;
//        [self didChangeValueForKey:@"age"];
//    }else {
//        _age = age;
//    }
//}

//+(BOOL)automaticallyNotifiesObserversOfAge {
//    return NO;
//}
//
//+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    if ([key isEqualToString:@"age"]) {
//        return NO;
//    }
//    return [super automaticallyNotifiesObserversForKey: key];
//}

@end


@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    NSString *contextNSString = @"abcdefg";
    NSArray *contentNSArray = @[@"100",@"200"];
    NSDictionary *contextNSDictionary = @{@"teacher": @"zhanglaoshi", @"student": @"xiaoming"};
    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(contentNSArray)];
    
//    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(contextNSString)];
//    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(contextNSString)];
//    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: @"abcdefg"];
    self.name = @"zhangsan";
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"context is:%@",context);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver:self forKeyPath:@"name"];
}

@end



/*
 
 //获取animalName属性的setter方法实现的IMP，IMP是一个指向方法实现的指针
 IMP animalIMP1 = [animal1 methodForSelector:@selector(setAnimalName:)];
 IMP animalIMP2 = [animal2 methodForSelector:@selector(setAnimalName:)];
 NSLog(@"添加观察者前\nanimalIMP1:%p\nanimalIMP1:%p",animalIMP1,animalIMP2);
 
 
UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 120, 100, 30)];
btn.backgroundColor = [UIColor yellowColor];
[self.view addSubview:btn];
[btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
 
 -(void)clickBtn {
     [self removeObserver:self forKeyPath:@"view"];
 }
 
 UIView *customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)];
 customView.backgroundColor = [UIColor blueColor];
 self.view = customView;
*/
