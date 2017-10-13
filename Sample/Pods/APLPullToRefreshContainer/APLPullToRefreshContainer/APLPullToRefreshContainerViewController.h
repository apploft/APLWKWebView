//
//  APLPullToRefreshContainerViewController.h
//  APLPullToRefreshContainer
//
//  Created by Nico Schümann on 09.09.15.
//  Copyright (c) 2015 apploft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^APLPullToRefreshCompletionHandler)(void);

@protocol APLPullToRefreshView <NSObject>

@optional
- (void)aplPullToRefreshStartAnimating;
- (void)aplPullToRefreshStopAnimating;
- (void)aplPullToRefreshProgressUpdate:(CGFloat)progress beyondThreshold:(BOOL)beyondThreshold;

@end

@protocol APLPullToRefreshContainerDelegate <NSObject>

- (UIScrollView *)aplPullToRefreshContentScrollView;
- (UIView<APLPullToRefreshView> *)aplPullToRefreshPullToRefreshView;
- (void)aplDidTriggerPullToRefreshCompletion:(APLPullToRefreshCompletionHandler)completionHandler;

@optional
- (UIColor *)aplPullToRefreshContainerViewBackgroundColor;
- (void)aplPullToRefreshDidInstallPullToRefreshView:(id<APLPullToRefreshView>)pullToRefreshView;

@end


@interface APLPullToRefreshContainerViewController : UIViewController

@property (nonatomic, weak) UIViewController<APLPullToRefreshContainerDelegate> *delegate;

@end
