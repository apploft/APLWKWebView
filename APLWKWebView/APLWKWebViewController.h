//
//  APLWKWebViewController.h
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import <APLPullToRefreshContainer/APLPullToRefreshContainerViewController.h>

@import WebKit;

@interface APLWKWebViewController : APLPullToRefreshContainerViewController<APLPullToRefreshContainerDelegate, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) CGFloat loadThreshold;
@property (nonatomic) UIProgressView *progressView;


#pragma mark - Pull To Refresh handling
- (void)loadRequest:(NSURLRequest *)request;
- (void)finishPullToRefresh;
- (void)addLoadThresholdReachedHandlerForNextLoad:(void(^)())loadThresholdReachedHandler;

#pragma mark - Push Handling
- (void)pushNavigationAction:(WKNavigationAction *)action;

// Overridables
- (void)didTriggerPullToRefresh;
- (void)didFinishPullToRefresh;
- (APLWKWebViewController *)freshWebViewControllerForPush;
@end
