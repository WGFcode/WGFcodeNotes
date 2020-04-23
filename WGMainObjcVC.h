//
//  WGMainObjcVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^WGCustomBlock)(int age);


@interface WGAnimal : NSObject
@property(nonatomic, copy) WGCustomBlock block;
@property(nonatomic, strong) NSString *name;

@end


@interface WGMainObjcVC : UIViewController

@end

NS_ASSUME_NONNULL_END
