//
//  APLWKContentViewController.h
//  APLWKWebView
//
//  Created by Nico Schümann on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WebKit;

/**
 `APLWKContentViewController` contains a `WKWebView`.
 
 Due to the nature of `APLPullToRefreshContainerViewController`, an actual content
 view controller is required, which is this very `APLWKContentViewController`.
 
 All logic is hoisted to `APLWKWebViewController`, though.
 
 ## Subclassing Notes
 
 There should not be any need to subclass this class because everything of interest
 happens in `APLWKWebViewController`.
 
 */

@interface APLWKContentViewController : UIViewController

/**
 Sets the delegate properties of the `WKWebView` this view controller manages
 and returns it.
 
 @param webViewDelegate The delegate `WKWebView`'s `navigationDelegate` and `UIDelegate` properties should be set to.
 
 @return The `WKWebView` this view controller manages
 */
- (WKWebView *)installWebViewDelegate:(id<WKNavigationDelegate, WKUIDelegate>)webViewDelegate;

@end
