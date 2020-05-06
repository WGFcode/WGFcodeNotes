//
//  WGTestModel.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/5/3.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGTestModel : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) int age;

+(void)run;
-(void)eat;
-(void)sleepWithTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
