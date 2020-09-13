//
//  WGRunLoopSecondVC.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/10.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGRunLoopSecondVC.h"
#import "WGRunLoopVC.h"
@interface WGRunLoopSecondVC ()

@end

@implementation WGRunLoopSecondVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.navigationController pushViewController:[[WGRunLoopVC alloc]init] animated:YES];
}


@end
