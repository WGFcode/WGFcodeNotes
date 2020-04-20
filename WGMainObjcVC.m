//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGAnimal

-(instancetype)init {
    if (self == [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(change:) name:@"WGAnimalName" object:nil];
    }
    return self;
}

-(void)dealloc {
    NSLog(@"对象销毁了");
}

-(void)change:(NSNotification *)noti {
    NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",noti.name,noti.object,noti.userInfo);
}

@end



@interface WGMainObjcVC()
{
    WGAnimal *_animal;
}
@end


@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    //queue参数: 就是将usingBlock提交到queue队列里面执行，一般是设置为主队列用于更新UI，主队列任务都是在主线程中更新的
    [[NSNotificationCenter defaultCenter] addObserverForName:@"customStr" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",note.name,note.object,note.userInfo);
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"customStr" object:nil];
}

-(void)change:(NSNotification *)noti {
    NSLog(@"通知名称:%@,通知对象:%@,通知携带参数:%@",noti.name,noti.object,noti.userInfo);
}

@end
