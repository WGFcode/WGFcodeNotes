//
//  Person+PersonCategory.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//


#import "Person.h"

NS_ASSUME_NONNULL_BEGIN

@interface Person (PersonCategory)

@property(nonatomic, strong)NSString *teachName;
-(void)sleep;

@end

NS_ASSUME_NONNULL_END
