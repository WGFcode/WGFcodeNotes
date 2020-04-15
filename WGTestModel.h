//
//  WGTestModel.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/4.
//  Copyright © 2020 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGTeacher : NSObject
@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL isSex;
@end

@interface WGStudent : NSObject
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) WGTeacher *teacher;
@end

NS_ASSUME_NONNULL_END
