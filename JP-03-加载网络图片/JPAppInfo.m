//
//  JPAppInfo.m
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import "JPAppInfo.h"

@implementation JPAppInfo
+ (instancetype)appInfoWithDict:(NSDictionary *)dict
{
    return [[self alloc]initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        // kvc - 变量名和字典的key值一模一样是时用
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

@end
