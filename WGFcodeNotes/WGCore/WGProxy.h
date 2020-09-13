//
//  WGProxy.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/13.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// NSProxy消息转发的基类
@interface WGProxy : NSProxy
@property(nonatomic, weak) id target;
@end

NS_ASSUME_NONNULL_END
