//
//  WGFirstVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/24.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGFirstVC.h"
#import "WGMainObjcVC.h"


@interface WGFirstVC ()

@end

@implementation WGFirstVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.navigationController pushViewController:[[WGMainObjcVC alloc] init] animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
