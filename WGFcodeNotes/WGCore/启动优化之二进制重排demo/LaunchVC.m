//
//  ViewController.m
//  OCMachO
//
//  Created by 白菜 on 2025/1/8.
//

#import "ViewController.h"
#import <dlfcn.h>
#import <libkern/OSAtomic.h>
/*
 启动优化之-二进制重排
 第一：就是通过Xcode-> Build Settings-> Apple Clang - Custom Compiler Flags-> Other C Flags
 添加:
     -fsanitize-coverage=func,trace-pc-guard
 第二：
 1.第一步就是将符号地址信息以节点node的形式保存在原子队列中
 2.遍历原子队列中的节点node,然后通过函数符号地址找到对应的函数名称
 3.将函数名称保存在沙河指定的位置下
 4.取出文件中的信息复制到我们项目根目录下的order文件中
 5.这样就可以通过调整启动时的方法调用来减少Page In缺页中断的次数来达到启动优化的目的
 */

//原子队列(导入头文件#import <libkern/OSAtomic.h>)
static OSQueueHead symboList = OS_ATOMIC_QUEUE_INIT;
//定义符号结构体
typedef struct{
    void * pc;
    void * next;
}SymbolNode;



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.yellowColor;
    [self test1];
    [self test2];
}

-(void)test1 {
    NSLog(@"1");
}
-(void)test2 {
    NSLog(@"2");
}

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start, uint32_t *stop) {
    static uint64_t N;
    if (start == stop || *start) return;
    printf("INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;
}
//每次调用一个函数时都会先插入这个函数
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    void *PC = __builtin_return_address(0);
    //PC可以获取到函数地址--> 获取到函数名
    //将PC以节点的形式存储在链表中
    SymbolNode *node = malloc(sizeof(SymbolNode));
    *node = (SymbolNode){PC,NULL};
    //入队 将每个PC存放的节点数据入对
    // offsetof 用在这里是为了入队添加下一个节点找到 前一个节点next指针的位置
    OSAtomicEnqueue(&symboList, node, offsetof(SymbolNode, next));
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableArray<NSString *> * symbolNames = [NSMutableArray array];
    while (true) {
        //遍历链表 offsetof 就是针对某个结构体找到某个属性相对这个结构体的偏移量
        SymbolNode * node = OSAtomicDequeue(&symboList, offsetof(SymbolNode, next));
        if (node == NULL) break;
        Dl_info info;
        dladdr(node->pc, &info);
        //通过函数符号地址获取到函数名
        NSString * name = @(info.dli_sname);
        
        // OC方法是-[xxx]  C语言和Block方法前面需要添加下划线_
        BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
        NSString * symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        
        //去重
        if (![symbolNames containsObject:symbolName]) {
            [symbolNames addObject:symbolName];
        }
    }
    //取反
    NSArray * symbolAry = [[symbolNames reverseObjectEnumerator] allObjects];
    NSLog(@"通过函数符号地址找到的函数名称存放在数组中%@",symbolAry);
    //将结果写入到文件
    NSString * funcString = [symbolAry componentsJoinedByString:@"\n"];
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"lb.order"];
    NSData * fileContents = [funcString dataUsingEncoding:NSUTF8StringEncoding];
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
    if (result) {
        NSLog(@"%@",filePath);
    }else{
        NSLog(@"文件写入出错");
    }
}




@end
