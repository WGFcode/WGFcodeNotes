//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "WGTestModel.h"

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    WGTestModel *model = [[WGTestModel alloc]init];
    NSLog(@"--model对象的类class:%@---model对象的superClass是:%@----model对象的类的superClass:%@",[model class],[model superclass], [[model class] superclass]);
    Class modelClass = [model class];
    Class modelClassClass = [[model class] class];
    Class WGTestModelClass = [WGTestModel class];
    
    NSObject *objc = [[NSObject alloc]init];
    
    
     NSLog(@"--model对象的类class:%@--%p---model对象的class的class是:%@--%p",modelClass,modelClass, modelClassClass,modelClassClass);
}

@end


