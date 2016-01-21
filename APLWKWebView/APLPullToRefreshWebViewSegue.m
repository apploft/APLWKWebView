//
//  APLPullToRefreshWebViewSegue.m
//  Stiftunglife
//
//  Created by Arbeit on 21.01.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "APLPullToRefreshWebViewSegue.h"
#import "APLWKWebViewController.h"

@implementation APLPullToRefreshWebViewSegue

- (void)perform {
    APLWKWebViewController *source = self.sourceViewController;
    APLWKWebViewController *destination = self.destinationViewController;
    UINavigationController *navigationController = source.navigationController;
    UIView *snapshot = [source.webView snapshotViewAfterScreenUpdates:NO];
    
    [destination.view addSubview:snapshot];
    [destination.view sendSubviewToBack:snapshot];
    destination.webView.alpha = 0;
    
    [navigationController pushViewController:destination animated:NO];
    
    __weak APLWKWebViewController *weakDestination = destination;
    [destination addLoadThresholdReachedHandlerForNextLoad:^{
        weakDestination.webView.alpha = 1;
        [snapshot removeFromSuperview];
    }];
}

@end
