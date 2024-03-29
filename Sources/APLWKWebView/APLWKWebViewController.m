//
//  APLWKWebViewController.m
//
//  Copyright © 2021 apploft. All rights reserved.
//

#import "APLWKWebViewController.h"
#import <MessageUI/MessageUI.h>
#import "NSURLRequest+APLWKWebViewController.h"

static void *kAPLWKWebViewKVOContext = &kAPLWKWebViewKVOContext;

@interface APLWKWebViewController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, readwrite, strong) WKWebView *webView;
@property (nonatomic, readwrite, strong) UIProgressView *progressView;
@property (nonatomic, readwrite, strong) UIBarButtonItem *backButtonItem;
@property (nonatomic, readwrite, strong) UIBarButtonItem *forwardButtonItem;
@property (nonatomic, readwrite, strong) UIBarButtonItem *reloadButtonItem;

@property (nonatomic) NSMutableArray *pendingLoadThresholdReachedCompletionHandlers;
@property (nonatomic) BOOL didFinishDOMLoad;
@property (nonatomic) NSTimer *hideProgressViewTimer;

// Needed before viewDidLoad
@property (nonatomic) NSURLRequest *pendingLoadRequest;

// Needed for bottom bar
@property (nonatomic) CGFloat lastYPosition;

@property (nonatomic) BOOL isToolbarHidden;
@end


@implementation APLWKWebViewController

#pragma mark - Initialization

- (void)dealloc {
    if (_webView) {
        [self removeObserversFromWebView:_webView];
    }
}

- (id)init {
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self.mailtoLinkHandlingPolicy = APLWKWebViewMailtoLinkHandlingPolicyAutomatic;
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (id)initWithCoder:(NSCoder *)coder {
    self.mailtoLinkHandlingPolicy = APLWKWebViewMailtoLinkHandlingPolicyAutomatic;
    return [super initWithCoder:coder];
}

#pragma mark - Appearance callbacks

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loadThreshold = 0.9;
    self.hideProgressViewDelay = 0.3;

    [self addWebViewIfNeeded];
    [self observeWebView:self.webView];
    [self addProgressView];
    [self setupToolbarIfNeeded];

    if (self.pendingLoadRequest) {
        [self.webView loadRequest:self.pendingLoadRequest];
        self.pendingLoadRequest = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.isToolbarHidden = [self.navigationController isToolbarHidden];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationController.toolbarHidden = [self.toolbarItems count] == 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.toolbarHidden = self.isToolbarHidden;
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
        NSArray *loadThresholdCompletionHandlers = self.pendingLoadThresholdReachedCompletionHandlers;
        self.pendingLoadThresholdReachedCompletionHandlers = nil;

        for (void (^completionHandler)(void) in loadThresholdCompletionHandlers) {
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

    if ([delegate respondsToSelector:@selector(aplWebViewController:)]) {
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

- (void)addProgressView {
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

-(void)setupToolbarIfNeeded {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(showToolbar:withSuggestedControlItems:)]) {
        NSArray *items = [self.aplWebViewDelegate showToolbar:self withSuggestedControlItems:[self suggestedToolbarItems]];

        [self updateToolbarItems];
        self.toolbarItems = items;
    }
}

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

- (NSArray<UIBarButtonItem*> *)suggestedToolbarItems {
    UIBarButtonItem *backButtonItem = self.backButtonItem;
    UIBarButtonItem *forwardButtonItem = self.forwardButtonItem;
    UIBarButtonItem *reloadButtonItem = self.reloadButtonItem;
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                            target:nil
                                                                            action:nil];
    spacer.width = 32;

    UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:nil
                                                                                action:nil];

    if (self.preferredControlEnabledTintColor) {
        backButtonItem.tintColor = self.preferredControlEnabledTintColor;
        forwardButtonItem.tintColor = self.preferredControlEnabledTintColor;
        reloadButtonItem.tintColor = self.preferredControlEnabledTintColor;
    }
    return @[backButtonItem, spacer, forwardButtonItem, flexSpacer, reloadButtonItem];
}

- (void)setEnabled:(BOOL)enabled andColorForBarButtonItem:(UIBarButtonItem *)item {
    item.enabled = enabled;

    if (self.preferredControlEnabledTintColor && self.preferredControlDisabledTintColor) {
        item.tintColor = enabled ? self.preferredControlEnabledTintColor : self.preferredControlDisabledTintColor;
    }
}

- (void)updateToolbarItems {
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
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:kAPLWKWebViewKVOContext];
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
    // The idea is not to wait for the whole page, including all advertisements, to have loaded,
    // but for the DOM to be ready, where the page already appears to the user although some elements
    // may still be missing.
    if (_didFinishDOMLoad) {
        return;
    }

    [self.webView evaluateJavaScript:@"document.readyState != \"loading\" && document.readyState != \"uninitialized\"" completionHandler:^(id _Nullable finished, NSError * _Nullable error) {
        if ([finished boolValue]) {
            self->_didFinishDOMLoad = YES;
            [self scheduleHideProgressViewTimerAfter:self->_hideProgressViewDelay];
            if ([self->_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangeLoadingState:)]) {
                [self->_aplWebViewDelegate aplWebViewController:self didChangeLoadingState:NO];
            }
            [self updateToolbarItems];
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
        CGFloat newProgress = [change[NSKeyValueChangeNewKey] floatValue];
        CGFloat oldProgress = [change[NSKeyValueChangeOldKey] floatValue];

        if (!_hideProgressViewTimer) {
            // While _hideProgressViewTimer exists, the progress is clamped to 100%.
            // When navigation while loading, animating the "back jump" of
            // progress looks odd, don't do that.
            BOOL shouldAnimateChange = newProgress > oldProgress;
            [_progressView setProgress:newProgress animated:shouldAnimateChange];
        }

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
            [self cancelHideProgressViewTimer];
            _didFinishDOMLoad = NO;
            _reloadButtonItem.enabled = NO;
            _progressView.hidden = NO;
        }
        if (!loading) {
            // When using the DOM ready event, DOM ready is the signal for
            // completion, not the loading state.
            if (!_useDOMReadyEvent) {
                [self scheduleHideProgressViewTimerAfter:self->_hideProgressViewDelay];
            } else {
                [self checkDOMReady];
            }

            _reloadButtonItem.enabled = YES;
        }
        if ([_aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didChangeLoadingState:)]) {
            [_aplWebViewDelegate aplWebViewController:self didChangeLoadingState:loading];
        }
        [self updateToolbarItems];
    } else if ([keyPath isEqualToString:@"canGoBack"] || [keyPath isEqualToString:@"canGoForward"]) {
        [self updateToolbarItems];
        
        if ([_aplWebViewDelegate respondsToSelector:@selector(aplWebViewControllerDidChangeBrowserHistory:)]) {
            [_aplWebViewDelegate aplWebViewControllerDidChangeBrowserHistory:self];
        }
    }
}

#pragma mark - Smooth Progress View Hiding

- (void)scheduleHideProgressViewTimerAfter:(NSTimeInterval)delay {
    [_hideProgressViewTimer invalidate];
    [_progressView setProgress:1 animated:NO];
    _hideProgressViewTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(hideProgressViewTimerDidFire:) userInfo:nil repeats:NO];
}

- (void)cancelHideProgressViewTimer {
    [_hideProgressViewTimer invalidate];
    _hideProgressViewTimer = nil;
}

- (void)hideProgressViewTimerDidFire:(NSTimer *)timer {
    [self cancelHideProgressViewTimer];
    _progressView.hidden = YES;
    _progressView.progress = 0;
}

#pragma mark - WKNavigationDelegate and Forwardings

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    void (^decisionHandlerForMailtoLinkHandlingPolicy)(WKNavigationActionPolicy);
    
    switch (self.mailtoLinkHandlingPolicy) {
        case APLWKWebViewMailtoLinkHandlingPolicyCustom:
            decisionHandlerForMailtoLinkHandlingPolicy = decisionHandler;
            break;
        // defaulting to 'APLWKWebViewMailtoLinkHandlingPolicyAutomatic' for compatibility sake
        default:
            decisionHandlerForMailtoLinkHandlingPolicy = [self decisionHandlerWithMailtoHandlingForDecisionHandler:decisionHandler navigationAction:navigationAction];
            break;
    }

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.aplWebViewDelegate aplWebViewController:self decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandlerForMailtoLinkHandlingPolicy];
    } else {
        decisionHandlerForMailtoLinkHandlingPolicy(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didCommitNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFailNavigation:withError:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:didFinishNavigation:)]) {
        [self.aplWebViewDelegate aplWebViewController:self didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
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


#pragma mark - WKUIDelegate and Forwardings

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if ([self.aplWebViewUIDelegate respondsToSelector:@selector(aplWebViewController:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [self.aplWebViewUIDelegate aplWebViewController:self createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }

    if (!navigationAction.targetFrame.isMainFrame) {
        NSURLRequest *request = navigationAction.request;
        NSURL *targetURL = request.URL;
        if (!request || !targetURL) {
            return nil;
        }

        switch (self.targetBlankPolicy) {
            case APLWKWebViewTargetBlankPolicyOpenExternally:
                [[UIApplication sharedApplication] openURL:targetURL options:@{} completionHandler:nil];
                break;

            case APLWKWebViewTargetBlankPolicyOpenInSameWebView:
                [self loadRequest:request];
                break;

            default:
                break;
        }
    }

    return nil;
}


- (void)webViewDidClose:(WKWebView *)webView {
    if ([self.aplWebViewUIDelegate respondsToSelector:@selector(aplWebViewControllerDidClose:)]) {
        [self.aplWebViewUIDelegate aplWebViewControllerDidClose:self];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if ([self.aplWebViewUIDelegate respondsToSelector:@selector(aplWebViewController:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.aplWebViewUIDelegate aplWebViewController:self runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    if ([self.aplWebViewUIDelegate respondsToSelector:@selector(aplWebViewController:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.aplWebViewUIDelegate aplWebViewController:self runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        completionHandler(NO); // == Cancel, default behavior if selector unimplemented
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    if ([self.aplWebViewUIDelegate respondsToSelector:@selector(aplWebViewController:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]) {
        [self.aplWebViewUIDelegate aplWebViewController:self runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        completionHandler(nil); // == Cancel, default behavior if selector unimplemented
    }
}


#pragma mark - mailto: link handling

- (void(^)(WKNavigationActionPolicy))decisionHandlerWithMailtoHandlingForDecisionHandler:(void(^)(WKNavigationActionPolicy))decisionHandler navigationAction:(WKNavigationAction *)navigationAction {
    NSURLRequest *request = navigationAction.request;
    NSArray<NSString *> *recipients = request.aplWKWWmailRecipients;
    BOOL canSendMail = [MFMailComposeViewController canSendMail];

    if (canSendMail && request.aplWKWWisMailtoRequest && recipients.count > 0) {
        return ^(WKNavigationActionPolicy policy){
            if (policy != WKNavigationActionPolicyAllow) {
                decisionHandler(policy);
            } else {
                [self presentMailComposeViewControllerForRecipients:recipients decisionHandler:decisionHandler];
            }
        };
    } else {
        return decisionHandler;
    }
}

- (void)presentMailComposeViewControllerForRecipients:(NSArray<NSString *> *)recipients decisionHandler:(void(^)(WKNavigationActionPolicy))decisionHandler {
    NSString *subjectLine = @"";

    if ([self.aplWebViewDelegate respondsToSelector:@selector(aplWebViewController:subjectLineForMailtoRecipients:)]) {
        subjectLine = [self.aplWebViewDelegate aplWebViewController:self subjectLineForMailtoRecipients:recipients];
    }

    if (!subjectLine) {
        // The delegate vetoed the MFMailComposeViewController's presentation.
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    MFMailComposeViewController* composeVC = [MFMailComposeViewController new];
    composeVC.mailComposeDelegate = self;

    composeVC.toRecipients = recipients;
    composeVC.subject = subjectLine;

    [self presentViewController:composeVC animated:YES completion:nil];
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
