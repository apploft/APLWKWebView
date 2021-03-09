//
//  APLWKWebViewController.h
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

@import UIKit;
@import WebKit;

@class APLWKWebViewController;

/**
 `APLWKWebViewDelegate` is the `APLWKWebView`'s delegate set via its aplDelegate property.
 */

@protocol APLWKWebViewDelegate <NSObject>

@optional

/**
 This method is called when the user performs a scroll gesture in the web view.
 A Safari-like behaviour is achieved when hiding and unhiding the toolbar here.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 
 @param hideToolbar whether the toolbar should be displayed or hidden.
 */
- (void)aplWebViewController:(APLWKWebViewController *)webViewController toolbarShouldHide:(BOOL)hideToolbar;

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
 */
- (WKWebViewConfiguration * _Nonnull)aplWebViewController:(APLWKWebViewController *)webViewController;

@end

/**
 `APLWKWebViewController` combines `WKWebView` and a convenient Safari-like navigation bottom bar.
 */

@interface APLWKWebViewController : UIViewController<WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, readonly, strong) WKWebView *webView;
@property (nonatomic, readonly, strong) UIProgressView *progressView;
@property (nonatomic, readonly, strong) UIBarButtonItem *backButtonItem;
@property (nonatomic, readonly, strong) UIBarButtonItem *forwardButtonItem;
@property (nonatomic, readonly, strong) UIBarButtonItem *reloadButtonItem;

@property (nonatomic, weak) id<APLWKWebViewDelegate> aplWebViewDelegate;

/// The threshold for calling the load threshold handler registered via 'addLoadThresholdReachedHandlerForNextLoad'.
/// The default value of this property is 0.9.
@property (nonatomic) CGFloat loadThreshold;

@property (nonatomic, getter=usesContentPageTitle) BOOL useContentPageTitle;
@property (nonatomic, getter=usesDOMReadyEvent) BOOL useDOMReadyEvent;

- (void)resetWebView;

- (void)loadRequest:(NSURLRequest *)request;

/// Register a handler being called when the load threshold has been reached
/// @param loadThresholdReachedHandler <#loadThresholdReachedHandler description#>
- (void)addLoadThresholdReachedHandlerForNextLoad:(void (^)(void))loadThresholdReachedHandler;

#pragma mark - Suggested Toolbar Items

/**
 Returns a suggestion of items for the navigation toolbar. The returned array will contain in the following order a backward, spacer, forward,
 spacer and reload bar button item. You may change anything as long as you leave the items' original target and action intact.
 You may e.g. install anything but the reload item or whatever.
 
 @param color The items' tint color when they are active
 @param disabledColor The items' tint color when they are disabled, e.g. you cannot navigate further back
 @return An array of suggested items in this order: [back item, spacer, forward item, spacer, refresh item].
 */
- (NSArray * _Nonnull)suggestedToolbarItemsForNormalTintColor:(UIColor * _Nonnull)color disabledTintColor:(UIColor * _Nonnull)disabledColor;

@end
