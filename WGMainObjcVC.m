//
//  WGMainObjcVC.m
//  WGFcodeNotes
//
//  Created by 白菜 on 2020/4/2.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGMainObjcVC.h"

@implementation WGThread
-(void)dealloc {
    NSLog(@"线程销毁了");
}
@end


@interface WGMainObjcVC()
@property(nonatomic, strong) WGThread *thread;
//添加一个Runloop退出的条件
@property(nonatomic, assign, getter=isStop)BOOL isStop;
@end

@implementation WGMainObjcVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    self.isStop = NO;
    __weak typeof(self) weakSelf = self;
    if (@available(iOS 10.0, *)) {
        self.thread = [[WGThread alloc] initWithBlock:^{
            NSLog(@"开始执行线程中的任务");
            [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
            //self强引用thread,thread强引用Block，Block内又引用self,weakSelf来避免循环引用
            while (weakSelf && !weakSelf.isStop) {
                //[NSDate distantFuture]表示未来某一不可达到的事件点，说白了等同与正无穷大的事件
                //beforeDat:过期时间，传入distantFuture遥远的未来，就是永远不会过期
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
            NSLog(@"线程中任务执行完成");
        }];
    } else { /*Fallback on earlier versions*/ }
    [self.thread start];
    
    UIButton *stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
    stopBtn.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:stopBtn];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
}

-(void)stop{
    //https://www.jianshu.com/p/a761f4a85a15
    [self performSelector:@selector(stopRunLoop) onThread:self.thread withObject:nil waitUntilDone:YES];
}

-(void)stopRunLoop {
    NSLog(@"开始执行RunRunLoop停止的方法");
    self.isStop = YES;
    //系统提供的停止RunLoop的方法
    CFRunLoopStop(CFRunLoopGetCurrent());
    NSLog(@"执行RunRunLoop停止的方法已经结束了");
}

-(void)dealloc {
    [self stop];
    NSLog(@"WGMainObjcVC销毁了");
}
@end


