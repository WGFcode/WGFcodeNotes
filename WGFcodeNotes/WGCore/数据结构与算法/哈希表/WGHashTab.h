//
//  WGHashTab.h
//  ZJKBank
//
//  Created by 白菜 on 2021/12/16.
//  Copyright © 2021 buybal. All rights reserved.
//
/* 哈希表: 哈希表也叫散列表；哈希函数也叫散列函数；哈希表是【空间换时间】的典型应用；
 哈希表内部的数组元素也叫做桶(Bucket),整个数组叫做Buckets或者Bucket Array
    key       哈希函数hash_(key)      table
                                  索引  数据
    jack      ------------         00   777
                         |         01
    rose                 |         02
                         |______   03   888
                                   04
 key通过哈希函数获取哈希值，然后哈希值再与数组的长度进行运算获取到一个索引，然后找到数组中对应的索引并将值保存到数组中
 添加、搜索、删除的流程都是类似的
 1.利用哈希函数生成key对应的下标index(O(1))
 2.根据index定位数组元素(O(1))
 二、哈希冲突
 哈希冲突也叫哈希碰撞：2个不同的key,经过哈希函数计算出相同的结果，key1 != key2,hash(key1) = hash(key2)
 解决哈希冲突的方法：
    1. 开放定址法: 按照一定规则向其他地址探测，直到遇到空桶
    2. 再哈希法: 设计多个哈希函数
    3. 链地址法: 比如通过单向链表将同一index的元素串起来
 注意：java中哈希冲突方案就是:采用【单向链表+红黑树】方式解决哈希冲突
    添加元素时，可能由单向链表转为红黑树来存储元素（比如当哈希表容量 >= 64且单向链表的元素个数大于8时）
    当红黑树元素个数减少到一定程度时，又会转为单向链表
为什么解决哈希冲突采用单向链表？
    每次都是从头结点开始遍历
    单向链表比双向链表少一个指针，可以节省内存空间
三、哈希函数
 哈希表中哈希函数的实现步骤如下：
    1.先生成key的哈希值(必须是整数)
    2.再让key的哈希值跟数组的大小进行相关运算，生成一个索引值
 -(int)hash:(id)key {
     return hash_code(key) % table.length;
 }
 为了提高运算效率，可以使用 & 运算取代 %运算，前提条件是将数组的长度设计为 2的幂(2^n)
 -(int)hash:(id)key {
     return hash_code(key) & (table.length - 1);
 }
 这里2的幂-1将变成 111111l样式，通过 & 运算，不管值多大，结果都不可能大于table.length的值
 良好的哈希函数凭据：让哈希值更加均匀分布 ---> 减少哈希冲突的次数 ---> 提升哈希表的性能
 
 四、生成key的哈希值
 哈希表中的 key 常见类型：整数、浮点数、字符串、自定义对象
 不同种类的 key，哈希值的生成方式不一样，但目标都是一样的
    尽量让每个 key 的哈希值
    尽量让 key 的所有信息都参与运算
 1.key-整数: 整数值当哈希值(比如10的哈希值就是10)
 2.key-浮点数: 将存储的二进制格式转为整数值
         ios中int占4个字节(32bit)、long类型在32位机器上占4子节、在64位机器上占8个字节、double占8个字节
 3.key-Long:(这里我们用64位机器) value ^ (value >>> 32) 用高32bit和低32bit混合计算出32bit的哈希值【充分利用所有信息参与运算】
 4.key-Double:先将double转为long,然后再value ^ (value >>> 32)【充分利用所有信息参与运算】
 5.key-字符串: 字符串是由若干个字符组成，如jack,(((j * n) + a) * n + c) * n + k,java中指定【n = 31】，因为31是一个奇素数，java可以优化成【(i<<5)-i】
 其他开发语言可能不会对31进行优化，所以我们写成【(i<<5)-i】即可,但是在iOS中验证确实两者的结果是相同的，所以猜测iOS可能也做了优化
     int i = 10;
     int result = 10 * 31;
     int result1 = (i << 5) - i;
     NSLog(@"优化前: %d 优化后: %d ",result, result1);

 6.key-自定义对象:
 iOS中的NSDictionary字典就是使用哈希表来实现key和value之间的映射和存储的,一般在iOS中key通常都是字符串类型，并且键值key必须实现NSCopying协议，
 原因就是因为在NSDictionary内部，会对 aKey 对象 copy 一份新的。而  anObject 对象在其内部是作为强引用（retain或strong)。
    setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;
 知道了作为 key 值必须遵循 NSCopying 协议，说明我们换可以用其他类型对象来作为NSDictionary的key值，不过自定义对象类型的key值必须继承于NSObject并且要重载以下两个方法
    -(NSUInteger)hash;     用来计算key的hash值找到对应的位置，然后通过对比哈希表中已经存在key的hash值来决定是添加 or 覆盖
    -(BOOL)isEqual:(id)object;  如果两个key对象的hash值相同，但是是不是同一个对象key，就需要通过这个方法来判断了
    isEqual方法用来判断2个key是否是同一个key
    hash方法必须保证 isEqual 为 YES的2个key的哈希值是一样的
    hash值相同，不一定是同一个key，需要通过isEqual方法来判断
所以一般在哈希表(或者NSDictionary字典)中如果用对象类型作为key，尽量重写hash方法、isEqual方法
 
 五、数字【31】的特殊性
 1. 31不仅仅是符合 (2^n) - 1,它是一个奇素数(是奇数、是素数、也是质数)
 2. 素数和其他数相乘的结果比其他方法更容易产生唯一性，减少哈希冲突
 3. 最终选择31是经过观察分布结果后的选择
 

 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGHashTab : NSObject


@end

NS_ASSUME_NONNULL_END
