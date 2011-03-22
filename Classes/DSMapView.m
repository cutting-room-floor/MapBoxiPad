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

@end