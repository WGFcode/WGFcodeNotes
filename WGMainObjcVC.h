//
//  WGMainObjcVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//将监听的数组放在一个模型中
@interface WGCustomModel : NSObject

@property(nonatomic, strong) NSMutableArray *mutableArr;

@end


@interface WGMainObjcVC : UIViewController

//控制器持有这个存放数组的模型属性
//@property(nonatomic, strong) WGCustomModel *model;

@end

NS_ASSUME_NONNULL_END
