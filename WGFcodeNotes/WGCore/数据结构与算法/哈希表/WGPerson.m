//
//  WGPerson.m
//  appName
//
//  Created by 白菜 on 2021/12/16.
//  Copyright © 2021 baicai. All rights reserved.
//

#import "WGPerson.h"

@implementation WGPerson

-(instancetype)initWithName:(NSString *)name withScore:(NSString *)score withAge:(int)age {
    self = [super init];
    if (self) {
        self.name = name;
        self.score = score;
        self.age = age;
    }
    return self;
}

/*重写hash方法原因: 计算对象的哈希值，哈希值决定了该对象在哈希表中存储的位置，
 每次添加元素到哈希表中，字典会先利用插入key的哈希值和字典中已经存在的所有key的哈希值进行比较
 最终通过比较，来决定是新增一个key，还是覆盖原有的key
 仅仅通过key.hash比较，有时候出现两个对象的hash值相同的情况，这时就需要调用isEqual方法来继续比较两个key对象是否相同
*/
//这里我们计算哈希值就参考java的计算方法 每个属性的哈希值都乘以31  ((属性1 * 31) + 属性2) * 31 + 属性3 保证所有属性的哈希值都参与运算
-(NSUInteger)hash {
    NSUInteger hashValue = _name != nil ? _name.hash : 0;
    hashValue = (hashValue * 31) + (_score != nil ? _score.hash : 0);
    hashValue = (hashValue * 31) + _age;
    return hashValue;
}

//重写isEqual方法原因: 两个key对象的hash值是相同的，但是还不能确定是不是同一个对象key，这时就需要用isEqual方法来判断
//用来判断两个key对象是否是同一个对象
// 用来比较两个对象是否相等，这个可以根据自己的业务需求，这里我们定为所有的对象属性值相等 两个对象才相等
-(BOOL)isEqual:(id)object {
    //比较内存地址(内存地址一样，说明是同一个对象)
    if (self == object) {
        return YES;
    }
    //如果 object 为nil 或者 object不属于WGPerson类型，则说明不是同一个对象
    if (object == nil || ![object isMemberOfClass:[self class]]) {
        return NO;
    }
    WGPerson *person = object;
    return ([person.name isEqualToString:self.name] && [person.score isEqualToString:self.score] && (person.age == self.age));
}


//自定义对象作为字典的key，则必须让自定义对象实现NSCopying协议中的copyWithZone方法
-(id)copyWithZone:(NSZone *)zone {
    WGPerson *p = [[[self class] allocWithZone:zone]init];
    p.name = self.name;
    p.score = self.score;
    p.age = self.age;
    return p;
}

-(void)test{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    WGPerson *p1 = [[WGPerson alloc]initWithName:@"zhangsan" withScore:@"100" withAge:12];
    WGPerson *p2 = [[WGPerson alloc]initWithName:@"zhangsan" withScore:@"100" withAge:12];
    [dic setObject:@"1" forKey:p1];
    [dic setObject:@"2" forKey:@"a"];
    [dic setObject:@"3" forKey:p2];
    NSLog(@"%ld",[dic count]);
    //如果没有重写hash、isEqual方法，则打印结果是3个元素
    //如果没有按照我们自己的规则重写hash、isEqual方法，则打印结果是2个元素
}
@end
