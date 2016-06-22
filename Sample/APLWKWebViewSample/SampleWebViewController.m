//
//  SampleWebViewController.m
//  APLWKWebViewSample
//
//  Created by Nico Schümann on 05.04.16.
//  Copyright © 2016 apploft. All rights reserved.
//

#import "SampleWebViewController.h"
#import "RefreshView.h"

@interface SampleWebViewController () <APLWKWebViewDelegate>

@end

@implementation SampleWebViewController

- (void)viewDidLoad {
    /*
     * Basic APLWKWebViewController setup.
     */
    self.aplWebViewDelegate = self;

    [super viewDidLoad];
    self.useContentPageTitle = YES;
    self.toolbarItems = [self suggestedToolbarItemsForNormalTintColor:[UIColor blueColor] disabledTintColor:[UIColor grayColor]];
    
    
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.heise.de"]]];
}

- (void)aplWebViewController:(APLWKWebViewController *)webViewController toolbarShouldHide:(BOOL)hideToolbar {
    
    /*
     * Automatic Navigation Bar hiding/unhiding on scroll events.
     */
    self.navigationController.toolbarHidden = hideToolbar;
}

- (void)aplWebViewController:(APLWKWebViewController *)webViewController didChangeLoadingState:(BOOL)isLoadingNow {
    
    /*
     * Imitate Safari's behaviour: Show the bottom tool bar once loading starts.
     */
    if (isLoadingNow) {
        self.navigationController.toolbarHidden = NO;
    }
}

- (UIView<APLPullToRefreshView> *)aplPullToRefreshPullToRefreshView {
    
    /*
     * Our RefreshView instance that is used as a PullToRefresh view.
     */
    return [RefreshView instantiateFromNib];
}

@end
