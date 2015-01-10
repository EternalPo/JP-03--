//
//  JPAppCell.m
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import "JPAppCell.h"

@implementation JPAppCell

+(instancetype)appCellWithTableView:(UITableView *)tableView {
    id cell = [tableView dequeueReusableCellWithIdentifier:@"appCell"];
    
    return cell;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 图片的位置
//    NSLog(@"%@", NSStringFromCGRect(self.imageView.frame));
    CGRect tempR = self.imageView.frame;
    tempR.origin.y = 5;
    tempR.size.width = 48;
    tempR.size.height = 48;
    self.imageView.frame = tempR;
    
    // 文字的位置
    
//    NSLog(@"%@", NSStringFromCGRect(self.textLabel.frame));
    
    CGRect tempLabel = self.textLabel.frame;
    tempLabel.origin = CGPointMake(79, 20);
    self.textLabel.frame = tempLabel;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
