//
//  WGPermanentThreadC.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/2/6.
//  Copyright © 2021 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*
 通过C语言去保住线程的命,就不需要额外增加一个属性来控制是否要销毁掉RunLoop,更加的精简
 */

typedef void (^WGPermanentThreadTaskC)(void);

@interface WGPermanentThreadC : NSObject

-(void)run;

-(void)executeTask:(WGPermanentThreadTaskC)task;

-(void)stop;
@end

NS_ASSUME_NONNULL_END
