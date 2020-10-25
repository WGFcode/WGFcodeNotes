//
//  WGProxy.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/10/15.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGTargetProxy : NSProxy
@property(nonatomic, weak) id target;
+(instancetype)proxyWithTarget:(id)target;
@end

NS_ASSUME_NONNULL_END
