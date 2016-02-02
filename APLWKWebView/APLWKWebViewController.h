//
//  APLWKWebViewController.h
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import <APLPullToRefreshContainer/APLPullToRefreshContainerViewController.h>

@import WebKit;

@class APLWKWebViewController;

@protocol APLWKWebViewDelegate <NSObject>

@optional

- (APLWKWebViewController *)aplWebViewControllerFreshInstanceForPush:(APLWKWebViewController *)webViewController; // disables push if none provided
- (void)aplWebViewDidTriggerPullToRefresh:(APLWKWebViewController *)webViewController;
- (void)aplWebViewDidFinishPullToRefresh:(APLWKWebViewController *)webViewController;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didCommitNavigation:(WKNavigation *)navigation;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFinishNavigation:(WKNavigation *)navigation;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
           completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                       NSURLCredential *credential))completionHandler;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didStartProvisionalNavigation:(WKNavigation *)navigation;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
             decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (void)aplWebViewController:(APLWKWebViewController *)webViewController decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
             decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

@end

@interface APLWKWebViewController : APLPullToRefreshContainerViewController<APLPullToRefreshContainerDelegate, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) CGFloat loadThreshold;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic, weak) id<APLWKWebViewDelegate> aplWebViewDelegate;


#pragma mark - Pull To Refresh handling
- (void)loadRequest:(NSURLRequest *)request;
- (void)finishPullToRefresh;
- (void)addLoadThresholdReachedHandlerForNextLoad:(void(^)())loadThresholdReachedHandler;

#pragma mark - Push Handling
- (void)pushNavigationAction:(WKNavigationAction *)action;
@end
