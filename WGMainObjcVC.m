//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@interface WGMainObjcVC()<UIScrollViewDelegate>
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"WGMainObjcVC-viewDidLoad当前的model:---%@",[NSRunLoop currentRunLoop].currentMode);
    
    CFRunLoopRef
    
    UIScrollView *scrol = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 100)];
    scrol.backgroundColor = [UIColor redColor];
    scrol.delegate = self;
    scrol.contentSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height *2);
    [self.view addSubview:scrol];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"scrollViewDidScroll当前的model:---%@",[NSRunLoop currentRunLoop].currentMode);
}


@end


