//
//  DSMapBoxPopoverController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RMFoundation.h"

@interface DSMapBoxPopoverController : UIPopoverController
{
    RMProjectedPoint projectedPoint;
}

@property (nonatomic, assign) RMProjectedPoint projectedPoint;

@end