//
//  APLWKWebViewController.h
//
//  Copyright © 2021 apploft. All rights reserved.
//

@import UIKit;
@import WebKit;

@class APLWKWebViewController;

/**
 `APLWKWebViewDelegate` is the `APLWKWebView`'s delegate set via its aplWebViewDelegate property.
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

/**
 This delegate method is called when the user invokes a mailto: link and your `aplWebViewController:decidePolicyForNavigationAction:decisionHandler:
 allows the navigation action. It allows you to specify a subject line for the `MFMailComposeViewController` or to veto its presentation by returning nil.
 If the whole delegate method is unimplemented, the `MFMailComposeViewController` is presented with a blank subject.
 @return A (possibly zero-length) subject line to prefill in the `MFMailComposeViewController`. Nil to supress presentation of the `MFMailComposeViewController`.
 */
- (NSString * _Nullable)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController subjectLineForMailtoRecipients:(NSArray<NSString *> * _Nonnull)recipients;

@end

/**
 `APLWKWebViewUIDelegate` is the `APLWKWebView`'s UI delegate set via its aplUIDelegate property. It mirrors the `WKUIDelegate`.
 */

@protocol APLWKWebViewUIDelegate <NSObject>

@optional

/*! @abstract Creates a new web view.
@param webView The web view controller invoking the delegate method.
@param configuration The configuration to use when creating the new web
view. This configuration is a copy of webView.configuration.
@param navigationAction The navigation action causing the new web view to
be created.
@param windowFeatures Window features requested by the webpage.
@result A new web view or nil.
@discussion The web view returned must be created with the specified configuration. WebKit will load the request in the returned web view.

If you do not implement this method, the load will continue in the same web view controller.
*/
- (nullable WKWebView *)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;

/*! @abstract Notifies your app that the DOM window object's close() method completed successfully.
 @param webView The web view invoking the delegate method.
 @discussion Your app should remove the web view from the view hierarchy and update
 the UI as needed, such as by closing the containing browser tab or window.
 */
- (void)aplWebViewControllerDidClose:(APLWKWebViewController * _Nonnull)webViewController API_AVAILABLE(macos(10.11), ios(9.0));

/*! @abstract Displays a JavaScript alert panel.
 @param webView The web view controller invoking the delegate method.
 @param message The message to display.
 @param frame Information about the frame whose JavaScript initiated this
 call.
 @param completionHandler The completion handler to call after the alert
 panel has been dismissed.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have a single OK button.

 If you do not implement this method, the web view will behave as if the user selected the OK button.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;

/*! @abstract Displays a JavaScript confirm panel.
 @param webView The web view controller invoking the delegate method.
 @param message The message to display.
 @param frame Information about the frame whose JavaScript initiated this call.
 @param completionHandler The completion handler to call after the confirm
 panel has been dismissed. Pass YES if the user chose OK, NO if the user
 chose Cancel.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have two buttons, such as OK and Cancel.

 If you do not implement this method, the web view will behave as if the user selected the Cancel button.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

/*! @abstract Displays a JavaScript text input panel.
 @param webView The web view controller invoking the delegate method.
 @param prompt The prompt to display.
 @param defaultText The initial text to display in the text entry field.
 @param frame Information about the frame whose JavaScript initiated this call.
 @param completionHandler The completion handler to call after the text
 input panel has been dismissed. Pass the entered text if the user chose
 OK, otherwise nil.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have two buttons, such as OK and Cancel, and a field in
 which to enter text.

 If you do not implement this method, the web view will behave as if the user selected the Cancel button.
 */
- (void)aplWebViewController:(APLWKWebViewController * _Nonnull)webViewController runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler;

@end

/// Handling policy for links that require a new window, e. g. `target=_blank` anchors.
typedef NS_ENUM(NSInteger, APLWKWebViewTargetBlankPolicy) {
    APLWKWebViewTargetBlankPolicyOpenExternally,    /// Ask the system to handle the URL request, which probably yields the system browser.
    APLWKWebViewTargetBlankPolicyOpenInSameWebView, /// Load the request in the current web view ignoring `target=_blank`.
};

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
@property (nonatomic, weak) id<APLWKWebViewUIDelegate> _Nullable aplWebViewUIDelegate;

/// The threshold for calling the load threshold handler registered via 'addLoadThresholdReachedHandlerForNextLoad'.
/// The default value of this property is 0.9.
@property (nonatomic) CGFloat loadThreshold;

/// Automatically set the title of the HTML page as navigation bar title
@property (nonatomic, getter=usesContentPageTitle) BOOL useContentPageTitle;

/// Use the document 'readyState' to determine when to end the loading indicator. Default value is 'NO'.
/// see: [Document.readyState](https://developer.mozilla.org/de/docs/Web/API/Document/readyState)
@property (nonatomic, getter=usesDOMReadyEvent) BOOL useDOMReadyEvent;

/// How to handle target=_blank links. Defaults to `APLWKWebViewTargetBlankPolicyOpenExternally`.
/// If you want to customize this behavior, implement the APLWKWebViewUIDelegate's
/// `aplWebViewController:createWebViewWithConfiguration:forNavigationAction:windowFeatures:` method.
@property (nonatomic) APLWKWebViewTargetBlankPolicy targetBlankPolicy;

/// Just hiding the progress view when loading has completed looks artificial. Imitate Safari and
/// fill the progress view to 100%, then wait for 'hideProgressViewDelay' seconds until the progress view is hidden.
/// Default value is 0.3.
@property (nonatomic) NSTimeInterval hideProgressViewDelay;

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
