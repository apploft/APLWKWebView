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

static void *kAPLWKWebViewKVOContext = &kAPLWKWebViewKVOContext;

@interface APLWKWebViewController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (nonatomic) APLWKContentViewController *contentViewController;
@property (nonatomic, strong) APLPullToRefreshCompletionHandler pendingPullToRefreshCompletionHandler;
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

- (void)viewDidLoad {
    self.delegate = self;

    [super viewDidLoad];
    self.loadThreshold = 0.9;
    
    [self addChildViewController:self.contentViewController];
    
    UIView *childRootView = self.contentViewController.view;
    UIView *parentView = self.view;
    childRootView.frame = parentView.frame;
    [parentView addSubview:childRootView];
    
    [self.contentViewController didMoveToParentViewController:self];
    WKWebView *webView = [self.contentViewController installWebViewDelegate:self];
    self.webView = webView;
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    [webView addObserver:self forKeyPath:@"canGoForward" options:NSKeyValueObservingOptionNew context:kAPLWKWebViewKVOContext];
    
    self.contentView = childRootView;
    
    [self setupLoadingIndicator];
    [self configureWebViewFromDelegate:(id)self.delegate];
    
    if (self.pendingLoadRequest) {
        [self.webView loadRequest:self.pendingLoadRequest];
        self.pendingLoadRequest = nil;
    }
}

- (void)dealloc {
    WKWebView *webView = self.webView;
    [webView removeObserver:self forKeyPath:@"estimatedProgress" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"title" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"loading" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"canGoBack" context:kAPLWKWebViewKVOContext];
    [webView removeObserver:self forKeyPath:@"canGoForward" context:kAPLWKWebViewKVOContext];
    
    if (webView.scrollView.delegate == self) {
        webView.scrollView.delegate = nil;
    }
}

#pragma mark - Load Threshold

- (void)addLoadThresholdReachedHandlerForNextLoad:(void (^)(void))loadThresholdReachedHandler {
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

- (void)updateNavigationItemTitle:(NSString *)newTitle {
    self.navigationItem.title = newTitle;
}

#pragma mark - KVO: Loading Progress

- (void)checkDOMReady {
    if (_didFinishDOMLoad) {
        return;
    }
    
    [self.webView evaluateJavaScript:@"document.readyState == \"interactive\"" completionHandler:^(id _Nullable finished, NSError * _Nullable error) {
        if ([finished boolValue]) {
            [self finishPullToRefresh];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self->_progressView setProgress:1 animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /*
                 * Imitate Safari, which fills the progress bar before hiding it.
                 */
                self->_progressView.hidden = YES;
            });
            if ([self->_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangeLoadingState:)]) {
                [self->_aplWebViewDelegate aplWebViewController:self didChangeLoadingState:NO];
            }
            [self updateBottomItems];
        }
    }];
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
        [_progressView setProgress:[change[NSKeyValueChangeNewKey] floatValue] animated:YES];
        
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

#pragma mark - Bottom Navigation Bar

- (void)configureBottomBarScrollingDelegateForWebView:(WKWebView *)webView {
    if ([self.delegate respondsToSelector:@selector(aplWebViewController:toolbarShouldHide:)]) {
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
    
    id<APLWKWebViewDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(aplWebViewController:toolbarShouldHide:)]) {
        [delegate aplWebViewController:self toolbarShouldHide:shouldHideToolbar];
    }
}

- (NSArray *)suggestedToolbarItemsForNormalTintColor:(UIColor *)tintColor disabledTintColor:(UIColor *)disabledColor {
    UIBarButtonItem *backButtonItem = self.backButtonItem;
    UIBarButtonItem *forwardButtonItem = self.forwardButtonItem;
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = 32;
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.webView action:@selector(reload)];
    self.bottomEnabledColor = tintColor;
    self.bottomDisabledColor = disabledColor;
    
    if (tintColor) {
        refreshItem.tintColor = tintColor;
    }
    
    [self updateBottomItems];
    
    NSArray *suggestedItems = @[
                                backButtonItem,
                                spacer,
                                forwardButtonItem,
                                spacer,
                                refreshItem,
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
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
        _backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self.webView action:@selector(goBack)];
    }
    
    return _backButtonItem;
}

- (UIBarButtonItem *)forwardButtonItem {
    if (!_forwardButtonItem) {
        _forwardButtonItem = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self.webView action:@selector(goForward)];
    }
    
    return _forwardButtonItem;
}

#pragma mark - WebView setup from Delegate

- (void)configureWebViewFromDelegate:(id<APLWKWebViewDelegate>)delegate {
    if (!_webView) {
        /*
         * The delegate is set although the web view has not been initialized,
         * yet. -viewDidLoad will call us again.
         */
        return;
    }
    
    WKWebView *webView = self.webView;
    BOOL shouldEnableNavigationGestures = ![delegate respondsToSelector:@selector(aplWebViewControllerFreshInstanceForPush:)];
    webView.allowsBackForwardNavigationGestures = shouldEnableNavigationGestures;
    [self configureBottomBarScrollingDelegateForWebView:webView];
}

- (void)setAplWebViewDelegate:(id<APLWKWebViewDelegate>)aplWebViewDelegate {
    _aplWebViewDelegate = aplWebViewDelegate;
    
    [self configureWebViewFromDelegate:aplWebViewDelegate];
}


#pragma mark - Lazy Initializers

- (APLWKContentViewController *)contentViewController {
    if (!_contentViewController) {
        _contentViewController = [[APLWKContentViewController alloc] initWithAPLWKWebView:self];
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
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didCommitNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFinishNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self finishPullToRefresh];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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
