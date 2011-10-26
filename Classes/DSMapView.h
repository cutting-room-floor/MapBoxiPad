//
//  DSMapView.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/8/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMMapView.h"

@class DSMapBoxTiledLayerMapView;

@protocol DSMapBoxInteractivityDelegate

@required

- (void)presentInteractivityAtPoint:(CGPoint)point;
- (void)hideInteractivityAnimated:(BOOL)animated;

@end

#pragma mark -

@interface DSMapView : RMMapView

@property (nonatomic, assign) id <DSMapBoxInteractivityDelegate>interactivityDelegate;
@property (nonatomic, readonly, retain) DSMapView *topMostMapView;

- (void)insertLayerMapView:(DSMapBoxTiledLayerMapView *)layerMapView;

@end