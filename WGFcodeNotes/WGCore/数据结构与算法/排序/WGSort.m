//
//  WGSort.m
//  appName
//
//  Created by 白菜 on 2021/12/1.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGSort.h"

@implementation WGSort

/********************************冒泡排序*******************************
 冒泡排序
第一步: 从头开始比较每一对相邻的元素，如果第1个比第二个大，就交换它们的位置，执行完一轮后，最末尾那个元素就是最大的元素
第二步: 忽略第一步中找到的最大元素，重复执行第一步，直到全部元素有序
*/
/// 冒泡排序1 -正常
-(void)sort_maopao1 {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@34,@45,@6,@8]];
    //1.外循环控制需要遍历的长度
    for (int end = (int)arr.count - 1 ; end > 0; end--) {
        //2.内循环找到最大值
        for (int begin = 1 ; begin <= end; begin++) {
            if ([arr[begin-1] intValue] > [arr[begin] intValue]) { //左边比右边大则交换位置
                id temp = arr[begin-1];
                arr[begin-1] = arr[begin];
                arr[begin] = temp;
            }
        }
    }
    //打印元素
    [self printElement:arr];
}

/// 冒泡排序2 - 优化1: 如果是已经排好序的数据，那么一轮循环后，应该终止排序
-(void)sort_maopao2 {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@3,@45,@60,@89]];
    for (int end = (int)arr.count - 1 ; end > 0; end--) {
        //默认已经排好序了，经过一轮后，判断若为YES，则直接结束，若数据是没有排序，则会进入内循环
        BOOL hasSort = YES;
        for (int begin = 1 ; begin <= end; begin++) {
            if ([arr[begin-1] intValue] > [arr[begin] intValue]) { //左边比右边大则交换位置
                id temp = arr[begin-1];
                arr[begin-1] = arr[begin];
                arr[begin] = temp;
                hasSort = NO;
            }
        }
        //如果经过一轮排序后，没有发生任何元素交换位置，则认为是已经排序好了，直接结束循环
        if (hasSort) {
            break;
        }
    }
    [self printElement:arr];
}

/// 冒泡排序3 - 优化2: 如果数据序列尾部已经局部有序，可以记录最后一次交换的位置，来减少比较次数
-(void)sort_maopao3 {                                    //0  1   2   3   4   5   6    7
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@34,@45,@6,@80,@90,@123,@230]];
    for (int end = (int)arr.count - 1 ; end > 0; end--) {
        //sortIndex的初始值1在数组完全有序时有效
        int sortIndex = 1;
        for (int begin = 1 ; begin <= end; begin++) {
            if ([arr[begin-1] intValue] > [arr[begin] intValue]) { //左边比右边大则交换位置
                id temp = arr[begin-1];
                arr[begin-1] = arr[begin];
                arr[begin] = temp;
                //一旦发生位置交换就保存下下标位置
                sortIndex = begin;
            }
        }
        //下次循环从开头位置到sortIndex位置进行循环就行，sortIndex位置后的数据已经排好序了
        end = sortIndex;
    }
    [self printElement:arr];
}
/********************************选择排序*******************************
 选择排序
第一步: 从序列中找出最大的那个元素，然后与最末尾的元素交换位置，执行完第一轮后，最末尾的元素就是最大的元素
第二步: 忽略第一步中找到的最大元素，重复执行第一步
选择排序的交换次数要远远少于冒泡排序，平均性能优于冒泡排序
最好、最坏、平均时间复杂度O(n^2),空间复杂度O(1),属于稳定排序算法
选择排序优化方案: 使用堆来找最大值
*/
/// 选择排序
-(void)sort_select {
    //NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@34,@45,@6,@80,@90,@123,@230]];
//    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@4,@5,@6,@1,@2,@3]];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@2,@3,@2,@5,@6]];
    for (int end = (int)arr.count - 1; end > 0; end--) {
        int maxIndex = 0;  //初始值代表最大值为arr[0]元素
        for (int begin = 1; begin <= end; begin++) {
            if ([arr[maxIndex] intValue] < [arr[begin] intValue]) { //谁大就保存谁的下标
                maxIndex = begin;
            }
        }
        //找到最大值的下标，然后开始和最后一位进行交换位置
        id temp = arr[maxIndex];
        arr[maxIndex] = arr[end];
        arr[end] = temp;
    }
    [self printElement:arr];
}
///
/********************************插入排序*******************************
 插入排序（类似于扑克牌的排序）
第一步: 在执行过程中，插入排序会将序列分为两部分: 头部是已经排好序的，尾部是待排序的
第二步: 从头开始扫描每一个元素，每当扫描到一个元素，就将它插入到头部合适的位置，使得头部数据依然保持有序
逆序对:数组 [2,3,8,6,1]的逆袭对有5对[2,1],[3,1],[8,6],[8,1],[6,1]
插入排序的时间复杂度与序列的逆序队数量成正比关系，逆序对的数量越多，插入排序的时间复杂度越高
当逆序对的数量极少时，插入排序的效率特别高，速度甚至比O(logn)级别的快速排序还要快
最坏、平均时间复杂度O(n^2)，最好的时间复杂度是O(n),空间复杂度O(1),属于稳定排序算法
*/
/// 插入排序-正常
-(void)sort_insert1 {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@34,@45,@6,@80,@90,@123,@230]];
    for (int begin = 1; begin < (int)arr.count; begin++) {
        //假如0号位置是已经排好序的，然后开始添加第二个元素，先和第一个元素进行对比，如果大第一个元素就交换位置，然后再取出第三个元素
        int cur = begin;
        while (cur > 0 && [arr[cur-1] intValue] > [arr[cur] intValue]) {
            id temp = arr[cur];
            arr[cur] = arr[cur-1];
            arr[cur-1] = temp;
            cur--;
        }
    }
    [self printElement:arr];
}

/*优化思路：将交换变成移动
 1. 先将待插入的元素备份
 2. 头部有序数据中比待插入元素大的，都朝尾部方法挪动1个位置
 3. 将待插入元素放到最终合适的位置
 */
/// 插入排序-优化1
-(void)sort_insert2 {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@34,@45,@6,@80,@90,@123,@230]];
    for (int begin = 1; begin < (int)arr.count; begin++) {
        int cur = begin;
        //先备份待插入的元素
        id waitInsert = arr[cur];
        // 1 34 45
        //如果待插入的元素比前面元素小，那么就让前面元素向后移动一位
        while (cur > 0 && [arr[cur-1] intValue] > [waitInsert intValue]) {
            arr[cur] = arr[cur-1];
            cur--;
        }
        arr[cur] = waitInsert;
    }
}
///插入排序的优化方案二中需要用到二分搜索，先了解下二分搜索思路
/* 二分搜索
 如何确定一个元素在数组中的位置？
 如果是无序数组，从第0位置开始遍历去查找，时间复杂度是O(n)
 如果是有序数组，可以使用二分搜索，最坏的时间复杂度是O(logn)
 二分搜索思路：假设在[begin,end)范围内搜索某个元素V，mid = (begin + end) / 2,mid位置的元素值是m
    如果v < m,去[begin, mid)范围内二分搜索
    如果v > m,去[mid + 1, end)范围内二分搜索
    如果v = m,直接返回mid
 */
/// 查找元素V在有序数组array中的位置 返回位置下标
-(int)binarySearchWithElement:(int)element inArr:(NSMutableArray *)arr {
    if (arr == nil || arr.count == 0) { //没有找到
        return -1;
    }
    int begin = 0;
    int end = (int)arr.count;
    while (begin < end) {
        int mid = (begin + end) >> 1;
        if (element < [arr[mid] intValue]) { //向左边找
            end = mid;
        }else if (element > [arr[mid] intValue]) { //向右边找
            begin = mid + 1;
        }else {
            return mid;
        }
    }
    return -1; //没有找到
}


/// 插入排序-优化2-二分搜索优化
-(void)sort_insert3 {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@123,@230,@1,@34,@45,@6,@80,@90]];
    for (int begin = 1 ; begin < arr.count; begin++) {
        id V = arr[begin];
        //从[0,begin)找到待插入位置，然后将[insertIndex，begin)位置的元素向后移动；其实这里的arr[begin]就是等待插入的元素
        int insertIndex = [self searchWithIndex:begin withArr:arr];
        //从[begin,insertIndex)范围内元素统一向后移动
        for (int i = begin; i > insertIndex; i--) {
            arr[i] = arr[i-1];
        }
        arr[insertIndex] = V;
    }
    [self printElement:arr];
}
/*利用二分搜索找到index位置的待插入位置，已经排好序数组的区间范围是[0,index)，即找到[0,index)的插入位置
 0   1   2   3   4   5    6     7
 2   4   8   8   8   12   14
在元素V的插入过程中，可以先二分搜索出合适的位置，然后再将元素V插入
要求二分搜索返回的插入位置：第一个大于V的元素位置 ，如果V=5，返回下标2；如果V=15，返回7；如果V=1，返回0；如果V=8，返回5
 */
-(int)searchWithIndex:(int)index withArr:(NSMutableArray *)arr {
    //这里的index其实就是即将要插入的元素下标（待排序的元素下标）
    int begin = 0;
    int end = index;
    while (begin < end) {
        int mid = (begin + end) >> 1;
        if ([arr[index] intValue] < [arr[mid] intValue]) { //向左边找
            end = mid;
        }else { //相等或者大于都向右边找
            begin = mid + 1;
        }
    }
    return begin;
}


/********************************快速排序*******************************
 快速排序（类似于扑克牌的排序）
第一步: 从序列中选择一个轴点(pivot)元素
    假设每次选择0位置作为轴点元素
第二步: 利用轴点(pivot)将序列分割成2个子序列
    将小于pivot的元素放在pivot左边(前面)
    将大于pivot的元素放在pivot右边(后面)
    等于pivot的元素放在那边都可以
第三步:对序列进行【第一步】【第二步】操作，直到不能再分割为止(子序列中只剩下一个元素)
快速排序的本质就是：逐渐将每个元素都转为轴点元素
最好、平均时间复杂度O(nlogn)，最坏的时间复杂度是O(n^2),由于递归调用的缘故空间复杂度O(logn),属于不稳定排序算法
*/
/// 快速排序
-(void)sort_quick {
    //NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@123,@230,@1,@34,@45,@6,@80,@90]];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@1,@2,@3,@2,@5,@6]];
    [self sortQuickWithBeginIndex:0 withEndIndex:(int)arr.count withArr:arr];
    [self printElement:arr];
}
// 对[begin, end)范围的元素进行快速排序 0 1 2
-(void)sortQuickWithBeginIndex:(int)begin withEndIndex:(int)end withArr:arr {
    if (end - begin < 2) { //(end-begin=元素的个树)
        return;
    }
    //确定轴点位置
    int mid = [self pivotIndexWithBegin:begin withEnd:end withArr:arr];
    //对子序列进行快速排序
    [self sortQuickWithBeginIndex:begin withEndIndex:mid withArr:arr];
    [self sortQuickWithBeginIndex:mid+1 withEndIndex:end withArr:arr];
}
// 构造出[begin, end)范围的轴点元素 return轴点元素的位置下标
-(int)pivotIndexWithBegin:(int)begin withEnd:(int)end withArr:(NSMutableArray *)arr {

    //备份begin元素的元素(首先就是让begin位置作为轴点)
    id pivotElement = arr[begin];
    //end指向最后一个元素的下标
    end--;
    while (begin < end) {
        while (begin < end) {
            //从右向左
            //右边元素 > 轴点元素, 将元素放在轴点的右边，刚好就在右边，所以不用动，继续下一个元素对比
            if ([pivotElement intValue] < [arr[end] intValue]) { //
                end--;
            }else { // 右边元素 <= 轴点元素,让右边元素占居当前轴点位置的元素,之前轴点位置元素是被覆盖了，
                //但是我们已经备份过了pivotElement，所以不用担心，此时end位置应该已经空置出来了 ，然后让begin++,
                arr[begin] = arr[end];
                begin++;
                break;
            }
        }
        while (begin < end) {
            //从左向右
            if ([pivotElement intValue] > [arr[begin] intValue]) { //左边元素 < 轴点元素，元素位置不懂，继续下一个元素
                begin++;
            }else { //左边元素 >= 轴点元素,
                arr[end] = arr[begin];
                end--;
                break;
            }
        }
    }
    //将轴点元素放入最终的位置
    arr[begin] = pivotElement;
    //返回轴点元素的位置
    return begin;
}


/********************************希尔排序*******************************
 希尔排序把序列看成是一个矩阵，分成m列，逐列进行排序，因此希尔排序也被称为递减增量排序
    m从某个整数逐渐减为1，当m = 1时，整个序列将完全有序
    矩阵的列数取决于步长序列，如果步长序列为{1,4,6,8},就代表依次分成8列、6列、4列、1列进行排序，不同的步长序列执行效率也不一样
    希尔本人给出的步长序列是n/(2^k),当n = 16时，步长序列为{1,2,4,8},依次分成8列、4列、2列、1列进行排序，
    排序是列与列进行比较排序的
 从8列到1列的划分排序过程中，逆序队的数量在逐渐减少，因此希尔排序底层一般使用插入排序对每一列进行排序
 所以很大资料认为希尔排序是插入排序的改进版
 假设有11个元素，步长序列为{1,2,5}
 11 10 9 8 7 6 5 4 3 2 1
 
 11 10 9 8 7        1  5  4  3  2
 6   5 4 3 2  ====> 6  10 9  8  7
 1                  11
 假设元素在第col列、第row行，步长(总列数)是step
 那么这个元素在数组中的索引是 col + row * step
 例如9在排序前是第2列、第0行，那么它排序前的索引是 2 + 0 *5 = 2
 例如4在排序前是第2列、第1行，那么它排序前的索引是 2 + 1 *5 = 7
 */
/// 希尔排序 待定
-(void)sort_shell {
    
}

/// 分成step列进行排序
-(void)sortWithStep:(int)step withArr:(NSMutableArray *)arr {
    //col: 第col列
    for (int col = 0; col < step; col++) { //对第col列进行排序
        // col col+step col+2*step col+3*step
        for (int begin = col + step; begin < arr.count; begin+=step) {
            int cur = begin;
            while (cur > col && [arr[cur] intValue] < [arr[cur-step] intValue]) {
                //交换位置
                id temp = arr[cur];
                arr[cur] = arr[cur-step];
                arr[cur-step] = temp;
                cur -= step;
            }
        }
    }
}


/********************************计数排序*******************************
 前面的冒泡、选择、插入、归并、快速、希尔、堆排序都是基于比较的排序，平均复杂度最低是O(nlogn)
 计数排序、桶排序、基数排序都不是基于比较的排序，他们是典型的空间换时间，在某些时候，平均时间复杂度可以比O(nlogn)更低
 计数排序适合对一定范围内的整数进行排序
 计数排序的核心：统计每个整数在序列中出现的次数，进而推导出每个整数在有序序列中的索引
 待排序序列 7  3  5  8  6  7  4  5
 索引     0  1  2  3  4  5  6  7  8
 出现次数           1  1  2  1  1  1
 排序后序列 3  4  5  5  6  7  8
 该版本排序缺点：
 无法对负数进行排序；
 及其浪费内存空间，因为要根据待排序的最大值来分配多少个下标的内存(例如最大是8，就要分配存放8个元素的下标)；
 是个不稳定的排序
 */
/// 计数排序
-(void)sort_count {
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@3,@0,@1,@6,@9,@4,@8,@1]];
    //找出最大的值
    id max = arr[0];
    for (int i = 1; i < arr.count; i++) {
        if ([arr[i] intValue] > [max intValue]) {
            max = arr[i];
        }
    }
    //开辟内存空间，存储每个整数出现的次数
    NSMutableArray *countArr = [NSMutableArray arrayWithCapacity:[max intValue] + 1];
    //统计每个整数出现的次数,出现的次数保存在countArr中
    for (int i = 0; i < arr.count; i++) {
        int elementValue = [arr[i] intValue];
        countArr[elementValue] = @1;
    }
    //根据整数出现的次数，进行排序
    int index = 0;
    for (int i = 0; countArr.count; i++) {
        while ([countArr[i] intValue] > 0) {
            arr[index] = [NSNumber numberWithInt:i];
            index++;
        }
    }
}













/// 私有方法 打印元素内容
-(void)printElement:(NSArray *)arr {
    NSMutableString *elementStr = [NSMutableString stringWithString:@"元素:"];
    for (id i in arr) {
        [elementStr appendString:[NSString stringWithFormat:@"%d_",[i intValue]]];
    }
    NSLog(@"%@",elementStr);
}
@end
