//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@interface WGMainObjcVC ()
{
    int _pageNum;
}
@end

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)method1 {
    @synchronized (self) {
        _pageNum -= 1;
        NSLog(@"当前的pageNum为:%d",_pageNum);
    }
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
