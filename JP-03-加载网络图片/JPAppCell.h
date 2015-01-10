//
//  JPAppCell.h
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JPAppInfo;
@interface JPAppCell : UITableViewCell

/**
 *  接收传递来的模型
 */
@property (nonatomic, strong) JPAppInfo *app;

/**
 *  快速创建cell
 */
+ (instancetype)appCellWithTableView:(UITableView *)tableView;
@end
