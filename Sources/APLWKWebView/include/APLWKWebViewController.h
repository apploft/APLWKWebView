//
//  APLWKWebViewController.h
//
//  Copyright © 2021 apploft. All rights reserved.
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
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
           toolbarShouldHide:(BOOL)hideToolbar;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
         didCommitNavigation:(WKNavigation * _Nonnull)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
           didFailNavigation:(WKNavigation * _Nonnull)navigation
                   withError:(NSError * _Nullable)error;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
didFailProvisionalNavigation:(WKNavigation * _Nonnull)navigation
                   withError:(NSError * _Nullable)error;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
         didFinishNavigation:(WKNavigation * _Nonnull)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge * _Nonnull)challenge
           completionHandler:(void (^ _Nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
didReceiveServerRedirectForProvisionalNavigation:(WKNavigation * _Nonnull)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
didStartProvisionalNavigation:(WKNavigation * _Nonnull)navigation;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
decidePolicyForNavigationAction:(WKNavigationAction * _Nonnull)navigationAction
             decisionHandler:(void (^ _Nonnull)(WKNavigationActionPolicy))decisionHandler;

/**
 Same as the corresponding `WKNavigationDelegate` method.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
decidePolicyForNavigationResponse:(WKNavigationResponse * _Nonnull)navigationResponse
             decisionHandler:(void (^ _Nonnull)(WKNavigationResponsePolicy))decisionHandler;

/**
 Called when the page starts or finished loading. To imitate Safari's behaviour,
 unhide the toolbar once loading starts.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 @param isLoadingNow whether loading starts or finishes
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
       didChangeLoadingState:(BOOL)isLoadingNow;

/**
 The window's title should be updated. Use `APLWKWebView`'s `useContentPageTitle` property
 in order to automatically set the view controller's title.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 @param pageTitle the new page title that was extracted from the page
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController
          didChangePageTitle:(NSString * _Nullable)pageTitle;

/**
  If you want to customise the `WKWebView`'s `configuration`, implement this method.
 
  Subclassing notes: If you want to subclass `APLWKWebViewController`, make sure to set the
  `aplWebViewDelegate` BEFORE calling [super viewDidLoad]. Else this method will not be
  called.
 
 @param webViewController the `APLWKWebViewController` instance that calls this delegate method.
 */
- (WKWebViewConfiguration * _Nonnull)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController;

/**
    Implement this delegate method if you want to show a toolbar with web view control elements.
    @param suggestedToolbarItems an array of suggested toolbar items in the following order:  [back-item, spacer, forward-item, spacer, refresh-item]
    @return You may return a modified array by removing elements or changing the order of elements. Alternatively you can return 'nil' in which case no
    toolbar will be shown.
 */
- (NSArray<UIBarButtonItem*> * _Nullable)showToolbar:(APLWKWebViewController* _Nonnull)webViewController
         withSuggestedControlItems:(NSArray<UIBarButtonItem*> * _Nonnull)suggestedToolbarItems;

@end

/**
 `APLWKWebViewController` combines `WKWebView` and a convenient Safari-like navigation bottom bar.
 */

@interface APLWKWebViewController : UIViewController<WKNavigationDelegate, WKUIDelegate>

/// Read only access to certain properties. Don't fiddle with the target and action properties of the bar button items.
@property (nonatomic, readonly, strong) WKWebView * _Nonnull webView;
@property (nonatomic, readonly, strong) UIProgressView * _Nonnull progressView;
@property (nonatomic, readonly, strong) UIBarButtonItem * _Nonnull backButtonItem;
@property (nonatomic, readonly, strong) UIBarButtonItem * _Nonnull forwardButtonItem;
@property (nonatomic, readonly, strong) UIBarButtonItem * _Nonnull reloadButtonItem;

@property (nonatomic, weak) id<APLWKWebViewDelegate> _Nullable aplWebViewDelegate;

/// The threshold for calling the load threshold handler registered via 'addLoadThresholdReachedHandlerForNextLoad'.
/// The default value of this property is 0.9.
@property (nonatomic) CGFloat loadThreshold;

/// Automatically set the title of the HTML page as navigation bar title
@property (nonatomic, getter=usesContentPageTitle) BOOL useContentPageTitle;

/// Use the document 'readyState' to determine when to end the loading indicator. Default value is 'NO'.
/// see: [Document.readyState](https://developer.mozilla.org/de/docs/Web/API/Document/readyState)
@property (nonatomic, getter=usesDOMReadyEvent) BOOL useDOMReadyEvent;

/// If you want to show a toolbar (see delegate method 'showToolbarWithSuggestedControlItems:...') determine the
/// tint color of these control elements.
@property (nonatomic, strong) UIColor * _Nullable preferredControlEnabledTintColor;
@property (nonatomic, strong) UIColor * _Nullable preferredControlDisabledTintColor;

- (void)resetWebView;

- (void)loadRequest:(NSURLRequest * _Nonnull)request;

/// Register a handler being called when the load threshold has been reached
/// @param loadThresholdReachedHandler <#loadThresholdReachedHandler description#>
- (void)addLoadThresholdReachedHandlerForNextLoad:(void (^ _Nullable)(void))loadThresholdReachedHandler;

@end
