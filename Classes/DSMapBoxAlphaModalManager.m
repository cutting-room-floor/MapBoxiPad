//
//  DSMapBoxAlphaModalManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/6/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxAlphaModalManager.h"

#import "DSFingerTipWindow.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxAlphaModalManager

static DSMapBoxAlphaModalManager *defaultManager;

+ (DSMapBoxAlphaModalManager *)defaultManager
{
    @synchronized(@"DSMapBoxAlphaModalManager")
    {
        if ( ! defaultManager)
            defaultManager = [[self alloc] init];
    }
    
    return defaultManager;
}

#pragma mark -

- (void)presentModalViewController:(UIViewController *)modalViewController overView:(UIView *)view animated:(BOOL)animated
{
    // set to form sheet size
    //
    modalViewController.view.frame = CGRectMake(5, 5, 540, 620);
    
    // create modal window (larger than view for donut-shaped shadow)
    //
    CGRect windowRect = CGRectMake(0, 0, modalViewController.view.bounds.size.width + 10, modalViewController.view.bounds.size.height + 10);
    modalWindow = [[DSFingerTipWindow alloc] initWithFrame:windowRect];
    modalWindow.rootViewController = modalViewController;
    [modalWindow addSubview:modalViewController.view];
    
    // round-rect the modal view
    //
    modalViewController.view.layer.cornerRadius = 5.0;
    modalViewController.view.clipsToBounds = YES;
    
    // add donut-shaped shadow to window
    //
    modalWindow.layer.shadowOpacity = 0.5;
    modalWindow.layer.shadowRadius  = 5.0;
    modalWindow.layer.shadowOffset  = CGSizeMake(0, 1);
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPath];
    
    [shadowPath moveToPoint:CGPointMake(0, 0)];
    [shadowPath addLineToPoint:CGPointMake(modalWindow.bounds.size.width, 0)];
    [shadowPath addLineToPoint:CGPointMake(modalWindow.bounds.size.width, modalWindow.bounds.size.height)];
    [shadowPath addLineToPoint:CGPointMake(0, modalWindow.bounds.size.height)];
    [shadowPath closePath];
    
    [shadowPath moveToPoint:CGPointMake(2, 2)];
    [shadowPath addLineToPoint:CGPointMake(2, modalWindow.bounds.size.height - 4)];
    [shadowPath addLineToPoint:CGPointMake(modalWindow.bounds.size.width - 4, modalWindow.bounds.size.height - 4)];
    [shadowPath addLineToPoint:CGPointMake(modalWindow.bounds.size.width - 4, 2)];
    [shadowPath closePath];
    
    modalWindow.layer.shadowPath = [shadowPath CGPath];
    
    // create shield window
    //
    shieldWindow = [[UIWindow alloc] initWithFrame:view.bounds];
    
    shieldWindow.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    shieldWindow.alpha = 0.0;
    
    // add to view hierarchy
    //
    [view addSubview:shieldWindow];
    [view addSubview:modalWindow];
    
    // place modal
    //
    modalWindow.center = view.window.center;
    
    // make visible
    //
    [shieldWindow makeKeyAndVisible];
    [modalWindow makeKeyAndVisible];
    
    // animate in (if desired)
    //
    if (animated)
    {
        CGPoint destinationPoint = modalWindow.center;
        CGPoint offScreenCenter  = CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, [UIScreen mainScreen].bounds.size.height * 1.5);
        modalWindow.center       = offScreenCenter;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.75];
        
        modalWindow.center = destinationPoint;
        shieldWindow.alpha = 1.0;
        
        [UIView commitAnimations];
    }
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    [modalWindow.rootViewController viewWillDisappear:YES];
    
    // animate out (if desired) & remove
    //
    if (animated)
    {
        CGPoint destinationPoint = CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, [UIScreen mainScreen].bounds.size.height * 1.5);
        
        [UIView animateWithDuration:0.75
                         animations:^(void)
                         {
                             modalWindow.center = destinationPoint;
                             shieldWindow.alpha = 0.0;
                         }
                         completion:^(BOOL finished)
                         {
                             [modalWindow  removeFromSuperview];
                             [shieldWindow removeFromSuperview];
                             
                             [modalWindow  release];
                             [shieldWindow release];
                         }];
    }
    else
    {
        [modalWindow  removeFromSuperview];
        [shieldWindow removeFromSuperview];
        
        [modalWindow  release];
        [shieldWindow release];
    }
}

@end