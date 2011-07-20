    //
//  DSMapBoxAlphaModalNavigationController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxAlphaModalNavigationController.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxAlphaModalNavigationController

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    self.navigationBar.barStyle    = UIBarStyleBlack;
    self.navigationBar.translucent = YES;

    // image background with poor man's blur
    //
    backgroundImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 540, 620)] autorelease];
    
    backgroundImageView.contentMode = UIViewContentModeBottom;
    backgroundImageView.alpha       = 0.5;
    
    [[backgroundImageView layer] setRasterizationScale:0.5];
    [[backgroundImageView layer] setShouldRasterize:YES];
    
    [self.view insertSubview:backgroundImageView atIndex:0];
    
    // watch for keyboard show/hide to adjust background image in landscape
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification 
                                               object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification 
                                               object:self.view.window];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( ! backgroundImageView.image)
    {
        NSAssert(self.modalPresentationStyle == UIModalPresentationFormSheet, @"alpha modals only supported with form sheet presentation");

        // Not totally in love with manually accessing the main app view,
        // but how else could we do this? Also note that we don't retain
        // the view, since, assuming we are modal, it is below us and 
        // isn't going anywhere.
        //
        baseView = [[UIApplication sharedApplication].keyWindow.subviews objectAtIndex:0];
            
        BOOL viewIsFullscreen = ((baseView.bounds.size.width >= 748 && baseView.bounds.size.width <= 768 && baseView.bounds.size.height >= 1004 && baseView.bounds.size.height <= 1024) ||
                                 (baseView.bounds.size.height >= 748 && baseView.bounds.size.height <= 768 && baseView.bounds.size.width >= 1004 && baseView.bounds.size.height <= 1024));
        
        NSAssert(viewIsFullscreen, @"main app view must be full screen for iPad");
        
       // take snapshot of main view to fake background
       //
       // start with a vertical slice of the middle, slightly taller than modal
       //
       UIGraphicsBeginImageContext(CGSizeMake(540, baseView.bounds.size.height - ((baseView.bounds.size.height - 620) / 2)));
       
       // translate & clip layer before rendering for performance
       //
       CGContextTranslateCTM(UIGraphicsGetCurrentContext(), (baseView.bounds.size.width - 540) / -2, 0);
       CGContextClipToRect(UIGraphicsGetCurrentContext(), CGRectMake((baseView.bounds.size.width - 540) / 2, 0, 540, baseView.bounds.size.height - ((baseView.bounds.size.height - 620) / 2)));
       
       // render to context
       //
       [baseView.layer renderInContext:UIGraphicsGetCurrentContext()];
       
       // set image from it
       //
       backgroundImageView.image = UIGraphicsGetImageFromCurrentImageContext();

       // clean up
       //
       UIGraphicsEndImageContext();
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:self.view.window];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

#pragma mark -

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        CGFloat delta = (baseView.bounds.size.height / 2) - (self.view.bounds.size.height / 2);
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        
        backgroundImageView.center = CGPointMake(backgroundImageView.center.x, backgroundImageView.center.y + delta);
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        CGFloat delta = (baseView.bounds.size.height / 2) - (self.view.bounds.size.height / 2);
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        
        backgroundImageView.center = CGPointMake(backgroundImageView.center.x, backgroundImageView.center.y - delta);
        
        [UIView commitAnimations];
    }
}

@end