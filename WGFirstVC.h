//
//  WGFirstVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/24.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WGCustomProtocol <NSObject>

-(void)eat:(NSString *)foodName;
@end



@interface WGFirstVC : UIViewController

@property(nonatomic, weak) id<WGCustomProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
