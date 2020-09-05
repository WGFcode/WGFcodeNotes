//
//  WGMainObjcVC.m
//  WGstrNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"
#import "BinaryTree.h"
#import <UIKit/UIKit.h>
#import "WGFirstVC.h"
#import "Person.h"
#import "Person+PersonCategory.h"


@interface WGMainObjcVC()
{
    NSString *name4;
}
@property(nonatomic, strong) NSString *name0;
@property(atomic, strong) NSString *name1;
@property(nonatomic, copy) NSString *name2;
@property(nonatomic, assign) int nameAge;

@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    Person *p = [[Person alloc]init];
    NSLog(@"p对象的父类%@-----p对象的class:%@----Person的父类:%@----Person的class:%@", [p superclass], [p class], [Person superclass], [Person class]);
    NSLog(@"%@-----%@", [NSObject superclass], [NSObject class]);
}





@end


