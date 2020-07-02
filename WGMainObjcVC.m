//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "BinaryTree.h"

@implementation WGMainObjcVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];


    NSArray *arr = @[@12, @53, @2, @234, @12, @34, @123, @34, @66];
    BinaryTree *tree = [BinaryTree create:arr];
    NSLog(@"-----%@-----",tree);

    
    WGTestModel *model = [[WGTestModel alloc]init];
    NSLog(@"--model对象的类class:%@---model对象的superClass是:%@----model对象的类的superClass:%@",[model class],[model superclass], [[model class] superclass]);
    Class modelClass = [model class];
    Class modelClassClass = [[model class] class];
    Class WGTestModelClass = [WGTestModel class];
    
    NSObject *objc = [[NSObject alloc]init];
    
    
    NSLog(@"--model对象的类class:%@--%p---model对象的class的class是:%@--%p",modelClass,modelClass, modelClassClass,modelClassClass);

}

@end


