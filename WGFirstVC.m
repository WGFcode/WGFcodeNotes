//
//  WGFirstVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/24.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGFirstVC.h"
#import "WGMainObjcVC.h"
//#import "WGTargetProxy.h"
#import "WGSort.h"

//typedef void(^WGBlock)(void);
//#import "Person.h"

@interface WGFirstVC()
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSObject *observerName;
@property(nonatomic, assign) int age;
@end

@implementation WGFirstVC



- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
}


-(void)dealloc {
    NSLog(@"---%s",__func__);
}

@end
