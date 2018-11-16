//
//  APLWKContentViewController.m
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "APLWKContentViewController.h"
#import "APLWKWebViewController.h"

@interface APLWKContentViewController ()

@property (nonatomic) WKWebView *webView;
@property (nonatomic, weak) APLWKWebViewController *webViewController;

@end

@implementation APLWKContentViewController

- (instancetype)initWithAPLWKWebViewController:(APLWKWebViewController *)webViewController {
    if (self = [super init]) {
        _webViewController = webViewController;
    }
    
    return self;
}

- (WKWebView *)installWebViewDelegate:(id<WKNavigationDelegate, WKUIDelegate>)webViewDelegate {
    if (!_webView) {
        UIView *view = self.view;
        WKWebView *webView = self.webView;
        NSDictionary *bindings = NSDictionaryOfVariableBindings(webView);
        
        [view addSubview:webView];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:bindings]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:bindings]];
    }
    self.webView.navigationDelegate = webViewDelegate;
    self.webView.UIDelegate = webViewDelegate;
    return self.webView;
}

- (WKWebView *)webView {
    if (!_webView) {
        id<APLWKWebViewDelegate> delegate = self.webViewController.aplWebViewDelegate;
        WKWebViewConfiguration *configuration;
        if ([delegate respondsToSelector:@selector(aplWebViewController:configurationForWebViewInViewController:)]) {
            configuration = [delegate aplWebViewController:self.webViewController configurationForWebViewInViewController:self];
        } else {
            configuration = [WKWebViewConfiguration new];
        }
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _webView;
}

@end
