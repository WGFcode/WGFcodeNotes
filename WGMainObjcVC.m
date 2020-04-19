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

@interface WGMainObjcVC()
@property(nonatomic, strong) NSMutableArray *mutableArr;

@end


@implementation WGMainObjcVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    self.mutableArr = [[NSMutableArray alloc]init];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(mutableArr)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    UIButton *addBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 120, 100, 30)];
    addBtn.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:addBtn];
    [addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
    UIButton *deleteBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 160, 100, 30)];
    deleteBtn.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:deleteBtn];
    [deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
    UIButton *replaceBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 30)];
    replaceBtn.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:replaceBtn];
    [replaceBtn addTarget:self action:@selector(clickReplaceBtn) forControlEvents:UIControlEventTouchUpInside];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    ////在数组属性发生变化的方法添加willChangeValueForKey 和 didChangeValueForKey方法
    //[self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr addObject:@"100"];
    //[self didChangeValueForKey:@"mutableArr"];
}
-(void)clickAddBtn {
    //[self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr addObject:@"200"];
    //[self didChangeValueForKey:@"mutableArr"];
}
-(void)clickDeleteBtn {
    [self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr removeLastObject];
    [self didChangeValueForKey:@"mutableArr"];
}
-(void)clickReplaceBtn {
    [self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr replaceObjectAtIndex:0 withObject:@"888"];
    [self didChangeValueForKey:@"mutableArr"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSString *newParents = [change objectForKey:NSKeyValueChangeNewKey];
    NSString *oldParents  = [change objectForKey:NSKeyValueChangeOldKey];
    NSLog(@"\nnewParents:%@\noldParents:%@",newParents,oldParents);
}


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver:self forKeyPath:@"mutableArr"];
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
