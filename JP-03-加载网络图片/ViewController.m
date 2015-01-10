//
//  ViewController.m
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import "ViewController.h"
#import "JPAppInfo.h"

@interface ViewController ()
/**
 *  模型数组
 */
@property (nonatomic, strong) NSArray *appInfos;

/**
 *  全局队列
 */
@property (nonatomic, strong) NSOperationQueue *opQueue;
@end

@implementation ViewController

/**
 *  懒加载数组
 */
- (NSArray *)appInfos {
    if (_appInfos== nil) {
        // 读取plist
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"apps.plist" withExtension:nil];
        
        NSArray *dictA = [NSArray arrayWithContentsOfURL:url];
        NSMutableArray *arrayM= [NSMutableArray arrayWithCapacity:dictA.count];
        // 遍历数组中的每个字典，转模型
        // 用代码块比forin 效率更高
        [dictA enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            // 字典转模型
            JPAppInfo *appInfo = [JPAppInfo appInfoWithDict:obj];
            // 添加模型到数组
            [arrayM addObject:appInfo];
        }];
        _appInfos = [arrayM copy]; // 用copy 能够实现可变转不可变，而且不会相影响

    }
    return _appInfos;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
/**
 *  懒加载全局队列
 */
- (NSOperationQueue *)opQueue {
    if (_opQueue== nil) {
        _opQueue = [[NSOperationQueue alloc]init];
    }
    return _opQueue;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 数据源方法
/**
 *  加载cell
 
 设置cell的imageView的图片 
 第一种 -- 同步加载 在主线程中直接加载
 问题： 
    -1 如果网络线程较慢，会出现卡顿，不会执行
    -2 每次刷新一行都会在次下载图片  
 所以 ： 异步下载图片 
 第二种 -- 异步加载图片，在后台加载
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 创建cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"appCell"];
    
    JPAppInfo *app = self.appInfos[indexPath.row];
    
    cell.textLabel.text = app.name;
    
    cell.detailTextLabel.text = app.download;
    /**
     *
      第二种 -- 异步加载图片，在后台加载
     问题：页面出现时，没有imageView显示 - 只有点击这一行的时候才会有图片 
     原因分析：因为是异步执行 是在另一个线程中，在主线程中已经返回了cell而在另一个线程中，图片还没有下载完成，那么，当图片下载完成的时候，显示出的cell中此时imageView的大小为空，当点击cell时，有应为这个cell是系统的cell所以会调用 layoutSubviews方法 重新布局cell的子控件的位子 所以在 用一个占位图 来先分配到一个位子
     */
    // 占位图
    cell.imageView.image = [UIImage imageNamed:@"user_default"];
    
    // 添加 操作到循环
    [self.opQueue addOperationWithBlock:^{
        
        // 耗时操作
        // 加载网络图片
        NSURL *url = [NSURL URLWithString:app.icon];

        NSData *data = [NSData dataWithContentsOfURL:url];

        UIImage *image = [UIImage imageWithData:data];
//        [NSThread sleepForTimeInterval:0.2f];
        // 通知主线程 设置图片
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            
            cell.imageView.image = image;
        }];
        
    }];
 
    return cell;
    
}
@end
