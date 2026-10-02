//
//  LoadingFrameViewController.m
//  Moonlight
//
//  Created by Diego Waxemberg on 2/24/15.
//  Copyright (c) 2015 Moonlight Stream. All rights reserved.
//

#import "LoadingFrameViewController.h"
#import "MoonlightAppearance.h"

@implementation LoadingFrameViewController {
    BOOL presented;
    UIView* _loadingPanel;
};

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.opaque = NO;
    self.view.backgroundColor = [MLBackgroundColor() colorWithAlphaComponent:0.6];
    self.loadingSpinner.color = MLAccentColor();
    self.loadingSpinner.isAccessibilityElement = YES;
    self.loadingSpinner.accessibilityLabel = @"Loading";

    _loadingPanel = [[UIView alloc] init];
    _loadingPanel.userInteractionEnabled = NO;
    _loadingPanel.backgroundColor = MLSurfaceColor();
#if TARGET_OS_TV
    _loadingPanel.layer.cornerRadius = 28.0;
#else
    _loadingPanel.layer.cornerRadius = 20.0;
#endif
    _loadingPanel.layer.borderWidth = 1.0;
    _loadingPanel.layer.borderColor = MLBorderColor().CGColor;
    _loadingPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    _loadingPanel.layer.shadowOpacity = 0.25;
    _loadingPanel.layer.shadowRadius = 16.0;
    _loadingPanel.layer.shadowOffset = CGSizeMake(0, 8);
    [self.view insertSubview:_loadingPanel belowSubview:self.loadingSpinner];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

#if TARGET_OS_TV
    CGFloat panelSize = 176.0;
#else
    CGFloat panelSize = 112.0;
#endif
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    self.loadingSpinner.center = center;
    _loadingPanel.frame = CGRectMake(center.x - panelSize / 2, center.y - panelSize / 2, panelSize, panelSize);
    _loadingPanel.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_loadingPanel.bounds
                                                             cornerRadius:_loadingPanel.layer.cornerRadius].CGPath;
}

- (UIViewController*) activeViewController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)showLoadingFrame:(void (^)(void))completion {
    if (!presented) {
        Log(LOG_I, @"Loading frame presenting start");
        presented = YES;
        [[self activeViewController] presentViewController:self animated:NO completion:^{
            Log(LOG_I, @"Loading frame presenting complete");
            if (completion) {
                completion();
            }
        }];
    }
    else if (completion) {
        Log(LOG_E, @"Loading frame already shown!");
        completion();
    }
}

- (void)dismissLoadingFrame:(void (^)(void))completion {
    if (presented) {
        Log(LOG_I, @"Loading frame hiding start");
        [self dismissViewControllerAnimated:NO completion:^{
            Log(LOG_I, @"Loading frame hiding complete");
            
            // Since presented is set to NO here rather than
            // immediately in dismissLoadingFrame, we may
            // falsely avoid displaying the loading frame if
            // a dismiss is in progress while attempting to show
            // the frame. That's preferable to crashing due to
            // displaying the same VC twice though.
            //
            // This scenario can happen if the app is suspended
            // while the dismiss is in progress then on resume
            // it attempts to display it again before the dismiss
            // completes. It can be reproduced by rapidly pressing
            // Home and switching back to Moonlight while in the app grid.
            // It reproduces more easily if the VC transitions are animated.
            self->presented = NO;
            
            if (completion) {
                completion();
            }
        }];
    }
    else if (completion) {
        completion();
    }
}

- (BOOL)isShown {
    return presented;
}

@end
