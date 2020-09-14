//
//  WGRunLoopVC.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/9/9.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGRunLoopVC.h"
#import "WGThread.h"
#import "WGRunLoopSecondVC.h"
#import "WGProxy.h"

@interface WGRunLoopVC ()
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) WGProxy *proxy;
@property(nonatomic, strong) NSString *name;
@end

@implementation WGRunLoopVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];

}





-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    //创建全局队列并添加异步任务
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"11111");
        /*
         1. 打印结果 11111  22222  33333
         分析: 该方法定义在NSObject.h文件中,就是正常的方法调用, 代码执行到这里就会去执行testPerform方法
        */
        //[self performSelector:@selector(testPerform) withObject:nil];
        
        /*
         2. 打印结果 11111 33333
         分析: 该方法定义在NSRunLoop.h文件中,该方法底层是设置一个Timer(定时器)事件源,但是当前子线程的RunLoop默认是没有开启的
         所以,testPerform方法是不会被执行的, 无论afterDelay设置的时间是多少都不会被执行
        */
        //[self performSelector:@selector(testPerform) withObject:nil afterDelay:0];
        /*
         2.1 如果我们开启当前线程的RunLoop,那么打印结果就是 11111  22222  33333
         我们知道 [[NSRunLoop currentRunLoop] run]; 是个循环,为什么还会打印33333?
         因为testPerform一旦执行完成,RunLoop中没有任务就会死掉,所以testPerform执行完成后跳出RunLoop循环就接着打印了33333
         */
        //[[NSRunLoop currentRunLoop] run];
        
        /*
         3. 打印结果
         waitUntilDone: YES: 11111 22222 33333
                         NO: 11111 33333
         分析: 该方法定义在NSThread.h头文件中
         如果是YES,并且onThread和当前所在的线程是同一个线程,那么就立马先执行testPerform后返回
         然后再接着往下执行; 如果是NO,那么该方法就依赖当前线程的RunLoop,由于当前线程的RunLoop没有开启,所以testPerform不会执行
        */
        [self performSelector:@selector(testPerform) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
        /*
         3.1 如果我们开启当前线程的RunLoop,那么waitUntilDone在设置为NO的情况下,打印结果如下: 11111 22222
         [[NSRunLoop currentRunLoop] run]是循环, testPerform执行完成后RunLoop不应该销毁吗?(因为任务完成了)为什么?
         ⚠️⚠️: 这里有疑问, 暂时猜测此处的RunLoop开启会陷入一个死循环, 所以后续的信息33333就不会打印了
         */
        //[[NSRunLoop currentRunLoop] run];
        
        
        /* 3.2 开启RunLoop方法二
        如果没有输入源或者Timer事件添加到运行循环中,次方法将立即退出, 否则会重复调用该方法直到指定的时间到来
        因为我们设置了到指定的未来时间截止,所以该RunLoop开启后会一直运行
        我们也可以理解成死循环了 所以下面打印的结果就是: 11111 22222
        */
        //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
        
        /* 3.3 开启RunLoop方法三
        如果没有输入源或者Timer事件添加到运行循环中,则此方法立即退出并返回NO,否则,将在处理完第一个输入源后或事件到达后返回
        所以下面打印的结果就是: 11111 22222 33333
        */
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        NSLog(@"33333");
    });
}

-(void)testPerform{
    NSLog(@"22222");
}


@end
