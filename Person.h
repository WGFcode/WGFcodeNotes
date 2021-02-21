//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Student.h"

NS_ASSUME_NONNULL_BEGIN


@interface Person : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) NSInteger age;

-(void)test;
@end


NS_ASSUME_NONNULL_END
