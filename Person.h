//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

+(instancetype)shareInstance;
+(void)cleanInstance;
@end

NS_ASSUME_NONNULL_END
