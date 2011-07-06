//
//  DSMapBoxAlphaModalManager.h
//  MapBoxiPad
//
//  Created by Justin Miller on 7/6/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSFingerTipWindow;

@interface DSMapBoxAlphaModalManager : NSObject
{
    DSFingerTipWindow *modalWindow;
    UIWindow *shieldWindow;
}

+ (DSMapBoxAlphaModalManager *)defaultManager;

- (void)presentModalViewController:(UIViewController *)modalViewController overView:(UIView *)view animated:(BOOL)animated;
- (void)dismissModalViewControllerAnimated:(BOOL)animated;

@end