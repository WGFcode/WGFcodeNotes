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
@property(nonatomic, assign) int age;
- (void)eat;
- (int)answerQuestionNum;
-(void)footName:(NSString *)name;

@end


NS_ASSUME_NONNULL_END
