//
//  Student+StudentCategory.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/22.
//  Copyright © 2020 WG. All rights reserved.
//

#import "Student.h"

NS_ASSUME_NONNULL_BEGIN

@interface Student (StudentCategory)
+(void)load;

@property(nonatomic, strong) NSString *name;
@end

NS_ASSUME_NONNULL_END
