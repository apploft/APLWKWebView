//
//  APLWKWebViewController.m
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "APLWKWebViewController.h"

static void *kAPLWKWebViewKVOContext = &kAPLWKWebViewKVOContext;

@interface APLWKWebViewController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>
@property (nonatomic, readwrite, strong) WKWebView *webView;
@property (nonatomic, readwrite, strong) UIProgressView *progressView;
@property (nonatomic, readwrite, strong) UIBarButtonItem *backButtonItem;
@property (nonatomic, readwrite, strong) UIBarButtonItem *forwardButtonItem;
@property (nonatomic, readwrite, strong) UIBarButtonItem *reloadButtonItem;

@property (nonatomic) NSMutableArray *pendingLoadThresholdReachedCompletionHandlers;
@property (nonatomic) BOOL didFinishDOMLoad;

// Needed before viewDidLoad
@property (nonatomic) NSURLRequest *pendingLoadRequest;

// Needed for bottom bar
@property (nonatomic) CGFloat lastYPosition;
@property (nonatomic) UIColor *bottomEnabledColor;
@property (nonatomic) UIColor *bottomDisabledColor;
@end


@implementation APLWKWebViewController

#pragma mark - Initialization

- (void)dealloc {
    if (_webView) {
        [self removeObserversFromWebView:_webView];
    }
}

#pragma mark - Appearance callbacks

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loadThreshold = 0.9;

    [self addWebViewIfNeeded];
    [self observeWebView:self.webView];
    [self addLoadingIndicator];

    if (self.pendingLoadRequest) {
        [self.webView loadRequest:self.pendingLoadRequest];
        self.pendingLoadRequest = nil;
    }
}

#pragma mark - Navigation Item

- (void)updateNavigationItemTitle:(NSString *)newTitle {
    self.navigationItem.title = newTitle;
}

#pragma mark - Load Threshold

- (NSMutableArray *)pendingLoadThresholdReachedCompletionHandlers {
    if (!_pendingLoadThresholdReachedCompletionHandlers) {
        _pendingLoadThresholdReachedCompletionHandlers = [NSMutableArray new];
    }

    return _pendingLoadThresholdReachedCompletionHandlers;
}

- (void)addLoadThresholdReachedHandlerForNextLoad:(void (^)(void))loadThresholdReachedHandler {
    [self.pendingLoadThresholdReachedCompletionHandlers addObject:loadThresholdReachedHandler];
}

- (void)loadThresholdReached {
    if (_pendingLoadThresholdReachedCompletionHandlers) {
        NSArray *loadThresoldCompletionHandlers = self.pendingLoadThresholdReachedCompletionHandlers;
        self.pendingLoadThresholdReachedCompletionHandlers = nil;

        for (void (^completionHandler)(void) in loadThresoldCompletionHandlers) {
            completionHandler();
        }
    }
}

#pragma mark - Web View

/// Lazy getter, creating web view and installing necessary delegates
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero
                                      configuration:[self webViewConfigurationFromDelegateOrDefault]];

        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
    }
    return _webView;
}

- (void)loadRequest:(NSURLRequest *)request {
    if (self.webView) {
        [self.webView loadRequest:request];
    } else {
        self.pendingLoadRequest = request;
    }
}

- (void)resetWebView {
    [self removeObserversFromWebView:self.webView];

    id<WKNavigationDelegate, WKUIDelegate> delegate = (id)_webView.navigationDelegate;
    [_webView removeFromSuperview];
    _webView = nil;

    [self addWebViewIfNeeded];
    [self observeWebView:self.webView];
}

- (void)addWebViewIfNeeded {
    if (self.webView.superview != nil) {
        return;
    }

    UIView *view = self.view;
    WKWebView *webView = self.webView;

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:webView];

    UILayoutGuide *safeAreaLayoutGuide = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [webView.topAnchor constraintEqualToAnchor:safeAreaLayoutGuide.topAnchor],
        [webView.leadingAnchor constraintEqualToAnchor:safeAreaLayoutGuide.leadingAnchor],
        [webView.bottomAnchor constraintEqualToAnchor:safeAreaLayoutGuide.bottomAnchor],
        [webView.rightAnchor constraintEqualToAnchor:safeAreaLayoutGuide.rightAnchor]
    ]];
}

/// Return a web view configuration either from the delegate or a default web view configuration if the 
-(WKWebViewConfiguration * _Nonnull)webViewConfigurationFromDelegateOrDefault {
    id<APLWKWebViewDelegate> delegate = self.aplWebViewDelegate;
    WKWebViewConfiguration *configuration;

    if ([delegate respondsToSelector:@selector(aplWebViewController)]) {
        configuration = [delegate aplWebViewController:self];
    } else {
        configuration = [WKWebViewConfiguration new];
    }
    return configuration;
}

#pragma mark - Loading Indicator

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [UIProgressView new];
    }

    return _progressView;
}

- (void)addLoadingIndicator {
    UIProgressView *progressView = self.progressView;

    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.hidden = YES;

    [self.view addSubview:progressView];

    UILayoutGuide *safeAreaLayoutGuide = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [progressView.topAnchor constraintEqualToAnchor:safeAreaLayoutGuide.topAnchor],
        [progressView.leftAnchor constraintEqualToAnchor:safeAreaLayoutGuide.leftAnchor],
        [progressView.rightAnchor constraintEqualToAnchor:safeAreaLayoutGuide.rightAnchor]
    ]];
}

#pragma mark - Toolbar

- (void)configureBottomBarScrollingDelegateForWebView:(WKWebView *)webView {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:toolbarShouldHide:)]) {
        webView.scrollView.delegate = self;
    } else {
        if (webView.scrollView.delegate == self) {
            webView.scrollView.delegate = nil;
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastYPosition = scrollView.contentOffset.y;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    BOOL shouldHideToolbar = scrollView.contentOffset.y > _lastYPosition;
    id<APLWKWebViewDelegate>delegate = self.aplWebViewDelegate;

    if ([delegate respondsToSelector:@selector(aplWebViewController:toolbarShouldHide:)]) {
        [delegate aplWebViewController:self toolbarShouldHide:shouldHideToolbar];
    }
}

- (NSArray *)suggestedToolbarItemsForNormalTintColor:(UIColor *)tintColor disabledTintColor:(UIColor *)disabledColor {
    UIBarButtonItem *backButtonItem = self.backButtonItem;
    UIBarButtonItem *forwardButtonItem = self.forwardButtonItem;
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = 32;

    UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *reloadItem = self.reloadButtonItem;

    self.bottomEnabledColor = tintColor;
    self.bottomDisabledColor = disabledColor;

    if (tintColor) {
        reloadItem.tintColor = tintColor;
    }

    [self updateBottomItems];

    NSArray *suggestedItems = @[
                                backButtonItem,
                                spacer,
                                forwardButtonItem,
                                flexSpacer,
                                reloadItem
                                ];
    return suggestedItems;
}

- (void)setEnabled:(BOOL)enabled andColorForBarButtonItem:(UIBarButtonItem *)item {
    item.enabled = enabled;
    [item setTitleTextAttributes:@{ NSForegroundColorAttributeName: enabled ? self.bottomEnabledColor : self.bottomDisabledColor} forState:UIControlStateNormal];
}

- (void)updateBottomItems {
    if (_backButtonItem || _forwardButtonItem) {
        [self setEnabled:_webView.canGoBack andColorForBarButtonItem:_backButtonItem];
        [self setEnabled:_webView.canGoForward andColorForBarButtonItem:_forwardButtonItem];
    }
}

- (UIBarButtonItem *)backButtonItem {
    if (!_backButtonItem) {
        _backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self.webView
                                                          action:@selector(goBack)];
    }
    return _backButtonItem;
}

- (UIBarButtonItem *)forwardButtonItem {
    if (!_forwardButtonItem) {
        _forwardButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self.webView
                                                             action:@selector(goForward)];
    }
    return _forwardButtonItem;
}

-(UIBarButtonItem*)reloadButtonItem {
    if (!_reloadButtonItem) {
        _reloadButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                          target:self.webView
                                                                          action:@selector(reload)];
    }
    return _reloadButtonItem;
}

#pragma mark - KVO: Loading Progress

- (void)observeWebView:(WKWebView *)webView {
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"canGoForward" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
}

- (void)removeObserversFromWebView:(WKWebView *)webView {
    [webView removeObserver:self forKeyPath:@"estimatedProgress" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"title" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"loading" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"canGoBack" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"canGoForward" context:kAPLWKWebViewKVOContext];

    if (webView.scrollView.delegate == self) {
        webView.scrollView.delegate = nil;
    }
}

- (void)checkDOMReady {
    if (_didFinishDOMLoad) {
        return;
    }

    [self.webView evaluateJavaScript:@"document.readyState != \"loading\"" completionHandler:^(id _Nullable finished, NSError * _Nullable error) {
        if ([finished boolValue]) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self setProgressViewProgressTo:1 andHideAfter:1.0];

            if ([self->_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangeLoadingState:)]) {
                [self->_aplWebViewDelegate aplWebViewController:self didChangeLoadingState:NO];
            }
            [self updateBottomItems];
        }
    }];
}

-(void)setProgressViewProgressTo:(CGFloat)progressValue andHideAfter:(NSTimeInterval)delayBeforeHiding {
    [_progressView setProgress:progressValue animated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayBeforeHiding * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        /*
         * Imitate Safari, which fills the progress bar before hiding it.
         */
        _progressView.hidden = YES;
        _progressView.progress = 0;
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    /*
     * Direct ivar access intended because no lazy initializers
     * should be fired.
     */

    if (context != kAPLWKWebViewKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    } else if (object != _webView) {
        return;
    }

    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newProgress = [change[NSKeyValueChangeNewKey] floatValue];

        [_progressView setProgress:newProgress animated:YES];

        if (_webView.estimatedProgress > _loadThreshold) {
            [self loadThresholdReached];
        } else if (_useDOMReadyEvent) {
            [self checkDOMReady];
        }
    } else if ([keyPath isEqualToString:@"title"]) {
        if (_useContentPageTitle) {
            NSString *title = change[NSKeyValueChangeNewKey];
            [self updateNavigationItemTitle:title];
            if ([_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangePageTitle:)]) {
                [_aplWebViewDelegate aplWebViewController:self didChangePageTitle:title];
            }
        }
    } else if ([keyPath isEqualToString:@"loading"]) {
        BOOL loading = [change[NSKeyValueChangeNewKey] boolValue];
        if (loading) {
            _didFinishDOMLoad = NO;
        }
        _progressView.hidden = !loading;
        if (!loading) {
            _progressView.progress = 0;
        }
        if ([_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangeLoadingState:)]) {
            [_aplWebViewDelegate aplWebViewController:self didChangeLoadingState:loading];
        }
        [self updateBottomItems];
    } else if ([keyPath isEqualToString:@"canGoBack"] || [keyPath isEqualToString:@"canGoForward"]) {
        [self updateBottomItems];
    }
}

#pragma mark - WKNavigationDelegate and Forwardings

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:self decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didCommitNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFinishNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailProvisionalNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
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

@end
