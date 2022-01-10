//
//  WGHeap.m
//  ZJKBank
//
//  Created by 白菜 on 2021/12/14.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGBinaryHeap.h"

@interface WGBinaryHeap()
{
    int size;
    NSMutableArray *arr;
}
@end



@implementation WGBinaryHeap

/// 获取元素的个数
-(int)size {
    return size;
}


/// 判断是否为空
-(BOOL)isEmpty {
    return size == 0;
}


/// 清空
-(void)clear {
    for (int i = 0; i < size; i++) {
        arr[i] = [NSNull null];
    }
    size = 0;
}


/* 添加思路分析
 添加元素都是先添加到数组的末尾，假设添加的元素的节点叫做node
 循环执行以下操作
    如果 node > 父节点的值，则与父节点交换位置
    如果 node <= 父节点的值，或node没有父节点，则退出循环
 这个过程叫做上滤(Sift up),时间复杂度O(logn)
             ------------72------------
             ↓                        ↓
        -----68-----              ----50-----
        ↓          ↓             ↓           ↓
     ---43---   ---38---         47          21
     ↓      ↓   ↓      ↓
     14     40  3      80(要添加的元素)
 */
/// 添加元素
-(void)addElement:(int)element {
    //先将元素添加到数组的最后位置
    arr[size++] = [NSNumber numberWithInt:element];
    //然后对数组中最后一个元素进行上滤操作
    [self siftUpWithIndex:size-1];
}
/// 让index位置的元素进行上滤
-(void)siftUpWithIndex:(int)index {
    int element = [arr[index] intValue];
    while (index > 0) {
        //找到index的父节点的索引
        int parentIndex = (index - 1) >> 1;
        //父节点元素的值
        int parentElement = [arr[parentIndex] intValue];
        if (parentElement >= element) { //父节点的值 >= index位置的元素 则不需要再操作
            return;
        }
        //交换index、parentIndex位置的元素
        id temp = arr[index];
        arr[index] = arr[parentIndex];
        arr[parentIndex] = temp;
        //重新赋值index，即让父节点的下标赋值给index
        index = parentIndex;
    }
}
//一般交换位置需要3行代码，可进一步优化，将新添加元素备份，确定最终位置才摆放上去
/// 让index位置的元素进行上滤--- 交换位置的优化版
-(void)siftUpWithIndex1:(int)index {
    int element = [arr[index] intValue];
    while (index > 0) {
        //找到index的父节点的索引
        int parentIndex = (index - 1) >> 1;
        //父节点元素的值
        int parentElement = [arr[parentIndex] intValue];
        if (parentElement >= element) { //父节点的值 >= index位置的元素 则不需要再操作
            return;
        }
        //将父节点的元素存储在index上
        arr[index] = [NSNumber numberWithInt:parentElement];
        
        //重新赋值index，即让父节点的下标赋值给index
        index = parentIndex;
    }
    //最终index位置就是元素待插入的位置
    arr[index] = [NSNumber numberWithInt:element];
}


/// 获取堆顶元素
-(int)get {
    return [arr[0] intValue];
}

/* 删除堆顶元素思路分析
 1. 用最后一个节点覆盖根节点(43 覆盖 80)
 2. 删除最后一个节点(删除43节点)
 3. 循环执行以下操作(43简称为node)
    如果node < 子节点，与最大的子节点交换位置
    如果node >= 子节点 或者 node没有子节点，退出循环
这个过程叫做下滤(Sift down),时间复杂度O(logn),同样的交换位置的优化可以参照上滤
 
             ------------80------------
             ↓                        ↓
        -----72-----              ----50-----
        ↓          ↓             ↓           ↓
     ---68---      38            47          21
     ↓      ↓
     14     43

          ------------43------------
          ↓                        ↓
     -----72-----              ----50-----
     ↓          ↓             ↓           ↓
  ---68         38            47          21
  ↓
  14
 */
/// 删除堆顶元素 返回删除的堆顶元素
-(int)remove {
    if (size == 0) { //无元素可以删除
        return -1;
    }
    //堆顶元素
    int heapTopElement = [arr[0] intValue];
    //将末尾元素覆盖掉堆顶元素
    arr[0] = arr[size-1];
    //删除末尾元素
    arr[size-1] = [NSNull null];
    //数组元素-1
    size--;
    //对新的堆顶元素进行下滤操作
    [self siftDownWithIndex:0];
    return heapTopElement;
}
/// 让index位置的元素下滤
-(void)siftDownWithIndex:(int)index {
    int element = [arr[index] intValue];
    //第一个叶子节点的索引 = 非叶子节点的数量
    int half = size >> 1;
    // index < 第一个叶子节点的索引,必须保证index位置是非叶子节点
    while (index < half) {
        // index位置的节点有2种情况 1:只有左子节点 2:同时有左右子节点
        // 默认为左子节点跟它进行进行比较
        int childIndex = (index << 1) + 1;  //index*2 + 1
        int childElement = [arr[childIndex] intValue];
        
        //右子节点
        int rightIndex = childIndex + 1;
        int rightElement = [arr[rightIndex] intValue];
        
        //选出左右子节点中的最大值 如果右子节点 > 左子节点 则需要跟右子节点进行比较
        if (rightIndex < size && rightElement > childElement) {
            childIndex = rightIndex;
            childElement = [arr[childIndex] intValue];
        }
        // 到这里 childIndex、childElement就是index位置节点的左右子节点中最大节点的下标和元素值
        //拿到左右子节点中的最大值和element进行比较
        if (element > childElement) { //添加的元素比左右子节点都大,则不需要任何操作
            break;
        }
        //将子节点存放在Index（即将最大值放到index位置）
        arr[index] = [NSNumber numberWithInt:childElement];
        //重新设置index
        index = childIndex;
    }
    arr[index] = [NSNumber numberWithInt:element];
}


/// 删除堆顶元素的同时插入一个新元素 并返回删除的堆顶元素
-(int)replace:(int)element {
    int root = -1;   //没有堆顶元素，返回-1
    if (size == 0) { //添加的第一个元素
        arr[0] = [NSNumber numberWithInt:element];
        size++;
    }else {
        //先获取堆顶元素，便于返回
        root = [arr[0] intValue];
        //让element覆盖0位置的元素
        arr[0] = [NSNumber numberWithInt:element];
        //对0位置的元素进行下滤操作
        [self siftDownWithIndex:0];
    }
    return root;
}


/* 批量建堆又两种方式： 1:自上而下的上滤 2:自下而上的上滤
 1.自上而下的上滤执行流程图如下：除了堆顶元素不需要操作之外，其他所有的节点都需要做上滤操作
        ------------30---------
        ↓                      ↓
     ---34---              ----73
     ↓       ↓             ↓
    60       68            43
    ------------------------------------------
         ------------34---------
         ↓                      ↓
      ---30---              ----73
      ↓       ↓             ↓
     60       68            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---30---              ----34
      ↓       ↓             ↓
     60       68            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---60---              ----34
      ↓       ↓             ↓
     30       68            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---68---              ----34
      ↓       ↓             ↓
     30       60            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---68---              ----43
      ↓       ↓            ↓
     30       60           34
     ------------------------------------------
 */
/// 批量建堆 -- 自上而下的上滤
-(void)heapify1 {
    for (int i = 1 ; i < size; i++) {
        [self siftUpWithIndex:i];
    }
}


/*
 2.自下而上的下滤执行流程图如下：除了叶子节点，其他节点都需要做下滤操作
        ------------30---------
        ↓                      ↓
     ---34---              ----73
     ↓       ↓             ↓
    60       68            43
    ------------------------------------------
         ------------30---------
         ↓                      ↓
      ---68---              ----73
      ↓       ↓             ↓
     60       34            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---68---              ----30
      ↓       ↓             ↓
     60       34            43
     ------------------------------------------
         ------------73---------
         ↓                      ↓
      ---68---              ----43
      ↓       ↓             ↓
     60       34            30
     ------------------------------------------
 */
/// 批量建堆 -- 自下而上的下滤
-(void)heapify2 {
    //(size/2)-1 是第一个非叶子节点的索引
    for (int i = (size >> 1) - 1; i >= 0; i--) {
        [self siftDownWithIndex:i];
    }
}


/// 初始化二叉堆时对传进来的数组序列进行批量建堆
-(instancetype)initWithElements:(NSArray *)baseArr {
    self = [super init];
    if (self) {
        //初始化数组
        arr = [NSMutableArray array];
        //将外面传进来的数据拷贝到我们自己的数组中
        for (int i = 0; i < baseArr.count; i++) {
            arr[i] = baseArr[i];
        }
        size = (int)arr.count;
        //批量建堆
        [self heapify1];
    }
    return self;
}

-(void)test {
    WGBinaryHeap *heap = [[WGBinaryHeap alloc]initWithElements:@[@123,@230,@1,@34,@45,@6,@80,@90,@900,@34,@567]];
    //获取堆顶元素
    NSLog(@"heap top element:%d",heap.get);
    //删除堆顶元素
    NSLog(@"delete heap top element: %d",[heap remove]);
    
    //替换堆顶元素
    NSLog(@"replace heap top element: %d",[heap replace:8]);
    
    //获取堆顶元素
    NSLog(@"heap top element:%d",heap.get);
    
    [heap addElement:1000];
}
@end
