//
//  DSMapBoxLayerAddNavigationController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxAlphaModalNavigationController : UINavigationController
{
    UIImageView *backgroundImageView;
    UIImage *backgroundImage;
}

@property (nonatomic, retain) UIImage *backgroundImage;

@end

#pragma mark -

@interface UIViewController (UIViewController_CustomUIAdditions)

- (void)prepareNavigationControllerForAlphaModal:(DSMapBoxAlphaModalNavigationController *)navigationController;

@end