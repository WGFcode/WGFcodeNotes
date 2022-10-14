//
//  Car.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^WGBlock)(void);

NS_ASSUME_NONNULL_BEGIN


@interface Car : NSObject

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) int age;
-(void)run;



@property(nonatomic, copy) WGBlock block;
@end

NS_ASSUME_NONNULL_END
