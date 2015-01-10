//
//  JPAppInfo.h
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPAppInfo : NSObject
/**
 *  图片地址
 */
@property (nonatomic, copy) NSString *icon;
/**
 *  下载量
 */
@property (nonatomic, copy) NSString *download;
/**
 *  应用名字
 */
@property (nonatomic, copy) NSString *name;


/**
 *  通过字典创建模型
 */
- (instancetype)initWithDict:(NSDictionary *)dict;

/**
 *  快速创建模型
 */
+ (instancetype)appInfoWithDict:(NSDictionary *)dict;

@end
