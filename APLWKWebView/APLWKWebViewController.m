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
    [self didTriggerPullToRefresh];
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
    [self didFinishPullToRefresh];
}

- (void)didTriggerPullToRefresh {
    [self.webView reload];
}

- (void)didFinishPullToRefresh {
    
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self pushNavigationAction:navigationAction];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    self.progressView.hidden = YES;
    NSLog(@"Error: %@", error);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self finishPullToRefresh];
    self.progressView.hidden = YES;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    self.progressView.hidden = YES;
    
    NSLog(@"Provisional error: %@", error);
}

#pragma mark - Web View Push

- (void)pushNavigationAction:(WKNavigationAction *)action {
    APLWKWebViewController *freshWebView = [self freshWebViewControllerForPush];
    APLPullToRefreshWebViewSegue *segue = [[APLPullToRefreshWebViewSegue alloc] initWithIdentifier:@"APLPullToRefreshWKWebViewSegue" source:self destination:freshWebView];
    [freshWebView loadRequest:action.request];
    [segue perform];
}

- (APLWKWebViewController *)freshWebViewControllerForPush {
    NSAssert(NO, @"-[APLPullToRefreshWKWebView freshWebViewControllerForPush] must be implemented in your concrete subclass.");
    return nil;
}

@end
