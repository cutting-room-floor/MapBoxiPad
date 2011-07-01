    //
//  DSMapBoxLayerAddNavigationController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddNavigationController.h"

@implementation DSMapBoxLayerAddNavigationController

- (void)viewDidLoad
{
    self.navigationBar.tintColor = [UIColor blackColor];
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