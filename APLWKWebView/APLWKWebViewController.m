//
//  APLWKWebViewController.m
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "APLWKWebViewController.h"
#import "APLWKContentViewController.h"
#import "APLPullToRefreshWebViewSegue.h"

@interface APLWKWebViewController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic) APLWKContentViewController *contentViewController;
@property (nonatomic, strong) APLPullToRefreshCompletionHandler pendingPullToRefreshCompletionHandler;
@property (nonatomic) NSMutableArray *pendingLoadThresholdReachedCompletionHandlers;

// Needed before viewDidLoad
@property (nonatomic) NSURLRequest *pendingLoadRequest;

@end

@implementation APLWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadThreshold = 0.9;
    
    [self addChildViewController:self.contentViewController];
    
    UIView *childRootView = self.contentViewController.view;
    UIView *parentView = self.view;
    childRootView.frame = parentView.frame;
    [parentView addSubview:childRootView];
    
    [self.contentViewController didMoveToParentViewController:self];
    self.webView = [self.contentViewController installWebViewDelegate:self];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    self.delegate = self;
    self.contentView = childRootView;
    
    [self setupLoadingIndicator];
    
    if (self.pendingLoadRequest) {
        [self.webView loadRequest:self.pendingLoadRequest];
        self.pendingLoadRequest = nil;
    }
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

#pragma mark - Load Threshold

- (void)addLoadThresholdReachedHandlerForNextLoad:(void (^)())loadThresholdReachedHandler {
    [self.pendingLoadThresholdReachedCompletionHandlers addObject:loadThresholdReachedHandler];
}

- (void)loadThresholdReached {
    if (_pendingLoadThresholdReachedCompletionHandlers) {
        NSArray *loadThresoldCompletionHandlers = self.pendingLoadThresholdReachedCompletionHandlers;
        self.pendingLoadThresholdReachedCompletionHandlers = nil;
        
        for (void (^completionHandler)() in loadThresoldCompletionHandlers) {
            completionHandler();
        }
    }
}

#pragma mark - Web View Logic

- (void)loadRequest:(NSURLRequest *)request {
    if (self.webView) {
        [self.webView loadRequest:request];
    } else {
        self.pendingLoadRequest = request;
    }
}

#pragma mark - KVO: Loading Progress

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == _webView) {
        _progressView.progress = _webView.estimatedProgress;
        
        if (_webView.estimatedProgress > _loadThreshold) {
            [self loadThresholdReached];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Loading Indicator

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [UIProgressView new];
    }
    
    return _progressView;
}

- (void)setupLoadingIndicator {
    UIProgressView *progressView = self.progressView;
    UIView *view = self.view;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.hidden = YES;
    [view addSubview:progressView];
    
    id<UILayoutSupport>topLayoutGuide = self.topLayoutGuide;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(progressView, topLayoutGuide);
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|" options:0 metrics:nil views:bindings]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][progressView]" options:0 metrics:nil views:bindings]];
}

#pragma mark - Pull To Refresh Handling

- (UIScrollView *)aplPullToRefreshContentScrollView {
    return self.webView.scrollView;
}

- (void)aplDidTriggerPullToRefreshCompletion:(APLPullToRefreshCompletionHandler)completionHandler {
    self.pendingPullToRefreshCompletionHandler = completionHandler;
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewDidTriggerPullToRefresh:)]) {
        [self.aplWebViewDelegate aplWebViewDidTriggerPullToRefresh:self];
    } else {
        [self.webView reload];
    }
}

- (UIView<APLPullToRefreshView> *)aplPullToRefreshPullToRefreshView {
    NSAssert(nil, @"-[APLPullToRefreshWKWebView aplPullToRefreshPullToRefreshView] must be implemented in your concrete subclass.");
    return nil;
}

- (void)aplPullToRefreshDidInstallPullToRefreshView:(id<APLPullToRefreshView>)pullToRefreshView {
    [self.view bringSubviewToFront:self.progressView];
}

- (void)finishPullToRefresh {
    if (!_pendingPullToRefreshCompletionHandler) {
        return;
    }
    
    _pendingPullToRefreshCompletionHandler();
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewDidFinishPullToRefresh:)]) {
        [self.aplWebViewDelegate aplWebViewDidFinishPullToRefresh:self];
    }
}


#pragma mark - Lazy Initializers

- (APLWKContentViewController *)contentViewController {
    if (!_contentViewController) {
        _contentViewController = [APLWKContentViewController new];
    }
    
    return _contentViewController;
}

- (NSMutableArray *)pendingLoadThresholdReachedCompletionHandlers {
    if (!_pendingLoadThresholdReachedCompletionHandlers) {
        _pendingLoadThresholdReachedCompletionHandlers = [NSMutableArray new];
    }
    
    return _pendingLoadThresholdReachedCompletionHandlers;
}

#pragma mark - WKNavigationDelegate and Forwardings

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewControllerFreshInstanceForPush:)] && navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self pushNavigationAction:navigationAction];
    } else if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:self decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.progressView.hidden = NO;
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didCommitNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.progressView.hidden = YES;

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.progressView.hidden = YES;
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFinishNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.progressView.hidden = YES;
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailProvisionalNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didStartProvisionalNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:self decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}


#pragma mark - Web View Push

- (void)pushNavigationAction:(WKNavigationAction *)action {
    // This method is only called if our delegate respondsToSelector:@selector(aplWebViewControllerFreshInstanceForPush:).
    // Hence this call is safe:
    APLWKWebViewController *freshWebView = [self.aplWebViewDelegate aplWebViewControllerFreshInstanceForPush:self];
    
    APLPullToRefreshWebViewSegue *segue = [[APLPullToRefreshWebViewSegue alloc] initWithIdentifier:@"APLPullToRefreshWKWebViewSegue" source:self destination:freshWebView];
    [freshWebView loadRequest:action.request];
    [segue perform];
}

@end
