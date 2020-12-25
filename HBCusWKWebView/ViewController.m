//
//  ViewController.m
//  HBCusWKWebView
//
//  Created by Mac on 2020/12/25.
//  Copyright © 2020 yanruyu. All rights reserved.
//

#import "ViewController.h"
#import "HBWebViewVC.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"自定义WKWebView";
    [self setupUI];
}
#pragma mark ==========子视图==========
-(void)setupUI{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
#pragma mark ==========点击事件==========
-(void)clickBtn{
    HBWebViewVC *vc = [[HBWebViewVC alloc]init];
    vc.url = @"https://www.baidu.com";
    [self.navigationController pushViewController:vc animated:YES];
}
@end
