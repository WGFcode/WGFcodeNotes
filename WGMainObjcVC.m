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

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    Student *stu = [[Student alloc]init];
    
    
//    NSObject *obj1 = [[NSObject alloc]init];
//    NSObject *obj2 = [[NSObject alloc]init];
//
//    //获取类对象方式
//    //方式一: 通过调用实例对象的class方法
//    Class objClass1 = [obj1 class];
//    Class objClass2 = [obj2 class];
//    //方式二: 通过调用类的class方法
//    Class objClass3 = [NSObject class];
//    //方式三: 通过RunTime的object_getClass将实例对象传递进去
//    Class objClass4 = object_getClass(obj1);
//    Class objClass5 = object_getClass(obj2);
    
    //获取元类对象---元类对象和类对象都是Class类型
    //通过RunTime的object_getClass将类对象传递进去
//    Class objcMetaClass = object_getClass([NSObject class]);
//    //为了验证元类对象和类对象不是同一个对象
//    Class objClass = [NSObject class];
//    NSLog(@"objcMetaClass:%p---\nobjClass:%p---\n",objcMetaClass, objClass);
    
    //获取类对象
    Class objClass = [NSObject class];
    //获取元类对象
    Class objcMetaClass = object_getClass([NSObject class]);
    //通过类的class方法获取到类对象,再通过类对象的class方法获取对象
    Class cls1 = [[NSObject class] class];
    Class cls2 = [[[NSObject class] class] class];
    NSLog(@"objcMetaClass:%p---\nobjClass:%p---\ncls1:%p---\ncls2:%p---\n",objcMetaClass, objClass,cls1,cls2);
    //malloc_size(<#const void *ptr#>)
    
    // 使用malloc_size 需要导入#import <malloc/malloc.h>头文件
    NSObject *objc = [[NSObject alloc]init];
    NSLog(@"%zd-----%zd",class_getInstanceSize([NSObject class]), malloc_size((__bridge const void *)(objc)));
    //打印结果: 8-----16
    //malloc_size 系统分配的内存空间大小
    //class_getInstanceSize: 真正使用的内存空间大小
    
}
@end


