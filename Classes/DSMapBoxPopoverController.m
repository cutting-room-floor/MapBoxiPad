//
//  DSMapBoxPopoverController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxPopoverController.h"

#import "RMMapView.h"
#import "RMMapContents.h"
#import "RMProjection.h"

@implementation DSMapBoxPopoverController

@synthesize projectedPoint;

- (void)dismissPopoverAnimated:(BOOL)animated
{
    [super dismissPopoverAnimated:animated];
    
    [self.delegate popoverControllerDidDismissPopover:self];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    if ([view isKindOfClass:[RMMapView class]])
    {
        CGPoint attachPoint     = CGPointMake(rect.origin.x /*+ (rect.size.width / 2)*/, rect.origin.y /*+ (rect.size.height / 2)*/);
        RMLatLong attachLatLong = [((RMMapView *)view).contents pixelToLatLong:attachPoint];

        self.projectedPoint = [((RMMapView *)view).contents.projection latLongToPoint:attachLatLong];
    }

    [super presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

@end