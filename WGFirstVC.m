//
//  WGFirstVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/24.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGFirstVC.h"
#import "WGMainObjcVC.h"
#import "WGTargetProxy.h"

@interface WGFirstVC()
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, strong) NSTimer *timer;

@end

@implementation WGFirstVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.lightGrayColor;
    
//    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(test) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    //self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(test) userInfo:nil repeats:YES];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[WGTargetProxy proxyWithTarget:self] selector:@selector(test) userInfo:nil repeats:YES];

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
   // [self.timer invalidate];
}

-(void)dealloc {
    NSLog(@"---%s",__func__);
}

-(void)test{
    NSLog(@"-----%s-----",__func__);
}
@end
