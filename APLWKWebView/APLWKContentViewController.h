//
//  APLWKContentViewController.h
//  Stiftunglife
//
//  Created by Arbeit on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WebKit;

@interface APLWKContentViewController : UIViewController

- (WKWebView *)installWebViewDelegate:(id<WKNavigationDelegate, WKUIDelegate>)webViewDelegate;

@end
