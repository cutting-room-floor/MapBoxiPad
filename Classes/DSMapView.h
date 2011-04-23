//
//  DSMapView.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/8/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapView.h"

@class DSTiledLayerMapView;

@protocol DSMapBoxInteractivityDelegate

@required

- (void)presentInteractivityOnMapView:(RMMapView *)aMapView atPoint:(CGPoint)point;
- (void)hideInteractivityAnimated:(BOOL)animated;

@end

#pragma mark -

@interface DSMapView : RMMapView
{
    BOOL touchesMoved;
    id <DSMapBoxInteractivityDelegate>interactivityDelegate;
    NSInvocationOperation *interactivityOperation;
    CGPoint lastInteractivityPoint;
}

@property (nonatomic, assign) id <DSMapBoxInteractivityDelegate>interactivityDelegate;

- (DSMapView *)topMostMapView;
- (void)insertLayerMapView:(DSTiledLayerMapView *)layerMapView;

@end