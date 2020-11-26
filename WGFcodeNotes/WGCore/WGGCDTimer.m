//
//  WGGCDTimer.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/10/24.
//  Copyright © 2020 WG. All rights reserved.
//

#import "WGGCDTimer.h"



@implementation WGGCDTimer

//8. 声明静态变量字典,来保存定时器唯一标识(key)和对应的定时器(Timer)
static NSMutableDictionary *timerDic;
//14. 信号量静态变量
dispatch_semaphore_t semp;

///9. 为了保证timerDic只创建一次,我们使用initialize,第一次使用才会调用
+(void)initialize {
    //有可能会调用多次initialize,所以我们使用dispatch_once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timerDic = [NSMutableDictionary dictionary];
        semp = dispatch_semaphore_create(1);
    });
    
}


/// task:定时器任务 start:开始时间  interval: 时间间隔 repeats:是否重复  async:是否是异步
+(NSString *)handlerTask:(void(^)(void))task start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(BOOL)repeats async:(BOOL)async {
    //1. 外面不存在任务,就不用去创建GCD定时器了
    if (!task) {
        return nil;
    }
    
    //12. 更严谨的写法
    if (start < 0 || (interval <= 0 && repeats)) {
        return nil;
    }
    
    //10. 为了外部能够调用cancelTask方法来取消定时器,需要设置定时器的唯一标识
    //static int i = 0;
    //NSString *timerName = [NSString stringWithFormat:@"%d",i++];
    //上面代码可以修改成如下
    //NSString *timerName = [NSString stringWithFormat:@"%ld",timerDic.count];
    
    //2. 队列
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) : dispatch_get_main_queue();
    //3. 创建定时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //4. 设置时
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC),
                              interval * NSEC_PER_SEC,
                              0);
    
    //14
    dispatch_semaphore_wait(semp, DISPATCH_TIME_FOREVER);
    //14 由于第10 也是操作字典,那么我们就可以把上面第10行代码移动到这里,同意进行加锁处理,这样就可以提高性能
    NSString *timerName = [NSString stringWithFormat:@"%ld",timerDic.count];
    //11. 将唯一标识和定时器保存到字典中
    timerDic[timerName] = timer;
    dispatch_semaphore_signal(semp);
    
    //5. 设置回调
    dispatch_source_set_event_handler(timer, ^{
        task();
        //6. 非重复,即不重复而是只执行一次
        if (!repeats) {
            //dispatch_source_cancel(timer);   //取消定时器
            //有了外部的取消定时器方法,上面的要移除掉,要用外面的方法来取消
            [self cancelTask:timerName];
        }
    });
    //7. 启动定时器
    dispatch_resume(timer);
    return timerName;
}

/// 取消任务
// 通过定时器唯一标识,来取出定时器,然后取消任务,怎么通过标识来获取对应的定时器哪? 考虑用字典
+(void)cancelTask:(NSString *)timerName {
    //13. 更严谨的写法
    if (timerName.length == 0) {
        return;
    }
    //14
    dispatch_semaphore_wait(semp, DISPATCH_TIME_FOREVER);
    dispatch_source_t timer = [timerDic objectForKey:timerName];
    if (timer) {
        dispatch_source_cancel(timer);
        //取消后,要把字典中的已经取消的定时器也删除
        [timerDic removeObjectForKey:timerName];
    }
    //14
    dispatch_semaphore_signal(semp);
}

//14. 如果我们在子线程中使用定时器,那么可能就有多个线程来同时操作定时器,即同一时间创建定时器和取消定时器只能有一个方法被执行,所以我们需要使用信号量来进行"资源锁定",等同于加锁操作,因为加锁耗费性能,所以我们使用信号量的方式来实现同样的效果,再分析一下,就是保证操作定时器的原子性,那么我只需要在操作字典的地方进行添加信号量控制即可

@end
