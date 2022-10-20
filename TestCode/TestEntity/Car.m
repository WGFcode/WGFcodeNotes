//
//  Car.m
//  WGFcodeNotes
//
//  Created by wubaicai on 2021/3/21.
//  Copyright © 2021 WG. All rights reserved.
//

#import "Car.h"

@interface Car() <NSSecureCoding>

@end

@implementation Car


-(void)run {
    NSLog(@"----%s",__func__);
}

/*
//编码 类对象 -> Data
- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInt:self.age forKey:@"age"];
}

//解码 Data -> 类对象
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        self.age = [coder decodeIntForKey:@"age"];
        self.name = [coder decodeObjectForKey:@"name"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
*/

-(void)dealloc {
    NSLog(@"%s",__func__);
}

-(void)test {
    NSLog(@"%s",__func__);
}
@end
