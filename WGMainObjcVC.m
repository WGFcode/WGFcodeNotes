//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "WGTestModel.h"


@interface WGMainObjcVC ()

@property(nonatomic, strong) NSString *name;

@end

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(name)) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.name = @"张三";
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSString *name = [change objectForKey:NSKeyValueChangeNewKey];
}

@end
