//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGView
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"WGView点击了");
}
@end

@interface WGMainObjcVC()<UIGestureRecognizerDelegate>

@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    WGView *view = [[WGView alloc]initWithFrame:CGRectMake(0, 100, 300, 200)];
    [self.view addSubview:view];
    
    UILongPressGestureRecognizer *tap = [[UILongPressGestureRecognizer alloc]init];


    
    /*

*/
}



@end


