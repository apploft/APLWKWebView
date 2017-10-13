//
//  APLPullToRefreshContainerViewController.m
//  APLPullToRefreshContainer
//
//  Created by Nico Schümann on 09.09.15.
//  Copyright (c) 2015 apploft. All rights reserved.
//

#import "APLPullToRefreshContainerViewController.h"

static const CGFloat APLPullToRefreshTriggerThreshold = 0.9;
static const CGFloat APLPullToRefreshAnimationDuration = 0.2;

@interface APLPullToRefreshContainerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIPanGestureRecognizer *gestureRecognizer;
@property (nonatomic, weak) UIView<APLPullToRefreshView> *currentPullToRefreshView;
@property (nonatomic, weak) UIScrollView *currentGestureScrollView;
@property (nonatomic, weak) NSLayoutConstraint *bottomConstraint;
@property (nonatomic) CGFloat pullToRefreshViewHeight;
@property (nonatomic) BOOL pullToRefreshInProgress;
@property (nonatomic) BOOL scrollViewShowsScrollIndicator;

// As an optimization, only bother updating the scroll view insets if
// the layout guides changed

@property (nonatomic) CGFloat lastBottomLayoutValue;
@property (nonatomic) CGFloat lastTopLayoutValue;

@end

@implementation APLPullToRefreshContainerViewController

#pragma mark - Storyboard handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"aplContent"]) {
        _delegate = segue.destinationViewController;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    UIPanGestureRecognizer *gr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    gr.delegate = self;
    _gestureRecognizer = gr;
    [self.view addGestureRecognizer:gr];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLayoutLentgh = [self.topLayoutGuide length];
    CGFloat bottomLayoutLength = [self.bottomLayoutGuide length];
    
    if (_lastTopLayoutValue == topLayoutLentgh && _lastBottomLayoutValue == bottomLayoutLength) {
        return;
    }
    _lastBottomLayoutValue = bottomLayoutLength;
    _lastTopLayoutValue = topLayoutLentgh;
    
    if (_delegate.automaticallyAdjustsScrollViewInsets) {
        [self setChildContentInsetWithTopOffset:0 forceApplyingLayoutGuides:NO];
    }
    
    if (_pullToRefreshInProgress) {
        /*
         * Most likely a rotation event.
         */
        _bottomConstraint.constant = _pullToRefreshViewHeight + topLayoutLentgh;
    }
}

- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer {
    UIGestureRecognizerState state = gestureRecognizer.state;
    if (state == UIGestureRecognizerStateBegan) {
        _currentGestureScrollView = [_delegate aplPullToRefreshContentScrollView];
        _scrollViewShowsScrollIndicator = _currentGestureScrollView.showsVerticalScrollIndicator;
    }
    
    CGPoint contentOffset = _currentGestureScrollView.contentOffset;
    CGFloat progress = (-contentOffset.y - _lastTopLayoutValue) / _pullToRefreshViewHeight;
    
    if (!_currentPullToRefreshView && contentOffset.y < 0) {
        /*
         * Over-scrolling just started.
         */
        [self addPullToRefreshView];
    } else if (state == UIGestureRecognizerStateEnded && _currentPullToRefreshView) {
        /*
         * When the pan gesture ends, decide whether there was enough scrolling
         * or not.
         */
        if (progress >= APLPullToRefreshTriggerThreshold) {
            [self didTriggerPullToRefreshWithContentOffset:contentOffset];
        } else {
            [self didCancelPullToRefresh];
        }
    } else {
        /*
         * Determine how much was over-scrolled and set the pull to refresh
         * view's origin accordingly.
         */
        _bottomConstraint.constant = -contentOffset.y;
        CGFloat alphaProgress = fmin(progress, 1);
        alphaProgress = fmax(0, alphaProgress);
        _currentPullToRefreshView.alpha = alphaProgress;
        if ([_currentPullToRefreshView respondsToSelector:@selector(aplPullToRefreshProgressUpdate:beyondThreshold:)]) {
            [_currentPullToRefreshView aplPullToRefreshProgressUpdate:alphaProgress beyondThreshold:progress >= APLPullToRefreshTriggerThreshold];
        }
        
        if (_scrollViewShowsScrollIndicator) {
            _currentGestureScrollView.showsVerticalScrollIndicator = progress < APLPullToRefreshTriggerThreshold;
        }
    }
}

- (void)setChildContentInsetWithTopOffset:(CGFloat)topOffset forceApplyingLayoutGuides:(BOOL)forceApplyLayoutGuides {
    CGFloat topLayoutGuideLength = 0;
    CGFloat bottomLayoutGuideLength = 0;
    
    if (forceApplyLayoutGuides || _delegate.automaticallyAdjustsScrollViewInsets) {
        topLayoutGuideLength = [self.topLayoutGuide length];
        bottomLayoutGuideLength = [self.bottomLayoutGuide length];
    }
    UIScrollView *scrollView = _currentGestureScrollView ?: [_delegate aplPullToRefreshContentScrollView];
    UIEdgeInsets contentInset = UIEdgeInsetsMake(topLayoutGuideLength + _pullToRefreshViewHeight, 0,
                                                 bottomLayoutGuideLength, 0);
    scrollView.contentInset = contentInset;
    scrollView.scrollIndicatorInsets = contentInset;
}

- (void)addPullToRefreshView {
    UIView<APLPullToRefreshView> *pullToRefreshView = [_delegate aplPullToRefreshPullToRefreshView];
    if (!pullToRefreshView) {
        return;
    }

    UIView *view = self.view;
    if ([_delegate respondsToSelector:@selector(aplPullToRefreshContainerViewBackgroundColor)]) {
        view.backgroundColor = [_delegate aplPullToRefreshContainerViewBackgroundColor];
    }
    
    pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:pullToRefreshView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1. constant:0];
    
    
    [view addSubview:pullToRefreshView];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pullToRefreshView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(pullToRefreshView)]];
    [view addConstraint:constraint];
    [view bringSubviewToFront:pullToRefreshView];
    
    _bottomConstraint = constraint;
    _currentPullToRefreshView = pullToRefreshView;
    _pullToRefreshViewHeight = pullToRefreshView.bounds.size.height;
    
    if ([_delegate respondsToSelector:@selector(aplPullToRefreshDidInstallPullToRefreshView:)]) {
        [_delegate aplPullToRefreshDidInstallPullToRefreshView:pullToRefreshView];
    }
    
    [view layoutIfNeeded];
    pullToRefreshView.alpha = 0;
    constraint.constant = 0;
}

- (void)removePullToRefreshView {
    [_currentPullToRefreshView removeFromSuperview];
    _currentPullToRefreshView = nil;
    _currentGestureScrollView = nil;
    _bottomConstraint = nil;
    _gestureRecognizer.enabled = YES;
}

- (void)scrollBack {
    [_currentPullToRefreshView layoutIfNeeded];
    _bottomConstraint.constant = _lastTopLayoutValue;
    [UIView animateWithDuration:APLPullToRefreshAnimationDuration animations:^{
        [_currentPullToRefreshView layoutIfNeeded];
        _currentPullToRefreshView.alpha = 0;
        _pullToRefreshViewHeight = 0;
        [self setChildContentInsetWithTopOffset:0 forceApplyingLayoutGuides:YES];
    } completion:^(BOOL finished) {
        [self removePullToRefreshView];
        _pullToRefreshInProgress = NO;
    }];
}

- (void)didTriggerPullToRefreshWithContentOffset:(CGPoint)contentOffset {
    _pullToRefreshInProgress = YES;
    _bottomConstraint.constant = -contentOffset.y;
    CGFloat topLayoutGuide = [self.topLayoutGuide length];
    
    _currentPullToRefreshView.alpha = 1;
    [_currentPullToRefreshView layoutIfNeeded];
    _bottomConstraint.constant = _pullToRefreshViewHeight + topLayoutGuide;
    [_currentGestureScrollView setContentOffset:contentOffset animated:NO];
    
    [UIView animateWithDuration:APLPullToRefreshAnimationDuration animations:^{
        [_currentPullToRefreshView layoutIfNeeded];
        [self setChildContentInsetWithTopOffset:_pullToRefreshViewHeight forceApplyingLayoutGuides:YES];
        _currentGestureScrollView.contentOffset = CGPointMake(0, -_pullToRefreshViewHeight -_lastTopLayoutValue);
    } completion:^(BOOL finished) {
        _currentGestureScrollView.showsVerticalScrollIndicator = _scrollViewShowsScrollIndicator;
    }];
    
    _gestureRecognizer.enabled = NO;
    __weak APLPullToRefreshContainerViewController * weakSelf = self;
    
    __weak UIView<APLPullToRefreshView> *currentPullToRefreshView = _currentPullToRefreshView;
    if ([currentPullToRefreshView respondsToSelector:@selector(aplPullToRefreshStartAnimating)]) {
        [currentPullToRefreshView aplPullToRefreshStartAnimating];
    }
    
    [_delegate aplDidTriggerPullToRefreshCompletion:^{
        [weakSelf scrollBack];
        if ([currentPullToRefreshView respondsToSelector:@selector(aplPullToRefreshStopAnimating)]) {
            [currentPullToRefreshView aplPullToRefreshStopAnimating];
        }
    }];
}

- (void)didCancelPullToRefresh {
    _currentGestureScrollView.showsVerticalScrollIndicator = _scrollViewShowsScrollIndicator;
    [self scrollBack];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    /*
     * Be transparent and don't eat any touches.
     */
    return YES;
}


@end
