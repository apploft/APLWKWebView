//
//  APLWKContentViewController.m
//  Stiftunglife
//
//  Created by Arbeit on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "APLWKContentViewController.h"

@interface APLWKContentViewController ()

@property (nonatomic) WKWebView *webView;

@end

@implementation APLWKContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = self.view;
    WKWebView *webView = self.webView;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(webView);
    
    [view addSubview:webView];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:bindings]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:bindings]];
}

- (WKWebView *)installWebViewDelegate:(id<WKNavigationDelegate, WKUIDelegate>)webViewDelegate {
    self.webView.navigationDelegate = webViewDelegate;
    self.webView.UIDelegate = webViewDelegate;
    return self.webView;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [WKWebView new];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _webView;
}

@end
