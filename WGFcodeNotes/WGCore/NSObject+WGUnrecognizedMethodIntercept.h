//
//  NSObject+WGUnrecognizedMethodIntercept.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/17.
//  Copyright © 2021 WG. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//MARK: 解决因为unrecognized selector sent to instance而crash闪退的问题

@interface NSObject (WGUnrecognizedMethodIntercept)

@end

NS_ASSUME_NONNULL_END
