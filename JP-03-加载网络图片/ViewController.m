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
@property (nonatomic, strong) NSMutableDictionary *operationCaches;
/**
 *  图片缓冲池
 */
@property (nonatomic, strong) NSMutableDictionary *imageCaches;
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
- (NSMutableDictionary *)operationCaches {
    if (_operationCaches== nil) {
        _operationCaches = [NSMutableDictionary dictionary];
    }
    return _operationCaches;
}
/**
 *  懒加载图片缓冲池
 */
- (NSMutableDictionary *)imageCaches {
    if (_imageCaches== nil) {
        _imageCaches = [NSMutableDictionary dictionary];
    }
    return _imageCaches;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    JPAppCell *cell = [JPAppCell appCellWithTableView:tableView];
    
    JPAppInfo *app = self.appInfos[indexPath.row];
    
    cell.textLabel.text = app.name;
    
    cell.detailTextLabel.text = app.download;
    // 设置图片
    /**
     *
      第二种 -- 异步加载图片，在后台加载
     问题：页面出现时，没有imageView显示 - 只有点击这一行的时候才会有图片 
     原因分析：因为是异步执行 是在另一个线程中，在主线程中已经返回了cell而在另一个线程中，图片还没有下载完成，那么，当图片下载完成的时候，显示出的cell中此时imageView的大小为空，当点击cell时，有应为这个cell是系统的cell所以会调用 layoutSubviews方法 重新布局cell的子控件的位子 所以在 用一个占位图 来先分配到一个位子
     */
    // 占位图
    /**
     *  
     问题 ：使用占位图的问题，当用户交互的时候 图片的尺寸会变小，因为之前的占位图的尺寸过大，当用户交互的时候，会从新布局子控件的位置和大小，会根据当前图片的大小来设置
     
     解决思路 ：因为是系统用的cell，所以自定一个cell设置cell的位子即可 
     
     问题：如果图片下载速度不一样，用户又来回滚动cell，可能出现"图片错行"的问题
     分析：
     每一次都在直接给cell的图像设置数值，而cell是变化的，可以重用的，不固定的！
     
     谁是固定的？每一行的模型是固定的！
     
     MVC 设计模式，C(控制器) 让 V(视图) 显示 M(模型)
     
     目前的实际情况，C 让 (不固定的)V 显示不固定的 图像，忽略模型
     解决，让模型添加一个新的属性image 
     解决办法：使用 MVC 来在图像下载结束后，刷新指定的行
     
     *******
     新的问题：如果某张下载速度非常慢，用户快速来回滚动表格，会造成下载操作会重复创建！
     直接的结果：用户网络流量的浪费！
     思路：创建下载操作前，首先检查缓冲池中有没有下载操作
        -如果有，等待下载完成，什么都不做
        -如果没有，创建下载操作
     问题：缓存池的选取（容器： 数组、字典、set）
     数组：有序 --》indexPath
     字典： key --》URL
     set： 无序
     取舍思考： 
     如果下载的图片中有两张相同的图片，那么
     如果用数组 分布在不同的行，还会多次下载
     如果用字典， 不用多次下载，因为下载路径相同
     ********
     新的问题，当前下载的图片是保存在模型中，当发生内存警告时，程序需要释放内存
     目前图片下载完成之后，是保存在模型中的！如果应用程序运行过程中，出现内存警告！需要释放内存！
     图片如果保存在模型中，当需要释放内存的时候，不好释放！
     
     假设一共有2000条记录，记录2000张图片在内存！
     
     解决办法：建立图片缓冲池！如果内存警告，直接清空图片缓存即可！
     目标：图片不能保存在模型中！
     
     **********
     新问题： 当图片下载完成后，下载操作不需要在存在，即操作缓冲池中的内容没必要留着
     如果一直保留着的问题：
        -内存会无谓的消耗
        -如果有一个下载失败了，能够直接从操作缓冲池中移除，下次刷新重新下载
    解决办法：
        - 下载完成后直接移除缓冲池对应的下载操作
     
     *******
     *** 细节问题：如果网络图片下载失败，直接设置图片缓冲区字典，会崩溃！
     *** 下载失败，会不断刷新表格，需要判断图像是否真的获取
     ===> 再高级的做法，如果下载失败，可以建立一个黑名单的数组，
     存放所有下载失败的 URL，如果碰到黑名单中的URL，就不在下载！
     ****************
     *** 问题：会出现循环引用吗？
     借助 dealloc 辅助判断

     */
    
    if (self.imageCaches[app.icon] != nil) {
        NSLog(@"没有下载图片");
        
        cell.imageView.image = self.imageCaches[app.icon];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"user_default"];
        // 下载网络图片刷新设置表格
        [self downloadWithIndexPath:indexPath];
    }
    
    // 返回cell
    return cell;
    
}
#pragma mark - 代码重构
/**
 代码重构－抽代码
 
 目的：
 1. 相同的代码不要出现两次，可以保证今后的调整，只需要修改一个地方的代码
 2. 对于有些功能相对独立的代码，可以抽取出来作为一个自方法
 
 实际开发套路：
 在写代码的时候，分主方法和子方法
 - 主方法：主要写各个子方法的调用，通过子方法的名称的串联，就可以看出主方法的主要工作！便于阅读和维护
 - 子方法：专门处理一个独立的业务逻辑！可以重点测试！一旦测试完成，就可以不再看了！
 
 如果对整体业务逻辑进行调整的时候，子方法就会变成像积木一样可以搭建！
 
 步骤：
 
 1. 新建一个方法
 2. 把要抽取的代码复制到新方法中
 - 要根据实际情况，调整参数
 3. 把原有代码，先注释掉！给自己一个后悔的机会！如果代码结构调整的大，还可以做一个参照！
 4. 增加新方法的调用
 5. 测试
 6. 删除注释代码
 7. 复查代码
 - 修改注释
 - 检查代码优化
 提示：在任何语言开发中，if 的深层嵌套都是非常忌讳的！
 原因
 - 系统执行性能会变差！
 - 阅读起来非常麻烦
 通常 if 的层次，能少就少！
 
 关于注释：注释是邪恶的！
 
 在实际编写代码的时候，注释不是越多越好！
 *** 尤其在重构的时候，要重点检查注释的描述！
 
 什么地方应该加注释呢！
 - .m 文件中，重点难点的逻辑！不加注释，时间长了自己也看不懂！
 - .h 文件中，所有的方法，属性都应该加注释！因为 .h 是整个团队共同使用的！
 
 关于代码重构重要原则
 - 小步走！
 - 只要有修改，就有风险
 - 不断测试自己的预期结果是否达成！
 */
- (void)downloadWithIndexPath:(NSIndexPath *)indexPath{
    
    JPAppInfo *app = self.appInfos[indexPath.row];
    // 判断下载操作是不是存在
    if (self.operationCaches[app.icon] != nil) {
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
                [self.imageCaches setObject:image forKey:app.icon];
            }
            
            // 清除已经完成的下载操作
            /**
             1. 可以节约内存
             2. 如果下载失败，可以重试
             3. 可以避免出现循环引用！
             */
            // 清除下载操作
            [self.operationCaches removeObjectForKey:app.icon];
            
            
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
        [self.operationCaches setObject:download forKey:app.icon];
    }
    
    
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@",self.operationCaches);
}
- (void)dealloc {
    NSLog(@"我去了");
}
@end
