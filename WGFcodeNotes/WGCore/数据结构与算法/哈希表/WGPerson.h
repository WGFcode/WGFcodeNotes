//
//  WGPerson.h
//  appName
//
//  Created by 白菜 on 2021/12/16.
//  Copyright © 2021 baicai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGPerson : NSObject<NSCopying>

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *score;
@property(nonatomic, assign) int age;

-(instancetype)initWithName:(NSString *)name withScore:(NSString *)score withAge:(int)age;
@end

NS_ASSUME_NONNULL_END
