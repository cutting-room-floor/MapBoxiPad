//
//  DSMapBoxMailComposeViewController.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/16/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "DSMapBoxMailComposeViewController.h"

@implementation DSMapBoxMailComposeViewController

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.modalPresentationStyle = UIModalPresentationPageSheet;
        
        self.navigationBar.barStyle = UIBarStyleBlack;
        
        self.visibleViewController.navigationItem.rightBarButtonItem.style     = UIBarButtonItemStyleBordered;
        self.visibleViewController.navigationItem.rightBarButtonItem.tintColor = kMapBoxBlue;
    }
    
    return self;
}

@end