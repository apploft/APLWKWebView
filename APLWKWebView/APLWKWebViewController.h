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

/**
 `APLWKWebViewDelegate` is the `APLWKWebView`'s delegate set via its aplDelegate property.
 */

@protocol APLWKWebViewDelegate <NSObject>

@optional

/**
 There are two flavours of the Safari-like swipe navigation: You either return
 a fresh `APLWKWebViewController` instance or your own subclass. Then it is pushed
 when a link is clicked. Or you return `nil` or don't respond to this selector at all,
 which automatically sets the `WKWebView`'s `shouldEnableNavigationGestures` property
 to yes.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 */
- (APLWKWebViewController *)aplWebViewControllerFreshInstanceForPush:(APLWKWebViewController *)webViewController;

/**
 This method is called when the user performs a scroll gesture in the web view.
 A Safari-like behaviour is achieved when hiding and unhiding the toolbar here.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 
 @param hideToolbar whether the toolbar should be displayed or hidden.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController toolbarShouldHide:(BOOL)hideToolbar;

/**
 A pull-to-refresh gesture has been fully triggered and the web view starts reloading.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 */
- (void)aplWebViewDidTriggerPullToRefresh:(APLWKWebViewController *)webViewController;

/**
 The web view did finish loading after pull to refresh, the pull-to-refresh controll will hide.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 */
- (void)aplWebViewDidFinishPullToRefresh:(APLWKWebViewController *)webViewController;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didCommitNavigation:(WKNavigation *)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didFinishNavigation:(WKNavigation *)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
           completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                       NSURLCredential *credential))completionHandler;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didStartProvisionalNavigation:(WKNavigation *)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
             decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
             decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

/**
 Called when the page starts or finished loading. To imitate Safari's behaviour,
 unhide the toolbar once loading starts.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 
 @param isLoadingNow whether loading starts or finishes
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didChangeLoadingState:(BOOL)isLoadingNow;

/**
 The window's title should be updated. Use `APLWKWebView`'s `useContentPageTitle` property
 in order to automatically set the view controller's title.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 
 @param pageTitle the new page title that was extracted from the page
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController didChangePageTitle:(NSString *)pageTitle;

/**
  If you want to customise the `WKWebView`'s `configuration`, implement this method.
 
  Subclassing notes: If you want to subclass `APLWKWebViewController`, make sure to set the
  `aplWebViewDelegate` BEFORE calling [super viewDidLoad]. Else this method will not be
  called.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 
 @param containingViewController the `UIViewController` instance the `WKWebView` is about to be installed
 */
- (WKWebViewConfiguration *)aplWebViewController:(APLWKWebViewController *)webViewController
         configurationForWebViewInViewController:(UIViewController *)containingViewController;

@end

/**
 `APLWKWebViewController` combines `WKWebView` with pull-to-refresh handling
 and a convenient Safari-like navigation bottom bar.
 
 */

@interface APLWKWebViewController : APLPullToRefreshContainerViewController<APLPullToRefreshContainerDelegate, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) CGFloat loadThreshold;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic, weak) id<APLWKWebViewDelegate> aplWebViewDelegate;
@property (nonatomic, getter=usesContentPageTitle) BOOL useContentPageTitle;
@property (nonatomic, getter=usesDOMReadyEvent) BOOL useDOMReadyEvent;


@property (nonatomic) UIBarButtonItem *backButtonItem;
@property (nonatomic) UIBarButtonItem *forwardButtonItem;

- (void)resetWebView;

#pragma mark - View Controller Appearence
- (void)updateNavigationItemTitle:(NSString *)newTitle;

#pragma mark - Pull To Refresh handling
- (void)loadRequest:(NSURLRequest *)request;
- (void)finishPullToRefresh;
- (void)addLoadThresholdReachedHandlerForNextLoad:(void(^)(void))loadThresholdReachedHandler;

#pragma mark - Push Handling
- (void)pushNavigationAction:(WKNavigationAction *)action;

#pragma mark - Navigation Tool Bar
/**
 Returns a suggestion of items for the navigation bottom toolbar. You may change
 anything as long as you leave the items' original target and action intact. You
 may e.g. install anything but the refresh item or whatever.
 
 @param color The items' tint color when they are active
 
 @param disabledColor The items' tint color when they are disabled, e.g. you cannot navigate further back
 
 @return An array of suggested items in this order: [back item, spacer, forward item, spacer, refresh item].
 */
- (NSArray *)suggestedToolbarItemsForNormalTintColor:(UIColor *)color disabledTintColor:(UIColor *)disabledColor;

@end
