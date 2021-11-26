//
//  WGCustomArray.m
//  ZJKBank
//
//  Created by 白菜 on 2021/11/9.
//  Copyright © 2021 buybal. All rights reserved.
//

#import "WGDynamicArray.h"

//全局常量 作用域是这个文件，
///默认开辟的内存空间，可以存放10个元素
static int DEFAULT_CAPACITY = 10;
/// 找不到元素
static int ELEMENT_NOT_FOUND = -1;

@interface WGDynamicArray()
{
    int _size;                      //数组中元素个数
    int _length;                    //数组的容量
    NSMutableArray *_elements;      //这里只能用可变数组，如果用不可变数组，无法对其进行元素进行更改，
}
@end

@implementation WGDynamicArray

/*
 1.由于OC中没有类似java中可以指定数组容量的方法，所以这里我们用[NSNull null]来装填
 2.为什么不用nil，因为集合对象(NSArray/NSSet/NSDictionary)无法包含nil作为其具体值,相应地，nil值用一个特定的对象NSNull来表示
 3.NSNull提供了一个单一实例用于表示对象属性中的的nil值
 nil:用来给对象赋值(Objective-C中的任何对象都属于id类型),一般赋值给空对象；当向nil发送消息时，返回NO，不会有异常
 NULL: 用来给任何指针赋值；NULL和nil不能互换；一般赋值给nil之外的其他空值。如SEL等
 NSNull：NSNull则用于集合操作，NSNull只有一个方法：+(NSNull *)null;
 [NSNull null]用来在NSArray和NSDictionary中加入非nil（表示列表结束）的空值.
 [NSNull null]是一个对象，他用在不能使用nil的场合。向NSNull的对象发送消息时会收到异常
 [NSArray alloc]initWithObjects:(nonnull id), ..., nil 中的nil表示列表元素的结束
 */
///创建制定容量的空数组  该方法不能用，因为NSArray 替换成了NSMutableArray
//-(NSArray *)createSpecificCapacity:(int)capacity {
//    NSMutableArray *arr = [NSMutableArray array];
//    for (int i = 0; i < capacity; i++) {
//        NSNull *null = [NSNull null];
//        [arr addObject:null];
//    }
//    return arr;
//}

//MARK: 初始化动态数组 默认的容量可以存放10个元素
-(instancetype)init {
    self = [super init];
    if (self) {
        _elements = [NSMutableArray arrayWithCapacity:DEFAULT_CAPACITY];
        _length = DEFAULT_CAPACITY;
    }
    return self;
}


//MARK: 初始化动态数组 指定容量 若制定的容量小于默认容量，则用默认的容量
-(instancetype)initWithCapaticy:(int)capaticy {
    self = [super init];
    if (self) {
        int capa = capaticy < DEFAULT_CAPACITY ? DEFAULT_CAPACITY : capaticy;
        _elements = [NSMutableArray arrayWithCapacity:capa];
        _length = capa;
    }
    return self;
}


//MARK: 获取数组元素的个数
-(int)size {
    return _size;
}


//MARK: 判断数组是否为空
-(BOOL)isEmpty {
    return _size == 0;
}


//MARK: 判断是否包含某个元素
-(BOOL)contains:(int)element {
    //判断元素下标是否可以找到
    return [self indexOf:element] != ELEMENT_NOT_FOUND;
}


//MARK: 添加元素到最面
-(void)add:(int)element {
    //_elements[_size] = @(element);
    //_size++;
    //上面代码也可以用这个代替 [self add:_size withElement:element];，但是为了确保扩容处理，这里调用已知方式
    [self add:_size withElement:element];
}


//MARK: 向指定位置添加元素
-(void)add:(int)index withElement:(int)element {
    if (index < 0 || index > _size) { //index不能小于0 不能大于最大元素个数的小标,但这里可以等于size,因为可以添加到数组最后面
        NSLog(@"Not suitable index不合适; index: %d, size: %d",index,_size);
        return;
    }
    //添加元素前 先确保容量够用，不够用需要扩容处理
    [self ensureCapacity:_size + 1];
    //12   32  43  54  54
    // 0   1   2   3   4
    //【index～size-1】 的元素向后移动 index = 2 size = 5
    for (int i = _size - 1; i >= index; i--) {
        _elements[i+1] = _elements[i];
    }
    _elements[index] = @(element);
    _size++;
}


//MARK: 返回index位置的元素
-(int)get:(int)index {
    if (index < 0 || index >= _size) { //index不能小于0 不能大于等于最大元素个数的小标
        NSLog(@"Not suitable index不合适; index: %d, size: %d",index,_size);
        return -1;
    }
    return [_elements[index] intValue];
}


//MARK: 设置index位置的元素,并返回被覆盖的值
-(int)set:(int)index withElement:(int)element {
    if (index < 0 || index >= _size) { //index不能小于0 不能大于等于最大元素个数的小标
        NSLog(@"Not suitable index不合适; index: %d, size: %d",index,_size);
        return -1;
    }
    int old = [_elements[index] intValue];
    _elements[index] = @(element);
    return old;
}


//MARK: 删除index位置的元素,并返回删除的元素
-(int)remove:(int)index {
    if (index < 0 || index >= _size) { //index不能小于0 不能大于等于最大元素个数的小标
        NSLog(@"Not suitable index不合适; index: %d, size: %d",index,_size);
        return -1;
    }
    int old = [_elements[index] intValue];
    //12   32  43  54  54
    // 0   1   2   3   4
    //删除下标index是2的元素   [index+1~size-1]元素向前移动
    for (int i = index + 1; i <= _size - 1; i++) {
        _elements[i - 1] = _elements[i];
    }
    _size--;
    return old;
}


//MARK:  删除指定元素
-(void)removeElement:(int)element {
    //先找到元素的下标，然后进行删除
    int index = [self indexOf:element];
    [self remove:index];
}


//MARK: 查看元素的位置
-(int)indexOf:(int)element {
    for (int i = 0; i < _size; i++) {
        if ([_elements[i] intValue] == element) {
            return i;
        }
    }
    return ELEMENT_NOT_FOUND;
}


//MARK: 清除所有的元素
-(void)clear {
    _size = 0;
    //如果数组中存放是对象类型，则还需要设置_elements = nil; 而不需要遍历数组 挨个对象置为nil
//    for (int i = 0; i < _size; i++) {
//        _elements[i] = nil;
//    }
    //_elements = nil;
}


/// 打印数组内容
-(void)printContent {
    NSMutableString *str = [[NSMutableString alloc]initWithString:@"["];
    for (int i = 0; i < self.size; i++) {
        int element = [self get:i];
        if (i == 0) {
            [str appendString:[NSString stringWithFormat:@"%d",element]];
        }else {
            [str appendString:[NSString stringWithFormat:@", %d",element]];
        }
    }
    [str appendString:@"]"];
    NSLog(@"元素个数:%d->元素内容:%@",_size,str);
}


//MARK: 私有方法 数组超过默认开辟的空间时，就需要扩容处理
-(void)ensureCapacity:(int)capacity {
    //现有容量就是_length
    int oldCapacity = _length;
    if (oldCapacity >= capacity) { //现有容量比需要的容量大，就不需要扩容
        return;
    }
    //需要扩容  0000 0100(4) >> 1  0000 0010(2)
    // 新容量为旧容量的1.5倍
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    //创建新的容量数组
    NSMutableArray *newArr = [NSMutableArray arrayWithCapacity:newCapacity];
    //对容量属性进行重新赋值
    _length = newCapacity;
    //将之前的数据重新装填到新扩容的数组中
    for (int i = 0; i < _size; i++) {
        newArr[i] = _elements[i];
    }
    //将现用的数组指针指向新的数组
    _elements = newArr;
    NSLog(@"容量:%d 扩容后容量:%d",oldCapacity,newCapacity);
}

@end
