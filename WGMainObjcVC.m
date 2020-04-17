//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "WGTestModel.h"


@implementation WGCustomModel

//懒加载
- (NSMutableArray *)mutableArr {
    if (_mutableArr == nil) {
        _mutableArr = [[NSMutableArray alloc]init];
    }
    return _mutableArr;
}

@end


@interface WGMainObjcVC()

//直接在控制器中声明一个可变数组的属性
@property(nonatomic, strong) NSMutableArray *mutableArr;

@end


@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    //属性初始化
    self.mutableArr = [NSMutableArray array];
    //添加观察
    [self addObserver:self forKeyPath:@"mutableArr" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

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
    //在数组属性发生变化的方法添加willChangeValueForKey 和 didChangeValueForKey方法
    [self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr addObject:@"100"];
    [self didChangeValueForKey:@"mutableArr"];
}
-(void)clickAddBtn {
    [self willChangeValueForKey:@"mutableArr"];
    [self.mutableArr addObject:@"200"];
    [self didChangeValueForKey:@"mutableArr"];
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
    NSArray *newArr = [change objectForKey:NSKeyValueChangeNewKey];
    NSArray *oldArr = [change objectForKey:NSKeyValueChangeOldKey];
    NSLog(@"\nkeyPath:%@\nobject:%@\nchange:%@\ncontext:%@\nnewArr:%@\noldArr:%@\n",keyPath,object,change,context,newArr,oldArr);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver:self forKeyPath:@"mutableArr"];
}

@end



/*
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
