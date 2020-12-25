//
//  HBJSHandler.m
//  HBPleasedChoose
//
//  Created by Mac on 2020/4/17.
//  Copyright © 2020 yanruyu. All rights reserved.
//

#import "HBJSHandler.h"

@implementation HBJSHandler

-(instancetype)initWithViewController:(UIViewController *)webVC configuration:(WKWebViewConfiguration *)configuration {
    self = [super init];
    if (self) {
        _webVC = webVC;
        _configuration = configuration;
        //注册JS 事件
        [configuration.userContentController addScriptMessageHandler:self name:@"backPage"];
        [configuration.userContentController addScriptMessageHandler:self name:@"authorization"];
        
    }
    return self;
}

#pragma mark -  JS 调用 Native  代理
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([message.name isEqualToString:@"backPage"]) {
        //返回
        if (self.webVC.presentingViewController) {
            [self.webVC dismissViewControllerAnimated:YES completion:nil];
        }else{
            [self.webVC.navigationController popViewControllerAnimated:YES];
        }
        return;
     }
    //淘宝授权
    if ([message.name isEqualToString:@"authorization"]) {
        //返回
        NSLog(@"%@", message.body);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TAOBAOKE_AUTH_SUCCESS" object:nil
                                                          userInfo:message.body];
        [self webBack];
    }
}
-(void)webBack{
    //返回
    if (self.webVC.presentingViewController) {
        [self.webVC dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.webVC.navigationController popViewControllerAnimated:YES];
    }
    return;
}
#pragma mark -  记得要移除
-(void)cancelHandler {
    [_configuration.userContentController removeScriptMessageHandlerForName:@"backPage"];
    [_configuration.userContentController removeScriptMessageHandlerForName:@"authorization"];
    
    [_configuration.userContentController removeScriptMessageHandlerForName:@"Native"];
    [_configuration.userContentController removeScriptMessageHandlerForName:@"callApp"];
}

-(void)dealloc {
   
}

@end
