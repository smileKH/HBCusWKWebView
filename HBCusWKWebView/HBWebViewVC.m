//
//  HBWebViewVC.m
//  HBSecurityCode
//
//  Created by Mac on 2020/4/17.
//  Copyright © 2020 yanruyu. All rights reserved.
//

#import "HBWebViewVC.h"
#import "HBJSHandler.h"
/**
系统高度，宽度 bounds
*/
#define SCREEN_WIDTH            ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT           ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_BOUNDS           [UIScreen mainScreen].bounds

//系统状态栏高度
#define bStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
//系统底部TabBar高度
#define bTabBarHeight          (bStatusBarHeight>20?83:49)
//系统导航栏总高度
#define bAllNavTotalHeight     (bStatusBarHeight>20?88:64)
// 底部安全区域远离高度
#define kBottomSafeHeight      (bStatusBarHeight>20?34:0)

//宽高比
#define kAdaptedWidth(x) ((x) * SCREEN_WIDTH/375.0)
#define kAdaptedHeight(x) ((x) * SCREEN_HEIGHT/667.0)
//判断是否iPhone几
#define kUI_IPHONE             ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define kUI_IPHONE5            (kUI_IPHONE && SCREEN_HEIGHT == 568.0)
#define kUI_IPHONE6            (kUI_IPHONE && SCREEN_HEIGHT == 667.0)
#define kUI_IPHONE6PLUS        (kUI_IPHONE && SCREEN_HEIGHT == 736.0) // Both orientations
@interface HBWebViewVC ()<WKNavigationDelegate,WKScriptMessageHandler,WKUIDelegate>
@property (nonatomic,strong) HBJSHandler * jsHandler;
@property (nonatomic,assign) double lastProgress;//上次进度条位置
@property (nonatomic, assign) BOOL isTBDidLoad;//避免重复跳淘宝开关

@end

@implementation HBWebViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    /**初始化webView*/
    [self initWKWebView];
    /**进度条颜色*/
    _progressViewColor = [UIColor redColor];
//    /**跳转规则中,重新加载WebView*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(againReload) name:@"web" object:nil];
//    /**跳转规则中,关闭webView*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeWeb) name:@"closeWeb" object:nil];
//    /**新增智能验证成功,关闭webView*/
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(smartValidationSuccessWeb) name:@"popSmartValidationSuccess" object:nil];
//    /**新增智能验证失败,关闭webView*/
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(smartValidationFailWeb) name:@"popSmartValidationFail" object:nil];
}
#pragma mark ==========登录成功刷新界面==========
-(void)loginSuccess:(NSNotification *)noti{
    //登录成功，重新更新界面
    [self againReload];
}
#pragma mark =======加载URL==========
-(void)againReload{
    //如果存在token，那么在这里加上token
//    NSString *token = YRY_TOKEN;
//    if ([HBHuTool isJudgeOrNotString:token]) {
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",self.url]]];
//        [_webView loadRequest:request];
//    }else{
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?&token=%@",self.url,token]]];
//        [_webView loadRequest:request];
//    }
}
#pragma mark 初始化webview
-(void)initWKWebView{
    WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
    configuration.preferences.javaScriptEnabled = YES;//打开js交互
    //这两个方法有内存泄漏，需要解决一下
    [configuration.userContentController addScriptMessageHandler:self name:@"Native"];
    [configuration.userContentController addScriptMessageHandler:self name:@"callApp"];
    configuration.preferences.minimumFontSize = 0;

    _webConfiguration = configuration;
    _jsHandler = [[HBJSHandler alloc]initWithViewController:self configuration:configuration];
    
    _webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-bAllNavTotalHeight-kBottomSafeHeight) configuration:configuration];

    _webView.scrollView.backgroundColor = [UIColor whiteColor];
     [self.webView setOpaque:NO];
    _webView.navigationDelegate = self;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.allowsBackForwardNavigationGestures =YES;//打开网页间的 滑动返回
    _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    //监控进度
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    [self.view addSubview:_webView];
    //进度条
    _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.tintColor = [UIColor redColor];
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 5.0);
    [_webView addSubview:_progressView];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url]];
    [_webView loadRequest:request];
    NSLog(@"打印一下网页链接:%@",_url);
    
    //更新导航栏按钮
    [self updateNavigationItems];
}
#pragma mark ==========设置标题==========
-(void)setMyTitle:(NSString *)myTitle{
    _myTitle = myTitle;
   self.title = myTitle;
}
#pragma mark - public funcs
-(void)reloadWebView{
    [self.webView reload];
}
#pragma mark ==========KVO 监测进度==========
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webView) {
        self.progressView.progress = self.webView.estimatedProgress;
        if (self.progressView.progress == 1) {
            __weak typeof (self)weakSelf = self;
            [UIView animateWithDuration:0.25f delay:0.3f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                weakSelf.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
            } completion:^(BOOL finished) {
                weakSelf.progressView.hidden = YES;
            }];
        }
    }else if ([keyPath isEqualToString:@"title"] && object == self.webView){//网页title
        NSInteger titleLength = 0;
        if (kUI_IPHONE5) {
            titleLength = 6;
        }else if (kUI_IPHONE6){
            titleLength = 9;
        }else if (kUI_IPHONE6PLUS){
            titleLength = 12;
        }else{
            titleLength = 9;
        }
        if (self.webView.title.length > titleLength) {
            NSString *titleStr = [self.webView.title substringToIndex:titleLength];
            self.title = [NSString stringWithFormat:@"%@...",titleStr];
        }else{
            self.title  =self.webView.title;
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"方法名:%@", message.name);
    NSLog(@"参数:%@", message.body);
    //自定义参数，这个可以跟前端后台统一参数，可以传字典类型
    //[HBClickEventManage GTPushViewController:nil andPushVC:self isPushType:2 ClickType:[message.body objectForKey:@"function"] clickParameter:[message.body objectForKey:@"parameters"] ClickUrl:@"" Title:@""];
}

#pragma mark ==========加载完成==========
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSString *injectionJSString = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"width=device-width, initial-scale=1.0,maximum-scale=1.0, minimum-scale=1.0, user-scalable=no\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [webView evaluateJavaScript:injectionJSString completionHandler:nil];
    
    //更新进度调
    [self updateProgress:webView.estimatedProgress];
    
    //更新导航栏按钮
    [self updateNavigationItems];
}
#pragma mark ==========更新进度条==========
-(void)updateProgress:(double)progress{
    self.progressView.alpha = 1;
    if(progress > _lastProgress){
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }else{
        [self.progressView setProgress:self.webView.estimatedProgress];
    }
    _lastProgress = progress;
    
    if (progress >= 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.alpha = 0;
            [self.progressView setProgress:0];
            self.lastProgress = 0;
        });
    }
}
//加载失败 隐藏progressView
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.progressView.hidden = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
#pragma mark ==========判断链接是否允许跳转==========
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSURL *URL = navigationAction.request.URL;
    NSString *scheme = [URL scheme];
    // 打电话
    if ([scheme isEqualToString:@"tel"]) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:URL]) {
            [app openURL:URL];
            // 一定要加上这句,否则会打开新页面
            decisionHandler(WKNavigationActionPolicyCancel); return;
        }
    } // 打开淘宝
    if ([scheme isEqualToString:@"tbopen"]) {
        if (!self.isTBDidLoad) {//避免重复跳淘宝开关
            UIApplication *app = [UIApplication sharedApplication];
            if ([app canOpenURL:URL]) {
                [app openURL:URL];
                // 一定要加上这句,否则会打开新页面
                self.isTBDidLoad = YES;
                decisionHandler(WKNavigationActionPolicyCancel); return;
            }
        }else{
            decisionHandler(WKNavigationActionPolicyAllow); return;
        }
    } // 打开appstore
    if ([URL.absoluteString containsString:@"ituns.apple.com"]) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:URL]) {
            [app openURL:URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}
//  * 拿到响应后决定是否允许跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
#pragma mark ==========继承方法==========
-(void)closeItemInNaviClicked{
    NSLog(@"closeItemInNaviClicked");
}
#pragma mark - update nav items
-(void)updateNavigationItems{
    NSLog(@"canGoBack ==%d",self.webView.canGoBack);
    if (self.webView.canGoBack) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        [self addWebNavigationItemWithTitles:@[@"mine_back_share_img", @"close_treasure_img"] isLeft:YES target:self action:@selector(leftBtnClick:) tags:@[@2000,@2001]];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self addWebNavigationItemWithTitles:@[@"mine_back_share_img"] isLeft:YES target:self action:@selector(leftBtnClick:) tags:@[@2000]];
    }
}

- (void)addWebNavigationItemWithTitles:(NSArray *)titles isLeft:(BOOL)isLeft target:(id)target action:(SEL)action tags:(NSArray *)tags{
    NSMutableArray * items = [[NSMutableArray alloc] init];
    NSInteger i = 0;
    for (NSString *imgNameStr in titles) {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 44 , 44);
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [btn setImage:[UIImage imageNamed:imgNameStr] forState:UIControlStateNormal];
        if (i==0) {
            btn.backgroundColor = [UIColor redColor];
        }else{
            btn.backgroundColor = [UIColor blueColor];
        }
        [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        btn.tag = [tags[i++] integerValue];
        UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:btn];
        [items addObject:item];
    }
    if (isLeft) {
        self.navigationItem.leftBarButtonItems = items;
    } else {
        self.navigationItem.rightBarButtonItems = items;
    }
}

-(void)customBackItemClicked{
    self.webView.canGoBack? [self.webView goBack]: [self backBtnInNaviClicked];
}
#pragma mark ==========点击关闭按钮==========
-(void)closeWeb{
    NSLog(@"调用关闭按钮");
    [_jsHandler cancelHandler];
    [self.navigationController popViewControllerAnimated:YES];
}
/**
 js交互返回按钮
 */
-(void)backBtnClicked{
    [self.webView stopLoading];
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }else{
        [_jsHandler cancelHandler];
        [self backBtnClicked];
        
    }
}
-(void)backButtonClicked{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }else {
        [_jsHandler cancelHandler];
        [self backBtnClicked];
    }
}
-(void)leftBtnClick:(UIButton *)btn{
    switch (btn.tag) {
        case 2000:
            [self customBackItemClicked];
            break;
        case 2001:
            [self backBtnInNaviClicked];
            break;
        default: break;
    }
}


-(void)adToWebVCBackClickAction{
    NSLog(@"adToWebVCBackClickAction in baseWebVC");
    [_jsHandler cancelHandler];
}

- (void)backBtnInNaviClicked{
    [self adToWebVCBackClickAction];
    NSArray *viewcontrollers = self.navigationController.viewControllers;
    self.presentingViewController && viewcontrollers.count <= 1 ? [self dismissViewControllerAnimated:YES completion:nil]:[self.navigationController popViewControllerAnimated:YES];
}

-(void)dealloc{
    //注释通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_jsHandler cancelHandler];
    if (self.webView) {
        self.webView.scrollView.delegate = nil;
    }
    self.webView.navigationDelegate = nil;
    //清除缓存
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [_webView removeObserver:self forKeyPath:@"title"];
    [self clearCache];
    NSLog(@"清除全部缓存~~~~~~~~~~~~~");
    NSLog(@"哈哈哈哈哈哈哈哈哈哈或，内存释放了");
}
/** 清理缓存的方法，这个方法会清除缓存类型为HTML类型的文件*/
- (void)clearCache {
    /* 取得Library文件夹的位置*/
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
    /* 取得bundle id，用作文件拼接用*/
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleIdentifier"];
    /*
     * 拼接缓存地址，具体目录为App/Library/Caches/你的APPBundleID/fsCachedData
     */
    NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    NSError *error;
    /* 取得目录下所有的文件，取得文件数组*/
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // NSArray *fileList = [[NSArray alloc] init];
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:webKitFolderInCachesfs error:&error];
    /* 遍历文件组成的数组*/
    for(NSString * fileName in fileList){
        /* 定位每个文件的位置*/
        NSString * path = [[NSBundle bundleWithPath:webKitFolderInCachesfs] pathForResource:fileName ofType:@""];
        /* 将文件转换为NSData类型的数据*/
        NSData * fileData = [NSData dataWithContentsOfFile:path];
        /* 如果FileData的长度大于2，说明FileData不为空*/
        if(fileData.length >2){
            /* 创建两个用于显示文件类型的变量*/
            int char1 =0;
            int char2 =0;
            [fileData getBytes:&char1 range:NSMakeRange(0,1)];
            [fileData getBytes:&char2 range:NSMakeRange(1,1)];
            /* 拼接两个变量*/
            NSString *numStr = [NSString stringWithFormat:@"%i%i",char1,char2];
            /* 如果该文件前四个字符是6033，说明是Html文件，删除掉本地的缓存*/
            if([numStr isEqualToString:@"6033"]){
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",webKitFolderInCachesfs,fileName]error:&error];
                continue;
            }
        }
    }
}
@end
