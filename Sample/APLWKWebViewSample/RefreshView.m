//
//  ZONNewRefreshView.m
//  APLWKWebViewSample
//
//  Created by Nico Schümann on 15.01.16.
//  Copyright © 2016 apploft GmbH. All rights reserved.
//

#import "RefreshView.h"

@implementation RefreshView

+ (RefreshView *)instantiateFromNib {
    return [[UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil] instantiateWithOwner:nil options:nil][0];
}

- (void)aplPullToRefreshProgressUpdate:(CGFloat)progress beyondThreshold:(BOOL)beyondThreshold {
    self.loadingArrowImageView.transform = CGAffineTransformMakeRotation(-2 * progress * M_PI);
}

- (void)aplPullToRefreshStartAnimating {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.loadingArrowImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)aplPullToRefreshStopAnimating {
    [self.loadingArrowImageView.layer removeAllAnimations];
    self.loadingArrowImageView.transform = CGAffineTransformIdentity;
}

@end
