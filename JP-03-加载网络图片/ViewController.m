//
//  ViewController.m
//  JP-03-加载网络图片
//
//  Created by soulPo on 15/1/10.
//  Copyright (c) 2015年 soulPo. All rights reserved.
//

#import "ViewController.h"
#import "JPAppInfo.h"
#import "JPAppCell.h"

@interface ViewController ()
/**
 *  模型数组
 */
@property (nonatomic, strong) NSArray *appInfos;

/**
 *  全局队列
 */
@property (nonatomic, strong) NSOperationQueue *opQueue;
/**
 *  操作缓存池
 */
@property (nonatomic, strong) NSMutableDictionary *operationCache;
/**
 *  图片缓冲池
 */
@property (nonatomic, strong) NSMutableDictionary *imageCache;
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
/**
 *  懒加载全局队列
 */
- (NSOperationQueue *)opQueue {
    if (_opQueue== nil) {
        _opQueue = [[NSOperationQueue alloc]init];
    }
    return _opQueue;
}

/**
 *  懒加载操作缓存池
 */
- (NSMutableDictionary *)operationCache {
    if (_operationCache== nil) {
        _operationCache = [NSMutableDictionary dictionary];
    }
    return _operationCache;
}
/**
 *  懒加载图片缓冲池
 */
- (NSMutableDictionary *)imageCache {
    if (_imageCache== nil) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // 内存警告 --  操作缓冲池 和 清空图片缓冲池
    [self.operationCache removeAllObjects];
    [self.imageCache removeAllObjects];
}

#pragma mark - 数据源方法


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 创建cell
    JPAppCell *cell = [JPAppCell appCellWithTableView:tableView];
    
    JPAppInfo *app = self.appInfos[indexPath.row];
    
    cell.textLabel.text = app.name;
    
    cell.detailTextLabel.text = app.download;
   
    
    if (self.imageCache[app.icon] != nil) {
        NSLog(@"没有下载图片");
        
        cell.imageView.image = self.imageCache[app.icon];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"user_default"];
        // 下载网络图片刷新设置表格
        [self downloadWithIndexPath:indexPath];
    }
    
    return cell;
    
}
#pragma mark - 代码重构
- (void)downloadWithIndexPath:(NSIndexPath *)indexPath{
    
    JPAppInfo *app = self.appInfos[indexPath.row];
    // 判断下载操作是不是存在
    if (self.operationCache[app.icon] != nil) {
        NSLog(@"正在玩命加载");
    } else {
        
        // 定义下载操作
        NSBlockOperation *download = [NSBlockOperation blockOperationWithBlock:^{
            // 耗时操作
            
            // 加载网络图片
            NSURL *url = [NSURL URLWithString:app.icon];
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            UIImage *image = [UIImage imageWithData:data];
            
            // 图片添加到图片缓冲池
            if (image != nil) {
                [self.imageCache setObject:image forKey:app.icon];
            }
            
                       // 清除下载操作
            [self.operationCache removeObjectForKey:app.icon];
        
            // 通知主线程 刷新表格
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                // 刷新之前先判断图片是不是为空
                if (image != nil) {
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
        }];
        // 添加操作到队列
        [self.opQueue addOperation:download];
        [self.operationCache setObject:download forKey:app.icon];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@",self.operationCache);
}
- (void)dealloc {
    NSLog(@"我去了");
}
@end
