    //
//  DSMapBoxLayerAddNavigationController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddNavigationController.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxLayerAddNavigationController

@synthesize backgroundImage;

- (void)viewDidLoad
{
    self.navigationBar.tintColor = [UIColor blackColor];
    
    backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    // poor man's blur
    //
    [[backgroundImageView layer] setRasterizationScale:0.5];
    [[backgroundImageView layer] setShouldRasterize:YES];
    
    [self.view insertSubview:backgroundImageView atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    backgroundImageView.frame = self.view.bounds;
    backgroundImageView.alpha = 0.0;
    
    backgroundImageView.image = self.backgroundImage;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    
    backgroundImageView.alpha = 0.5;
    
    [UIView commitAnimations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    
    backgroundImageView.alpha = 0.0;
    
    [UIView commitAnimations];
}

- (void)dealloc
{
    [backgroundImageView release];
    [backgroundImage release];

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

@end

#pragma mark -

@implementation UIViewController (UIViewController_CustomUIAdditions)

- (void)prepareNavigationControllerForAlphaModal:(DSMapBoxLayerAddNavigationController *)navigationController
{
    if (navigationController.modalPresentationStyle == UIModalPresentationFormSheet)
    {
        UIGraphicsBeginImageContext(self.view.bounds.size);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGImageRef croppedImage = CGImageCreateWithImageInRect(fullImage.CGImage, CGRectMake((self.view.bounds.size.width  - 540) / 2, 
                                                                                             (self.view.bounds.size.height - 620) / 2, 
                                                                                             540, 
                                                                                             620));
        
        navigationController.backgroundImage = [UIImage imageWithCGImage:croppedImage];
        
        CGImageRelease(croppedImage);
    }
}

@end