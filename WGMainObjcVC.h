//
//  WGMainObjcVC.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGThread : NSThread

@end

typedef void (^WGHandle)(void);
//线程保活类
@interface WGKeepThreadAlive : NSObject

-(instancetype)init;
//在当前子线程下处理一个事件
-(void)handleEvent:(WGHandle)handle;
//停止当前线程对应的RunLoop循环并销毁线程
-(void)stopRunLoop;

@end


@interface WGMainObjcVC : UIViewController

@end


NS_ASSUME_NONNULL_END
