//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import <UIKit/UIKit.h>
#import "Person.h"
#import <objc/runtime.h>
#import "Student.h"
#import <malloc/malloc.h>
#import "WGTargetProxy.h"
#import "Person+PersonTest.h"



@interface WGMainObjcVC()
@property(nonatomic, copy) NSString *name;
@end


@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    Person *person1 = [[Person alloc]init];
    person1.name= @"zhang san";
    NSLog(@"name is %@",person1.name);
    
    Person *person2 = [[Person alloc]init];
    person2.name= @"li si";
    NSLog(@"name is %@",person2.name);
    
    //文字计算
    [@"sdf" boundingRectWithSize:CGSizeMake(100, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:nil context:nil];
    //文字绘制
    [@"test" drawWithRect:CGRectMake(0, 0, 100, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:nil context:nil];
    
    UIImageView *imgView = [[UIImageView alloc]init];
    //通过这种方式加载图片,其实是不会直接显示到屏幕上的,加载的其实是经过压缩后的二进制数据
    //如果要渲染到屏幕上,还需再经过解码,解码成屏幕需要的格式,而解码是放在主线程的,所以可能会产生卡顿
    //可以把解码放在子线程,具体如何解码可以参考网上好多第三方的库中找到
    imgView.image = [UIImage imageNamed:@"test"];
    [self.view addSubview:imgView];
    
}
@end


