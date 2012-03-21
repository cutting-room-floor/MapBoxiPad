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

@property (nonatomic, strong) UITapGestureRecognizer *outsideTapRecognizer;

@end

#pragma mark -

@implementation DSMapBoxAlphaModalNavigationController

@synthesize outsideTapRecognizer;

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
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

@end