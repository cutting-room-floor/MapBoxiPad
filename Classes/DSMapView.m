//
//  DSMapView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/8/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapView.h"

@implementation DSMapView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchesMoved = NO;
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchesMoved = YES;
    
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // two-finger tap to zoom out
    //
    if (lastGesture.numTouches == 2 && ! touchesMoved)
        [self zoomOutToNextNativeZoomAt:lastGesture.center animated:YES];
        
    else
        [super touchesEnded:touches withEvent:event];
}

#pragma mark -

- (DSMapView *)topMostMapView
{
    /**
     * This iterates our own peer views, bottom-up, returning the top-most
     * map one, which might just be us.
     */

    DSMapView *topMostMapView = self;
    
    for (UIView *peerView in [[self superview] subviews])
    {
        if ( ! [peerView isKindOfClass:[RMMapView class]])
            break;
        
        topMostMapView = (DSMapView *)peerView;
    }
    
    return topMostMapView;
}

- (void)insertLayerMapView:(DSTiledLayerMapView *)layerMapView
{
    [[self superview] insertSubview:(UIView *)layerMapView aboveSubview:[self topMostMapView]];
}

@end