//
//  HBWebViewVC.h
//  HBSecurityCode
//
//  Created by Mac on 2020/4/17.
//  Copyright © 2020 yanruyu. All rights reserved.
//
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBWebViewVC : UIViewController
/**
*  embed WKWebView
*/
@property (nonatomic,strong) WKWebView * webView;
@property (nonatomic,strong) UIProgressView * progressView;
@property (nonatomic,assign) UIColor *progressViewColor;//进度颜色
@property (nonatomic,weak) WKWebViewConfiguration * webConfiguration;
@property (nonatomic, copy) NSString * url;//URL
@property (nonatomic, strong) NSString *myTitle;//标题


/**
 重新刷新 WebView
 */
-(void)reloadWebView;


/**
 部分子页面会继承 这个页面，但是有些页面会
 */
-(void)adToWebVCBackClickAction;
@end

NS_ASSUME_NONNULL_END
