//
//  ZONNewRefreshView.h
//  APLWKWebViewSample
//
//  Created by Arbeit on 15.01.16.
//  Copyright © 2016 apploft GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <APLPullToRefreshContainer/APLPullToRefreshContainerViewController.h>

@interface RefreshView : UIView <APLPullToRefreshView>

@property (weak, nonatomic) IBOutlet UIImageView *loadingArrowImageView;

+ (instancetype)instantiateFromNib;

@end
