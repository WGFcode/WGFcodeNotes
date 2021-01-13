//
//  Person.h
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/8/23.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WGBlock) (void);

@interface Person : NSObject
//copy、strong都可以保证将block拷贝到堆上,但建议使用copy,这样无论是ARC还是MRC,这个写法都是一致的
@property(nonatomic, copy) WGBlock block;
@property(nonatomic, assign) int age;
@end


NS_ASSUME_NONNULL_END
