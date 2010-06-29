//
//  RMCircle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/28/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapLayer.h"
#import "RMLatLong.h"

@class RMMapContents;
@class RMMapView;

@interface RMCircle : RMMapLayer <RMMovingMapLayer>
{
    RMProjectedPoint projectedLocation;

    UIColor *lineColor;
    UIColor *fillColor;

    CGMutablePathRef path;
    
    float lineWidth;
    
    CGPathDrawingMode drawingMode;
    
    BOOL scaleLineWidth;
    BOOL enableDragging;
    BOOL enableRotation;
    
    float renderedScale;
    
    RMMapContents *contents;
}

@property CGPathDrawingMode drawingMode;
@property float lineWidth;
@property BOOL	scaleLineWidth;
@property (assign) BOOL enableDragging;
@property (assign) BOOL enableRotation;
@property (readwrite, assign) UIColor *lineColor;
@property (readwrite, assign) UIColor *fillColor;

- (id)initWithContents:(RMMapContents *)inContents centerCoordinate:(RMLatLong)centerCoordinate radius:(float)meterRadius;
- (id)initForMap:(RMMapView *)map centerCoordinate:(RMLatLong)centerCoordinate radius:(float)meterRadius;

@end