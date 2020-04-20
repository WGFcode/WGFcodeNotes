//
//  WGMainObjcVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



//typedef简化Block生命
/*在swift中有可选类型和非可选类型(?和!),在OC中没有这个区分,所以在混编的时候,swift编译器并不知道它是可选还是非可选,为了解决这个问题,引入了两个关键字
 _Nullable: 表示对象可以是NULL或nil
 _Nonnull: 表示对象不应该为空
 如果不明确是否可选,那么编译器会一直警告
 */
typedef void (^WGCustomBlock)(NSString *name);

@interface WGMainObjcVC : UIViewController



@end

NS_ASSUME_NONNULL_END
