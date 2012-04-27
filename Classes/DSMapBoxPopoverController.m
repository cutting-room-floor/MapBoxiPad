//
//  DSMapBoxPopoverController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxPopoverController.h"

#import "RMMapView.h"

@implementation DSMapBoxPopoverController

@synthesize presentingView;
@synthesize arrowDirection;
@synthesize projectedPoint;

- (void)dismissPopoverAnimated:(BOOL)animated
{
    self.presentingView = nil;
    
    [super dismissPopoverAnimated:animated];

    // this is normally only called when the user takes action to dismiss the popover
    //
    [self.delegate popoverControllerDidDismissPopover:self];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    self.presentingView = nil;
    
    // if attached to a map, track the view & the attach point
    //
    if ([view isKindOfClass:[RMMapView class]])
    {
        self.presentingView = view;
        
        CGPoint attachPoint     = CGPointMake(rect.origin.x, rect.origin.y);
        CLLocationCoordinate2D attachLatLong = [((RMMapView *)view) pixelToCoordinate:attachPoint];

        self.projectedPoint = [((RMMapView *)view) coordinateToProjectedPoint:attachLatLong];
    }

    // determine best arrow direction based on screen location
    //
    UIPopoverArrowDirection direction = UIPopoverArrowDirectionDown;
    
    if (CGRectGetMidY(rect) < 200)
        direction = UIPopoverArrowDirectionUp;

    [super presentPopoverFromRect:rect inView:view permittedArrowDirections:direction animated:animated];

    // remember for later (see https://github.com/developmentseed/MapBoxiPad/issues/178)
    //
    self.arrowDirection = direction;
}

@end