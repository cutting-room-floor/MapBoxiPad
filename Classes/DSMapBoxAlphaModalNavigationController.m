    //
//  DSMapBoxAlphaModalNavigationController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxAlphaModalNavigationController.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxAlphaModalNavigationController ()

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UITapGestureRecognizer *outsideTapRecognizer;

@end

#pragma mark -

@implementation DSMapBoxAlphaModalNavigationController

@synthesize baseView;
@synthesize backgroundImageView;
@synthesize outsideTapRecognizer;

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    self.navigationBar.barStyle = UIBarStyleBlackTranslucent;

    // image background with poor man's blur
    //
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 540, 620)];
    
    self.backgroundImageView.contentMode = UIViewContentModeBottom;
    self.backgroundImageView.alpha       = 0.5;
    
    [[self.backgroundImageView layer] setRasterizationScale:0.5];
    [[self.backgroundImageView layer] setShouldRasterize:YES];
    
    [self.view insertSubview:self.backgroundImageView atIndex:0];
    
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
    
    if ( ! self.backgroundImageView.image && self.modalPresentationStyle == UIModalPresentationFormSheet)
    {
        // Not totally in love with manually accessing the main app view,
        // but how else could we do this? Also note that we don't retain
        // the view, since, assuming we are modal, it is below us and 
        // isn't going anywhere.
        //
        self.baseView = [[UIApplication sharedApplication].keyWindow.subviews objectAtIndex:0];
            
        BOOL viewIsFullscreen = ((self.baseView.bounds.size.width >= 748 && self.baseView.bounds.size.width <= 768 && self.baseView.bounds.size.height >= 1004 && self.baseView.bounds.size.height <= 1024) ||
                                (self.baseView.bounds.size.height >= 748 && self.baseView.bounds.size.height <= 768 && self.baseView.bounds.size.width >= 1004 && self.baseView.bounds.size.height <= 1024));

        if (viewIsFullscreen)
        {
            // take snapshot of main view to fake background
            //
            // start with a vertical slice of the middle, slightly taller than modal
            //
            UIGraphicsBeginImageContext(CGSizeMake(540, self.baseView.bounds.size.height - ((self.baseView.bounds.size.height - 620) / 2)));

            // translate & clip layer before rendering for performance
            //
            CGContextTranslateCTM(UIGraphicsGetCurrentContext(), (self.baseView.bounds.size.width - 540) / -2, 0);
            CGContextClipToRect(UIGraphicsGetCurrentContext(), CGRectMake((self.baseView.bounds.size.width - 540) / 2, 0, 540, self.baseView.bounds.size.height - ((self.baseView.bounds.size.height - 620) / 2)));

            // render to context
            //
            [self.baseView.layer renderInContext:UIGraphicsGetCurrentContext()];

            // set image from it
            //
            self.backgroundImageView.image = UIGraphicsGetImageFromCurrentImageContext();

            // clean up
            //
            UIGraphicsEndImageContext();
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.modalPresentationStyle == UIModalPresentationFormSheet)
    {
        self.outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        
        [self.outsideTapRecognizer setNumberOfTapsRequired:1];
        
        self.outsideTapRecognizer.cancelsTouchesInView = NO;
        
        [self.view.window addGestureRecognizer:self.outsideTapRecognizer];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.outsideTapRecognizer)
    {
        [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
    
        [self.outsideTapRecognizer removeTarget:self action:@selector(handleGesture:)];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:self.view.window];    
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

- (void)handleGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [recognizer locationInView:nil];
        
        if ( ! [self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]) 
            [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        CGFloat delta = (self.baseView.bounds.size.height / 2) - (self.view.bounds.size.height / 2);
        
        [UIView beginAnimations:nil context:nil];
        
        if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
            [UIView setAnimationDuration:0.3];
        else 
            [UIView setAnimationDuration:0.25];
        
        self.backgroundImageView.center = CGPointMake(self.backgroundImageView.center.x, self.backgroundImageView.center.y + delta);
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        CGFloat delta = (self.baseView.bounds.size.height / 2) - (self.view.bounds.size.height / 2);
        
        [UIView beginAnimations:nil context:nil];

        if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
            [UIView setAnimationDuration:0.3];
        else 
            [UIView setAnimationDuration:0.25];

        self.backgroundImageView.center = CGPointMake(self.backgroundImageView.center.x, self.backgroundImageView.center.y - delta);
        
        [UIView commitAnimations];
    }
}

@end